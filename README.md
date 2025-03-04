# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

OpenAI Whisper, Faster-Whisper, NVIDIA NeMo ASR, and Wav2Vec are all speech-to-text (ASR) models, but they differ in terms of architecture, performance, hardware requirements, and use cases. Here’s how they compare:

||OpenAI Whisper|Faster-Whisper|NeMo|
|-|-|-|-|
|Developer|OpenAI|OpenAI (optimized by Faster-Whisper)|
|Model Type|Transformer-based|Transformer-based|Conformer-based|
|Pretraining Method|Supervised (large-scale labeled data)|Optimized Whisper|Supervised & Semi-Supervised|
|Multilingual|Yes (99+ languages)|Yes (99+ languages)|Yes (for some models)|
|Hardware|CPU/GPU|Optimized for GPU|Optimized for NVIDIA GPUs|
|Streaming|No|No|Yes|

Tracking the deployment and integration status of different speech-to-text (ASR) models (OpenAI Whisper, Faster-Whisper, NVIDIA NeMo ASR, and Wav2Vec 2.0) across various environments, model servers, and performance metrics.

||OpenAI Whisper|Faster-Whisper|NeMo|
|-|-|-|-|
|Ubuntu Dockerfile|X|TODO|TODO|TODO|
|UBI Dockerfile|X|TODO|TODO|
|ModelKit|TODO|TODO|TODO|
|RHEL OS|X|TODO|TODO|
|OCP|X|TODO|TODO|
|Embedded Server|X|TODO|TODO|
|Built-in Server|X|TODO|TODO|
|Decoupled Server|TODO|TODO|TODO|
|NVIDIA Triton|TODO|TODO|TODO|
|vLLM|TODO|TODO|TODO|
|Ray Serve|TODO|TODO|TODO|
|Batch|X|TODO|TODO|
|Streaming|TODO|TODO|TODO|
|Word Error Rate (WER)|X|TODO|TODO|
|Match Error Rate (MER)|X|TODO|TODO|
|Word Information Lost (WIL)|X|TODO|TODO|
|Word Information Preserved (WIP)|X|TODO|TODO|
|Character Error Rate (CER)|X|TODO|TODO|
|Pipeline Build|TODO|TODO|TODO|
|Summary|TODO|TODO|TODO|

## Getting Started

### Environments

1. Request environments from demo.redhat.com

2. [RHEL AI (GA) VM](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/rhdp.rhel-ai-vm.prod&utm_source=webapp&utm_medium=share-link)
    - Activity: `Practice / Enablement`
    - Purpose: `Trying out a technical solution`
    - Region: `us-east-2`
    - GPU Selection by Node Type: `g6.xlarge 1 x L4` OR `g6.12xlarge 4 x L4`
3. [AWS with OpenShift Open Environment](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-ocp.prod&utm_source=webapp&utm_medium=share-link)
    - Activity: `Practice / Enablement`
    - Purpose: `Trying out a technical solution`
    - Region: `us-east-2`
    - OpenShift Version: `4.17`
    - Control Plane Count: `1`
    - Control Plane Instance Type: `m6a.4xlarge`

4. [Pipeline Demo Environment](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/enterprise.redhat-tap-demo.prod&utm_source=webapp&utm_medium=share-link)
    - Activity: `Practice / Enablement`
    - Purpose: `Trying out a technical solution`
    - Developer Hub: `stable`
    - Orchestrator: `Enabled`
    - Enable RHOAI: `Enabled`

### Crawl

Go to the [Crawl README](./crawl/README.md)

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
