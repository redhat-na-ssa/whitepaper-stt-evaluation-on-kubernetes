#
# USAGE
# BASIC = 
# python3.12 evaluation-scripts/evaluation.py
#
# CUSTOM = 
# python3.12 evaluation-scripts/evaluation.py \
#   --model whisper \
#   --model_name tiny.en \
#   --language en \
#   --input input-samples/harvard.mp3 \
#   --model_dir /tmp \
#   --output_dir /tmp \
#   --reference_file ground-truth/harvard.txt \
#   --hypothesis_file /tmp/harvard.txt

import subprocess
import argparse
import csv
import os
import time
import jiwer
import sys
import torch  # PyTorch for detecting FP16/FP32 support
from datetime import datetime
import logging

PYTHON_EXECUTABLE = "python3.12"

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
            logger.error("Unknown OS")
            return "Unknown OS"

def get_floating_point_precision():
    return sys.float_info.dig

def get_float_format():
    if torch.cuda.is_available():
        if torch.cuda.get_device_capability(0)[0] >= 7:
            return "FP16"
        else:
            return "FP32"
    else:
        return "FP32"

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
    if not os.path.exists(hypothesis_path):
        logger.error(f"Error: Hypothesis file '{hypothesis_path}' not found.")
        return {}
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
        logger.error(f"Error evaluating accuracy: {e}")
        return {}

from transcribe_audio import transcribe_audio

def run_whisper(model, input_file, model_name, model_dir, output_dir, reference_file, language, hypothesis_file):

    current_function_name = sys._getframe().f_code.co_name
    logger.debug(f'{current_function_name}: model = {model}')
    logger.debug(f'{current_function_name}: input_file = {input_file}')
    logger.debug(f'{current_function_name}: model_name = {model_name}')
    logger.debug(f'{current_function_name}: model_dir = {model_dir}')
    logger.debug(f'{current_function_name}: output_dir = {output_dir}')
    logger.debug(f'{current_function_name}: output_dir = {output_format}')
    logger.debug(f'{current_function_name}: reference_file = {reference_file}')
    logger.debug(f'{current_function_name}: language = {language}')
    logger.debug(f'{current_function_name}: hypothesis_file = {hypothesis_file}')

    # Transcribe
    start_time = time.time()
    
    transcribe_audio(
        model=model,
        input_file=input_file,
        output_dir=output_dir,
        model_name=model_name,
        model_dir=model_dir,
        output_format="txt",
        language=language,
        task="transcribe"
    )

    end_time = time.time()
    elapsed_time = end_time - start_time
    
    logger.info(f'{current_function_name}: Transcription of {input_file} by {model_name} was completed in {elapsed_time:.3f} seconds.')

    # Evaluate
    accuracy_start_time = time.time()
    accuracy_metrics = evaluate_accuracy(hypothesis_file, reference_file)
    logger.debug(f'{current_function_name}: Time to evaluate accuracy = {time.time() - accuracy_start_time:.5f} seconds.')

    os.makedirs(output_dir, exist_ok=True)
        
    float_format = get_float_format()
    
    timestamp = datetime.now().strftime("%H%M%S")
    date_today = datetime.now().strftime("%Y-%m-%d")
    csv_filename = f"{timestamp}.csv"
    csv_temp_path = os.path.join(output_dir, csv_filename)
    file_exists = os.path.isfile(csv_temp_path)
    
    executed_command = f"{PYTHON_EXECUTABLE} evaluation-scripts/evaluation.py --model_name {model_name} --input {input_file} --reference_file {reference_file} --language {language} --output_dir {output_dir} --output_format txt"
    
    #
    # Write out the benchmark results. 
    #
    with open(csv_temp_path, mode="a", newline="") as file:
        fieldnames = ["date", "timestamp", "model", "model_name", "model_dir", "input_file", "output_dir", "start_time", "end_time", "duration", "wer", "mer", "wil", "wip", "cer", "floating_point_format", "executed_command"]
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        
        if not file_exists:
            writer.writeheader()
        
        row_data = {
            "date": date_today,
            "timestamp": timestamp,
            "model": model,
            "input_file": input_file,
            "model_name": model_name,
            "model_dir": model_dir,
            "output_dir": output_dir,
            "start_time": start_time,
            "end_time": end_time,
            "duration": elapsed_time,
            "wer": accuracy_metrics.get("wer", "N/A"),
            "mer": accuracy_metrics.get("mer", "N/A"),
            "wil": accuracy_metrics.get("wil", "N/A"),
            "wip": accuracy_metrics.get("wip", "N/A"),
            "cer": accuracy_metrics.get("cer", "N/A"),
            "floating_point_format": float_format,
            "executed_command": executed_command
        }
        writer.writerow(row_data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run Whisper with configurable arguments.")
    parser.add_argument("--model", default="whisper", help="Path to the Whisper executable.")
    parser.add_argument("--model_name", default="tiny.en", help="Name of the Whisper model to use.")
    parser.add_argument("--input", default="input-samples/harvard.wav", help="Path to the input audio file.")
    parser.add_argument("--model_dir", default="/tmp/", help="Directory for storing the model.")
    parser.add_argument("--output_dir", default="metrics/", help="Directory for storing the output.")
    parser.add_argument("--output_format", default="txt", help="Format of the output file.")
    parser.add_argument("--reference_file", default="ground-truth/harvard.txt", help="Path to the reference text file for accuracy evaluation.")
    parser.add_argument("--hypothesis_file", default="metrics/harvard.txt", help="Path to the hypothesis text file.")
    parser.add_argument("--language", default="en", help="Language for Whisper transcription.")
    parser.add_argument("--log_level", default="INFO", help="Sets python logging to ERROR, WARNING (default), INFO or DEBUG")

    
    args = parser.parse_args()
    logger = logging.getLogger()
    logging.basicConfig(level=args.log_level)
    run_whisper(args.model, args.input, args.model_name, args.model_dir, args.output_dir, args.reference_file, args.language, args.hypothesis_file, args.output_format)

