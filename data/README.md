# Data Folder

Directory folders:

1. input-samples - provided audio files for transcription
1. evaluations - scripts to evaluate model (whisper currently)
1. ground-truth - official transcriptions to evaluate accuracy
1. metrics - .csv files from the evaluation scripts for performance analysis

## AI Model metrics

- script/output: system_non_functional_monitoring.py > system_non_functional_metrics.csv
- columns: date,timestamp,container_name,token_count,tokens_per_second,audio_duration,real_time_factor,container_runtime_sec,wer,mer,wil,wip,cer,threads,start_type

Metric | Definition | Target / Ideal Value | Notes
|-|-|-|-|
token_count | Number of tokens (words) generated in transcription | Should match across modes for same audio | Large deviations suggest inconsistent output
tokens_per_second | Transcription speed (higher = faster) | >10 TPS (GPU), >2 TPS (CPU) | Compare cold vs warm, CPU vs GPU
audio_duration | Length of the audio input (in seconds) | Informational | Used to calculate RTF
real_time_factor (RTF) | Ratio of inference time to audio duration | <1.0 is real-time; <0.5 ideal for production | Key for latency-sensitive apps
container_runtime_sec | Total time the container was alive | Lower is better | Includes cold start, container overhead
wer (Word Error Rate) | % of words with errors (substituted, inserted, deleted) | <5% = good, <1% = excellent | Main metric for transcription accuracy
mer (Match Error Rate) | Fraction of mismatches including insertions and deletions | Should correlate with WER | Can sometimes be more forgiving
wil (Word Info Lost) | Semantic loss (penalizes under-prediction) | <0.3 preferred | High WIL = info lost
wip (Word Info Preserved) | Complement to WIL (1 - wil) | >0.7 preferred | Shows how much meaning was preserved
cer (Char Error Rate) | Fine-grained error metric (char-level) | <2% for clean audio, higher acceptable for noisy audio | 
threads | Number of CPU threads used in container | Match to your configuration (e.g., 4–12) | Useful for correlation
start_type | cold = fresh container start; warm = reused/cached | Compare to isolate container overhead | Warm starts should always be faster |

Examples:

- Latency-sensitive use case (e.g., real-time voice agents): prioritize RTF < 1.0 and container_runtime_sec < 10s

- Batch transcription: prioritize tokens_per_second and throughput scaling across jobs

- Accuracy testing: focus on low WER, CER, and WIL; ensure token_count is stable

## Host metrics

- script/output: whisper-functional-batch-metrics.sh > aiml_functional_metrics.csv
- columns: date,timestamp,container name,processor/gpu name,core/gpu count,max usage (%),max gpu temperature (C),max pwr:usage/cap (%),max vram usage (%),startup time (s),task time (s),shutdown time (s),total time (s),cpu usage (%),memory usage (MB)

Metric | Definition | Target / Interpretation
|-|-|-|
processor/gpu name | Name of the CPU or GPU used | Descriptive — e.g., "AMD EPYC", "NVIDIA L4", "Intel Xeon"
core/gpu count | Physical CPU cores or total number of GPUs | Matches system configuration. Useful for planning concurrency.
max usage (%) | Highest observed CPU or GPU utilization during container execution | CPU: Ideally ~90–100% on inference workloadGPU: >50% for meaningful load
max gpu temperature (C) | Peak GPU temp (Celsius) during inference | <85°C recommended. Over 90°C can reduce lifespan or performance
max pwr:usage/cap (%) | Percentage of maximum GPU power draw | High values (70–100%) show full power usage; low (<30%) might suggest underutilization
max vram usage (%) | Highest % of GPU memory used | <90% safe, >95% risks OOM errors in larger models
startup time (s) | Time to start container and load model (cold start) | Should be <60s for large models, <10s for smaller ones.
task time (s) | Time spent transcribing audio (actual inference) | Should scale with audio length and model size
shutdown time (s) | Time between transcription end and container shutdown | Should be low (<2s). Long delays might mean cleanup issues
total time (s) | Entire container lifespan (startup + task + shutdown) | Useful for cold vs warm comparison or orchestration latency
cpu usage (%) | Real-time CPU usage averaged or peak (via psutil) | >80% indicates full CPU utilization; <20% suggests underuse or IO waiting
memory usage (MB) | System memory consumed by the containerized job | Monitor to avoid memory pressure (swap, OOM kill). Compare vs total RAM

Examples:

Is your hardware fully utilized?

- High CPU/GPU usage, power draw, and VRAM suggest efficient utilization.

- Low values may mean suboptimal thread use, bottlenecks elsewhere (e.g., I/O), or model size mismatch.

Are you constrained by system resources?

- High memory usage might point to the need for tuning batch sizes, model sizes, or container limits.

- Slow startup time may highlight image loading, container init delay, or model deserialization bottlenecks.

Can you sustain multiple concurrent containers?

- Compare CPU usage and task time across different MAX_CPU_JOBS to find optimal job saturation level.

Is your environment healthy?

- Avoid excessive GPU temps or 100% VRAM saturation. Consider NVIDIA MIG or time-slicing if needed.