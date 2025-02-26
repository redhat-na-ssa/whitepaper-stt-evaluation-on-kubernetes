#!/bin/bash

# USAGE
# bash transcribe.sh medium.en jfk-audio-rice-university-12-september-1962

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