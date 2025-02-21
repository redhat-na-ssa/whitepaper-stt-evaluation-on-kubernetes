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
|STT Benchmark WER|TODO|TODO|TODO|TODO|
|STT Benchmark Core-Hour|TODO|TODO|TODO|TODO|
|Model Size|tiny|TODO|TODO|TODO|
|Summary|TODO|TODO|TODO|TODO|

## Performance Metrics Evaluated:

1. [STT Benchmark from Picovoice](https://github.com/Picovoice/speech-to-text-benchmark?tab=readme-ov-file)
1. Execution Time: Measure total inference time per transcription.
1. Accuracy (Word Error Rate - WER): Evaluate transcription correctness.
1. Resource Utilization:
    - CPU & Memory consumption
    - GPU utilization and cost analysis
1. Power Consumption: Measure energy usage for each setup.
1. Inference Architecture Comparison:
    - Embedded Model Inference Microservice vs. Decoupled Model Serving with External Storage.
1. Profiling Insights: Analyze execution bottlenecks using cProfile (Python).

## Observations

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
