
# Whisper on Ubuntu

## Overview

This guide walks you through benchmarking OpenAI Whisper models in containerized environments (Ubuntu-based), including:

- Cold vs. warm start comparisons  
- CPU vs. GPU performance  
- Hyperparameter tuning impact  
- System metrics collection  
- Accuracy measurement  
- Automation via batch testing

## Objectives

- Run Whisper STT inside containers with different configurations  
- Compare transcription performance and latency across models and hardware  
- Evaluate accuracy using metrics like WER, MER, and CER  
- Capture CPU/GPU utilization and system resource impact  
- Scale benchmarking with automated batch scripts  
- Prepare for production by testing real-world workloads

## Questions to Explore

| **Before the Benchmark**                          | **After the Benchmark (Expected Insight)**                                                  |
|---------------------------------------------------|---------------------------------------------------------------------------------------------|
| What is the impact of model size (tiny → turbo)?  | Larger models increase accuracy but also inference time and image size.                    |
| How much faster is GPU inference than CPU?        | GPUs are typically 10–15× faster on warm starts.                                            |
| Cold vs. warm start performance?                  | Warm starts reduce latency by 3–5× by skipping model loading and initialization.            |
| Do hyperparameters improve accuracy?              | Yes, slightly. Beam search and logprob thresholds improve WER/WIL but increase latency.     |
| How does Whisper perform on short vs. long audio? | Short clips are consistently accurate; long clips show variance based on model and config.  |
| Fastest transcription?                            | _[Fill in based on experiment]_                                                            |
| Slowest transcription?                            | _[Fill in based on experiment]_                                                            |
| Most useful metrics?                              | tokens/sec, RTF, container_runtime_sec, WER, MER, WIL, WIP, CER                             |
| Target throughput for deployment?                 | Aim for >30 tokens/sec on GPU warm inference                                               |
| Run jobs sequentially or in parallel?             | Parallel is faster but must respect core/GPU capacity                                      |
| Are containers reusable across tests?             | Yes—especially valuable for warm starts and reproducible results                           |

## Quick Start

### Step 1: Clone the Project

```bash
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git && \
cd whitepaper-stt-evaluation-on-kubernetes
```

## Review Whisper Requirements

