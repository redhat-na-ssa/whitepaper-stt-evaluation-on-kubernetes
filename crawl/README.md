# Crawl

Crawl Speech-to-Text models on CPU and GPU on Linux and OpenShift.

## Crawl procedure

In summary:

1. Provision RHEL - [provision RHEL with GPU](provision_rhel_aws.sh)
1. Test OpenAI Whisper - [build and run Whisper](openai-whisper/README.md)
1. Test Faster-Whisper - TODO
1. Test NVIDIA Riva - TODO

## Goal

Test 3x STT models:

- Whisper
- Faster-Whisper
- NVIDIA Riva

Test 2x Deployment setups:

- Embedded inference microservices on Ubuntu, UBI9-platform, and UBI9-minimal (Linux & Kubernetes)
- Decoupled model servers: vLLM, Faster-Whisper, NVIDIA Triton

Test on CPU and GPU Hardware:

- GPUs: T4, L4, A10, H100
- CPUs: Intel Cascade Lake, Graviton3, AMD EPYC, Intel Sapphire Rapids

Provided input files:

1. Harvard.wav
1. JFK Inaugural Address from Jan. 20, 1961
1. JFK Rice University from Sept. 12, 1962

Provided ground truth transcriptions:

1. Harvard.txt
1. JFK Inaugural Address from Jan. 20, 1961 transcript from the White House
1. JFK Rice University from Sept. 12, 1962 transcript from the White House

## Questions to answer

### Custom Configurations in OpenShift

1. Reducing GPU Temperature: Are there any OpenShift configurations to help reduce GPU temperature during transcription?
1. Reducing GPU Power Consumption: Is it possible to lower GPU power usage during transcription in OpenShift?
1. Optimizing GPU Utilization: How can GPU utilization be optimized in OpenShift for transcription tasks?
1. NTO Impact: Does NTO (Node Tuning Operator) provide any performance gains?
1. PPC Effectiveness: Does PPC (Performance Profile Creator) offer any benefits in these scenarios?
1. What other configurations are worth testing?

### Concurrency and Scalability

1. Increasing Concurrency: How can the number of concurrent audio files processed be increased in OpenShift?
1. Handling Larger Audio Files: How does OpenShift scale with larger audio file sizes?
1. Scaling Larger Models: Do larger models scale linearly, or do they hit memory/processing limits faster in OpenShift?

### Resource Management

1. Container Startup Times: How do container startup times impact resource usage?
1. GPU Fractionalization: How does GPU fractionalization impact throughput and performance?
1. Simultaneous Inference: How many concurrent inference tasks can a GPU handle at once, and how does this scale?
1. MIG vs. No MIG: How does the presence or absence of MIG (Multi-Instance GPU) affect performance?
1. Time-Slicing: What is the impact of time-slicing on GPU usage and throughput?
1. MIG + Time-Slicing: What happens when MIG and time-slicing are used together?

### Optimization

1. Cost vs. Performance: What is the optimal GPU configuration for balancing cost and performance, considering different model sizes?
1. Tokens Per Second: How does OpenShift affect tokens per second in transcription tasks?

### Comparison to Linux

1. Performance Comparison: Does OpenShift slow down transcription performance compared to running directly on Linux?
1. Right-Sizing: How should model size and GPU configuration be right-sized for optimal performance in OpenShift?