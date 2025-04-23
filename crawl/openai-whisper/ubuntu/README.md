# Whisper on Ubuntu

## Review OpenAI Whisper Requirements

Go to [OpenAI Whisper](https://github.com/openai/whisper?tab=readme-ov-file#setup) and review basic packages to install: ffmpeg, Python, Openai-whisper, etc.

## Review the Dockerfile

Notice: ffmpeg is an apt install

```sh
cat crawl/openai-whisper/ubuntu/Dockerfile 
```

## (Option A) Pull the Dockerfiles from Quay.io

```sh
# login to Quay.io
podman login quay.io

export FLAVOR=ubuntu # or ubi9 or ubi9-minimal

screen -S download-images bash -c '
  set -e
  for tag in tiny.en-'$FLAVOR' base.en-'$FLAVOR' small.en-'$FLAVOR' medium.en-'$FLAVOR' large-'$FLAVOR' turbo-'$FLAVOR'; do
    echo "📦 Pulling quay.io/redhat_na_ssa/speech-to-text/whisper:$tag"
    podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag || echo "❌ Failed to pull $tag"
  done
'
```

## (Option B) Build the Dockerfile Embedding the model in the `/data` directory

```sh
for model in tiny.en base.en small.en medium.en large turbo; do
  tag="whisper:${model}-ubuntu"
  echo "🔧 Building image: $tag"
  podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubuntu/.
done
```

NOTE: models will be saved in `/data/.cache/whisper/` in each container image

## Test the containers

### Harvard

[Harvard Speech Recognition Dataset](https://www.kaggle.com/datasets/tmshaikh/speech-recognition-data) provides a way to smoke test before running against more complex audio data.

#### tiny.en

The first test lets run whisper tiny.en ubuntu on cpu transcribing harvard audio data sample:

```sh
# start the container on cpu
podman run --rm -it --name whisper-tiny-en-ubuntu-cpu -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# vanilla whisper command
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en

# Rerun the same command (warm start)
```

```sh
# stop the container
exit
```

The second test lets run whisper with basic arguments:

- `/outside/input-samples/harvard.wav`	Path to the input audio file
- `--model tiny.en`	Use the English-only Tiny model
- `--model_dir /tmp/`	Location to cache/load downloaded models
- `--output_dir metrics/`	Where to write the transcription result
- `--output_format txt`	Output format: plain text (can also be vtt, json, etc.)
- `--language en`	Language code (e.g., en for English)
- `--task transcribe`	Task type: transcribe or translate
- `--fp16 False`	Force FP32 inference (useful on CPU or unsupported GPUs)

```sh
# start the container on cpu
podman run --rm -it --name whisper-tiny-en-ubuntu-cpu-basic -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# whisper command with basic arguments
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en \
  --model_dir /tmp/ \
  --output_dir metrics/ \
  --output_format txt \
  --language en \
  --task transcribe \
  --fp16 False

# Rerun the same command (warm start)
```

```sh
# stop the container
exit
```

The third test lets run whisper with hyperparameter argument values:

- `--beam_size 10`	Number of beams used in beam search (improves quality but slower)
- `--temperature 0`	Sampling temperature (0 = deterministic; higher = more random)
- `--patience 2`	Allowed delay in selecting a less confident token (used in beam search)
- `--suppress_tokens -1`	Disable default token suppression; decode all tokens
- `--compression_ratio_threshold 2.0`	Threshold for flagging repetitive audio artifacts
- `--logprob_threshold -0.5`	Minimum average log probability per segment to accept
- `--no_speech_threshold 0.4`	Threshold for skipping non-speech segments

```sh
# start the container on cpu
podman run --rm -it --name whisper-tiny-en-ubuntu-cpu-hyperparameter -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# whisper command with hyperparameters
time whisper /outside/input-samples/harvard.wav \
--model tiny.en \
--model_dir /tmp/ \
--output_dir metrics/ \
--output_format txt \
--language en \
--task transcribe \
--fp16 False \
--beam_size 10 \
--temperature 0 \
--patience 2 \
--suppress_tokens -1 \
--compression_ratio_threshold 2.0 \
--logprob_threshold -0.5 \
--no_speech_threshold 0.4

# Rerun the same command (warm start)
```

Measure transcription accuracy from (JiWER)[https://github.com/jitsi/jiwer]:

- word error rate (WER)
- match error rate (MER)
- word information lost (WIL)
- word information preserved (WIP)
- character error rate (CER)

```sh
# calculate WER 0.00% means the transcription matches the ground truth exactly
python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate WIL 0.00% means the hypothesis is a perfect match with the reference
python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
```

Review your times for different cpu experiments:

1. whisper command (cold vs warm)
1. whisper command with basic arguments (cold vs warm)
1. whisper command with hyperparameters (cold vs warm)

```sh
# stop the container
exit
```

The first test lets run whisper tiny.en ubuntu on gpu transcribing harvard audio data sample:

```sh
# start the container on gpu
podman run --rm -it --name whisper-tiny-en-ubuntu-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# whisper command
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en

# Rerun the same command (warm start)
```

```sh
# stop the container
exit
```

The second test lets run whisper with basic arguments:

```sh
# start the container on gpu
podman run --rm -it --name whisper-tiny-en-ubuntu-gpu-basic --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# whisper command with basic arguments
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en \
  --model_dir /tmp/ \
  --output_dir metrics/ \
  --output_format txt \
  --language en \
  --task transcribe \
  --fp16 False

# Rerun the same command (warm start)
```

```sh
# stop the container
exit
```

The third test lets run whisper with hyperparameter argument values:

```sh
# start the container on gpu
podman run --rm -it --name whisper-tiny-en-ubuntu-gpu-hyperparameter --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# default whisper command
time whisper /outside/input-samples/harvard.wav \
--model tiny.en \
--model_dir /tmp/ \
--output_dir metrics/ \
--output_format txt \
--language en \
--task transcribe \
--fp16 False \
--beam_size 10 \
--temperature 0 \
--patience 2 \
--suppress_tokens -1 \
--compression_ratio_threshold 2.0 \
--logprob_threshold -0.5 \
--no_speech_threshold 0.4

# Rerun the same command (warm start)
```

Measure transcription accuracy:

```sh
# calculate WER 0.00% means the transcription matches the ground truth exactly
python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate WIL 0.00% means the hypothesis is a perfect match with the reference
python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
```

Review your times for different gpu experiments:

1. whisper command (cold vs warm | cpu vs gpu)
1. whisper command with basic arguments (cold vs warm | cpu vs gpu)
1. whisper command with hyperparameters (cold vs warm | cpu vs gpu)

```sh
# stop the container
exit
```

Rerun the experiment jobs and write the data to test_results.csv for review

```sh
# single test without arguments
./run_cold_warm_test.sh tiny.en-ubuntu cpu harvard none

# single test with basic arguments
./run_cold_warm_test.sh tiny.en-ubuntu cpu harvard basic

# single test with hyperparameters
./run_cold_warm_test.sh tiny.en-ubuntu cpu harvard hyperparameter
```

```sh
# batch tests
for CONFIG in \
  "tiny.en-ubuntu cpu harvard" \
  "base.en-ubuntu cpu harvard" \
  "small.en-ubuntu cpu harvard" \
  "medium.en-ubuntu cpu harvard" \
  "large-ubuntu cpu harvard" \
  "turbo-ubuntu cpu harvard" \
  "tiny.en-ubuntu gpu harvard" \
  "base.en-ubuntu gpu harvard" \
  "small.en-ubuntu gpu harvard" \
  "medium.en-ubuntu gpu harvard" \
  "large-ubuntu gpu harvard" \
  "turbo-ubuntu gpu harvard" 
do
  ./data/evaluation-scripts/run_cold_warm_test.sh $CONFIG
done
```

## Observations:

- Model size
  - Larger models take significantly longer
  - Inference time scales roughly with model size, as expected.
- CPU vs GPU performance
  - GPU tests are faster for warm starts, but not yet efficient on cold start
  - GPU gives more benefit as model size increases and batch size scales
  - CPU-only inference with large or turbo is costly — avoid in production unless necessary.
- Cold start versus warm start
  - Warm starts are consistently faster
  - Warm inference is still faster than CPU even at small batch sizes
  - Warm start skips some loading overhead (e.g., model weights into memory, tokenization cache)
  - Cold start impact is significant on larger models, making persistent or warmed containers more efficient.
- No arguments versus hyperparameters
- Container image scanning results from Quay.io
- IDE versus a notebook for experiments

|||
|-|-|
|[Next -> UBI9 Platform with Whisper](../ubi/platform/README.md)|