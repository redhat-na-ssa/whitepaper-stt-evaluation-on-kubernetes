# Benchmark Instructions for Whisper

Complete the steps from [README](./README.md)

| **Question**                                                                 | **Insight or Decision You Can Make**                                                                 |
|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| How much faster is a **warm start** compared to a **cold start**?         | Understand startup overhead. Helps optimize deployment patterns (e.g., always-on vs. just-in-time).   |
| Are GPUs consistently faster than CPUs across all samples and modes?      | Determine cost/performance tradeoffs. Helps justify GPU provisioning or autoscaling strategies.       |
| Do **hyperparameters** improve accuracy (WER, MER, etc.)?                 | Evaluate if added complexity gives better results. Useful for tuning production pipelines.            |
| How does **tokens per second** vary between CPU and GPU?                  | Quantify throughput gains. Helps size workloads or batch strategies.                                  |
| Does **model accuracy (WER, MER, WIL)** stay consistent across inputs?    | Identify model sensitivity to input types. May highlight weaknesses or dataset alignment issues.       |
| Are **cold start GPU times** worth the latency compared to CPU warm start? | Reveal if GPUs only benefit long-running or warmed models. Useful for real-time or burst workloads.    |
| Which models/configs have the lowest **CER**?                             | Helps pick setups for domains needing fine-grained accuracy (e.g., legal or medical transcription).    |
| Are **tokens_per_second** scaling linearly with input length?            | Detect performance bottlenecks for longer inputs. Nonlinear scaling may imply inefficiencies.          |
| Is **accuracy stable between cold and warm starts**?                     | Ensures caching or warm-up doesn’t affect output quality. Detects potential reproducibility issues.    |
| What’s the **best tradeoff** between speed and accuracy?                 | Allows selecting config based on latency, throughput, or quality — critical for user-facing apps.      |

## Pull Whisper Images

```sh
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

---

## Step 2: Monitor and Benchmark

### Terminal 1: Start System Monitoring

```sh
# start the container monitoring
nohup python3 data/evaluation-scripts/system_non_functional_monitoring.py > data/metrics/monitoring.log 2>&1 &
```

### Terminal 2: Run Benchmark Experiments

Run the appropriate benchmark based on your instance type:

|Instance Type|	Threads per Job (--cpu-threads)|	Max Concurrent CPU Jobs (--max-cpu-jobs)|	Total vCPUs|
|-|-|-|-|
|g6.12xlarge|	4|	12|	48|
|p5.48xlarge|	4|	48|	192|
|g5.48xlarge|	4|	48|	192|
|g5.12xlarge|	4|	12|	48|
|g4dn.12xlarge|	3|	12|	48|

💡 --cpu-threads controls threads inside the container.

💡 --max-cpu-jobs limits parallel jobs on the host.

```sh
# Individual test
THREADS=4  # or however many CPU threads you want to assign

podman run --rm \
  --userns=keep-id \
  --user "$(id -u):$(id -g)" \
  -e OPENBLAS_NUM_THREADS=$THREADS \
  -e OMP_NUM_THREADS=$THREADS \
  -e MKL_NUM_THREADS=$THREADS \
  -v "$(pwd)/data:/outside:z" \
  quay.io/redhat_na_ssa/speech-to-text/whisper:tiny.en-ubi9-minimal \
  whisper /outside/input-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
    --model_dir /outside/tmp \
    --output_dir /outside/metrics/ \
    --output_format txt \
    --language en \
    --task transcribe \
    --threads $THREADS \
    --fp16 False


# Set your parameters
IMAGE_FLAVOR=ubi9-minimal           # Container image flavor (e.g., ubuntu, ubi9)
INSTANCE=g6.12xlarge                # Name of the machine or VM for labeling
THREADS=4                           # Number of CPU threads per container job
MAX_JOBS=12                         # Maximum number of concurrent jobs
MODEL=turbo                         # Comma-separated list of models to include
INPUT_SAMPLE=jfk-audio-inaugural-address-20-january-1961.mp3  # Audio sample filename (with extension)


# Launch the bulk benchmark using screen
screen -S whisper-benchmark ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor="$IMAGE_FLAVOR" \
  --instance="$INSTANCE" \
  --cpu-threads="$THREADS" \
  --max-cpu-jobs="$MAX_JOBS" \
  --model="$MODEL" \
  --input-sample="$INPUT_SAMPLE"

  # Optional flag if you only want to test a model size or sizes comma separated no spaces
  # --model=tiny.en
