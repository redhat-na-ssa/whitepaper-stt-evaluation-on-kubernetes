#!/bin/bash

###############################################################################
# Whisper Transcription Benchmark Script
#
# Benchmarks transcription performance and accuracy using containerized Whisper.
# For each audio file, it runs in 4 modes:
#   - cpu_fast
#   - cpu_complex
#   - gpu_fast
#   - gpu_complex
#
# USAGE:
#   ./run-whisper-benchmark.sh                      # use ubuntu images
#   ./run-whisper-benchmark.sh --flavor=ubi9       # use ubi9 images
#   ./run-whisper-benchmark.sh --flavor=ubi9-minimal
#
# OUTPUT:
#   - Transcripts: ./data/metrics/whisper-*.txt
#   - Metrics CSV: ./data/metrics/experiment_metrics.csv
###############################################################################

IMAGE_FLAVOR="ubuntu"

# Parse optional CLI argument
for ARG in "$@"; do
  case $ARG in
    --flavor=*)
      IMAGE_FLAVOR="${ARG#*=}"
      ;;
    -h|--help)
      grep '^# ' "$0" | cut -c 3-
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $ARG"
      exit 1
      ;;
  esac
done

echo "📦 Using image flavor: $IMAGE_FLAVOR"

# Audio files to process (in ./data/input-samples/)
INPUT_SAMPLES=(
  "harvard.wav"
  "jfk-audio-inaugural-address-20-january-1961.mp3"
  "jfk-audio-rice-university-12-september-1962.mp3"
)

# Extra decoding flags for complex mode
COMPLEX_ARGS="--beam_size 10 \
  --temperature 0 \
  --patience 2 \
  --suppress_tokens -1 \
  --compression_ratio_threshold 2.0 \
  --logprob_threshold -0.5 \
  --no_speech_threshold 0.4"

# Container images to benchmark
BASE="quay.io/redhat_na_ssa/speech-to-text/whisper"
IMAGES=(
  "$BASE:tiny.en-${IMAGE_FLAVOR}"
  "$BASE:turbo-${IMAGE_FLAVOR}"
  "$BASE:large-${IMAGE_FLAVOR}"
  "$BASE:medium.en-${IMAGE_FLAVOR}"
  "$BASE:small.en-${IMAGE_FLAVOR}"
  "$BASE:base.en-${IMAGE_FLAVOR}"
)

# Create output directory
mkdir -p ./data/metrics

# Initialize metrics CSV
METRIC_FILE="./data/metrics/experiment_metrics.csv"
if [ ! -f "$METRIC_FILE" ]; then
  echo "date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,wer,mer,wil,wip,cer" > "$METRIC_FILE"
fi

