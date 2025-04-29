# Whisper on Ubuntu

## Section Expectations

- Run Whisper STT inside containers with various configs
- Compare cold vs warm starts, CPU vs GPU, basic vs hyperparam runs
- Measure transcription speed, accuracy, and runtime
- Evaluate container performance using system metrics (CPU/GPU/memory)
- Understand trade-offs across model sizes and environments (Ubuntu vs UBI)
- Automate and scale tests using batch scripts
- Prepare for production by benchmarking real-world workloads

## Questions to Ask Before Running Whisper Benchmarks

| **Question Before the Exercise**| **Expected Answer / Learning After Completion**|
|-|-|
| What is the impact of model size (e.g., tiny → turbo)?                 |  |
| How much faster is GPU inference compared to CPU?                      |  |
| How do cold starts compare to warm starts?                             |  |
| Do advanced arguments (hyperparameters) improve accuracy?              |  |
| How accurate is Whisper across short vs. long audio?                   |  |
| What was the fastest transcription?                                    |  |
| What was the slowest transcription?                                    |  |
| What metrics are most useful to compare experiments?                   |  |
| What’s a reasonable throughput goal for deployment?                    |  |
| Should experiments run in parallel or sequentially?                    |  |
| Are containers reusable across experiments?                            |  |

## Git clone the project on the VM

ssh into your VM

```sh
# clone in the VM
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git

# move to repo
cd whitepaper-stt-evaluation-on-kubernetes
```

## Review OpenAI Whisper Requirements

