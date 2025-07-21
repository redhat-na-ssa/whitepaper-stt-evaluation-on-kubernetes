
# Whisper on Ubuntu

## Overview

This guide crawls you through OpenAI Whisper models in containerized images (Ubuntu-based) and experimenting with:

- Cold vs. warm start comparisons  
- CPU vs. GPU performance  
- Hyperparameter tuning impact  
- System metrics collection  
- Accuracy measurement  
- Automation via batch testing all the above

---

## Learning Objectives

- Run Whisper STT inside containers with different configurations.
- Compare transcription performance and latency across models and hardware.
- Evaluate accuracy using metrics like WER, MER, and CER.
- Capture CPU/GPU utilization and system resource impact.
- Run batch jobs for large-scale benchmarking across multiple configurations.
- Build intuition for scaling from single-container tests to production deployments.

---

## Questions to Explore

| **Questions**| **Answers**|
|---------------------------------------------------|-|
| How big are the decompressed images with embedded models? | |
| What is the security posture (CVE report) of these model images (packages vs. model)? | |
| What is the role of ground truth and overall model evaluation (simple vs. complex data)? | |
| Performance gains from cold vs. warm start performance.  | |
| What can the model autodetect (FP, Language, Task)? | |
| What is the performance gains of basic inference flags?   | |
| The impact of advanced decoding arguments on speed and quality. | |
| Do advanced arguments / hyperparameters improve accuracy? | |
| How to measure accuracy for Audio models (Experiment vs. Production)?  | |
| Container placement on CPU and GPU.                | |
| The importance of scheduling batch jobs, parallel processing and saturation. | |
| Making data driven decisions from experiments.     | |
| What combinations of model-size, processor, argument flags, and start type performed the best on different audio samples.       | |
| Should you target CPU, GPU or Both?                | |
| Should you always have models warm?                | |
| What was the fastest transcription?                | |
| What was the slowest transcription?                | |
| What was the most accurate on complex audio files? | |
| What are useful metrics?                           | |

---

## Procedure

Prerequisites:

1. SSH into your VM
2. Cloned this repo on the VM
3. Navigated to the repo root
4. Completed the [VM w/GPU provisioning](crawl/RHEL_GPU.md)

---

### Clone the Project

```bash
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git && \
cd whitepaper-stt-evaluation-on-kubernetes
```

## Review Whisper Requirements

