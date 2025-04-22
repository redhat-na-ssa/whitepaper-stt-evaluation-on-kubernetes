#!/bin/bash

###############################################################################
# Whisper Parallel Benchmark Script (Restored Version + GPU Support)
#
# Benchmarks Whisper transcription performance across CPUs and GPUs using
# containerized Whisper models from quay.io or localhost builds.
###############################################################################

# Default config values
IMAGE_FLAVOR="ubi9-minimal"          # Container image flavor to use (e.g., ubuntu, ubi9)
INSTANCE_TYPE="test-instance"       # Descriptive name for the machine type
CPU_THREADS=4                        # Threads used per containerized CPU job
MAX_CPU_JOBS=1                       # Max number of concurrent CPU jobs
MODEL_FILTER=""                      # Optional model size filter (e.g., "tiny,base")

# Parse optional model filter from command line
for ARG in "$@"; do
  case $ARG in
    --model=*) MODEL_FILTER="${ARG#*=}" ;;  # e.g., --model=tiny,base
  esac
done

# Ensure ./data/metrics is writable
mkdir -p ./data/metrics
if ! touch ./data/metrics/.write_test 2>/dev/null; then
  echo "⚠️ Attempting to fix permissions for ./data/metrics..."
  sudo chown -R $(id -u):$(id -g) ./data/metrics 2>/dev/null || sudo chmod -R a+rw ./data/metrics 2>/dev/null
  if ! touch ./data/metrics/.write_test 2>/dev/null; then
    echo "❌ ERROR: Cannot write to ./data/metrics/. Check ownership and permissions."
    exit 1
  fi
fi
rm -f ./data/metrics/.write_test

# List of all Whisper image variants
ALL_IMAGES=(
  "localhost/whisper:tiny.en-${IMAGE_FLAVOR}"
  "localhost/whisper:base.en-${IMAGE_FLAVOR}"
  "localhost/whisper:small.en-${IMAGE_FLAVOR}"
  "localhost/whisper:medium.en-${IMAGE_FLAVOR}"
  "localhost/whisper:large-${IMAGE_FLAVOR}"
  "localhost/whisper:turbo-${IMAGE_FLAVOR}"
)

# Apply filtering if --model=... is specified
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

# Audio inputs to test against
INPUT_SAMPLES=(
  "harvard.wav"
  "jfk-audio-inaugural-address-20-january-1961.mp3"
  "jfk-audio-rice-university-12-september-1962.mp3"
)

# Mode combinations to run
MODES=("cpu_fast" "cpu_complex" "gpu_fast" "gpu_complex")

