#!/bin/bash

###############################################################################
# Whisper Parallel Benchmark Script (Cold + Warm Start Support)
#
# This script benchmarks Whisper transcription performance across CPUs and GPUs
# with support for both cold and warm start container execution.
###############################################################################

# =========================== Configuration Defaults ============================
IMAGE_FLAVOR="ubi9-minimal"          # Container image flavor (e.g., ubuntu, ubi9)
INSTANCE_TYPE="test-instance"        # Name of the machine or VM for labeling
CPU_THREADS=4                         # Number of CPU threads per container job
MAX_CPU_JOBS=1                        # Maximum number of concurrent jobs
MODEL_FILTER=""                      # Comma-separated list of models to include
INPUT_SAMPLE_FILTER=""               # Specific audio sample to use (optional)

# ======================== Command-line Argument Parsing ========================
for ARG in "$@"; do
  case $ARG in
    --model=*) MODEL_FILTER="${ARG#*=}" ;;
    --flavor=*) IMAGE_FLAVOR="${ARG#*=}" ;;
    --instance=*) INSTANCE_TYPE="${ARG#*=}" ;;
    --input-sample=*) INPUT_SAMPLE_FILTER="${ARG#*=}" ;;
    --cpu-threads=*) CPU_THREADS="${ARG#*=}" ;;
    --max-cpu-jobs=*) MAX_CPU_JOBS="${ARG#*=}" ;;
  esac
done

# ===================== Define Output Directory ============================
OUTPUT_DIR="data/metrics/$INSTANCE_TYPE/$IMAGE_FLAVOR"
mkdir -p "$OUTPUT_DIR"

# ============================ CSV Header Setup =============================
METRIC_FILE="$OUTPUT_DIR/aiml_functional_metrics.csv"
if [[ ! -f "$METRIC_FILE" ]]; then
  echo "date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,container_runtime_sec,wer,mer,wil,wip,cer,threads,start_type" > "$METRIC_FILE"
fi

# ======================= Ensure Metrics Directory is Writable ==================
# DELETE mkdir -p ./data/metrics
if ! touch $OUTPUT_DIR/.write_test 2>/dev/null; then
  echo "⚠️ Attempting to fix permissions for ./data/metrics..."
  sudo chown -R $(id -u):$(id -g) ./data/metrics 2>/dev/null || sudo chmod -R a+rw ./data/metrics 2>/dev/null
  if ! touch $OUTPUT_DIR/.write_test 2>/dev/null; then
    echo "❌ ERROR: Cannot write to $OUTPUT_DIR/. Check ownership and permissions."
    exit 1
  fi
fi
rm -f $OUTPUT_DIR/.write_test

# =========================== Image Selection Logic =============================
MODEL_NAMES=("tiny.en" "base.en" "small.en" "medium.en" "large" "turbo")
ALL_IMAGES=()

for MODEL in "${MODEL_NAMES[@]}"; do
  TAG="$MODEL-${IMAGE_FLAVOR}"
  LOCAL_IMG="localhost/whisper:$TAG"
  REMOTE_IMG="quay.io/redhat_na_ssa/speech-to-text/whisper:$TAG"
  if podman image exists "$LOCAL_IMG"; then
    ALL_IMAGES+=("$LOCAL_IMG")
  else
    ALL_IMAGES+=("$REMOTE_IMG")
  fi
done

IMAGES=()
IFS=',' read -ra FILTERS <<< "$MODEL_FILTER"
for IMG in "${ALL_IMAGES[@]}"; do
  if [[ -z "$MODEL_FILTER" ]]; then
    IMAGES+=("$IMG")
  else
    for FILTER in "${FILTERS[@]}"; do
      if [[ "$IMG" == *"$FILTER"* ]]; then
        IMAGES+=("$IMG")
        break
      fi
    done
  fi
done

# ========================== Audio Sample Selection =============================
ALL_SAMPLES=(
  "harvard.wav"
  "jfk-audio-inaugural-address-20-january-1961.mp3"
  "jfk-audio-rice-university-12-september-1962.mp3"
)
INPUT_SAMPLES=()
for SAMPLE in "${ALL_SAMPLES[@]}"; do
  if [[ -z "$INPUT_SAMPLE_FILTER" || "$SAMPLE" == "$INPUT_SAMPLE_FILTER" ]]; then
    INPUT_SAMPLES+=("$SAMPLE")
  fi
done

# ============================ Inference Modes ==================================
MODES=("cpu_basic" "cpu_hyperparam" "gpu_basic" "gpu_hyperparam")
START_TYPES=("cold" "warm")

