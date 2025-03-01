# USAGE
# BASIC = python3 evaluations/evaluation.py
# CUSTOM = python3 evaluations/evaluation.py \
#   --model whisper \
#   --input path/to/audio.mp3 \
#   --model_name base.en \
#   --model_dir /models \
#   --output_dir /output

import subprocess
import argparse
import csv
import os
import time
import jiwer
import sys
from datetime import datetime

def get_os_version():
    try:
        result = subprocess.run(["cat", "/etc/redhat-release"], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        try:
            with open("/etc/os-release", "r") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        return line.split("=")[1].strip().strip('"')
        except FileNotFoundError:
            return "Unknown OS"

def get_floating_point_precision():
    return sys.float_info.dig

def get_gpu_info():
    try:
        result = subprocess.run(["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"], capture_output=True, text=True, check=True)
        gpus = result.stdout.strip().split("\n")
        gpu_name = gpus[0] if gpus else "CPU"
        gpu_count = len(gpus) if gpus else 0
        return gpu_name.replace(" ", "_"), gpu_count
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "CPU", 0

def evaluate_accuracy(hypothesis_path, reference_path):
    try:
        with open(hypothesis_path, "r") as hyp_file, open(reference_path, "r") as ref_file:
            hypothesis = hyp_file.read().strip()
            reference = ref_file.read().strip()
        
        wer = jiwer.wer(reference, hypothesis)
        mer = jiwer.mer(reference, hypothesis)
        wil = jiwer.wil(reference, hypothesis)
        wip = jiwer.wip(reference, hypothesis)
        cer = jiwer.cer(reference, hypothesis)
        
        return {"wer": wer, "mer": mer, "wil": wil, "wip": wip, "cer": cer}
    except Exception as e:
        print(f"Error evaluating accuracy: {e}")
        return {}

def run_whisper(model, input_file, model_name, model_dir, output_dir, reference_file):
    command = [
        model, 
        input_file, 
        "--model", model_name, 
        "--model_dir", model_dir, 
        "--output_dir", output_dir
    ]
    
    start_time = time.time()
    try:
        subprocess.run(command, check=True)
        print("Whisper command executed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error executing Whisper: {e}")
    end_time = time.time()
    
    os.makedirs(output_dir, exist_ok=True)
    
    os_version = get_os_version()
    float_precision = get_floating_point_precision()
    gpu_name, gpu_count = get_gpu_info()
    current_date = datetime.now().strftime("%m-%d-%Y")
    
    hypothesis_filename = os.path.basename(input_file).rsplit(".", 1)[0] + ".txt"
    hypothesis_path = os.path.join(output_dir, hypothesis_filename)
    accuracy_metrics = evaluate_accuracy(hypothesis_path, reference_file)
    
    sanitized_input_file = os.path.basename(input_file).replace(".", "_")
    csv_filename = f"evaluation_{current_date}_{model}_{model_name}_{os_version.replace(' ', '_')}_{gpu_name}_{sanitized_input_file}.csv"
    csv_temp_path = os.path.join("/tmp", csv_filename)
    file_exists = os.path.isfile(csv_temp_path)
    
    executed_command = f"python3 evaluations/evaluation.py --model_name {model_name} --input {input_file} --reference_file {reference_file}"
    
    with open(csv_temp_path, mode="a", newline="") as file:
        fieldnames = ["model", "input_file", "model_name", "model_dir", "output_dir", "start_time", "end_time", "duration", "os_version", "float_precision", "gpu_name", "gpu_count", "date", "hypothesis_file", "reference_file", "wer", "mer", "wil", "wip", "cer", "executed_command"]
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
        
        row_data = {
            "model": model,
            "input_file": input_file,
            "model_name": model_name,
            "model_dir": model_dir,
            "output_dir": output_dir,
            "start_time": start_time,
            "end_time": end_time,
            "duration": end_time - start_time,
            "os_version": os_version,
            "float_precision": float_precision,
            "gpu_name": gpu_name,
            "gpu_count": gpu_count,
            "date": current_date,
            "hypothesis_file": hypothesis_filename,
            "reference_file": reference_file,
            "wer": accuracy_metrics.get("wer", "N/A"),
            "mer": accuracy_metrics.get("mer", "N/A"),
            "wil": accuracy_metrics.get("wil", "N/A"),
            "wip": accuracy_metrics.get("wip", "N/A"),
            "cer": accuracy_metrics.get("cer", "N/A"),
            "executed_command": executed_command,
        }
        writer.writerow(row_data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Whisper with configurable arguments.")
    parser.add_argument("--model", default="whisper", help="Path to the Whisper executable.")
    parser.add_argument("--input", default="audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3", help="Path to the input audio file.")
    parser.add_argument("--model_name", default="tiny.en", help="Name of the Whisper model to use.")
    parser.add_argument("--model_dir", default="/tmp", help="Directory for storing the model.")
    parser.add_argument("--output_dir", default="/tmp", help="Directory for storing the output.")
    parser.add_argument("--reference_file", default="ground-truth/jfk-audio-inaugural-address-20-january-1961.txt", help="Path to the reference text file for accuracy evaluation.")
    
    args = parser.parse_args()
    run_whisper(args.model, args.input, args.model_name, args.model_dir, args.output_dir, args.reference_file)
