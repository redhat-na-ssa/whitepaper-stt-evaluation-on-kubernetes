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
|Batch|X|TODO|TODO|TODO|
|Streaming|TODO|TODO|TODO|TODO|
|Word Error Rate (WER)|X|TODO|TODO|TODO|
|Match Error Rate (MER)|X|TODO|TODO|TODO|
|Word Information Lost (WIL)|X|TODO|TODO|TODO|
|Word Information Preserved (WIP)|X|TODO|TODO|TODO|
|Character Error Rate (CER)|X|TODO|TODO|TODO|
|Pipeline Build|TODO|TODO|TODO|TODO|
|Summary|TODO|TODO|TODO|TODO|

## Performance Metrics Evaluated:

**Infrastructure**: What types of hardware were tested?

1. RHEL EC2 Instance `g6.xlarge 1 x NVIDIA L4` OR `g6.12xlarge 4 x NVIDIA L4`
1. OpenShift Instance ``

**Scale**:

1. Max concurrent inference endpoints
1. Queries per second

**Cost:** How much does it cost to infer?

**Resources:** How many resources does it consume to infer?

1. Container size
1. GPU
1. CPU
1. VRAM

**Speed:** How fast is the model at transcribing using the `time` command which prints

1. `real` - wall-clock time (actual elapsed time) from when the command started to when it finished.
1. `user` - total amount of CPU time spent in user mode, meaning the time the CPU spent executing the process's code (excluding kernel operations).
1. `sys` - total amount of CPU time spent in kernel mode, meaning time spent executing system calls on behalf of the process (e.g., file I/O, memory allocation). If you are using a GPU, it's likely that much of the work gets offloaded resulting in a lower number.
1. responseLatency - i

**Precision:** Floating-Point Precision Comparison for Transcription:

|Precision|Accuracy|Speed|Memory Usage|Hardware Support|ASR Models Using It|
|---|---|---|---|---|---|
|FP8 (8-bit Floating Point)|Lowest (accuracy degradation)|Fastest|Lowest|NVIDIA H100, A100 (TensorRT, CUDA 12)|Not widely used yet; experimental for some ASR models|
|FP16 (Half-Precision, 16-bit Floating Point)|Slightly reduced vs. FP32|Fast (GPU-optimized)|Lower than FP32|Most modern GPUs (NVIDIA Tensor Cores, AMD ROCm)|Faster-Whisper, NeMo ASR, Canary, Wav2Vec|
|FP32 (Full Precision, 32-bit Floating Point)|Highest (best transcription accuracy)|Slowest|Highest|Universal (CPU & GPU)|Whisper, NeMo ASR, Canary, Wav2Vec|

**Accuracy:** How accurate is the model? JiWER is a simple and fast python package to evaluate an automatic speech recognition system. It supports the following measures:

1. `Word Error Rate (WER)` – Measures the percentage of words that were incorrectly predicted compared to the reference text.

    - S = Substitutions
    - D = Deletions
    - I = Insertions
    - N = Number of words in the reference transcript
    - Lower is better.

    WER = (S + D + I) / N

1. `Match Error Rate (MER)` – Represents the fraction of words that need to be transformed (inserted, deleted, or substituted) to match the reference text. Unlike WER, it considers the total number of words in both the reference and hypothesis.

    - S = Substitutions
    - D = Deletions
    - I = Insertions
    - C = Correctly recognized words
    - Unlike WER, MER includes the total correct words in the denominator.
    - Lower is better.

    WER = (S + D + I) / (S + D + C)

1. `Word Information Lost (WIL)` – Estimates how much word-level information is lost due to errors. It penalizes deletions and substitutions while being less sensitive to insertions.

    - Related to WER but normalizes by WIP.

    WIL = WER / (1 - WIP)

1. `Word Information Preserved (WIP)` – The inverse of WIL, this measures how much word-level information is correctly preserved in the hypothesis relative to the reference.

    - Measures how much information was retained in the STT output.

    WIP = C / (C + S + D)

1. `Character Error Rate (CER)` – Similar to WER but at the character level, CER measures the percentage of incorrectly predicted characters compared to the reference text, making it useful for evaluating text with short words or heavy misspellings.

    - Similar to WER but at the character level rather than words.
    - Useful for languages with compound words or agglutinative structures.

    CER = (S + D + I) / N

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

### RHEL AI VM

1. SSH to your RHEL AI VM
1. Clone the git repo `git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git`
1. Move to your cloned git folder `cd whitepaper-stt-evaluation-on-kubernetes/`

### OCP AI

1. TBP

## Observations

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