# =========================== GPU Detection =====================================
GPU_IDS=($(nvidia-smi --query-gpu=index --format=csv,noheader))
GPU_COUNT=${#GPU_IDS[@]}
GPU_INDEX=0

# ============================ Job Execution Function ===========================
run_job() {
  local IMAGE="$1"
  local SAMPLE_FILE="$2"
  local MODE="$3"
  local CPU_THREADS="$4"
  local START_TYPE="$5"

  local FILENAME="${SAMPLE_FILE%.*}"
  local IMAGE_TAG=$(basename "$IMAGE" | sed 's/whisper://; s/:/-/g; s/\./_/g')
  local OUTPUT_PREFIX="whisper-${IMAGE_TAG}_${FILENAME}_${MODE}_${START_TYPE}"
  local UNIQUE_ID=$(uuidgen | cut -d'-' -f1)
  local CONTAINER_NAME="${OUTPUT_PREFIX}_${UNIQUE_ID}"

  THREADS_FLAG="--threads $CPU_THREADS"
  FP16_FLAG="--fp16 False"
  ENV_FLAGS="-e OPENBLAS_NUM_THREADS=$CPU_THREADS -e OMP_NUM_THREADS=$CPU_THREADS -e MKL_NUM_THREADS=$CPU_THREADS"
  GPU_FLAGS=""

  if [[ "$MODE" == gpu* ]]; then
    GPU_ID=${GPU_IDS[$GPU_INDEX]}
    GPU_FLAGS="--security-opt=label=disable --device nvidia.com/gpu=$GPU_ID"
    THREADS_FLAG=""
    FP16_FLAG=""
    ENV_FLAGS=""
    GPU_INDEX=$(((GPU_INDEX + 1) % GPU_COUNT))
  fi

  AUDIO_DURATION_RAW=$(podman run --rm --pull=never -v "$(pwd)/data:/outside:z" "$IMAGE" \
    ffprobe -v error -show_entries format=duration -of csv=p=0 "/outside/input-samples/$SAMPLE_FILE" 2>/dev/null)

  if [[ "$AUDIO_DURATION_RAW" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    AUDIO_DURATION=$(printf "%.3f" "$AUDIO_DURATION_RAW")
  else
    echo "⚠️  Warning: Could not determine audio duration for $SAMPLE_FILE"
    AUDIO_DURATION="0.000"
  fi

  START_TIME=$(date +%s.%N)
  CMD="umask 002 && mkdir -p /outside/metrics && \
    whisper /outside/input-samples/$SAMPLE_FILE \
      --model_dir /outside/tmp \
      --output_dir /outside/metrics/ \
      --output_format txt \
      --language en \
      --task transcribe \
      $THREADS_FLAG \
      $FP16_FLAG"

  echo "🧪 Running container with image: $IMAGE"
  podman run --rm --pull=never \
    --name "$CONTAINER_NAME" \
    --userns=keep-id \
    --user "$(id -u):$(id -g)" \
    $ENV_FLAGS \
    $GPU_FLAGS \
    -v "$(pwd)/data:/outside:z" \
    "$IMAGE" \
    bash -c "$CMD"
  END_TIME=$(date +%s.%N)
  TRANSCODE_SEC=$(awk "BEGIN {print $END_TIME - $START_TIME}")

  OUTPUT_NAME="${OUTPUT_PREFIX}.txt"
  if [[ -f "./data/metrics/${FILENAME}.txt" ]]; then
    mv "./data/metrics/${FILENAME}.txt" "$OUTPUT_DIR/$OUTPUT_NAME"
  fi

  TOKEN_COUNT=$(wc -w < "$OUTPUT_DIR/$OUTPUT_NAME" | tr -d '[:space:]')
  TOKENS_PER_SEC="NA"
  RTF="NA"
  if [[ "$TOKEN_COUNT" -gt 0 ]] && awk "BEGIN {exit ($TRANSCODE_SEC <= 0)}"; then
    TOKENS_PER_SEC=$(awk "BEGIN {printf \"%.2f\", $TOKEN_COUNT / $TRANSCODE_SEC}")
  fi
  if awk "BEGIN {exit ($TRANSCODE_SEC <= 0 || $AUDIO_DURATION <= 0)}"; then
    RTF=$(awk "BEGIN {printf \"%.3f\", $TRANSCODE_SEC / $AUDIO_DURATION}")
  fi

  WER="NA"; MER="NA"; WIL="NA"; WIP="NA"; CER="NA"
  if [[ -f "$OUTPUT_DIR/$OUTPUT_NAME" && -f "./data/ground-truth/${FILENAME}.txt" ]]; then
    METRIC_LINES=$(podman run --rm -v "$(pwd)/data:/outside:z" "$IMAGE" \
      python3 /outside/evaluation-scripts/compare_transcripts.py \
      "/outside/ground-truth/${FILENAME}.txt" "/outside/$(realpath --relative-to=./data "$OUTPUT_DIR")/${OUTPUT_NAME}")
    while IFS='=' read -r key val; do
      case $key in
        WER) WER="$val" ;; MER) MER="$val" ;; WIL) WIL="$val" ;;
        WIP) WIP="$val" ;; CER) CER="$val" ;;
      esac
    done <<< "$METRIC_LINES"
  fi

  echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),$CONTAINER_NAME,$TOKEN_COUNT,$TOKENS_PER_SEC,$AUDIO_DURATION,$RTF,$TRANSCODE_SEC,$WER,$MER,$WIL,$WIP,$CER,$CPU_THREADS,$START_TYPE" >> "$METRIC_FILE"
  echo "✅ Completed: $OUTPUT_PREFIX"
}

# ============================ Run All Jobs ====================================
JOBS_RUNNING=0
for IMAGE in "${IMAGES[@]}"; do
  for SAMPLE_FILE in "${INPUT_SAMPLES[@]}"; do
    for MODE in "${MODES[@]}"; do
      for START_TYPE in "${START_TYPES[@]}"; do
        run_job "$IMAGE" "$SAMPLE_FILE" "$MODE" "$CPU_THREADS" "$START_TYPE" &
        ((JOBS_RUNNING++))
        if [[ "$JOBS_RUNNING" -ge "$MAX_CPU_JOBS" ]]; then
          wait -n
          ((JOBS_RUNNING--))
        fi
      done
    done
  done
  GPU_INDEX=0

done
wait

# ============================ Print Summary ====================================
printf "\n📊 Summary of Completed Jobs:\n"
printf "%-55s %-8s %-8s %-8s\n" "Container Name" "Tokens" "TPS" "Runtime(s)"
awk -F',' 'NF>=8 && NR > 1 { printf "%-55s %-8s %-8s %-8s\n", $3, $4, $5, $8 }' "$METRIC_FILE" | sort
