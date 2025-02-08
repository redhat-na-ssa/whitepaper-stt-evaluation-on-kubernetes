# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both real-time and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

## Use Cases:

- [ ] Real-time transcription
- [ ] Batch offline transcription

## Model Variants:

- [x] OpenAI Whisper (V2 & V3)
- [ ] Faster-Whisper
- [ ] NVIDIA NeMo ASR
- [ ] Wav2Vec 2.0 (Meta AI)

## Container Environments:

- [x] Ubuntu
- [x] UBI

## Model Server Frameworks:

- [x] OpenAI Whisper's model server
- [ ] Faster-Whisper API
- [ ] Triton Server
- [ ] Hugging Face Transformers API
- [ ] NeMo API Server
- [ ] vLLM

## Deployment Platforms:

- [ ] Red Hat Enterprise Linux
- [ ] Red Hat OpenShift

## Hardware Configurations:

- [ ] CPU
- [ ] GPU

## Performance Metrics Evaluated:

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
