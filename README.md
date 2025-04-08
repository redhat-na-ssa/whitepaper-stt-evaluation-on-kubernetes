# Speech to Text Analysis Whitepaper

This project evaluates various Speech-to-Text (STT) configurations for both streaming and batch (offline) transcription, testing different model variants, container environments, model serving frameworks, deployment platforms, and hardware configurations.

## Goal

Test 3x general-purpose speech recognition models:

1. Whisper
1. Faster-Whisper
1. NVIDIA Riva

Test 2x Deployment setups:

1. Embedded inference microservices on Ubuntu, UBI9-platform, and UBI9-minimal (Linux & Kubernetes)
1. Decoupled model servers: vLLM, Faster-Whisper, NVIDIA Triton

Test on CPU and GPU Hardware:

1. GPUs: T4, L4, A10, H100
1. CPUs: Intel Cascade Lake, Graviton3, AMD EPYC, Intel Sapphire Rapids

Provided input files:

1. Harvard.wav
1. JFK Inaugural Address from Jan. 20, 1961
1. JFK Rice University from Sept. 12, 1962

Provided ground truth transcriptions:

1. Harvard.txt
1. JFK Inaugural Address from Jan. 20, 1961 transcript from the White House
1. JFK Rice University from Sept. 12, 1962 transcript from the White House

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

### Walk

Go to the [Walk README](./walk/README.md)

### Run

Go to the [Run README](./run/README.md)

## Related resources

- https://github.com/pmichaillat/latex-paper
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