```

Detach with `Ctrl+A D`, reattach with `screen -r whisper-benchmark`.

### Terminal 3: GPU and CPU Monitoring

```sh
watch -n 2 -t '
  echo "== NVIDIA GPU Usage =="
  nvidia-smi
  echo "\n== Top Whisper Threads by CPU Usage =="
  ps -T -p $(pgrep -d"," -f whisper) -o pid,tid,pcpu,pmem,comm | sort -k3 -nr | head -20
'
```

Monitor file output progress:

```sh
ls -lhtr /outside/metrics/whisper-*.txt
```

Monitor CSV updates:

```sh
# watch the experiment logs
tail -f /data/metrics/aiml_functional_metrics.csv

# watch the container logs
tail -f data/metrics/system_non_functional_metrics.csv
```

---

## Step 3: Stop Monitoring

To stop a frozen job (if failure/freezing occurs):

```sh
podman ps -a -q | xargs podman rm -f
```

### Terminal 1

```sh
# Press Ctrl+C to stop GPU/CPU monitoring
```

### Terminal 2

```sh
# Press Ctrl+C, then clean up:
ps aux | grep system_non_functional_monitoring.py
kill <pid>
```

---

## Step 4: Collect Results from `container` and `experiment` metrics

Use `sftp` to retrieve the following files, review, append and move the results as needed:

- `/data/metrics/system_non_functional_metrics.csv`
- `/data/metrics/aiml_functional_metrics.csv`

```sh
# sftp from your machine to the host
sftp user@ec2-N-NNN-NNN-NNN.us-east-2.compute.amazonaws.com

# move to directory
cd /home/ec2-user/whitepaper-stt-evaluation-on-kubernetes/data/metrics

# get CSV files
get *.csv

# one-liner to merge without duplicate headers or rows
FILE="container"  # or "experiment"
INSTANCE="g6.12xlarge"
(head -n 1 /outside/metrics/${FILE}_metrics.csv && tail -n +2 -q /outside/metrics/${FILE}_metrics.csv /outside/metrics/{$INSTANCE}/${FILE}_metrics.csv | sort -u) > /outside/metrics/merged_${FILE}_metrics.csv

# replace the original file
mv /outside/metrics/merged_${FILE}_metrics.csv /outside/metrics/g6-12xlarge/${FILE}_metrics.csv
---

## Step 5: Cleanup

```sh
# Remove benchmark results
./data/evaluation-scripts/cleanup-benchmark-results.sh

# Remove all local images
podman rmi -a

# Ensure proper permissions if using UBI images
chmod 775 data/metrics
```

## 📊 Questions and Insights from Benchmark Data

| **Question**                                                                 | **Answer / Insight from Data**                                                                                                                                      |
|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| How much faster is a **warm start** compared to a **cold start**?         | Warm starts cut container runtime by over 50% in most cases (e.g., CPU basic from 59.7s to 20.0s).                                                                 |
| Are GPUs consistently faster than CPUs across all samples and modes?      | Yes. GPUs are ~5–10x faster than CPU cold starts and ~2–4x faster than CPU warm starts, with consistent performance at scale.                                     |
| Do **hyperparameters** improve accuracy (WER, MER, etc.)?                 | Slightly — minor but consistent improvements (e.g., WER drops from 0.2600 to 0.2457 on JFK sample with GPU hyperparameters).                                      |
| How does **tokens per second (TPS)** vary between CPU and GPU?           | TPS on GPU (30–33) is an order of magnitude higher than on CPU (2–3).                                                                                              |
| Are **TPS** values stable across warm vs cold starts?                    | Yes. TPS improves slightly with warm start due to reduced overhead (e.g., GPU basic 3.83 → 4.71).                                                                  |
| Does **model accuracy** stay consistent across inputs and configs?        | Yes. Accuracy metrics remain stable across cold/warm starts and CPU/GPU for the same input (e.g., Harvard sample has 0.0000 WER in all tests).                   |
| Are **cold start GPU times** better than CPU warm starts?                | Yes. Even cold-start GPU runs (e.g., ~11s) outperform CPU warm starts (~20s) for small audio files, with wider margins on longer audio.                          |
| Which configs give lowest **CER** (Character Error Rate)?                | GPU hyperparameter runs consistently yield lower CER on complex samples (e.g., JFK CER down to 0.0811).                                                           |
| Is **accuracy stable between cold and warm starts**?                     | Yes. WER/WIL/WIP metrics remain virtually identical, validating container cold/warm consistency.                                                                  |
| What’s the **best tradeoff** between speed and accuracy?                 | GPU + hyperparameter + warm start: fastest execution and best accuracy across all samples. Avoid large models on CPU without warm-up.                            |
