# USAGE 
# python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-tiny-ubuntu-jfk-transcript-inaugural-address-20-january-1961-1-gpu-2025-02-26_20-37-29.txt

import jiwer
import argparse

def calculate_wer(reference_file, hypothesis_file):
    with open(reference_file, 'r', encoding='utf-8') as ref_file:
        reference = ref_file.read().strip()
    
    with open(hypothesis_file, 'r', encoding='utf-8') as hyp_file:
        hypothesis = hyp_file.read().strip()

    # word error rate 
    wer = jiwer.wer(reference, hypothesis)
    print(f"Word Error Rate (WER): {wer:.2%}")

    # match error rate
    mer = jiwer.mer(reference, hypothesis)
    print(f"Match Error Rate (MER): {mer:.2%}")

    # word information lost
    wil = jiwer.wil(reference, hypothesis)
    print(f"Word Information Lost (WIL): {wil:.2%}") 

    # word information preserved
    wip = jiwer.wip(reference, hypothesis)
    print(f"Word Information Preserved (WIP): {wip:.2%}") 

    # character error rate
    cer = jiwer.cer(reference, hypothesis)
    print(f"Character Error Rate (CER): {cer:.2%}")    

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate error rates between two text files using jiwer.")
    parser.add_argument("reference_file", type=str, help="Path to the reference text file.")
    parser.add_argument("hypothesis_file", type=str, help="Path to the hypothesis text file.")
    
    args = parser.parse_args()
    calculate_wer(args.reference_file, args.hypothesis_file)
