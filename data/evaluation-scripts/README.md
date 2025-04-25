# Scripts

`whisper-functional-batch-metrics.sh`
- Runs batch Whisper transcription experiments across multiple models, modes (CPU/GPU), and audio samples, collecting functional performance metrics into a CSV.

`compare_transcripts.py`
- Compares Whisper transcription outputs against ground-truth text files and calculates accuracy metrics like WER, MER, WIL, WIP, and CER.

`system_non_functional_monitoring.py`
- Continuously monitors Podman Whisper containers, logging system resource metrics (CPU, memory, GPU usage) and timing details to a CSV during each transcription job.

`cleanup-benchmark-results.sh`
- Cleans up old benchmark results, output files, and metrics CSVs to prepare the workspace for a fresh round of Whisper experiments.