Go to [OpenAI Whisper](https://github.com/openai/whisper?tab=readme-ov-file#setup) and review basic packages to install: ffmpeg, Python, Openai-whisper, etc.

## Review the Dockerfile

Notice: ffmpeg is an apt install with the Ubuntu image

```sh
cat crawl/openai-whisper/ubuntu/Dockerfile 
```

## (Option A) Pull the Dockerfiles from Quay.io

```sh
podman login quay.io

export FLAVOR=ubuntu # or ubi9 or ubi9-minimal

time {
  set -e
  start_time=$(date +%s)
  for tag in tiny.en-$FLAVOR base.en-$FLAVOR small.en-$FLAVOR medium.en-$FLAVOR large-$FLAVOR turbo-$FLAVOR; do
    echo "📦 Pulling quay.io/redhat_na_ssa/speech-to-text/whisper:$tag"
    podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag || echo "❌ Failed to pull $tag"
  done
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "⏱️ Total download time: $duration seconds"
}


#⏱️ Total download time: 1038 seconds

#real    17m18.519s
#user    10m17.688s
#sys     7m45.052s
```

## (Option B) Build the Dockerfile Embedding the model in the `/data` directory

```sh
# Set your flavor
export FLAVOR=ubuntu  # (or ubi9 or ubi9-minimal)

# Start a screen session for building
set -e
start_time=$(date +%s)

for model in tiny.en base.en small.en medium.en large turbo; do
  tag="whisper:${model}-$FLAVOR"
  echo "🔧 Building image: $tag"
  podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/$FLAVOR/. || echo "❌ Failed to build $tag"
done

end_time=$(date +%s)
duration=$((end_time - start_time))
echo "⏱️ Total build time: $(($duration / 60)) min $(($duration % 60)) sec"
```

NOTE: models will be saved in `/data/.cache/whisper/` in each container image

## Capture the image sizes

This captures the image sizes for comparison later and writes to `data/metrics/image_sizes.csv`.

```sh
# image sizes
mkdir -p data/metrics && \
echo "repository,tag,size" | tee data/metrics/image_sizes.csv && \
podman images --format '{{.Repository}},{{.Tag}},{{.Size}}' | grep 'speech-to-text/whisper' | tee -a data/metrics/image_sizes.csv
```

```sh
# expected output
#repository,tag,size
#quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubuntu,8.25 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubuntu,9.72 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubuntu,8.16 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubuntu,7.12 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubuntu,6.78 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubuntu,6.71 GB
```

## Test the containers

### Harvard

[Harvard Speech Recognition Dataset](https://www.kaggle.com/datasets/tmshaikh/speech-recognition-data) provides a way to smoke test before running against more complex audio data.

### Review the ground truth data

```sh
echo "--- File Contents ---"
cat data/ground-truth/harvard.txt

echo "--- Word Count ---"
wc -w data/ground-truth/harvard.txt
```

### The first test lets run whisper tiny.en ubuntu on cpu transcribing harvard audio data sample:

```sh
# start the container on cpu
podman run --rm -it --name whisper-tiny-en-ubuntu-cpu -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```sh
# run whisper command
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en

# rerun the same command (warm start)

# sample time cold output
# real    0m3.065s
# user    0m30.300s
# sys     0m0.585s

# sample time warm output
# real    0m3.051s
# user    0m30.710s
# sys     0m0.525s
```

Notice:

- language has to be detected
- floating point has to be detected
- the task of transcribe has to be detected

```sh
# stop the container
exit
```

### The second test lets run whisper with basic arguments:

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

# sample time cold output
# real    0m6.038s
# user    0m33.521s
# sys     0m1.360s

# sample time warm output
# real    0m3.280s
# user    0m34.902s
# sys     0m1.947s
```

#### What happens during the first run:

1. Model download
  - You see the 72.1M/72.1M progress bar:
  - 100%|█████████████████████████████████████| 72.1M/72.1M
  - Whisper is downloading the tiny.en model weights from HuggingFace (or OpenAI) into /tmp/ (your --model_dir).
1. Model loading
  - After downloading, the model is deserialized into memory (PyTorch .bin format → model object).
1. Tokenizer initialization
  - The tokenizer (based on SentencePiece or similar) is loaded and possibly compiled.
1. First-time memory allocation
  - CPU RAM is allocated for model layers.
  - OpenBLAS may also initialize CPU thread pools (expensive on first call).
1. Inference
  - Audio is transcribed.

All of those steps — downloading, deserializing, setting up caches — take time.
That's why your first real time is 6 seconds.

#### What happens during the second run:

1. No download
  - Model already exists in /tmp/. No need to fetch from network.
1. Model loaded from disk
  - Much faster — it reads the weights from local storage.
1. Tokenizer is ready
  - Possibly kept in memory, or quickly initialized if disk-cached.
1. Thread pools are warm
  - OpenBLAS, MKL, or NumPy threading libraries have already spun up threads.
1. Inference only
  - Just the actual transcribing.

So your second real time drops to ~3.3 seconds — about 50% faster.

```sh
# stop the container
exit
```

You can see this even more dramatically if you use larger models (like medium.en, large, turbo) —
First run cold start might take 30–90 seconds.
Second run will often cut that by half or more!

### The third test lets run whisper with hyperparameter argument values:

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

# real    0m6.022s
# user    0m44.440s
# sys     0m0.730s

# real    0m3.674s
# user    0m44.729s
# sys     0m0.581s
```

Argument | Plain English Meaning | Impact
|-|-|-|
--beam_size 10 | Instead of picking the next word instantly, the model tries 10 different guesses before choosing. | Makes transcription slower but sometimes slightly better.
--temperature 0 | Always pick the most confident guess (no randomness at all). | No real slowdown.
--patience 2 | Wait a little longer (2 chances) before locking in the final guess. | Small extra time cost.
--suppress_tokens -1 | Don’t block any words — allow the model to say anything. | No real effect unless customized.
--compression_ratio_threshold 2.0 | Detect if audio sounds repetitive (like "uh uh uh") and fix it. | Tiny time cost; helpful for noisy audio.
--logprob_threshold -0.5 | Reject very bad guesses based on confidence. | Small compute cost, better quality.
--no_speech_threshold 0.4 | Skip silence faster if the model thinks there’s no speaking. | Can slightly speed things up.

#### First, why is the second run faster?

Same as before — cold start vs warm start:

- First run loads the model from scratch (even though you don't see it download because it's cached, /tmp/ model_dir still has to deserialize and initialize PyTorch weights).
- Second run benefits from Python memory caching, already initialized OpenBLAS/MKL thread pools, and tokenizer caches.

#### Why the second pass is faster, but not dramatically faster with beam search?

- Model load time is eliminated
- Thread pools are warmed
- Beam search still costs CPU cycles, even in warm start
- (Beam search is CPU bound — because it's exploring multiple hypotheses at every token step.)

#### Second, what about the bigger difference you’re seeing with hyperparameters?

You added beam search and other decoding hyperparameters, and that changes the inference behavior:

Config | Decode Strategy | Speed | Accuracy
|-|-|-|-|
Basic (no hyperparams) | Greedy (fastest) | Fast | Good
Hyperparams | Beam Search (explores alternatives) | Slower | Slightly better

- Beam size = trade speed for accuracy
- Temperature = deterministic vs random
- Patience = wait for better guesses
- Suppress / compression / logprob = clean up bad or repetitive results
- No speech threshold = don't waste time on silence

### Measure transcription accuracy from [JiWER](https://github.com/jitsi/jiwer):

- **WER (Word Error Rate):** How many words were wrong in the transcription.
- **MER (Match Error Rate):** How many changes were needed to fix the transcription.
- **WIL (Word Information Lost):** How much word meaning was missed.
- **WIP (Word Information Preserved):** How much word meaning was kept.
- **CER (Character Error Rate):** How many letters were wrong.

```sh
# WER 0.00% means the transcription matches the ground truth exactly
# MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
# WIL 0.00% means the hypothesis is a perfect match with the reference
# WIP 1.00 (100%) means perfect preservation from the reference in the hypothesis (i.e., a perfect match).
# CER 0.00% means characters in your hypothesis match the characters in your reference exactly

python3 -c '
from jiwer import wer, mer, wil, cer
ref = open("/outside/ground-truth/harvard.txt").read()
hyp = open("metrics/harvard.txt").read()
wil_val = wil(ref, hyp)
print(f"WER: {wer(ref, hyp):.2%}")
print(f"MER: {mer(ref, hyp):.2%}")
print(f"WIL: {wil_val:.2%}")
print(f"WIP: {1 - wil_val:.2%}")
print(f"CER: {cer(ref, hyp):.2%}")
'
```

### Review your times for different cpu experiments

1. whisper command (cold vs warm)
1. whisper command with basic arguments (cold vs warm)
1. whisper command with hyperparameters (cold vs warm)

```sh
# stop the container
exit
```

### Testing on GPU

For illustration purposes, here is how you would run the same container on a GPU setting the `--security-opt=label=disable` and `--device nvidia.com/gpu=all` arguments.

You can pass this step and move onto batch testing.

```sh
# start the container on gpu
podman run --rm -it --name whisper-tiny-en-ubuntu-gpu \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -v $(pwd)/data/:/outside/:z \
  whisper:tiny.en-ubuntu /bin/bash
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

## Batch jobs running experiments on CPU and GPU in parallel

Instead of manually repeating these steps on gpu transcribing harvard audio data sample, lets create job of experiments and run them in parallel.

The output writes the data to `data/metrics/aiml_functional_metrics.csv` for easier review

```sh
# Terminal 1 of 2
# You can copy this entire block and paste in the terminal

# Set your parameters
FLAVOR=ubuntu         # Options: ubuntu, ubi9, ubi9-minimal
INSTANCE=g5.12xlarge  # Set your instance type
MODELS=tiny.en,small.en
INPUT=harvard.wav    # Enter if you want process a single input, else All Audio files processed
#INPUT=jfk-audio-inaugural-address-20-january-1961.mp3
#INPUT=jfk-audio-rice-university-12-september-1962.mp3

# Run the script
screen -S jobs ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor="$FLAVOR" \
  --instance="$INSTANCE" \
  --model="$MODELS"
```

```sh
# Terminal 2 of 2
# monitor the metrics writing to data/metrics/aiml_functional_metrics.csv
$ tail -f data/metrics/aiml_functional_metrics.csv

# monitor the cpu / gpu metrics
watch -n 2 -t '
  echo "== NVIDIA GPU Usage =="
  nvidia-smi
  echo "\n== Top Whisper Threads by CPU Usage =="
  ps -T -p $(pgrep -d"," -f whisper) -o pid,tid,pcpu,pmem,comm | sort -k3 -nr | head -20
'
```

| **Question Before the Exercise**                                      | **Expected Answer / Learning After Completion**                                                                           |
|------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| What is the impact of model size (e.g., tiny → turbo)?                 | Larger models offer better transcription accuracy but increase inference time and image size.                             |
| How much faster is GPU inference compared to CPU?                      | GPU inference is 10–15x faster on warm starts and is necessary for large models or real-time workloads.                   |
| How do cold starts compare to warm starts?                             | Cold starts can take 3–5x longer due to model loading and tokenization caching overhead.                                  |
| Do advanced arguments (hyperparameters) improve accuracy?              | Hyperparameters slightly improve accuracy (WER, WIL) but also increase latency.                                            |
| How accurate is Whisper across short vs. long audio?                   | Short samples are consistently accurate; longer files show more variation across model sizes and config modes.            |
| What was the fastest transcription?                                    |  |
| What was the slowest transcription?                                    |  |
| What metrics are most useful to compare experiments?                   | tokens/sec, real_time_factor (RTF), container_runtime_sec, WER, MER, WIL, WIP, CER.                                        |
| What’s a reasonable throughput goal for deployment?                    | Aim for >30 tokens/sec on GPU warm inference for real-time production performance.                                        |
| Should experiments run in parallel or sequentially?                    | Parallel jobs are efficient, but overloading CPU cores or GPU memory should be avoided.                                   |
| Are containers reusable across experiments?                            | Yes, especially useful for warm start reuse and reproducible performance analysis.                                        |

|[Previous <- Provision VM w/GPU](../../RHEL_GPU.md)|[Next -> UBI9 Minimal with Whisper](../ubi/minimal/README.md)|
|-|-|