# Benchmark Instructions for Whisper

Complete the steps from [README](./README.md)

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

### Terminal 1: Start Container Monitoring

```sh
# start the container monitoring
nohup python3 data/evaluation-scripts/podman_container_monitor.py &
```

### Terminal 1: Run Benchmark Experiments

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
# Set your parameters
FLAVOR=ubi9-minimal               # Options: ubuntu, ubi9, ubi9-minimal
INSTANCE=g6.12xlarge              # Set your instance type
THREADS=4                         # CPU threads per container
JOBS=12                           # Max parallel CPU jobs

# Launch the benchmark using screen
screen -S whisper-benchmark /outside/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor="$FLAVOR" \
  --instance="$INSTANCE" \
  --cpu-threads=$THREADS \
  --max-cpu-jobs=$JOBS 
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
tail -f /outside/metrics/experiment_metrics.csv

# watch the container logs
tail -f /outside/metrics/container_metrics.csv
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
ps aux | grep podman_container_monitor.py
kill <pid>
```

---

## Step 4: Collect Results from `container` and `experiment` metrics

Use `sftp` to retrieve the following files, review, append and move the results as needed:

- `/outside/metrics/container_metrics.csv`
- `/outside/metrics/experiment_metrics.csv`

```sh
# sftp from your machine to the host
sftp user@ec2-N-NNN-NNN-NNN.us-east-2.compute.amazonaws.com

# move to directory
cd whitepaper-stt-evaluation-on-kubernetes//outside/metrics/g6-12xlarge/

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

## Whisper Transcription Experiment Workflow

1. Provision one of four RHEL VMs with a GPU.
1. Pull six Ubuntu Whisper images from Quay.io.
1. Start container monitoring in the background.
1. For each of the six container images:
    - For each of the three audio samples:
        - Launch a new container using the image and transcribe the sample on the host CPU with:
            1. A fast command, saving the output with a unique filename.
            1. A complex command, saving the output with a unique filename.
        - Launch a new container using the image and transcribe the sample on the host GPU with: 
            1. A fast command, saving the output with a unique filename.
            1. A complex command, saving the output with a unique filename.
1. Stop container monitoring.
1. Remove the six Ubuntu Whisper images from the host.
1. Repeat steps 2–6 for the six UBI9 then UBI9-minimal Whisper images from Quay.io.
1. Repeat the entire process for all four RHEL VMs.

```sh
4 VMs × 18 containers × 3 samples × 2 commands × 2 modes
= 864 transcription files per VM
× 4 VMs
= 3,456 transcription files total
```