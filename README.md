# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

OpenAI Whisper, Faster-Whisper, NVIDIA NeMo ASR, and Wav2Vec are all speech-to-text (ASR) models, but they differ in terms of architecture, performance, hardware requirements, and use cases. Here’s how they compare:

||OpenAI Whisper|Faster-Whisper|NeMo|Wav2Vec 2.0|
|-|-|-|-|-|
|Developer|OpenAI|OpenAI (optimized by Faster-Whisper)|NVIDIA|Meta (Facebook)|
|Model Type|Transformer-based|Transformer-based|Conformer-based|Self-supervised Transformer|
|Pretraining Method|Supervised (large-scale labeled data)|Optimized Whisper|Supervised & Semi-Supervised|Self-supervised (unsupervised learning from audio)|
|Multilingual|Yes (99+ languages)|Yes (99+ languages)|Yes (for some models)|Mostly English (some multilingual versions)|
|Hardware|CPU/GPU|Optimized for GPU|Optimized for NVIDIA GPUs|CPU/GPU|
|Streaming|No|No|Yes|No|

Tracking the deployment and integration status of different speech-to-text (ASR) models (OpenAI Whisper, Faster-Whisper, NVIDIA NeMo ASR, and Wav2Vec 2.0) across various environments, model servers, and performance metrics.

||OpenAI Whisper|Faster-Whisper|NeMo|Wav2Vec 2.0|
|-|-|-|-|-|
|Ubuntu Dockerfile|X|TODO|TODO|TODO|TODO|
|UBI Dockerfile|X|TODO|TODO|TODO|
|ModelKit|TODO|TODO|TODO|TODO|
|RHEL OS|X|TODO|TODO|TODO|
|OCP|X|TODO|TODO|TODO|
|Embedded Server|X|TODO|TODO|TODO|
|Built-in Server|X|TODO|TODO|TODO|
|Decoupled Server|TODO|TODO|TODO|TODO|
|NVIDIA Triton|TODO|TODO|TODO|TODO|
|vLLM|TODO|TODO|TODO|TODO|
|Ray Serve|TODO|TODO|TODO|TODO|
|Batch|TODO|TODO|TODO|TODO|
|Streaming|TODO|TODO|TODO|TODO|
|Word Error Rate (WER)|TODO|TODO|TODO|TODO|
|Match Error Rate (MER)|TODO|TODO|TODO|TODO|
|Word Information Lost (WIL)|TODO|TODO|TODO|TODO|
|Word Information Preserved (WIP)|TODO|TODO|TODO|TODO|
|Character Error Rate (CER)|TODO|TODO|TODO|TODO|
|Summary|TODO|TODO|TODO|TODO|

## Performance Metrics Evaluated:

Each inference test outputs a transcription file using the following pattern:  `model-size-baseImage-audioFile-cpuOrGpu-qty-date.txt`

**Cost:** How much does it cost to infer?

**Resources:** How many resources does it consume to infer?

1. Container size
1. GPU
1. CPU

**Speed:** How fast is the model at transcribing using the `time` command which prints

1. `real` - wall-clock time (actual elapsed time) from when the command started to when it finished.
1. `user` - total amount of CPU time spent in user mode, meaning the time the CPU spent executing the process's code (excluding kernel operations).
1. `sys` - total amount of CPU time spent in kernel mode, meaning time spent executing system calls on behalf of the process (e.g., file I/O, memory allocation). If you are using a GPU, it's likely that much of the work gets offloaded resulting in a lower number.

**Accuracy:** How accurate is the model? JiWER is a simple and fast python package to evaluate an automatic speech recognition system. It supports the following measures:

1. `Word Error Rate (WER)` – Measures the percentage of words that were incorrectly predicted compared to the reference text. It accounts for substitutions, deletions, and insertions.
1. `Match Error Rate (MER)` – Represents the fraction of words that need to be transformed (inserted, deleted, or substituted) to match the reference text. Unlike WER, it considers the total number of words in both the reference and hypothesis.
1. `Word Information Lost (WIL)` – Estimates how much word-level information is lost due to errors. It penalizes deletions and substitutions while being less sensitive to insertions.
1. `Word Information Preserved (WIP)` – The inverse of WIL, this measures how much word-level information is correctly preserved in the hypothesis relative to the reference.
1. `Character Error Rate (CER)` – Similar to WER but at the character level, CER measures the percentage of incorrectly predicted characters compared to the reference text, making it useful for evaluating text with short words or heavy misspellings.

## Observations

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
