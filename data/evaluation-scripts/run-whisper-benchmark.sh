#!/bin/bash

###############################################################################
# Parallel Whisper Benchmark Script
#
# Benchmarks Whisper transcription performance across CPUs and GPUs using
# containerized Whisper models from quay.io.
#
# Features:
# - Automatically detects available CPUs and GPUs
# - Runs CPU jobs in parallel (up to number of vCPUs)
# - Runs GPU jobs concurrently (one per GPU device)
# - Measures runtime, throughput, and accuracy (WER, CER, etc.)
# - Supports safe mode for resource-constrained instances (like g4dn.xlarge)
# - Now runs one model size at a time to avoid OOM errors
#
# USAGE:
#   ./run-whisper-benchmark.sh                      # defaults to ubuntu images
#   ./run-whisper-benchmark.sh --flavor=ubi9        # use UBI9-based images
#   ./run-whisper-benchmark.sh --instance=g4dn.xlarge  # enables safe mode for small instance
#   ./run-whisper-benchmark.sh --flavor=ubi9-minimal --instance=g6.12xlarge
#
# START SESSION IN BACKGROUND:
#   screen -S whisper-benchmark ./run-whisper-benchmark.sh --flavor=ubi9-minimal --instance=g6.12xlarge
# Detach: Press Ctrl+A, then D | Reattach: screen -r whisper-benchmark
#
# OUTPUT:
#   - Transcripts: ./data/metrics/whisper-*.txt
#   - Metrics CSV: ./data/metrics/experiment_metrics.csv
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

# Determine CPU and GPU availability
MAX_CPU_JOBS=$(nproc)
GPU_IDS=($(nvidia-smi --query-gpu=index --format=csv,noheader))

# Select images based on instance size (safe mode skips large models)
BASE="quay.io/redhat_na_ssa/speech-to-text/whisper"
if [[ "$INSTANCE_TYPE" == "g4dn.xlarge" || "$INSTANCE_TYPE" == "g4dn.12xlarge" ]]; then
  IMAGES=(
    "$BASE:tiny.en-${IMAGE_FLAVOR}"
    "$BASE:base.en-${IMAGE_FLAVOR}"
    "$BASE:small.en-${IMAGE_FLAVOR}"
  )
else
  IMAGES=(
    "$BASE:turbo-${IMAGE_FLAVOR}"
    "$BASE:large-${IMAGE_FLAVOR}"
    "$BASE:medium.en-${IMAGE_FLAVOR}"
    "$BASE:tiny.en-${IMAGE_FLAVOR}"
    "$BASE:base.en-${IMAGE_FLAVOR}"
    "$BASE:small.en-${IMAGE_FLAVOR}"
  )
fi

# Whisper decoding arguments for more accurate (complex) mode
COMPLEX_ARGS="--beam_size 10 \
  --temperature 0 \
  --patience 2 \
  --suppress_tokens -1 \
  --compression_ratio_threshold 2.0 \
  --logprob_threshold -0.5 \
  --no_speech_threshold 0.4"

# Audio files for benchmarking
INPUT_SAMPLES=(
  "harvard.wav"
  "jfk-audio-inaugural-address-20-january-1961.mp3"
  "jfk-audio-rice-university-12-september-1962.mp3"
)

# Ensure output directory and CSV metrics file exist
mkdir -p ./data/metrics
METRIC_FILE="./data/metrics/experiment_metrics.csv"
[[ ! -f "$METRIC_FILE" ]] && echo "date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,container_runtime_sec,wer,mer,wil,wip,cer" > "$METRIC_FILE"

SCRIPT_START_TIME=$(date +%s)

