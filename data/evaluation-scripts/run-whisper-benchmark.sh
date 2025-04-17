#!/bin/bash

###############################################################################
# Parallel Whisper Benchmark Script
#
# Benchmarks Whisper transcription performance across CPUs and GPUs using
# containerized Whisper models from quay.io.
#
# Features:
# - Automatically detects available CPUs and GPUs
# - Runs CPU jobs in parallel (up to number of vCPUs or user-defined limit)
# - Runs GPU jobs concurrently (1 job per GPU at a time)
# - Assigns each GPU job to a unique GPU (no duplication)
# - Supports "safe mode" for resource-constrained instances (e.g. g4dn.xlarge)
# - Runs CPU and GPU jobs concurrently
# - Writes metrics to ./data/metrics/experiment_metrics.csv
# - Evaluates WER, MER, CER, RTF, and TPS
#
# USAGE:
#   ./run-whisper-benchmark.sh \
#     [--flavor=ubuntu|ubi9|ubi9-minimal] \
#     [--instance=g4dn.xlarge|g6.12xlarge|...] \
#     [--max-cpu-jobs=4]
#
# RECOMMENDED INSTANCES:
#   p5.48xlarge
#   g5.48xlarge
#   g6.12xlarge
#   g5.12xlarge
#   g4dn.12xlarge
#
# EXAMPLE WITH SCREEN:
#   screen -S benchmark-ubuntu-whisper \
#     ./data/evaluation-scripts/run-whisper-benchmark.sh \
#     --flavor=ubuntu \
#     --instance=g5.12xlarge
#
## Detach with Ctrl+A D, reattach with: screen -r benchmark-ubuntu-whisper
#
###############################################################################

IMAGE_FLAVOR="ubuntu"
INSTANCE_TYPE="default"

# Parse command-line arguments
for ARG in "$@"; do
  case $ARG in
    --flavor=*) IMAGE_FLAVOR="${ARG#*=}" ;;
    --instance=*) INSTANCE_TYPE="${ARG#*=}" ;;
    --max-cpu-jobs=*) MAX_CPU_JOBS="${ARG#*=}" ;;
    -h|--help) grep '^# ' "$0" | cut -c 3- ; exit 0 ;;
    *) echo "❌ Unknown argument: $ARG"; exit 1 ;;
  esac
done

# Auto-adjust CPU concurrency if not explicitly set
if [[ -z "$MAX_CPU_JOBS" ]]; then
  case "$INSTANCE_TYPE" in
    p5.48xlarge|g5.48xlarge) MAX_CPU_JOBS=160 ;;  # Large instances with many cores
    g6.12xlarge|g5.12xlarge) MAX_CPU_JOBS=40  ;;  # Medium instances
    g4dn.12xlarge) MAX_CPU_JOBS=36 ;;             # Slightly smaller instances
    *) MAX_CPU_JOBS=$(nproc) ;;                  # Default to all available cores
  esac
fi

