#!/usr/bin/env bash

set -euo pipefail

# === Parse input arguments ===
MODEL_NAME="$1"           # e.g., tiny.en-ubuntu
DEVICE="$2"               # e.g., cpu or gpu
AUDIO_SAMPLE="$3"         # e.g., harvard
PROFILE="${4:-basic}"     # default to "basic" if not provided

# === Timestamps ===
DATE=$(date +%F)
TIME=$(date +%H%M%S)

# === Derived values ===
TAG="${MODEL_NAME//./-}"
CONTAINER_NAME="whisper-${TAG}-${DEVICE}"
IMAGE_NAME="whisper:${MODEL_NAME}"
AUDIO_PATH="/outside/input-samples/${AUDIO_SAMPLE}.wav"
MOUNT_DIR="$(pwd)/data"
CSV_FILE="test_results.csv"

# === Command Profile Switch ===
case "$PROFILE" in
  none)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*}"
    ;;
  basic)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} --model_dir /tmp/ --output_dir metrics/ --output_format txt --language en --task transcribe --fp16 False"
    ;;
  hyperparameter)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} --model_dir /tmp/ --output_dir metrics/ --output_format txt --language en --task transcribe --fp16 False --beam_size 10 --temperature 0 --patience 2 --suppress_tokens -1 --compression_ratio_threshold 2.0 --logprob_threshold -0.5 --no_speech_threshold 0.4"
    ;;
  *)
    echo "❌ Unknown profile: $PROFILE"
    exit 1
    ;;
esac

# === Init CSV ===
if [ ! -f "$CSV_FILE" ]; then
  echo "date,timestamp,container_name,model,audio_source,profile,cold_start_sec,warm_start_sec" > "$CSV_FILE"
fi

echo "▶️ [$DATE $TIME] Running $PROFILE test for $CONTAINER_NAME"

# === Cold Start ===
COLD_TIME=$(
  podman run --rm -i --name "$CONTAINER_NAME" \
    -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
    /bin/bash -c "TIMEFORMAT='%R'; { time $WHISPER_CMD >/dev/null 2>&1; } 2>&1"
)

# === Warm Start ===
WARM_TIME=$(
  podman run --rm -i --name "$CONTAINER_NAME" \
    -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
    /bin/bash -c "$WHISPER_CMD >/dev/null 2>&1; TIMEFORMAT='%R'; { time $WHISPER_CMD >/dev/null 2>&1; } 2>&1"
)

# === Append to CSV ===
echo "$DATE,$TIME,$CONTAINER_NAME,${MODEL_NAME%%-*},$AUDIO_PATH,$PROFILE,$COLD_TIME,$WARM_TIME" >> "$CSV_FILE"

echo "✅ Logged: $DATE,$TIME,$CONTAINER_NAME,..."

# === Count experiments so far ===
NUM_EXPERIMENTS=$(($(wc -l < "$CSV_FILE") - 1))
echo "🧪 Total experiments logged: $NUM_EXPERIMENTS"