# Loop over images
for IMAGE in "${IMAGES[@]}"; do
  IMAGE_TAG=$(basename "$IMAGE" | sed 's/whisper://; s/:/-/g; s/\./_/g')

  for SAMPLE_FILE in "${INPUT_SAMPLES[@]}"; do
    FILENAME="${SAMPLE_FILE%.*}"
    RELATIVE_SAMPLE="input-samples/$SAMPLE_FILE"

    for MODE in cpu_fast cpu_complex gpu_fast gpu_complex; do
      # Build container and output names
      OUTPUT_PREFIX="whisper-${IMAGE_TAG}_${FILENAME}_${MODE}"
      CONTAINER_NAME="$OUTPUT_PREFIX"
      OUTPUT_NAME="${OUTPUT_PREFIX}.txt"

      echo "🚀 Running: $OUTPUT_PREFIX"

      # Runtime flags
      GPU_FLAGS=""
      [[ "$MODE" == *gpu* ]] && GPU_FLAGS="--security-opt=label=disable --device nvidia.com/gpu=all"

      EXTRA_ARGS=""
      [[ "$MODE" == *complex* ]] && EXTRA_ARGS="$COMPLEX_ARGS"

      FP16_FLAG=""
      [[ "$MODE" == *cpu* ]] && FP16_FLAG="--fp16 False"

      ENV_FLAGS=""
      [[ "$MODE" == *cpu* ]] && ENV_FLAGS="-e CUDA_VISIBLE_DEVICES="

      # Get audio duration using ffprobe inside the container
      AUDIO_DURATION=$(podman run --rm \
        -v "$(pwd)/data:/data:z" \
        "$IMAGE" \
        ffprobe -v error -show_entries format=duration -of csv=p=0 "$RELATIVE_SAMPLE" 2>/dev/null)
      AUDIO_DURATION=$(printf "%.3f" "$AUDIO_DURATION")

      # Run transcription and time it
      TMP_LOG=$(mktemp)
      SECONDS=0  # Start timing

      podman run --rm -it \
        --name "$CONTAINER_NAME" \
        $GPU_FLAGS \
        $ENV_FLAGS \
        -v "$(pwd)/data:/data:z" \
        "$IMAGE" \
        whisper "$RELATIVE_SAMPLE" \
          --model_dir /tmp \
          --output_dir /data/metrics/ \
          --output_format txt \
          --language en \
          --task transcribe \
          $FP16_FLAG \
          $EXTRA_ARGS > "$TMP_LOG" 2>&1

      TRANSCODE_SEC=$SECONDS  # End timing

      # Rename Whisper's default output (e.g., harvard.txt) to unique filename
      ORIGINAL_NAME="${FILENAME}.txt"
      if [[ -f "./data/metrics/$ORIGINAL_NAME" ]]; then
        mv "./data/metrics/$ORIGINAL_NAME" "./data/metrics/$OUTPUT_NAME"
      else
        echo "⚠️ Output file $ORIGINAL_NAME not found. Skipping rename."
      fi

      # Count tokens (by word count)
      if [[ -f "./data/metrics/$OUTPUT_NAME" ]]; then
        TOKEN_COUNT=$(wc -w < "./data/metrics/$OUTPUT_NAME" | tr -d '[:space:]')
      else
        TOKEN_COUNT=0
      fi

      # Compute tokens/sec
      TOKENS_PER_SEC="NA"
      if [[ "$TOKEN_COUNT" -gt 0 && "$TRANSCODE_SEC" -gt 0 ]]; then
        TOKENS_PER_SEC=$(awk "BEGIN {printf \"%.2f\", $TOKEN_COUNT / $TRANSCODE_SEC}")
      fi

      # Compute real-time factor
      RTF="NA"
      if [[ "$AUDIO_DURATION" != "" && "$TRANSCODE_SEC" != "0" ]]; then
        RTF=$(awk "BEGIN {printf \"%.3f\", $TRANSCODE_SEC / $AUDIO_DURATION}")
      fi

      # Accuracy scoring using jiwer
      GROUND_TRUTH="/data/ground-truth/${FILENAME}.txt"
      HYPOTHESIS="/data/metrics/${OUTPUT_NAME}"
      WER="NA"; MER="NA"; WIL="NA"; WIP="NA"; CER="NA"

      if [[ -f "./data/metrics/$OUTPUT_NAME" && -f "./data/ground-truth/${FILENAME}.txt" ]]; then
        METRIC_LINES=$(podman run --rm \
          -v "$(pwd)/data:/data:z" \
          "$IMAGE" \
          python3 /data/evaluation-scripts/compare_transcripts.py "$GROUND_TRUTH" "$HYPOTHESIS")

        while IFS='=' read -r key val; do
          case $key in
            WER) WER="$val" ;;
            MER) MER="$val" ;;
            WIL) WIL="$val" ;;
            WIP) WIP="$val" ;;
            CER) CER="$val" ;;
          esac
        done <<< "$METRIC_LINES"
      else
        echo "⚠️ Skipping accuracy scoring (missing transcript or ground-truth)"
      fi

      # Append row to CSV
      echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),$CONTAINER_NAME,$TOKEN_COUNT,$TOKENS_PER_SEC,$AUDIO_DURATION,$RTF,$WER,$MER,$WIL,$WIP,$CER" >> "$METRIC_FILE"

      # Keep CSV sorted by date + time
      HEADER=$(head -n 1 "$METRIC_FILE")
      TAIL=$(tail -n +2 "$METRIC_FILE" | sort -t, -k1,1 -k2,2)
      { echo "$HEADER"; echo "$TAIL"; } > "$METRIC_FILE"

      rm "$TMP_LOG"
      echo "✅ Done: $OUTPUT_PREFIX"
    done
  done
done
