# OpenAI Whisper Benchmark Guide

This guide provides instructions for evaluating OpenAI Whisper models using containerized environments. Each directory contains setup details for a specific base image:

- [Ubuntu with Whisper](ubuntu/README.md)
- [UBI9 with Whisper](ubi/platform/README.md)
- [UBI9-minimal with Whisper](ubi/minimal/README.md)

---

## Step 1: Prepare Your Environment

### Provision a RHEL VM with GPUs
Follow the [provisioning guide](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md) to set up your RHEL VM.

### Clone the Repository
```sh
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git
```

### Pull Whisper Images
```sh
podman login quay.io

FLAVOR=ubuntu
screen -S download-images bash -c '
  for tag in tiny.en-$FLAVOR base.en-$FLAVOR small.en-$FLAVOR medium.en-$FLAVOR large-$FLAVOR turbo-$FLAVOR; do
    echo "📦 Pulling quay.io/redhat_na_ssa/speech-to-text/whisper:$tag"
    podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag
  done'
```

---

## Step 2: Monitor and Benchmark

### Terminal 1: GPU and CPU Monitoring
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
ls -lhtr data/metrics/whisper-*.txt
```
Monitor CSV updates:
```sh
tail -f data/metrics/experiment_metrics.csv
```

### Terminal 2: Start Container Monitoring
```sh
nohup python3 data/evaluation-scripts/podman_container_monitor.py &
```

### Terminal 3: Run Benchmark Experiments
Run the appropriate benchmark based on your instance type:
```sh
# g6.12xlarge (48 vCPUs)
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor=ubi9 --instance=g6.12xlarge --cpu-threads=4 --max-cpu-jobs=12

# p5.48xlarge (192 vCPUs)
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor=ubuntu --instance=p5.48xlarge --cpu-threads=4 --max-cpu-jobs=48

# g5.48xlarge (192 vCPUs)
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor=ubuntu --instance=g5.48xlarge --cpu-threads=4 --max-cpu-jobs=48

# g5.12xlarge (48 vCPUs)
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor=ubi9 --instance=g5.12xlarge --cpu-threads=4 --max-cpu-jobs=12

# g4dn.12xlarge (48 vCPUs)
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh \
  --flavor=ubi9 --instance=g4dn.12xlarge --cpu-threads=3 --max-cpu-jobs=12
```
Detach with `Ctrl+A D`, reattach with `screen -r whisper-benchmark`.

To stop a frozen job:
```sh
podman ps -a -q | xargs podman rm -f
```

---

## Step 3: Stop Monitoring

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

## Step 4: Collect Results
Use `sftp` to retrieve the following files:
- `data/metrics/container_metrics.csv`
- `data/metrics/experiment_metrics.csv`

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

## Resources

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
- [Dataset](https://www.openslr.org/12)