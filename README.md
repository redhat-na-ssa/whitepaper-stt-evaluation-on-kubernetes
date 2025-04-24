# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

## Goal

Two fold:

1. Demonstrate how to move from individual experimentation to operational enterprise scale.
2. Collect benchmarking data to guide architectural and operational decisions on model performance, system efficiency, and container security.

## Summary of Experimentation to Operations

- **[Crawl README](./crawl/README.md)** — Start with open source Ubuntu containers and end on supported UBI9-minimal containers on a single server.
- **[Walk README](./walk/README.md)** — Move from a single server with finite resources to a Kubernetes cluster.
- **[Run README](./run/README.md)** — Transition from embedded inference to decoupled model serving.
- **Sprint** — Integrate with Model Registry and advanced serving infrastructure.

Along the journey, we introduce automation and answer common performance, security, and scalability questions.

## Summary of Benchmarking

Execute [benchmarking](./benchmark/README.md) to capture metrics from:

- **Models**: Whisper, Faster-Whisper
- **Containers**: Ubuntu, UBI9, UBI9-minimal
- **Platforms**: Linux, Kubernetes
- **Model Servers**: vLLM, Speeches, TensorRT
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

- `whisper-functional-batch-metrics.sh`
- `compare_transcripts.py`
- `system_non_functional_monitoring.py`
- `cleanup-benchmark-results.sh`

## Example Questions to Answer

- How much faster is GPU vs CPU inference?
- What is the benefit of warm starts?
- Do hyperparameters increase transcription quality?
- Is container startup time a major factor?
- How do different container bases (Ubuntu vs UBI) compare?
- Are larger models worth the additional runtime cost?

## Observations Summary Table

| **Metric**               | **Goal**            | **Notes**                                                                 |
|--------------------------|---------------------|--------------------------------------------------------------------------|
| `tokens_per_second`      | Higher = better     | Measures inference throughput. GPU modes should be much faster.         |
| `real_time_factor` (RTF) | < 1.0 = real-time   | Runtime / audio duration. Critical for low-latency requirements.         |
| `container_runtime_sec`  | Lower = better      | Includes startup/shutdown time. Reflects cold/warm tradeoffs.           |
| `token_count`            | Stable across modes | Large changes may indicate transcription variation.                     |
| `wer`                    | Lower = better      | Measures transcription accuracy.                                        |
| `mer`                    | Lower = better      | Broader accuracy metric (match + insertions + deletions).               |
| `wil`                    | Lower = better      | Captures meaning loss during transcription.                             |
| `wip`                    | Higher = better     | Complements WIL — reflects preserved meaning.                           |
| `cer`                    | Lower = better      | Character-level precision.                                               |

## Related Resources

- [LaTeX paper template](https://github.com/pmichaillat/latex-paper)
- [Convert Markdown to LaTeX](https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871)
