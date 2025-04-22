d#!/usr/bin/env bash

set -euo pipefail

# === Parse input arguments ===
MODEL_NAME="$1"       # e.g., tiny.en-ubi9-minimal
DEVICE="$2"           # e.g., cpu or gpu
AUDIO_SAMPLE="$3"     # e.g., harvard

# === Timestamp ===
DATE=$(date +%F)
TIME=$(date +%H%M%S)

# === Derived values ===
TAG="${MODEL_NAME//./-}"
CONTAINER_NAME="whisper-${TAG}-${DEVICE}"
IMAGE_NAME="whisper:${MODEL_NAME}"
AUDIO_PATH="/outside/input-samples/${AUDIO_SAMPLE}.wav"
MOUNT_DIR="$(pwd)/data"
CSV_FILE="test_results.csv"

# === Init CSV ===
if [ ! -f "$CSV_FILE" ]; then
  echo "date,timestamp,container_name,model,audio_source,cold_start_sec,warm_start_sec" > "$CSV_FILE"
fi

echo "▶️ [$DATE $TIME] Running test for $CONTAINER_NAME"

# === Cold Start ===
COLD_TIME=$(
  podman run --rm -i --name "$CONTAINER_NAME" \
    -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
    /bin/bash -c "TIMEFORMAT='%R'; { time whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} >/dev/null 2>&1; } 2>&1"
)

# === Warm Start ===
WARM_TIME=$(
  podman run --rm -i --name "$CONTAINER_NAME" \
    -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
    /bin/bash -c "whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} >/dev/null 2>&1; TIMEFORMAT='%R'; { time whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} >/dev/null 2>&1; } 2>&1"
)

# === Write to CSV ===
echo "$DATE,$TIME,$CONTAINER_NAME,${MODEL_NAME%%-*},$AUDIO_PATH,$COLD_TIME,$WARM_TIME" >> "$CSV_FILE"
echo "✅ Logged: $DATE,$TIME,$CONTAINER_NAME,..."
