#!/bin/bash

# USAGE
# bash evaluate.sh medium.en jfk-audio-rice-university-12-september-1962 jfk-transcript-rice-university-12-september-1962

# Set default values
MODEL=${1:-tiny.en}
INPUT=${2:-jfk-audio-inaugural-address-20-january-1961}
TRANSCRIPT=${3:-jfk-transcript-inaugural-address-20-january-1961}

# Define paths
GROUND_TRUTH_FILE="ground-truth/$TRANSCRIPT.txt"
OUTPUT_FILE="output/whisper-${MODEL}-ubuntu-${INPUT}-gpu-1-$(date +"%Y-%m-%d_%H-%M-%S").txt"
SCRIPT="wer.py"

# Ensure required files exist
if [[ ! -f "$GROUND_TRUTH_FILE" ]]; then
    echo "Error: Ground truth file '$GROUND_TRUTH_FILE' not found!"
    exit 1
fi

if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "Error: Transcription output '$OUTPUT_FILE' not found!"
    exit 1
fi

# Run evaluation
echo "Evaluating accuracy..."
python3 "$SCRIPT" "$GROUND_TRUTH_FILE" "$OUTPUT_FILE"

echo "Evaluation completed."