# Summary of Script Steps

There are three scripts that capture the following metrics.

1. system_non_functional_monitoring.py
1. whisper-functional-batch-metrics.sh
1. compare_transcripts.py

## whisper-functional-batch-metrics.sh script

How many containers are launched at once on a `g6.12xlarge`?

### CPU Jobs:

- Modes: `cpu_fast` and `cpu_complex`
- For each sample + image: One CPU container per mode
- Parallelism: These are run sequentially per image

So, for 3 audio samples × 2 CPU modes = 6 CPU jobs, run one after another per image.

### GPU Jobs:

- Modes: gpu_fast and gpu_complex
- For each GPU mode: A container is run per GPU, meaning up to 4 containers in parallel on L4s.

So, 3 audio samples × 2 GPU modes × 4 GPUs = 24 GPU jobs, but they are launched: 4 at a time (one per GPU) sequentially per mode and per sample

For each GPU mode and sample, it launches 4 containers in parallel, then moves to the next.

## What's the concurrency?

On a `g6.12xlarge`, this script launches up to 4 GPU containers concurrently and CPU jobs one at a time, for one model size at a time.

- Per model image (e.g. turbo-ubuntu):
- 6 CPU jobs (sequential)
- 24 GPU jobs (in sets of 4 running concurrently)
