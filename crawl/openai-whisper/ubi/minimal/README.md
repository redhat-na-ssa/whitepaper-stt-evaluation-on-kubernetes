# Whisper on Ubuntu

## Section Expectations

- Understand what UBI (Universal Base Image) is and why it matters for production.
- Learn key differences between Ubuntu and UBI9-minimal for AI workloads (e.g., security, support, compliance).
- Build or pull container images embedding Whisper models.
- Compare image sizes, performance, and cold/warm start times across models and platforms.
- Evaluate how moving to UBI affects:
  - Startup time
  - Inference speed
  - Transcription accuracy
  - System resource usage (CPU, GPU, memory)
- Measure operational metrics like power draw, GPU temperatures, and VRAM usage.
- Explore security implications (e.g., building FFmpeg from source vs using distro packages).
- See how batch testing enables large-scale benchmarking across multiple configurations.
- Build intuition on scaling from simple experiments toward production readiness (containers, clusters, registries).

## What is [UBI9-minimal (Universal Base Image)](https://catalog.redhat.com/software/base-images/ubi9-minimal)?

- Minimal RHEL Subset for Containers: UBI9-minimal is a slimmed-down Red Hat Enterprise Linux 9 base, stripped to essentials for lightweight, secure container builds.
- Optimized for Small Size: Only the critical libraries and utilities needed to run applications — no extra tools, shells, or services.
- Freely Redistributable: You can use, share, and deploy UBI9-minimal images without a RHEL subscription, following the Red Hat UBI license.
- DNF Package Access: UBI9-minimal still supports installing additional RPMs from Red Hat’s trusted ubi-9-baseos and ubi-9-appstream repositories when needed.
- Security and Compliance: Full access to Red Hat security updates, signed RPMs, and vulnerability scanning integrations (e.g., Clair, ACS).
- Ideal for AI and Microservices: Small surface area → faster cold starts, smaller image pull sizes, and reduced attack surface for inference workloads like Whisper.
- Offline/Disconnected Support: RPMs can be added even in air-gapped environments by allowlisting access to https://cdn-ubi.redhat.com.
- No FFMPEG by Default: Must manually build/install specific tools (like ffmpeg) into the image if needed for AI/multimedia workloads.

## Questions to Ask Before Running Whisper Benchmarks

| **Question Before the Exercise**| **Expected Answer / Learning After Completion**|
|-|-|
| Differences between Ubuntu and UBI9-minimal?                           |  |
| Decompressed size?                                                     |  |
| Speed?                                                                 |  |
| Accuracy?                                                              |  |
| Security?                                                              |  |
| Power?                                                                 |  |
| Temperature?                                                           |  |
| What is the impact of model size (e.g., tiny → turbo)?                 |  |
| How much faster is GPU inference compared to CPU?                      |  |
| How do cold starts compare to warm starts?                             |  |
| Do advanced arguments (hyperparameters) improve accuracy?              |  |
| How accurate is Whisper across short vs. long audio?                   |  |
| Do different base images (Ubuntu vs UBI) affect performance?           |  |
| What was the fastest transcription?                                    |  |
| What was the slowest transcription?                                    |  |
| What metrics are most useful to compare experiments?                   |  |
| What’s a reasonable throughput goal for deployment?                    |  |
| Should experiments run in parallel or sequentially?                    |  |
| Are containers reusable across experiments?                            |  |

Assuming

1. ssh into your VM
1. you git cloned the repo on your VM
1. you cd into the root folder
1. you completed the [Ubuntu](../../ubuntu/README.md) steps

## Review the Dockerfile

Notice: ffmpeg is built from source - how do security scanners handle it?

```sh
cat crawl/openai-whisper/ubi/minimal/Dockerfile 
```

## (Option A) Pull the Dockerfiles from Quay.io

```sh
# login to Quay.io
podman login quay.io

export FLAVOR=ubi9-minimal # or ubuntu or ubi9-minimal

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
  tag="whisper:${model}-ubi9-minimal"
  echo "🔧 Building image: $tag"
  podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi9/minimal/.
done
```

NOTE: models will be saved in `/data/.cache/whisper/` in each container image

## Capture the image sizes

This captures the image sizes for comparison laters and writes to `data/metrics/image_sizes.csv`.

```sh
# image sizes
mkdir -p data/metrics
echo "repository,tag,size" > data/metrics/image_sizes.csv
podman images --format '{{.Repository}},{{.Tag}},{{.Size}}' | grep 'speech-to-text/whisper' >> data/metrics/image_sizes.csv
```

```sh
repository,tag,size
quay.io/redhat_na_ssa/speech-to-text/whisper,turbo-ubi9-minimal,9.74 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,large-ubi9-minimal,12.7 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,medium.en-ubi9-minimal,9.56 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,small.en-ubi9-minimal,7.47 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,base.en-ubi9-minimal,6.79 GB
quay.io/redhat_na_ssa/speech-to-text/whisper,tiny.en-ubi9-minimal,6.65 GB
```

## Batch jobs running experiments on CPU and GPU in parallel

Instead of manually repeating these steps on gpu transcribing harvard audio data sample, lets create job of experiments and run them in parallel.

The output writes the data to `data/metrics/aiml_functional_metrics.csv` for easier review

```sh
# You can copy this entire block and paste in the terminal

# Set your parameters
FLAVOR=ubi9-minimal         # Options: ubuntu, ubi9, ubi9-minimal
INSTANCE=g6.12xlarge  # Set your instance type
#MODELS=large,turbo
#INPUT=harvard.wav    # Enter if you want process a single input, else All Audio files processed

# Run the script
screen -S jobs ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor="$FLAVOR" \
  --instance="$INSTANCE" # \
  #--model="$MODELS"
```

| **Question Before the Exercise**| **Expected Answer / Learning After Completion** |
|-|-|
| Differences between Ubuntu and UBI9-minimal?                           |  |
| Decompressed size?                                                     |  |
| Speed?                                                                 |  |
| Accuracy?                                                              |  |
| Security?                                                              |  |
| Power?                                                                 |  |
| Temperature?                                                           |  |
| What is the impact of model size (e.g., tiny → turbo)?                 | Larger models offer better transcription accuracy but increase inference time and image size.                             |
| How much faster is GPU inference compared to CPU?                      | GPU inference is 10–15x faster on warm starts and is necessary for large models or real-time workloads.                   |
| How do cold starts compare to warm starts?                             | Cold starts can take 3–5x longer due to model loading and tokenization caching overhead.                                  |
| Do advanced arguments (hyperparameters) improve accuracy?              | Hyperparameters slightly improve accuracy (WER, WIL) but also increase latency.                                            |
| How accurate is Whisper across short vs. long audio?                   | Short samples are consistently accurate; longer files show more variation across model sizes and config modes.            |
| Do different base images (Ubuntu vs UBI) affect performance?           | Not significantly in speed or accuracy, but image sizes and cold start performance may vary.                              |
| What metrics are most useful to compare experiments?                   | tokens/sec, real_time_factor (RTF), container_runtime_sec, WER, MER, WIL, WIP, CER.                                        |
| What’s a reasonable throughput goal for deployment?                    | Aim for >30 tokens/sec on GPU warm inference for real-time production performance.                                        |
| Should experiments run in parallel or sequentially?                    | Parallel jobs are efficient, but overloading CPU cores or GPU memory should be avoided.                                   |
| Are containers reusable across experiments?                            | Yes, especially useful for warm start reuse and reproducible performance analysis.                                        |

|[Previous <- Ubuntu](../../ubuntu/README.md)|[Next -> UBI9 Minimal with Whisper](../ubi/minimal/README.md)|
|-|-|