# Determine available GPUs using nvidia-smi
GPU_IDS=($(nvidia-smi --query-gpu=index --format=csv,noheader))
GPU_COUNT=${#GPU_IDS[@]}
GPU_INDEX=0

# Choose container images based on instance type
BASE="quay.io/redhat_na_ssa/speech-to-text/whisper"
if [[ "$INSTANCE_TYPE" == "g4dn.xlarge" || "$INSTANCE_TYPE" == "g4dn.12xlarge" ]]; then
  IMAGES=(
    "$BASE:tiny.en-${IMAGE_FLAVOR}"
    "$BASE:base.en-${IMAGE_FLAVOR}"
  )
else
  IMAGES=(
    "$BASE:tiny.en-${IMAGE_FLAVOR}"
    "$BASE:base.en-${IMAGE_FLAVOR}"
    "$BASE:small.en-${IMAGE_FLAVOR}"
    "$BASE:medium.en-${IMAGE_FLAVOR}"
    "$BASE:large-${IMAGE_FLAVOR}"
    "$BASE:turbo-${IMAGE_FLAVOR}"
  )
fi

# Configuration for complex transcription (higher quality)
COMPLEX_ARGS="--beam_size 10 \
  --temperature 0 \
  --patience 2 \
  --suppress_tokens -1 \
  --compression_ratio_threshold 2.0 \
  --logprob_threshold -0.5 \
  --no_speech_threshold 0.4"

# Input audio samples
INPUT_SAMPLES=(
  "harvard.wav"
  "jfk-audio-inaugural-address-20-january-1961.mp3"
  "jfk-audio-rice-university-12-september-1962.mp3"
)

# Prepare output directory and metrics file
mkdir -p ./data/metrics
METRIC_FILE="./data/metrics/experiment_metrics.csv"
[[ ! -f "$METRIC_FILE" ]] && echo "date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,container_runtime_sec,wer,mer,wil,wip,cer" > "$METRIC_FILE"

SCRIPT_START_TIME=$(date +%s)

# Function to execute a benchmark job
run_job() {
  local CONTAINER_NAME="$1"
  local OUTPUT_PREFIX="$2"
  local IMAGE="$3"
  local SAMPLE_FILE="$4"
  local RELATIVE_SAMPLE="$5"
  local MODE="$6"
  local GPU_ID="$7"

  local OUTPUT_NAME="${OUTPUT_PREFIX}.txt"
  local FILENAME="${SAMPLE_FILE%.*}"

  GPU_FLAGS=""
  ENV_FLAGS=""
  FP16_FLAG=""
  EXTRA_ARGS=""

  [[ "$MODE" == *gpu* ]] && GPU_FLAGS="--security-opt=label=disable --device nvidia.com/gpu=$GPU_ID"
  [[ "$MODE" == *gpu* ]] || ENV_FLAGS="-e CUDA_VISIBLE_DEVICES="
  [[ "$MODE" == *cpu* ]] && FP16_FLAG="--fp16 False"
  [[ "$MODE" == *complex* ]] && EXTRA_ARGS="$COMPLEX_ARGS"

  # Get audio duration
  AUDIO_DURATION=$(podman run --rm --pull=never -v "$(pwd)/data:/data:z" "$IMAGE" \
    ffprobe -v error -show_entries format=duration -of csv=p=0 "input-samples/$SAMPLE_FILE" 2>/dev/null)
  AUDIO_DURATION=$(printf "%.3f" "$AUDIO_DURATION")

  # Transcription job runtime
  SECONDS=0
  podman run --rm --pull=never \
    --name "$CONTAINER_NAME" \
    $GPU_FLAGS \
    $ENV_FLAGS \
    -v "$(pwd)/data:/data:z" \
    "$IMAGE" \
    whisper "input-samples/$SAMPLE_FILE" \
      --model_dir /tmp \
      --output_dir /data/metrics/ \
      --output_format txt \
      --language en \
      --task transcribe \
      $FP16_FLAG \
      $EXTRA_ARGS
  TRANSCODE_SEC=$SECONDS

  # Rename output to match prefix
  if [[ -f "./data/metrics/${FILENAME}.txt" ]]; then
    mv "./data/metrics/${FILENAME}.txt" "./data/metrics/$OUTPUT_NAME"
  else
    echo "⚠️ Output file ${FILENAME}.txt not found."
  fi

  # Metrics calculations
  TOKEN_COUNT=$(wc -w < "./data/metrics/$OUTPUT_NAME" | tr -d '[:space:]')
  TOKENS_PER_SEC="NA"
  [[ "$TOKEN_COUNT" -gt 0 && "$TRANSCODE_SEC" -gt 0 ]] && \
    TOKENS_PER_SEC=$(awk "BEGIN {printf \"%.2f\", $TOKEN_COUNT / $TRANSCODE_SEC}")

  RTF="NA"
  [[ "$AUDIO_DURATION" != "" && "$TRANSCODE_SEC" != "0" ]] && \
    RTF=$(awk "BEGIN {printf \"%.3f\", $TRANSCODE_SEC / $AUDIO_DURATION}")

  # Evaluate transcription accuracy
  WER="NA"; MER="NA"; WIL="NA"; WIP="NA"; CER="NA"
  if [[ -f "./data/metrics/$OUTPUT_NAME" && -f "./data/ground-truth/${FILENAME}.txt" ]]; then
    METRIC_LINES=$(podman run --rm -v "$(pwd)/data:/data:z" "$IMAGE" \
      python3 /data/evaluation-scripts/compare_transcripts.py \
      "/data/ground-truth/${FILENAME}.txt" "/data/metrics/${OUTPUT_NAME}")
    while IFS='=' read -r key val; do
      case $key in
        WER) WER="$val" ;; MER) MER="$val" ;; WIL) WIL="$val" ;;
        WIP) WIP="$val" ;; CER) CER="$val" ;;
      esac
    done <<< "$METRIC_LINES"
  fi

  # Log to CSV
  echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),$CONTAINER_NAME,$TOKEN_COUNT,$TOKENS_PER_SEC,$AUDIO_DURATION,$RTF,$TRANSCODE_SEC,$WER,$MER,$WIL,$WIP,$CER" >> "$METRIC_FILE"
  echo "✅ Done: $OUTPUT_PREFIX"
}

