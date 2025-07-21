# Scripts

## Get data from whisper experiments

`whisper-functional-batch-metrics.sh`

- Runs batch Whisper transcription experiments across multiple models, modes (CPU/GPU), start types (COLD/WARM) and audio samples, collecting functional performance metrics into a CSV.

This script launches multiple Whisper container runs in parallel across CPU and GPU, using two key controls:

- `--cpu-threads` → how many CPU threads each CPU container is allowed to use
- `--max-cpu-jobs` → how many parallel CPU containers to launch (total parallelism)

When you run:

```bash
export INSTANCE=g4dn-12xlarge
export FLAVOR=ubi9-minimal
export THREADS=3
export JOBS=12

screen -S jobs bash -c "time ./data/evaluation-scripts/whisper-functional-batch-metrics.sh \
  --flavor=$FLAVOR \
  --instance=$INSTANCE \
  --cpu-threads=$THREADS \
  --max-cpu-jobs=$JOBS \
  --model='tiny.en,base.en,small.en,medium.en,large,turbo'"
```

You are telling the script:

- `FLAVOR` → which container tag (e.g., ubi9-minimal)
- `INSTANCE` → which system label (e.g., g4dn-12xlarge)
- `THREADS` → how many CPU threads to assign per CPU run
- `JOBS` → how many CPU runs to launch at once
- `MODEL LIST` → which Whisper models to run tests for

The script handles two layers of parallelism:

1. GPU parallel runs
    - The script automatically detects if GPU(s) are present (nvidia-smi or similar).
    - For each selected model (like tiny.en, base.en, etc.), it launches a container on the GPU.
    - Typically, one container per GPU is launched, letting the GPU run at max utilization.
    - This gives you concurrent GPU jobs, limited by the number of available GPUs.  
1. CPU parallel runs
    1. The script calculates how many simultaneous CPU containers can be launched.
    1. You set:
        1. `--cpu-threads=$THREADS` → how many CPU threads per container.
        1. `--max-cpu-jobs=$JOBS` → how many parallel containers to launch at once.
    1. It runs up to $JOBS parallel CPU containers, each pinned or limited to $THREADS threads, so you don’t oversubscribe CPU resources.
    1. This creates a controlled batch of CPU jobs, spreading across your CPU cores.

### Example on g4dn.12xlarge

For:
- `INSTANCE=g4dn-12xlarge` → 4 GPUs, 48 vCPUs
- `--cpu-threads=3` → each CPU container uses 3 threads
- `--max-cpu-jobs=12` → runs 12 parallel CPU containers (using ~36 vCPUs total)

So, at full tilt:

- GPUs → up to 4 parallel GPU jobs (one per GPU)
- CPUs → up to 12 parallel CPU jobs, using 36/48 vCPUs

This parallelized batch design lets you:

- Stress test both CPU and GPU simultaneously.
- Saturating the system by carefully setting thread and job limits.
- Automatically iterate across multiple Whisper models.
- Collect metrics from all runs to compare performance, accuracy, and system load.

### Parallel flow

Around line 200 starting with `JOBS_RUNNING=0`:

- For each model image (tiny.en, base.en, etc.),
- each audio sample,
- each mode (cpu_basic, gpu_basic, etc.),
- and each start type (cold, warm),
- it launches a background job with `run_job ... &`

Around line 204 Configures the container run depending on:

- CPU: sets --cpus, OPENBLAS_NUM_THREADS, etc.
- GPU: assigns specific GPU ID (--device nvidia.com/gpu=$GPU_ID)
- Around line 124 Even though the script controls parallelism using MAX_CPU_JOBS, both CPU and GPU jobs are counted together, there’s no separate GPU cap, but the GPU assignments cycle over available GPUs using:
    - `GPU_ID=${GPU_IDS[$GPU_INDEX]}`
    - `GPU_INDEX=$(((GPU_INDEX + 1) % GPU_COUNT))`

Whisper's PyTorch CPU backend often uses OpenBLAS (OPENBLAS_NUM_THREADS) for:

- Linear layers
- Matrix multiplies
- Tokenization math
If you don’t set this:
- Each container may use all cores, regardless of --cpus set via Podman.
- You get thread oversubscription, leading to degraded performance due to context switching.

Job throttling is handled around line 205 `((JOBS_RUNNING++))`:

- Tracks how many background jobs are running.
- If the count hits $MAX_CPU_JOBS, it waits for any one job (wait -n) to finish before launching more.
- This controls the maximum concurrency — meaning no more than MAX_CPU_JOBS will run at once, whether CPU or GPU.

## Compare ground truth against hypothesis transcripts

`compare_transcripts.py`

- Compares Whisper transcription outputs against ground-truth text files and calculates accuracy metrics like WER, MER, WIL, WIP, and CER.

## Monitor host data usage

`system_non_functional_monitoring.py`

- Continuously monitors Podman Whisper containers, logging system resource metrics (CPU, memory, GPU usage) and timing details to a CSV during each transcription job.

## Cleanup data for next run

`cleanup-benchmark-results.sh`

- Cleans up old benchmark results, output files, and metrics CSVs to prepare the workspace for a fresh round of Whisper experiments.