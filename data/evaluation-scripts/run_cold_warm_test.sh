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
METRIC_DIR="metrics"

# Ensure metrics dir exists
mkdir -p "$MOUNT_DIR/$METRIC_DIR"

# === Command Profile Switch ===
case "$PROFILE" in
  none)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*}"
    ;;
  basic)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} --model_dir /tmp/ --output_dir $METRIC_DIR/ --output_format txt --language en --task transcribe --fp16 False"
    ;;
  hyperparameter)
    WHISPER_CMD="whisper \"$AUDIO_PATH\" --model ${MODEL_NAME%%-*} --model_dir /tmp/ --output_dir $METRIC_DIR/ --output_format txt --language en --task transcribe --fp16 False --beam_size 10 --temperature 0 --patience 2 --suppress_tokens -1 --compression_ratio_threshold 2.0 --logprob_threshold -0.5 --no_speech_threshold 0.4"
    ;;
  *)
    echo "❌ Unknown profile: $PROFILE"
    exit 1
    ;;
esac

# === Init CSV ===
if [ ! -f "$CSV_FILE" ]; then
  echo "date,timestamp,container_name,model,audio_source,profile,cold_start_sec,warm_start_sec,cold_tokens,warm_tokens,cold_tokens_per_sec,warm_tokens_per_sec,cold_rtf,warm_rtf" > "$CSV_FILE"
fi

echo "▶️ [$DATE $TIME] Running $PROFILE test for $CONTAINER_NAME"

# === Cold Start ===
podman run --rm -i --name "$CONTAINER_NAME" \
  -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
  /bin/bash -c "TIMEFORMAT='%R'; { time $WHISPER_CMD > /outside/$METRIC_DIR/cold_stdout.txt 2>&1; } 2>&1" > "$MOUNT_DIR/$METRIC_DIR/cold_time.txt"

COLD_TIME=$(cat "$MOUNT_DIR/$METRIC_DIR/cold_time.txt")
COLD_TOKENS=$(grep -i "tokens processed" "$MOUNT_DIR/$METRIC_DIR/cold_stdout.txt" | awk '{print $NF}')
COLD_TOKENS_PER_SEC=$(grep -i "tokens/sec" "$MOUNT_DIR/$METRIC_DIR/cold_stdout.txt" | awk '{print $NF}')
COLD_RTF=$(grep -i "real-time factor" "$MOUNT_DIR/$METRIC_DIR/cold_stdout.txt" | awk '{print $NF}')

# === Warm Start ===
podman run --rm -i --name "$CONTAINER_NAME" \
  -v "$MOUNT_DIR:/outside/:z" "$IMAGE_NAME" \
  /bin/bash -c "$WHISPER_CMD > /outside/$METRIC_DIR/warm_stdout.txt 2>&1; TIMEFORMAT='%R'; { time $WHISPER_CMD > /outside/$METRIC_DIR/warm_stdout_2.txt 2>&1; } 2>&1" > "$MOUNT_DIR/$METRIC_DIR/warm_time.txt"

WARM_TIME=$(cat "$MOUNT_DIR/$METRIC_DIR/warm_time.txt")
WARM_TOKENS=$(grep -i "tokens processed" "$MOUNT_DIR/$METRIC_DIR/warm_stdout_2.txt" | awk '{print $NF}')
WARM_TOKENS_PER_SEC=$(grep -i "tokens/sec" "$MOUNT_DIR/$METRIC_DIR/warm_stdout_2.txt" | awk '{print $NF}')
WARM_RTF=$(grep -i "real-time factor" "$MOUNT_DIR/$METRIC_DIR/warm_stdout_2.txt" | awk '{print $NF}')

# === Append to CSV ===
echo "$DATE,$TIME,$CONTAINER_NAME,${MODEL_NAME%%-*},$AUDIO_PATH,$PROFILE,$COLD_TIME,$WARM_TIME,$COLD_TOKENS,$WARM_TOKENS,$COLD_TOKENS_PER_SEC,$WARM_TOKENS_PER_SEC,$COLD_RTF,$WARM_RTF" >> "$CSV_FILE"

echo "✅ Logged: $DATE,$TIME,$CONTAINER_NAME,..."

# === Count experiments so far ===
NUM_EXPERIMENTS=$(($(wc -l < "$CSV_FILE") - 1))
echo "🧪 Total experiments logged: $NUM_EXPERIMENTS"