# Launch all benchmark jobs in parallel (concurrent CPU/GPU)
CPU_JOBS_RUNNING=0
JOB_PIDS=()
for IMAGE in "${IMAGES[@]}"; do
  IMAGE_TAG=$(basename "$IMAGE" | sed 's/whisper://; s/:/-/g; s/\./_/g')

  for SAMPLE_FILE in "${INPUT_SAMPLES[@]}"; do
    for MODE in cpu_fast cpu_complex gpu_fast gpu_complex; do
      FILENAME="${SAMPLE_FILE%.*}"
      OUTPUT_PREFIX="whisper-${IMAGE_TAG}_${FILENAME}_${MODE}"
      CONTAINER_NAME="$OUTPUT_PREFIX"
      RELATIVE_SAMPLE="input-samples/$SAMPLE_FILE"

      echo "⏳ Scheduling job: $OUTPUT_PREFIX"

      if [[ "$MODE" == *gpu* ]]; then
        # Round-robin GPU assignment
        GPU_ID=${GPU_IDS[$GPU_INDEX]}
        run_job "$CONTAINER_NAME-gpu$GPU_ID" "$OUTPUT_PREFIX-gpu$GPU_ID" "$IMAGE" "$SAMPLE_FILE" "$RELATIVE_SAMPLE" "$MODE" "$GPU_ID" &
        JOB_PIDS+=("$!")
        GPU_INDEX=$(((GPU_INDEX + 1) % GPU_COUNT))
      else
        run_job "$CONTAINER_NAME" "$OUTPUT_PREFIX" "$IMAGE" "$SAMPLE_FILE" "$RELATIVE_SAMPLE" "$MODE" "" &
        JOB_PIDS+=("$!")
        ((CPU_JOBS_RUNNING++))
        if [[ $CPU_JOBS_RUNNING -ge $MAX_CPU_JOBS ]]; then
          wait -n
          ((CPU_JOBS_RUNNING--))
        fi
      fi
    done
  done
  wait
  GPU_INDEX=0
done

wait

# Sort CSV by date and timestamp
HEADER=$(head -n 1 "$METRIC_FILE")
TAIL=$(tail -n +2 "$METRIC_FILE" | sort -t, -k1,1 -k2,2)
{ echo "$HEADER"; echo "$TAIL"; } > "$METRIC_FILE"

# Show total duration
SCRIPT_END_TIME=$(date +%s)
TOTAL_RUNTIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
MINUTES=$((TOTAL_RUNTIME / 60))
SECONDS=$((TOTAL_RUNTIME % 60))
echo -e "\n🏁 All benchmark jobs completed in ${MINUTES}m ${SECONDS}s."

# Print job summary table
printf "\n📊 Summary of Completed Jobs:\n"
printf "% -55s % -8s % -8s % -8s\n" "Container Name" "Tokens" "TPS" "Runtime(s)"
printf "% -55s % -8s % -8s % -8s\n" "-------------------------------------------------------" "-------" "-------" "--------"
awk -F',' 'NF>=8 && NR > 1 { printf "%-55s %-8s %-8s %-8s\n", $3, $4, $5, $8 }' "$METRIC_FILE" | sort
