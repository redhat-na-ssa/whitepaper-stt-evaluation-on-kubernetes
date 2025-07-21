# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

## Goal

Two fold:

1. Demonstrate how to move from individual experimentation to operational enterprise scale.
2. Collect benchmarking data to guide architectural and operational decisions on model performance, system efficiency, and container security.

## Summary of Experimentation to Operations

- **START HERE -> [Crawl README](./crawl/README.md)** — Experiment locally using Ubuntu and UBI9-minimal containers on a single server.
- **[Walk README](./walk/README.md)** — Scale from a single server to a Kubernetes cluster.
- **[Run README](./run/README.md)** — Shift from embedded inference to decoupled model serving.
- **Sprint** — Integrate Model Registries and optimize for production-scale serving.

Along the journey, we introduce automation and answer common performance, security, and scalability questions.

## Summary of Benchmarking

Execute [benchmarking](./benchmark/README.md) to capture metrics from:

- **Models**: OpenAI Whisper
- **Containers**: Ubuntu, UBI9-minimal
- **Platforms**: Linux, Kubernetes
- **Model Servers**: OpenAI Whisper, vLLM
- **CPUs**: Intel Cascade Lake, AWS Graviton3, AMD EPYC, Intel Sapphire Rapids
- **GPUs**: T4, L4, A10, H100
- **Instance Types**: g4dn.12xlarge, g6.12xlarge, g5.12xlarge, p5.48xlarge
- **Command Modes**: basic, hyperparameters
- **Start Modes**: cold, warm

### Input Audio Files (in `/data/input-samples/`):

1. [Harvard.wav](https://www.kaggle.com/datasets/pavanelisetty/sample-audio-files-for-speech-recognition)
2. [JFK Inaugural Address (1961)](https://www.jfklibrary.org/asset-viewer/archives/jfkwha-001)
3. [JFK Rice University Speech (1962)](https://www.jfklibrary.org/asset-viewer/archives/usg-15-29-2)

### Ground Truth Transcripts (in `/data/ground-truth/`):

1. Harvard.txt
2. JFK Inaugural Address (official transcript)
3. JFK Rice University Speech (official transcript)

### Evaluation Scripts (in `/data/evaluation-scripts/`):

- `whisper-functional-batch-metrics.sh` - Batch Transcription Benchmarking
- `compare_transcripts.py` - Accuracy Metrics Scoring
- `system_non_functional_monitoring.py` - System Resource Monitoring
- `cleanup-benchmark-results.sh` - Benchmark Workspace Cleanup

## Related Resources

- [LaTeX paper template](https://github.com/pmichaillat/latex-paper)
- [Convert Markdown to LaTeX](https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871)
