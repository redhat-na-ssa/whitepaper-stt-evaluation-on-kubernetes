#!/bin/bash

# USAGE
# bash evaluations/transcribe.sh medium.en jfk-audio-rice-university-12-september-1962

# Set default values
MODEL=${1:-tiny.en}  # Allow overriding via CLI argument
INPUT=${2:-jfk-audio-inaugural-address-20-january-1961}

# Define paths
AUDIO_FILE="audio-samples/$INPUT.mp3"
OUTPUT_DIR="output"
DATE_FMT=$(date +"%Y-%m-%d")
OUTPUT_FILE="$OUTPUT_DIR/whisper-${MODEL}-ubuntu-${INPUT}-gpu-1-${DATE_FMT}.txt"

# Ensure the audio file exists
if [[ ! -f "$AUDIO_FILE" ]]; then
    echo "Error: Audio file '$AUDIO_FILE' not found!"
    exit 1
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Run transcription
echo "Running: whisper $AUDIO_FILE --model $MODEL > $OUTPUT_FILE"
time whisper "$AUDIO_FILE" --model "$MODEL" > "$OUTPUT_FILE"

echo "Transcription saved to $OUTPUT_FILE"

# Determine the reference file dynamically
REFERENCE_FILE="ground-truth/${INPUT}.txt"

if [[ ! -f "$REFERENCE_FILE" ]]; then
    echo "Error: Reference file '$REFERENCE_FILE' not found!"
    exit 1
fi

# Ensure evaluations directory exists
EVAL_DIR="evaluations"
mkdir -p "$EVAL_DIR"

# Run WER evaluation
echo "Running: python3 evaluations/wer.py $REFERENCE_FILE $OUTPUT_FILE $EVAL_DIR"
time python3 evaluations/wer.py "$REFERENCE_FILE" "$OUTPUT_FILE" "$EVAL_DIR"

echo "WER evaluation completed. Results saved in $EVAL_DIR/wer_results.csv"