# Function to run a single benchmark job
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

  # Set container options based on mode (CPU/GPU, fast/complex)
  GPU_FLAGS=""
  ENV_FLAGS=""
  FP16_FLAG=""
  EXTRA_ARGS=""
  [[ "$MODE" == *gpu* ]] && GPU_FLAGS="--security-opt=label=disable --device nvidia.com/gpu=$GPU_ID"
  [[ "$MODE" == *gpu* ]] || ENV_FLAGS="-e CUDA_VISIBLE_DEVICES="
  [[ "$MODE" == *cpu* ]] && FP16_FLAG="--fp16 False"
  [[ "$MODE" == *complex* ]] && EXTRA_ARGS="$COMPLEX_ARGS"

  # Get duration of audio sample (needed for RTF)
  AUDIO_DURATION=$(podman run --rm --pull=never -v "$(pwd)/data:/data:z" "$IMAGE" \
    ffprobe -v error -show_entries format=duration -of csv=p=0 "input-samples/$SAMPLE_FILE" 2>/dev/null)
  AUDIO_DURATION=$(printf "%.3f" "$AUDIO_DURATION")

  # Run transcription and measure time
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

  # Rename Whisper's default output to match our pattern
  if [[ -f "./data/metrics/${FILENAME}.txt" ]]; then
    mv "./data/metrics/${FILENAME}.txt" "./data/metrics/$OUTPUT_NAME"
  else
    echo "⚠️ Output file ${FILENAME}.txt not found."
  fi

  # Calculate number of tokens (words) and tokens per second
  TOKEN_COUNT=$(wc -w < "./data/metrics/$OUTPUT_NAME" | tr -d '[:space:]')
  TOKENS_PER_SEC="NA"
  [[ "$TOKEN_COUNT" -gt 0 && "$TRANSCODE_SEC" -gt 0 ]] && \
    TOKENS_PER_SEC=$(awk "BEGIN {printf \"%.2f\", $TOKEN_COUNT / $TRANSCODE_SEC}")

  # Real-time factor (RTF): ratio of processing time to audio duration
  RTF="NA"
  [[ "$AUDIO_DURATION" != "" && "$TRANSCODE_SEC" != "0" ]] && \
    RTF=$(awk "BEGIN {printf \"%.3f\", $TRANSCODE_SEC / $AUDIO_DURATION}")

  # Evaluate accuracy if ground-truth exists
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

  # Log result to CSV file
  echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),$CONTAINER_NAME,$TOKEN_COUNT,$TOKENS_PER_SEC,$AUDIO_DURATION,$RTF,$TRANSCODE_SEC,$WER,$MER,$WIL,$WIP,$CER" >> "$METRIC_FILE"
  echo "✅ Done: $OUTPUT_PREFIX"
}

# Loop over container images, samples, and run modes (CPU/GPU + fast/complex)
CPU_JOBS_RUNNING=0
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
        for GPU_ID in "${GPU_IDS[@]}"; do
          run_job "$CONTAINER_NAME-gpu$GPU_ID" "$OUTPUT_PREFIX-gpu$GPU_ID" "$IMAGE" "$SAMPLE_FILE" "$RELATIVE_SAMPLE" "$MODE" "$GPU_ID"
        done
      else
        run_job "$CONTAINER_NAME" "$OUTPUT_PREFIX" "$IMAGE" "$SAMPLE_FILE" "$RELATIVE_SAMPLE" "$MODE" ""
      fi
    done
  done

done

# Sort the CSV output
HEADER=$(head -n 1 "$METRIC_FILE")
TAIL=$(tail -n +2 "$METRIC_FILE" | sort -t, -k1,1 -k2,2)
{ echo "$HEADER"; echo "$TAIL"; } > "$METRIC_FILE"

# Print total script runtime
SCRIPT_END_TIME=$(date +%s)
TOTAL_RUNTIME=$((SCRIPT_END_TIME - SCRIPT_START_TIME))
MINUTES=$((TOTAL_RUNTIME / 60))
SECONDS=$((TOTAL_RUNTIME % 60))
echo -e "\n🏁 All benchmark jobs completed in ${MINUTES}m ${SECONDS}s."

# Print summary of completed jobs from CSV
printf "\n📊 Summary of Completed Jobs:\n"
printf "%-55s %-8s %-8s %-8s\n" "Container Name" "Tokens" "TPS" "Runtime(s)"
printf "%-55s %-8s %-8s %-8s\n" "-------------------------------------------------------" "-------" "-------" "--------"
awk -F',' 'NF>=8 && NR > 1 { printf "%-55s %-8s %-8s %-8s\n", $3, $4, $5, $8 }' "$METRIC_FILE" | sort