See [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#setup) for prerequisites:  
- Python  
- `ffmpeg`  
- `openai-whisper`  

## ⏱ Understanding `time`

| Output   | Meaning                                                                 |
|----------|-------------------------------------------------------------------------|
| real     | Total wall clock time                                                   |
| user     | Time spent in user-mode (actual CPU execution)                         |
| sys      | Time spent in kernel-mode (e.g., system calls, I/O wait)               |

[Reference](https://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1)

## 🐳 Docker Image Setup

### Option A: Pull Prebuilt Images from Quay.io

```bash
# Login to Quay.io
podman login quay.io
```

Screen hints:
- To detach, press: `Ctrl + A, then D`
- To list sessions: `screen -ls`
- To reattach: `screen -r pull-whisper`

```sh
export FLAVOR=ubuntu # or ubi

screen -S pull-whisper bash -c '
time {
  set -e
  start_time=$(date +%s)
  for tag in tiny.en-'$FLAVOR' base.en-'$FLAVOR' small.en-'$FLAVOR' medium.en-'$FLAVOR' large-'$FLAVOR' turbo-'$FLAVOR'; do
    echo "Pulling quay.io/redhat_na_ssa/speech-to-text/whisper:$tag"
    podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag || echo "❌ Failed to pull $tag"
  done
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  echo "Total download time: $duration seconds"
}'

# Total download time: 1038 seconds

#real    17m18.519s
#user    10m17.688s
#sys     7m45.052s
```

### Option B: Build Locally with Embedded Models

```bash
# Set your flavor
export FLAVOR=ubuntu  # (or ubi)

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
echo "Total build time: $(($duration / 60)) min $(($duration % 60)) sec"
```

📌 Models are embedded in `/data/.cache/whisper/` inside each image.

### Capture Image Sizes

```bash
# Set your variables
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi)

# Create folders and write image size data
mkdir -p data/metrics/$INSTANCE/$FLAVOR && \
echo "repository,tag,size" | tee data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv && \
podman images --format '{{.Repository}},{{.Tag}},{{.Size}}' | grep 'speech-to-text/whisper' | tee -a data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv
```

```csv
# expected output in data/metrics/$INSTANCE/$FLAVOR
#repository,tag,size
#quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubuntu,8.25 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubuntu,9.72 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubuntu,8.16 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubuntu,7.12 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubuntu,6.78 GB
#quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubuntu,6.71 GB
```

## Run Benchmark Tests

### Review Dataset

```sh
echo "--- File Contents ---"
cat data/ground-truth/harvard.txt

echo "--- Word Count ---"
wc -w data/ground-truth/harvard.txt
```

### Test 1: Cold vs Warm (CPU)

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```bash
# Run transcription
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en

# Re-run for warm start

# sample time cold output
# real    0m9.341s
# user    0m29.231s
# sys     0m1.036s

# sample time warm output
# real    0m3.492s
# user    0m27.399s
# sys     0m0.489s
```

```bash
exit
```

### Test 2: Add Basic Inference Flags

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

- -- /outside/input-samples/harvard.wav Path to the input audio file
- --`model tiny.en` Use the English-only Tiny model
- --`model_dir /tmp/` Location to cache/load downloaded models
- --`output_dir metrics/` Where to write the transcription result
- --`output_format txt` Output format: plain text (can also be vtt, json, etc.)
- --`language en` Language code (e.g., en for English)
- --`task transcribe` Task type: transcribe or translate
- --`fp16 False` Force FP32 inference (useful on CPU or unsupported GPUs)

```bash
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en \
  --model_dir /tmp/ \
  --output_dir metrics/ \
  --output_format txt \
  --language en \
  --task transcribe \
  --fp16 False
```

```sh
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

```bash
exit
```

| **First Run (Cold Start)**                                                                                          | **Second Run (Warm Start)**                                                                                      |
|---------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| **Model download** Whisper downloads the model weights (e.g., 72.1M) into `/tmp/`.                                  | **No download** Model is already cached in `/tmp/`.                                                              |
| **Model loading** Weights are deserialized into memory (PyTorch .bin → model object).                              | **Model loaded from disk** Much faster read from local cache.                                                    |
| **Tokenizer initialization** SentencePiece-based tokenizer is loaded and possibly compiled.                        | **Tokenizer is ready** Possibly kept in memory or disk-cached.                                                   |
| **First-time memory allocation** RAM is allocated for model layers. OpenBLAS initializes CPU thread pools.         | **Thread pools are warm** OpenBLAS/MKL thread pools already initialized.                                         |
| **Inference** Audio is transcribed after setup steps complete.                                                      | **Inference only** Directly starts transcribing.                                                                 |
| **Result** All steps take time — cold start might take ~6s.                                                         | **Result** Warm start is ~50% faster — drops to ~3.3s.                                                            |

You can see this even more dramatically if you use larger models (like medium.en, large, turbo) — First run cold start might take 30–90 seconds. Second run will often cut that by half or more!

### Test 3: Add Hyperparameters

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

| **Argument**                     | **Plain English Meaning**                                                                 | **Impact on Performance**                                             |
|----------------------------------|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| `--beam_size 10`                | Try 10 different guesses before picking the best word (beam search).                       | Slower transcription, but can slightly improve quality.              |
| `--temperature 0`              | Always choose the most confident word (no randomness).                                    | Deterministic output; no significant slowdown.                       |
| `--patience 2`                 | Wait up to 2 rounds for a better guess before finalizing a word.                           | Small extra processing time; may improve result.                     |
| `--suppress_tokens -1`         | Don’t block any tokens; allow the model to say anything.                                   | No impact unless you’ve configured specific tokens to suppress.      |
| `--compression_ratio_threshold 2.0` | Detect repetitive artifacts (like "uh uh uh") and remove them.                         | Minimal cost; useful for cleaning noisy audio.                       |
| `--logprob_threshold -0.5`     | Discard low-confidence segments below -0.5 log probability.                                | Small compute overhead; improves quality by filtering bad output.    |
| `--no_speech_threshold 0.4`    | Skip over segments where the model detects no speech.                                      | Can slightly reduce transcription time.                              |

```bash
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

# sample time cold output
# real    0m4.966s
# user    0m37.362s
# sys     0m0.710s

# sample time warm output
# real    0m3.674s
# user    0m44.729s
# sys     0m0.581s
```

| **First Run (Cold Start with Hyperparameters)**                                                                                     | **Second Run (Warm Start with Hyperparameters)**                                                                                    |
|-------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| **Command:** Whisper with `--beam_size 10`, `--temperature 0`, `--patience 2`, and other decoding arguments.                        | **Same command**, re-run immediately after the first.                                                                               |
| **Model loading:** Model deserialized from `/tmp/` into memory (PyTorch).                                                           | **Model already in memory**, skipping deserialization.                                                                              |
| **Thread pools:** OpenBLAS thread pools initialized for the first time.                                                             | **Thread pools are warm**, no init overhead.                                                                                        |
| **Tokenizer:** Initialized from scratch.                                                                                            | **Tokenizer is ready**, cached in memory or quickly loaded.                                                                         |
| **Beam search:** Active — multiple hypotheses evaluated at each token step (CPU intensive).                                         | **Beam search still active**, contributes most of the CPU time in both runs.                                                       |
| **real:** `6.022s`                                                                                                                  | **real:** `3.674s`                                                                                                                  |
| **user:** `44.440s`                                                                                                                 | **user:** `44.729s` (almost identical — beam search CPU cost dominates)                                                             |
| **sys:** `0.730s`                                                                                                                   | **sys:** `0.581s`                                                                                                                   |
| **Conclusion:** Cold start includes model setup and memory/thread overhead.                                                        | **Conclusion:** Warm start cuts wall time nearly in half, but CPU time is still high due to beam search complexity.                |


## 🧠 Accuracy Metrics with JiWER

WER (Word Error Rate): How many words were wrong in the transcription.
MER (Match Error Rate): How many changes were needed to fix the transcription.
WIL (Word Information Lost): How much word meaning was missed.
WIP (Word Information Preserved): How much word meaning was kept.
CER (Character Error Rate): How many letters were wrong.


```bash
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

# sample accuracy output
# WER: 0.00%
# MER: 0.00%
# WIL: 0.00%
# WIP: 100.00%
# CER: 0.00%
```

```bash
exit
```

## ⚙️ Optional GPU Run

```bash
podman run --rm -it   --security-opt=label=disable   --device nvidia.com/gpu=all   -v $(pwd)/data/:/outside/:z   whisper:tiny.en-ubuntu /bin/bash
```

## 🧵 Run Batch Experiments (Parallel CPU/GPU)

Instead of manually repeating these steps on gpu transcribing harvard audio data sample, lets create job of experiments and run them in parallel.

The output writes the data to data/metrics/aiml_functional_metrics.csv for easier review

### Terminal 1: Run Experiments

```bash
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi)

screen -S jobs ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor=$FLAVOR \
  --instance=$INSTANCE \
  --model="tiny.en,small.en"
```

### Terminal 2: Monitor Output

```bash
tail -f data/metrics/$INSTANCE/$FLAVOR/aiml_functional_metrics.csv
```

```bash
watch -n 2 -t '
echo "== NVIDIA GPU Usage =="
nvidia-smi
echo "\n== Top Whisper Threads by CPU Usage =="
ps -T -p $(pgrep -d"," -f whisper) -o pid,tid,pcpu,pmem,comm | sort -k3 -nr | head -20
'
```

## ⏮ Navigation

| ← [Provision VM w/ GPU](../../RHEL_GPU.md) | [UBI9 Minimal with Whisper →](../ubi/README.md) |
|--------------------------------------------|----------------------------------------------------------|
