
# Whisper on UBI9-Minimal

## Overview

This guide walks you through benchmarking Whisper models using UBI9-minimal containers. It focuses on security, size, and performance trade-offs compared to Ubuntu-based containers.

---

## Learning Objectives

- Understand what UBI (Universal Base Image) is and why it matters in production.
- Compare Ubuntu vs. UBI9-minimal for AI workloads (security, support, compliance).
- Build or pull container images embedding Whisper models.
- Compare model startup time, inference speed, and accuracy across environments.
- Measure system metrics: CPU, GPU, memory usage, power draw, GPU temperatures, VRAM usage.
- Explore implications of building tools like ffmpeg from source vs. using OS packages.
- Run batch jobs for large-scale benchmarking across multiple configurations.
- Build intuition for scaling from single-container tests to production deployments.

---

## What is [UBI9-Minimal](https://catalog.redhat.com/software/base-images/ubi9-minimal)?

| Feature                         | Description                                                                                     |
|----------------------------------|-------------------------------------------------------------------------------------------------|
| Minimal RHEL Container Base     | Lightweight Red Hat Enterprise Linux 9 base image (no shells or extra tools).                   |
| Optimized for Size              | Only includes critical libraries and runtimes.                                                  |
| Freely Redistributable          | Can be shared and deployed without a RHEL subscription (under the Red Hat UBI license).         |
| RPM Support via DNF             | Install additional packages via Red Hat's `ubi-9-baseos` and `ubi-9-appstream` repos.           |
| Security & Compliance           | Includes signed RPMs, vulnerability scan support (e.g., Clair, ACS).                            |
| Suited for AI & Microservices   | Smaller image size → faster cold starts, minimal attack surface, good for inference workloads. |
| Offline-Friendly                | RPMs can be mirrored for air-gapped installs (https://cdn-ubi.redhat.com).                      |
| No ffmpeg by Default            | Must be manually built/installed (important for Whisper and media processing).                  |

---

## Questions to Explore

| **Question Before the Exercise**                         | **Expected Answer / Learning After Completion**                                               |
|----------------------------------------------------------|------------------------------------------------------------------------------------------------|
| Differences between Ubuntu and UBI9-minimal?             | Security, package availability, image size, startup behavior.                                  |
| Decompressed size?                                       | UBI9-minimal is smaller than Ubuntu in most configurations.                                    |
| Speed?                                                   | Performance is comparable; minor differences in cold starts.                                   |
| Accuracy?                                                | Same model = same accuracy, regardless of base image.                                          |
| Security?                                                | UBI9-minimal offers signed RPMs, minimal surface, supports Red Hat scanning tools.             |
| Power?                                                   | No significant differences unless system load varies due to threading behavior.                |
| Temperature?                                             | Similar under equivalent workloads.                                                            |
| Model size impact (e.g., tiny → turbo)?                  | Larger = better accuracy, but slower inference and bigger images.                              |
| GPU vs. CPU speed difference?                            | GPU is 10–15× faster, especially on large models and warm starts.                              |
| Cold vs. warm start?                                     | Cold starts 3–5× slower due to model loading, thread pools, tokenizer init.                    |
| Do hyperparameters help?                                 | Slight WER/WIL improvements; beam search adds latency.                                         |
| Do base images affect performance?                       | Not dramatically; affects size, build time, cold starts.                                       |
| Fastest transcription?                                   | _To be filled from your experiment_                                                            |
| Slowest transcription?                                   | _To be filled from your experiment_                                                            |
| Best metrics for comparison?                             | tokens/sec, RTF, container_runtime_sec, WER, MER, WIL, WIP, CER.                               |
| Deployment throughput goal?                              | Aim for >30 tokens/sec on GPU warm starts.                                                     |
| Parallel vs. sequential jobs?                            | Parallel preferred, but avoid overcommitting resources.                                        |
| Container reusability?                                   | Yes — warm start reuse reduces cost, ideal for benchmarking loops.                             |

---

## Prerequisites

Ensure you've completed the following:

1. SSH into your VM
2. Cloned this repo on the VM
3. Navigated to the repo root
4. Completed the [Ubuntu Setup](../../ubuntu/README.md)

---

## Review the UBI Dockerfile

Note: `ffmpeg` is built from source. Be aware of how security scanners handle custom binaries.

```sh
cat crawl/openai-whisper/ubi/minimal/Dockerfile
```

---

## Option A – Pull Prebuilt Images

```bash
# Login to Quay.io
podman login quay.io
```

```bash
# clear up disk space from the ubuntu images
podman rmi 
```

```bash
export FLAVOR=ubi9-minimal # or ubuntu

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

## Option B – Build Locally with Embedded Models

```sh
# Set your flavor
export FLAVOR=ubi9-minimal  # (or ubi9-minimal)

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

Models will be stored at `/data/.cache/whisper/` inside each image.

---

## Capture Image Sizes

```sh
# Set your variables
export INSTANCE=g4dn-12xlarge # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubi9-minimal  # (or ubuntu)

# Create folders and write image size data
mkdir -p data/metrics/$INSTANCE/$FLAVOR && \
echo "repository,tag,size" | tee data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv && \
podman images --format '{{.Repository}},{{.Tag}},{{.Size}}' | grep 'speech-to-text/whisper' | tee -a data/metrics/$INSTANCE/$FLAVOR/image_sizes.csv
```

```csv
# expected output in data/metrics/$INSTANCE/$FLAVOR
#repository,tag,size
```

**Sample Output:**

```csv
repository,tag,size
quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubi9-minimal,9.74 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubi9-minimal,12.7 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubi9-minimal,9.56 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubi9-minimal,7.47 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubi9-minimal,6.79 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubi9-minimal,6.65 GB
```

---

### Terminal 1: Run Experiments & Gather Metrics

This script writes metrics to data/metrics/$INSTANCE/$FLAVOR including:
date,timestamp,container_name,token_count,**tokens_per_second**,audio_duration,**real_time_factor**,container_runtime_sec,wer,mer,wil,wip,cer,threads,start_type

```sh
# Example setup
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi)

screen -S jobs bash -c "time ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor=$FLAVOR \
  --instance=$INSTANCE \
  --model='tiny.en,large'"
```

### Terminal 2: Monitor Output

```bash
export INSTANCE=g4dn-12xlarge  # (or g5-12xlarge, g6.12xlarge, etc)
export FLAVOR=ubuntu  # (or ubi9-minimal)

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

---

## What are the gains

We are moving up a rung on the ladder on security, supportability and efficiency:

- Whisper runtime is running embedded in the container image. UBI is supported although Whisper is not.
- We have moved from a less secure image with N CVEs to a more secure image with N CVEs.
- We have moved from an unsupported base image.
- We have moved from an image that takes up more storage than less storage.

## ⏮ Navigation

| ← [Back: Ubuntu Setup](../../ubuntu/README.md) | [Next: UBI9 Minimal Whisper Inference →](../../../walk/README.md) |
|-----------------------------------------------|--------------------------------------------------------------------|
