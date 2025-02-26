# USAGE 
# python3 evaluations/wer.py <reference_file> <hypothesis_file> <output_dir>
# python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-tiny-ubuntu-jfk-transcript-inaugural-address-20-january-1961-1-gpu-2025-02-26_20-37-29.txt evaluations

import jiwer
import argparse
import csv
import os

def calculate_wer(reference_file, hypothesis_file, output_dir):
    with open(reference_file, 'r', encoding='utf-8') as ref_file:
        reference = ref_file.read().strip()
    
    with open(hypothesis_file, 'r', encoding='utf-8') as hyp_file:
        hypothesis = hyp_file.read().strip()

    # Compute error rates
    wer = jiwer.wer(reference, hypothesis)
    mer = jiwer.mer(reference, hypothesis)
    wil = jiwer.wil(reference, hypothesis)
    wip = jiwer.wip(reference, hypothesis)
    cer = jiwer.cer(reference, hypothesis)

    # Print results
    print(f"Word Error Rate (WER): {wer:.2%}")
    print(f"Match Error Rate (MER): {mer:.2%}")
    print(f"Word Information Lost (WIL): {wil:.2%}") 
    print(f"Word Information Preserved (WIP): {wip:.2%}") 
    print(f"Character Error Rate (CER): {cer:.2%}")    

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    output_csv = os.path.join(output_dir, "wer_results.csv")

    # Append results to CSV if file exists, otherwise create and write header
    file_exists = os.path.isfile(output_csv)

    with open(output_csv, 'a', newline='', encoding='utf-8') as csvfile:
        csv_writer = csv.writer(csvfile)
        if not file_exists:
            csv_writer.writerow(["Hypothesis File", "WER", "MER", "WIL", "WIP", "CER"])  # Write header only if new file
        csv_writer.writerow([os.path.basename(hypothesis_file), wer, mer, wil, wip, cer])

    print(f"Results appended to {output_csv}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate error rates between two text files using jiwer and save to CSV.")
    parser.add_argument("reference_file", type=str, help="Path to the reference text file.")
    parser.add_argument("hypothesis_file", type=str, help="Path to the hypothesis text file.")
    parser.add_argument("output_dir", type=str, help="Path to the output directory where CSV will be saved.")
    
    args = parser.parse_args()
    calculate_wer(args.reference_file, args.hypothesis_file, args.output_dir)