# Detect GPUs
GPU_IDS=($(nvidia-smi --query-gpu=index --format=csv,noheader))
GPU_COUNT=${#GPU_IDS[@]}
GPU_INDEX=0

# Output CSV with grouped headers
METRIC_FILE="./data/metrics/aiml_functional_metrics.csv"
if [[ ! -f "$METRIC_FILE" ]]; then
  echo "date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,container_runtime_sec,wer,mer,wil,wip,cer,threads" > "$METRIC_FILE"
fi

# Run a single container job
run_job() {
  local IMAGE="$1"               # Whisper container image
  local SAMPLE_FILE="$2"         # Audio file to transcribe
  local MODE="$3"               # Mode: cpu_fast, cpu_complex, gpu_fast, gpu_complex
  local CPU_THREADS="$4"        # Threads per CPU job

  local FILENAME="${SAMPLE_FILE%.*}"
  local IMAGE_TAG=$(basename "$IMAGE" | sed 's/whisper://; s/:/-/g; s/\./_/g')
  local OUTPUT_PREFIX="whisper-${IMAGE_TAG}_${FILENAME}_${MODE}"
  local CONTAINER_NAME="$OUTPUT_PREFIX"

  # Default flags
  THREADS_FLAG="--threads $CPU_THREADS"
  FP16_FLAG="--fp16 False"
  ENV_FLAGS="-e OPENBLAS_NUM_THREADS=$CPU_THREADS -e OMP_NUM_THREADS=$CPU_THREADS -e MKL_NUM_THREADS=$CPU_THREADS"
  GPU_FLAGS=""

  # Adjust flags for GPU mode
  if [[ "$MODE" == gpu* ]]; then
    GPU_ID=${GPU_IDS[$GPU_INDEX]}
    GPU_FLAGS="--security-opt=label=disable --device nvidia.com/gpu=$GPU_ID"
    THREADS_FLAG=""
    FP16_FLAG=""
    ENV_FLAGS=""
    GPU_INDEX=$(((GPU_INDEX + 1) % GPU_COUNT))
  fi

  # Get audio duration for RTF calculation using ffprobe inside the container
  AUDIO_DURATION_RAW=$(podman run --rm --pull=never -v "$(pwd)/data:/outside:Z" "$IMAGE" \
    ffprobe -v error -show_entries format=duration -of csv=p=0 "/outside/input-samples/$SAMPLE_FILE" 2>/dev/null)

  # Validate duration result
  if [[ "$AUDIO_DURATION_RAW" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    AUDIO_DURATION=$(awk "BEGIN {printf \"%.3f\", $AUDIO_DURATION_RAW}")
  else
    echo "⚠️  Warning: Could not determine audio duration for $SAMPLE_FILE"
    AUDIO_DURATION="0.000"
  fi
  
  # Use fallback if empty or invalid
  if [[ "$AUDIO_DURATION_RAW" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    AUDIO_DURATION=$(printf "%.3f" "$AUDIO_DURATION_RAW")
  else
    AUDIO_DURATION="0.000"
  fi

  # Run transcription container
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
    -v "$(pwd)/data:/outside:Z" \
    "$IMAGE" \
    bash -c "$CMD"
  END_TIME=$(date +%s.%N)
  TRANSCODE_SEC=$(awk "BEGIN {print $END_TIME - $START_TIME}")

  # Move output to unique file
  OUTPUT_NAME="${OUTPUT_PREFIX}.txt"
  [[ -f "./data/metrics/${FILENAME}.txt" ]] && mv "./data/metrics/${FILENAME}.txt" "./data/metrics/$OUTPUT_NAME"

  # Calculate token stats
  TOKEN_COUNT=$(wc -w < "./data/metrics/$OUTPUT_NAME" | tr -d '[:space:]')
  TOKENS_PER_SEC="NA"; RTF="NA"

  if [[ "$TOKEN_COUNT" -gt 0 ]] && awk "BEGIN {exit ($TRANSCODE_SEC <= 0)}"; then
    TOKENS_PER_SEC=$(awk "BEGIN {printf \"%.2f\", $TOKEN_COUNT / $TRANSCODE_SEC}")
  fi

  if awk "BEGIN {exit ($TRANSCODE_SEC <= 0 || $AUDIO_DURATION <= 0)}"; then
    RTF=$(awk "BEGIN {printf \"%.3f\", $TRANSCODE_SEC / $AUDIO_DURATION}")
  fi

  # Evaluate WER/MER/etc.
  WER="NA"; MER="NA"; WIL="NA"; WIP="NA"; CER="NA"
  if [[ -f "./data/metrics/$OUTPUT_NAME" && -f "./data/ground-truth/${FILENAME}.txt" ]]; then
    METRIC_LINES=$(podman run --rm -v "$(pwd)/data:/outside:Z" "$IMAGE" \
      python3 /outside/evaluation-scripts/compare_transcripts.py \
      "/outside/ground-truth/${FILENAME}.txt" "/outside/metrics/${OUTPUT_NAME}")
    while IFS='=' read -r key val; do
      case $key in
        WER) WER="$val" ;; MER) MER="$val" ;; WIL) WIL="$val" ;;
        WIP) WIP="$val" ;; CER) CER="$val" ;;
      esac
    done <<< "$METRIC_LINES"
  fi

  # Log to CSV
  echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),$CONTAINER_NAME,$TOKEN_COUNT,$TOKENS_PER_SEC,$AUDIO_DURATION,$RTF,$TRANSCODE_SEC,$WER,$MER,$WIL,$WIP,$CER,$CPU_THREADS" >> "$METRIC_FILE"
  echo "✅ Completed: $OUTPUT_PREFIX"
}

# Schedule parallel jobs with CPU limit
JOBS_RUNNING=0
for IMAGE in "${IMAGES[@]}"; do
  for SAMPLE_FILE in "${INPUT_SAMPLES[@]}"; do
    for MODE in "${MODES[@]}"; do
      run_job "$IMAGE" "$SAMPLE_FILE" "$MODE" "$CPU_THREADS" &
      ((JOBS_RUNNING++))
      if [[ "$JOBS_RUNNING" -ge "$MAX_CPU_JOBS" ]]; then
        wait -n
        ((JOBS_RUNNING--))
      fi
    done
  done
  GPU_INDEX=0
done
wait

# Print formatted summary
printf "
📊 Summary of Completed Jobs:
"
printf "%-55s %-8s %-8s %-8s
" "Container Name" "Tokens" "TPS" "Runtime(s)"
awk -F',' 'NF>=8 && NR > 1 { printf "%-55s %-8s %-8s %-8s
", $3, $4, $5, $8 }' "$METRIC_FILE" | sort
