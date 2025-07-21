#!/usr/bin/env python3

"""
compare_transcripts.py

Compares a Whisper-generated transcript to a ground-truth reference transcript
using standard ASR evaluation metrics from the `jiwer` library.

USAGE:
    ./compare_transcripts.py <reference.txt> <hypothesis.txt>

ARGUMENTS:
    reference.txt     The ground truth transcription
    hypothesis.txt    The Whisper output transcription to evaluate

OUTPUT:
    Prints the following metrics to stdout in key=value format:
        - WER: Word Error Rate
        - MER: Match Error Rate
        - WIL: Word Information Lost
        - WIP: Word Information Preserved
        - CER: Character Error Rate

EXAMPLE:
    ./compare_transcripts.py data/ground-truth/harvard.txt data/metrics/harvard_cpu.txt
"""

import sys
from jiwer import wer, mer, wil, wip, cer

# Ensure exactly two arguments were passed in
if len(sys.argv) != 3:
    print("Usage: compare_transcripts.py <reference.txt> <hypothesis.txt>")
    sys.exit(1)

# Load reference (ground truth) transcript
with open(sys.argv[1], "r") as ref_file:
    reference = ref_file.read().strip()

# Load hypothesis (transcribed output)
with open(sys.argv[2], "r") as hyp_file:
    hypothesis = hyp_file.read().strip()

# Calculate jiwer metrics
wer_score = wer(reference, hypothesis)
mer_score = mer(reference, hypothesis)
wil_score = wil(reference, hypothesis)
wip_score = wip(reference, hypothesis)
cer_score = cer(reference, hypothesis)

# Output each metric as key=value (for parsing by shell script)
print(f"WER={wer_score:.4f}")
print(f"MER={mer_score:.4f}")
print(f"WIL={wil_score:.4f}")
print(f"WIP={wip_score:.4f}")
print(f"CER={cer_score:.4f}")
