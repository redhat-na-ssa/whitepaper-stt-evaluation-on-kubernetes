"""
USAGE:
    python3 script.py <reference_file> <output_dir> --input_file <input_file>

EXAMPLE:

    python3 evaluations/script.py \
        --model whisper \
        --model_size tiny.en \
        --base_image ubuntu \
        --platform ubuntu \
        --processor gpu \
        --input_file audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
        ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
        output

Arguments:
    Required:
        <reference_file>   - Path to the reference transcript file.
        <output_dir>       - Directory where results and hypothesis output will be saved.
        --input_file       - Path to the input file for model execution.
    Optional (defaults provided):
        --model            - Model name (default: "whisper").
        --model_size       - Model size (default: "tiny.en").
        --base_image       - Base image used (default: "ubuntu").
        --platform         - Platform information (default: "rhel").
        --processor        - Processor type (default: "gpu").
"""

import jiwer
import argparse
import csv
import os
import subprocess
import time
from datetime import datetime

def execute_model(model, model_size, base_image, platform, processor, input_file, output_dir):
    """Executes the model, captures timing metrics, and saves output to a file."""
    date_fmt = datetime.now().strftime("%Y-%m-%d")
    output_file = os.path.join(output_dir, f"{date_fmt}.txt")
    
    os.makedirs(output_dir, exist_ok=True)

    # Capture timing using built-in time module
    start_real = time.time()
    start_process = time.process_time()

    try:
        result = subprocess.run(
            [model, input_file, "--model", model_size],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        
        end_real = time.time()
        end_process = time.process_time()

        real_time = round(end_real - start_real, 3)  # Total elapsed time
        user_time = round(end_process - start_process, 3)  # CPU time used by the process
        sys_time = 0  # Python's time module does not track system time separately

        # Write model output to file
        with open(output_file, "w", encoding="utf-8") as out_file:
            out_file.write(result.stdout)
        
        print(f"Model executed and output saved to {output_file}")
        return output_file, real_time, user_time, sys_time

    except subprocess.CalledProcessError as e:
        print(f"Error executing model: {e}")
        return None, "", "", ""

def get_cuda_version():
    """Fetch CUDA version using nvidia-smi and parse output."""
    try:
        result = subprocess.run(["nvidia-smi"], capture_output=True, text=True, check=True)
        for line in result.stdout.split("\n"):
            if "CUDA Version" in line:
                return line.split("CUDA Version:")[1].split()[0]  # Extract the version number
    except Exception as e:
        print(f"Failed to get CUDA version: {e}")
    return "Unknown"

def calculate_eval(model, model_size, base_image, platform, processor, reference_file, hypothesis_file, output_dir, real_time, user_time, sys_time):
    """Calculates error rates between a reference and hypothesis text and writes results to a CSV file."""
    
    # Read reference and hypothesis files
    with open(reference_file, 'r', encoding='utf-8') as ref_file:
        reference = ref_file.read().strip()
    
    with open(hypothesis_file, 'r', encoding='utf-8') as hyp_file:
        hypothesis = hyp_file.read().strip()

    # Metadata
    metadata = {
        "model": model,
        "model_size": model_size,
        "base_image": base_image,
        "platform": platform,
        "processor": processor,
        "image_size": "",
        "cuda_ver": get_cuda_version(),
    }

    # Performance data
    performance = {
        "vram": "",
        "time_real": real_time,
        "time_sys": sys_time,
        "time_user": user_time,
        "response_latency": "",
        "qps": "",
        "max_concur_endpoints": "",
        "float_point": "",
    }

    # Compute error rates
    error_rates = {
        "wer": jiwer.wer(reference, hypothesis),
        "mer": jiwer.mer(reference, hypothesis),
        "wil": jiwer.wil(reference, hypothesis),
        "wip": jiwer.wip(reference, hypothesis),
        "cer": jiwer.cer(reference, hypothesis),
    }

    # Print results
    for metric, value in error_rates.items():
        print(f"{metric.upper()}: {value:.2%}")

    # Save results
    os.makedirs(output_dir, exist_ok=True)
    output_csv = os.path.join(output_dir, "eval_results.csv")
    
    file_exists = os.path.isfile(output_csv)
    
    with open(output_csv, 'a', newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)
        
        if not file_exists:
            headers = ["Hypothesis File"] + list(metadata.keys()) + list(performance.keys()) + list(error_rates.keys())
            csv_writer.writerow(headers)  # Write header only if file is new
        
        csv_writer.writerow([os.path.basename(hypothesis_file)] + list(metadata.values()) + list(performance.values()) + list(error_rates.values()))
    
    print(f"Results appended to {output_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate error rates between two text files using jiwer and save to CSV.")
    parser.add_argument("reference_file", type=str, help="Path to the reference text file.")
    parser.add_argument("output_dir", type=str, help="Path to the output directory where CSV will be saved.")
    parser.add_argument("--model", type=str, default="whisper", help="Model name.")
    parser.add_argument("--model_size", type=str, default="tiny.en", help="Model size.")
    parser.add_argument("--base_image", type=str, default="ubuntu", help="Base image used.")
    parser.add_argument("--platform", type=str, default="rhel", help="Platform information.")
    parser.add_argument("--processor", type=str, default="gpu", help="Processor type.")
    parser.add_argument("--input_file", type=str, required=True, help="Path to the input file for model execution.")
    
    args = parser.parse_args()
    
    hypothesis_file, real_time, user_time, sys_time = execute_model(
        args.model, args.model_size, args.base_image, args.platform, args.processor, args.input_file, args.output_dir
    )
    
    if hypothesis_file:
        calculate_eval(
            args.model, args.model_size, args.base_image, args.platform, args.processor, 
            args.reference_file, hypothesis_file, args.output_dir, real_time, user_time, sys_time
        )