See [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#setup) for prerequisites:  
1. Python
1. `ffmpeg`
1. `openai-whisper`
1. etc.

---

## Understanding `time`

| Output   | Meaning                                                                 |
|----------|-------------------------------------------------------------------------|
| real     | Total wall clock time                                                   |
| user     | Time spent in user-mode (actual CPU execution)                         |
| sys      | Time spent in kernel-mode (e.g., system calls, I/O wait)               |

[Reference](https://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1)

---

## Review the Dockerfile

From this section we can understand:

1. The Dockerfile alignment with the Whisper GitHub documents.
1. How big are the decompressed images with embedded models?
1. What is the security posture (CVE report) of these model images (packages vs. model)?

Note: `ffmpeg` is just installed.

```sh
cat crawl/openai-whisper/ubuntu/Dockerfile
```

---

### Option A: Pull Prebuilt Images from Quay.io

Screen hints for next command:

- To detach, press: `Ctrl + A, then D`
- To list sessions: `screen -ls`
- To reattach: `screen -r pull-whisper`

```sh
export FLAVOR=ubuntu # or ubi9-minimal

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

---

### Option B: Build Locally with Embedded Models

```bash
# Set your flavor
export FLAVOR=ubuntu  # (or ubi9-minimal)

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

Models are embedded in `/data/.cache/whisper/` inside each image.

---

### Capture Image Sizes

```bash
# Set your variables
export INSTANCE=g4dn-12xlarge # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi9-minimal)

# Create folders and write image size data
mkdir -p data/metrics/$INSTANCE/$FLAVOR && \
echo "repository,tag,size" | tee data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv && \
podman images --format '{{.Repository}},{{.Tag}},{{.Size}}' | grep 'speech-to-text/whisper' | tee -a data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv
```

```csv
# expected output in data/metrics/$INSTANCE/$FLAVOR
repository,tag,size
quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubuntu,8.25 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubuntu,9.72 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubuntu,8.16 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubuntu,7.12 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubuntu,6.78 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubuntu,6.71 GB
```

---

## Start Experimenting

From this section we can discuss what is the role of ground truth and overall model evaluation (simple vs. complex data)?

---

### Review Dataset

```sh
echo "--- File Contents ---"
cat data/ground-truth/harvard.txt

echo "--- Word Count ---"
wc -w data/ground-truth/harvard.txt
```

---

### Cold vs Warm (CPU)

From this section:

1. Performance gains from cold vs. warm start performance.
1. What can the model autodetect (FP, Language, Task)?

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

```bash
# Run transcription
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en

# Re-run for warm start

# sample time cold output
# real    0m3.735s
# user    0m31.462s
# sys     0m1.729s

# sample time warm output
# real    0m3.520s
# user    0m28.041s
# sys     0m0.656s
```

```bash
exit
```

Discussion:

- FP16 is not supported on CPU; using FP32 instead
- Language has to be detected
- Cold start - First transcription; loading model & audio from disk; no caching.
- Warm start - Second transcription; model and files are cached in memory.
- real: Total elapsed (wall-clock) time from start to finish. This is the actual time you wait.
  - The transcription took ~3.5 seconds to complete.
- user: Total CPU time spent running code in user space (e.g., Python, libraries). This adds up across CPU cores, so it’s often much larger than real time if multi-threading is used.
  - Multiple CPU threads were busy—likely ~8× parallelism, so 8 cores × ~3.5 sec each.
- sys: Total CPU time spent on system (kernel) tasks like file I/O. Also summed across cores.
  - Some additional time spent in system calls (model/file handling).

---

#### Details on Cold vs. Warm starts.

| **First Run (Cold Start)** | **Second Run (Warm Start)**  |
|-|-|
| **Model download** Whisper downloads the model weights (e.g., 72.1M) into `/tmp/`.                                  | **No download** Model is already cached in `/tmp/`.                                                              |
| **Model loading** Weights are deserialized into memory (PyTorch .bin → model object).                              | **Model loaded from disk** Much faster read from local cache.                                                    |
| **Tokenizer initialization** SentencePiece-based tokenizer is loaded and possibly compiled.                        | **Tokenizer is ready** Possibly kept in memory or disk-cached.                                                   |
| **First-time memory allocation** RAM is allocated for model layers. OpenBLAS initializes CPU thread pools.         | **Thread pools are warm** OpenBLAS/MKL thread pools already initialized.                                         |
| **Inference** Audio is transcribed after setup steps complete.                                                      | **Inference only** Directly starts transcribing.                                                                 |
| **Result** All steps take time — cold start might take ~6s.                                                         | **Result** Warm start is ~50% faster — drops to ~3.3s.                                                            |

You can see this even more dramatically if you use larger models (like medium.en, large, turbo) — First run cold start might take 30–90 seconds. Second run will often cut that by half or more!

---

### Add Basic Inference Flags

From this section:

1. What is the performance gains of basic inference flags?

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

- -- /outside/input-samples/harvard.wav Path to the input audio file
- --`model tiny.en` Use the English-only Tiny model
- --`language en` Language code (e.g., en for English)
- --`task transcribe` Task type: transcribe or translate
- --`fp16 False` Force FP32 inference (useful on CPU or unsupported GPUs)

```bash
time whisper /outside/input-samples/harvard.wav \
  --model tiny.en \
  --language en \
  --task transcribe \
  --fp16 False

# Rerun the same command (warm start)

# sample time cold output
# real    0m3.528s
# user    0m27.766s
# sys     0m0.621s

# sample time warm output
# real    0m3.473s
# user    0m27.031s
# sys     0m0.517s
```

```bash
exit
```

Discussion:

The real, user, sys times stay in the same ballpark as earlier, because:

- You still load the model (default path) and transcribe.
- You don’t write any output files (no --output_dir), so disk I/O is lighter.
- The minimal difference between ~27 user seconds is just normal noise (threading, CPU scheduling).

---

### Add Hyperparameters

From this second:

1. The impact of advanced decoding arguments on speed and quality.
1. Do advanced arguments / hyperparameters improve accuracy?

```bash
podman run --rm -it -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubuntu /bin/bash
```

| **Argument** | **Plain English Meaning** | **Impact on Performance** |
|-|-|-|
| `--beam_size 10`                | Try 10 different guesses before picking the best word (beam search).                       | Slower transcription, but can slightly improve quality.              |
| `--temperature 0`              | Always choose the most confident word (no randomness).                                    | Deterministic output; no significant slowdown.                       |
| `--patience 2`                 | Wait up to 2 rounds for a better guess before finalizing a word.                           | Small extra processing time; may improve result.                     |
| `--suppress_tokens -1`         | Don’t block any tokens; allow the model to say anything.                                   | No impact unless you’ve configured specific tokens to suppress.      |
| `--compression_ratio_threshold 2.0` | Detect repetitive artifacts (like "uh uh uh") and remove them.                         | Minimal cost; useful for cleaning noisy audio.                       |
| `--logprob_threshold -0.5`     | Discard low-confidence segments below -0.5 log probability.                                | Small compute overhead; improves quality by filtering bad output.    |
| `--no_speech_threshold 0.4`    | Skip over segments where the model detects no speech.                                      | Can slightly reduce transcription time.                              |

```bash
time whisper /outside/input-samples/harvard.wav\
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

# sample time cold output
# real    0m5.024s
# user    0m39.498s
# sys     0m3.831s

# sample time warm output
# real    0m3.813s
# user    0m35.207s
# sys     0m0.522s
```

Discussion:

- real time increased (~5.0s vs ~3.5s earlier)
  - The beam search (beam_size 10 + patience 2) forces Whisper to do more computation per transcription step, slowing things down slightly.
- user time jumped (~35–39 sec vs ~27 sec earlier)
  - More CPU work because decoding is more intensive.
- sys time
  - 1st run: 3.8 sec (writing output + initial setup).
  - 2nd run: 0.5 sec (no model download, only minimal I/O).
- You’ll notice the timestamps changed slightly
  - e.g., [00:00.000 --> 00:04.480] became [00:00.000 --> 00:04.000]
  - This reflects beam search making different alignment choices versus simpler decoding.
- Adding advanced decoding arguments (especially --beam_size) increases CPU time and wall-clock time because - Whisper is doing more thorough search to optimize output quality.
- The first run is slower because it loads the model and writes output; the second run benefits from caching.
- These settings are useful for improving accuracy and control but come with expected performance costs.

| **First Run (Cold Start with Hyperparameters)**| **Second Run (Warm Start with Hyperparameters)** |
|-|-|
| **Command:** Whisper with `--beam_size 10`, `--temperature 0`, `--patience 2`, and other decoding arguments.             | **Same command**, re-run immediately after the first.                                                               |
| **Model loading:** Model **loaded and deserialized** from `/tmp/` into memory (PyTorch weights + layers initialized).    | **Model already cached in memory**, skipping deserialization/loading overhead.                                      |
| **Thread pools:** OpenBLAS and other thread pools **initialized** for the first time (CPU threading overhead).           | **Thread pools reused**, no re-initialization overhead.                                                             |
| **Tokenizer:** Tokenizer **loaded and initialized** (likely from file or embedded resource).                             | **Tokenizer reused** from memory or fast re-initialization (much faster).                                           |
| **Beam search:** Active — **increases decoding complexity** by evaluating multiple hypotheses per token (CPU-intensive). | **Beam search still active**, continues to dominate CPU time in both runs.                                          |
| **real:** `~5.024s`                                                                                                      | **real:** `~3.813s`                                                                                                 |
| **user:** `~39.5s`                                                                                                       | **user:** `~35.2s` (slightly faster, but CPU load remains high due to beam search).                                 |
| **sys:** `~3.8s`                                                                                                         | **sys:** `~0.5s` (first run includes extra I/O for saving outputs and model setup).                                 |
| **Conclusion:** Cold start includes model + thread setup and output I/O overhead; beam search adds significant CPU load. | **Conclusion:** Warm start avoids setup cost (faster wall time), but beam search keeps CPU usage high in both runs. |

---

### Observations

On CPU with against 43 characters of clear speech:

- Warm start gives marginal gains on CPU - Skip optimizations for warm-start unless batching many tasks.
- Hyperparameters add 30–50% overhead - Use only if accuracy gain is worth the extra latency/CPU load.
- Lots of CPU parallelism seen - Tune thread usage if you batch jobs or run on shared hardware.
- Baseline performance is consistent - Your current baseline (no args or basic) looks efficient and stable.

---

## Accuracy Metrics with JiWER

How to measure accuracy for Audio models? JiWER is a common library for measuring audio model performance.

1. WER (Word Error Rate): How many words were wrong in the transcription.
1. MER (Match Error Rate): How many changes were needed to fix the transcription.
1. WIL (Word Information Lost): How much word meaning was missed.
1. WIP (Word Information Preserved): How much word meaning was kept.
1. CER (Character Error Rate): How many letters were wrong.

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

---

## (Optional) Running the same experiments on GPUS

Placing the container on GPU instead of CPU you add the `--security` and `--device` flags on run.

```bash
# Example running the cold hyperparameter experiment on GPU
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -v $(pwd)/data/:/outside/:z \
  whisper:tiny.en-ubuntu /bin/bash -c "
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
  "
```

```bash
# Example output
100%|█████████████████████████████████████| 72.1M/72.1M [00:02<00:00, 29.2MiB/s]
[00:00.000 --> 00:04.000]  The stale smell of old beer lingers.
[00:04.000 --> 00:07.000]  It takes heat to bring out the odor.
[00:07.000 --> 00:10.000]  A cold dip restores health and zest.
[00:10.000 --> 00:13.000]  A salt pickle tastes fine with ham.
[00:13.000 --> 00:15.000]  Tacos al pastor are my favorite.
[00:15.000 --> 00:18.000]  A zestful food is the hot cross bun.

real    0m15.241s
user    0m10.981s
sys     0m2.170s
```

---

## Run Batch Experiments (Parallel CPU/GPU) & Capture Metrics

This script writes metrics to data/metrics/$INSTANCE/$FLAVOR including:
date,timestamp,container_name,token_count,**tokens_per_second**,audio_duration,**real_time_factor**,container_runtime_sec,wer,mer,wil,wip,cer,threads,start_type

From this section:

1. The importance of scheduling batch jobs, parallel processing and saturation.
1. Making data driven decisions from experiments.

Instead of manually repeating these steps on gpu transcribing harvard audio data sample, lets create job of experiments and run them in parallel.

Parallelization:

- The script runs CPU and GPU jobs in parallel using background processes (&), limited by MAX_CPU_JOBS to control concurrency.
- CPU jobs: Each container is assigned multiple CPU threads using environment flags for OpenMP and similar libraries.
- GPU jobs: The script binds each GPU container to a specific GPU using --device nvidia.com/gpu=X, enabling parallel GPU execution.

---

#### Terminal 1: Run Experiments & Gather Metrics

This script writes metrics to data/metrics/$INSTANCE/$FLAVOR including:
date,timestamp,container_name,token_count,**tokens_per_second**,audio_duration,**real_time_factor**,container_runtime_sec,wer,mer,wil,wip,cer,threads,start_type

```bash
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi)

screen -S jobs bash -c "time ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor=$FLAVOR \
  --instance=$INSTANCE \
  --model='tiny.en,large'"
```

---

#### Terminal 2: Monitor Output

```bash
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi9-minimal)

tail -f data/metrics/$INSTANCE/$FLAVOR/aiml_functional_metrics.csv
```

Or you can watch the GPU and CPU processes

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
