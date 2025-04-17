# OpenAI Whisper

This README provides instructions for experimenting with Whisper models in containerized environments. Follow the steps in the respective directories for detailed setup:

- [Ubuntu with Whisper](ubuntu/README.md)
- [UBI9 with Whisper](ubi/platform/README.md)
- [UBI9-minimal with Whisper](ubi/minimal/README.md)

## Whisper Transcription Experiment Benchmark

Follow these steps to benchmark Whisper transcription. It is recommended to open 3 terminal sessions on the same VM:

1. **Monitor NVIDIA GPU usage** (`watch nvidia-smi`)
2. **Run the container monitoring script** (`podman_container_monitor.py`)
3. **Monitor the benchmark output** (`run-whisper-benchmark.sh`)

### Provision RHEL VM with GPUs

Follow the [instructions here](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md) to provision the RHEL VM with GPUs.

### Pull Ubuntu Whisper Images

Log in to Quay.io and pull the necessary Whisper images:

```sh
# Login to quay.io
podman login quay.io

# Pull Ubuntu images
screen -S download-images bash -c 'for tag in tiny.en-ubuntu base.en-ubuntu small.en-ubuntu medium.en-ubuntu large-ubuntu turbo-ubuntu; do podman pull quay.io/redhat_na_ssa/speech-to-text/whisper:$tag; done'
```

### Clone the Repository

```sh
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git
```

### Start Monitoring GPU and CPU Usage

Run the following command in Terminal 1 to monitor GPU and CPU usage:

- The complex config (beam size, patience, etc.) takes significantly longer, especially on CPU — this can be 5x–10x slower than fast mode.

```sh
watch -n 1 -t '
  echo "== NVIDIA GPU Usage ==";
  nvidia-smi;
  echo "";
  echo "== CPU Core Usage (mpstat -P ALL 1 1) ==";
  mpstat -P ALL 1 1 | awk "NR==3 || NR>4"
'
# Use this to keep an eye on file output progress:
ls -lhtr data/metrics/whisper-*.txt

# And track live updates to the CSV: If you see files growing or new CSV lines appear — it’s working!
tail -f data/metrics/experiment_metrics.csv

# a thread-level view of CPU usage within each Whisper containerized process
watch "ps -T -p \$(pgrep -d',' -f whisper) -o pid,tid,pcpu,pmem,comm | sort -k3 -nr | head -20"

```

You can adjust the frequency by changing 1 1 to 0.5 1 for faster snapshots.

### Start Container Monitoring

In Terminal 2, run the podman_container_monitor script in the background:

```sh
nohup python3 data/evaluation-scripts/podman_container_monitor.py &
```

### Run Benchmark Experiments

In Terminal 3, loop through all experiments by running the benchmark script in parallel:

```sh
screen -S whisper-benchmark ./data/evaluation-scripts/run-whisper-benchmark.sh --flavor=ubuntu --instance=g6.12xlarge --cpu-threads=4

# Detach the screen session with Ctrl+A D
# Reattach with: screen -r whisper-benchmark
# To stop the job if it freezes:
podman ps -a -q | xargs podman rm -f
```

### Stop Monitoring

To stop the monitoring processes:

- Terminal 1: Press Ctrl+C to stop GPU monitoring.
- Terminal 2: Press Ctrl+C to stop the container monitoring script. Then, find and kill the process:

```sh
ps aux | grep podman_container_monitor.py
kill <pid>
```

### Cleanup Disk Space

Run the cleanup script to free up disk space:

```sh
./data/evaluation-scripts/cleanup-benchmark-results.sh
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