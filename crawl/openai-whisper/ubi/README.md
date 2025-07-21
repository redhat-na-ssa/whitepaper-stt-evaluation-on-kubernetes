
# Whisper on UBI9-Minimal

## Overview

This guide continues from the Ubuntu experimentation for benchmarking Whisper models on UBI9-minimal containers. It focuses on security, size, and performance trade-offs compared to Ubuntu-based containers.

- Automation via batch testing (Speed, Quality, Accuracy, and best combination)

---

## Learning Objectives

- Run Whisper STT inside containers with different configurations
- Understand what UBI (Universal Base Image) is and why it matters in production.
- Compare Ubuntu vs. UBI9-minimal for AI workloads (security, support, compliance).
- Explore implications of building tools like ffmpeg from source vs. using OS packages.
- Build intuition for scaling from single-container tests to production deployments.

---

## Questions to Explore

| **Questions**| **Answers**|
|---------------------------------------------------|-|
| What is the difference between Ubuntu and UBI and is it worth switching? | |
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

## Procedure

Prerequisites:

1. SSH into your VM
2. Cloned this repo on the VM
3. Navigated to the repo root
4. Completed the [Ubuntu Setup](../../ubuntu/README.md)

---

## Review the Dockerfile

From this section we can understand:

1. The Dockerfile alignment with the Whisper GitHub documents.
1. How big are the decompressed images with embedded models?
1. What is the security posture (CVE report) of these model images (packages vs. model)?

Note: `ffmpeg` is built from source. Be aware of how security scanners handle custom binaries.

```sh
cat crawl/openai-whisper/ubi/Dockerfile
```

---

## Option A: Pull Prebuilt Images from Quay.io

Screen hints for next command:

- To detach, press: `Ctrl + A, then D`
- To list sessions: `screen -ls`
- To reattach: `screen -r pull-whisper`

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

## Option B: Build Locally with Embedded Models

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
repository,tag,size
quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubi9-minimal,9.74 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubi9-minimal,12.7 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubi9-minimal,9.56 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubi9-minimal,7.47 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubi9-minimal,6.79 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubi9-minimal,6.65 GB
```

---

### Run Batch Experiments (Parallel CPU/GPU) & Capture Metrics

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

---

## Observations

We are moving up a rung on the ladder on security, supportability and efficiency by switching to UBI from Ubuntu:

- Whisper runtime is running embedded in the container image. 
  - UBI is supported although Whisper is not.
- We have moved from a less secure image with *N* CVEs to a more secure image with *N* CVEs.
- We have moved from an unsupported base image.
- We have moved from an image that takes up more storage than less storage.

## ⏮ Navigation

| ← [Back: Ubuntu Setup](../../ubuntu/README.md) | [Next: Walk onto OpenShift →](../../../walk/README.md) |
|-----------------------------------------------|--------------------------------------------------------------------|
