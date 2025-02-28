# Here’s how you can manually run each step from the script in sequence for script.py

## Step 0: Build the Dockerfile

```sh
podman build -t whisper:ubi crawl/openai-whisper/ubi/.
```

## Step 1: Run the pod
Ensure you have the required Python packages installed:

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi /bin/bash 
```

## Step 2: Define Variables
```sh
REFERENCE_FILE="ground-truth/jfk-audio-inaugural-address-20-january-1961.txt"
OUTPUT_DIR="/tmp"
INPUT_FILE="audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3"
MODEL="whisper"
MODEL_SIZE="tiny.en"
MODEL_DIR="/tmp/whisper-models"
BASE_IMAGE="ubuntu"
PLATFORM="ubuntu"
PROCESSOR="gpu"
START_REAL=$(date +%s.%N)
START_PROCESS=$(ps -o etime= -p $$)
END_REAL=$(date +%s.%N)
END_PROCESS=$(ps -o etime= -p $$)
REAL_TIME=$(echo "$END_REAL - $START_REAL" | bc)
USER_TIME=$(echo "$END_PROCESS - $START_PROCESS" | bc)
SYS_TIME=0  # Approximate, since detailed system time isn't tracked
HYPOTHESIS_FILE="$OUTPUT_DIR/jfk-audio-inaugural-address-20-january-1961.txt"

# verify output dir
mkdir -p $OUTPUT_DIR
```

## Step 3: Run the Model
Execute the model and store the output:

```sh
$MODEL $INPUT_FILE \
  --model $MODEL_SIZE \
  --model_dir $MODEL_DIR \
  --output_dir $OUTPUT_DIR

whisper audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
  --model tiny.en \
  --model_dir /tmp/whisper-models \
  --output_dir /tmp
```

## Step 4: CUDA Version

```sh
nvidia-smi | grep "CUDA Version" | awk '{print $9}'
```