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
from datetime import datetime

def execute_model(model, model_size, base_image, platform, processor, input_file, output_dir):
    """Executes the model and saves output to a file."""
    date_fmt = datetime.now().strftime("%Y-%m-%d")
    output_file = os.path.join(output_dir, f"{date_fmt}.txt")
    
    os.makedirs(output_dir, exist_ok=True)
    
    command = [model, input_file, "--model", model_size]
    
    with open(output_file, "w", encoding="utf-8") as out_file:
        subprocess.run(command, stdout=out_file, stderr=subprocess.STDOUT, check=True)
    
    print(f"Model executed and output saved to {output_file}")
    return output_file

def calculate_eval(model, model_size, base_image, platform, processor, reference_file, hypothesis_file, output_dir):
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
        "cuda_ver": "",
    }

    # Performance data
    performance = {
        "vram": "",
        "time_real": "",
        "time_sys": "",
        "time_user": "",
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
    
    hypothesis_file = execute_model(args.model, args.model_size, args.base_image, args.platform, args.processor, args.input_file, args.output_dir)
    
    calculate_eval(args.model, args.model_size, args.base_image, args.platform, args.processor, args.reference_file, hypothesis_file, args.output_dir)
