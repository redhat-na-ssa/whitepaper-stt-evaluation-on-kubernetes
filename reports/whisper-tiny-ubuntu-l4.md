# Performance Evaluation Report

## Test Setup Procedure

```sh
# connect to env
ssh into env

# clone the repo
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git && cd whitepaper-stt-evaluation-on-kubernetes

# build the container
podman build -t whisper:ubuntu .

# run the container image
podman run -it --rm whisper:ubuntu /bin/bash

# create a scratch dir and download audio file
# https://www.jfklibrary.org/asset-viewer/archives/jfkwha
# Address at Rice University in Houston, Texas on the Nation's Space Effort, 12 September 1962
wget -O kennedy.mp4 "<insert web addr>"

# run inference
whisper kennedy.mp4 --model tiny.en

# time inference
time whisper kennedy.mp4 --model tiny.en


```

## Test Configuration

- Model Variant: `OpenAI Whisper (V2 & V3)`
- Container Environment: `Ubuntu`
- Model Server Framework: `OpenAI Whisper Model Server`
- Deployment Platform: `Red Hat Enterprise Linux (RHEL)`
- Hardware Configuration: `NVIDIA L4 GPU`
    - GPU CUDA Version: `12.4`
    - GPU Quantity: `4`

## Performance Metrics

1. Execution Time:
    - Total Inference Time: `0m54.636s`
    - Real-time Processing Capability: `Yes/No`(for real-time use cases)
    - Latency Breakdown:
        - Model Loading: `X seconds`
        - Transcription Processing: `X seconds`
        - Post-processing: `X seconds`
2. Accuracy (Word Error Rate - WER):
    - WER on Benchmark Dataset: `X%`
    - Performance across Noise Levels:
        Clean Audio: `X% WER`
        Moderate Noise: `X% WER`
        High Noise: `X% WER`
3. Resource Utilization:
    - Image Size: `6.66 GB`
    - CPU Usage: `X% (Peak: X%)`
    - Memory Usage: `X GB (Peak: X GB)`
    - GPU Utilization: `X% (Peak: X%)`
    - VRAM Usage: `X GB`
4. Power Consumption
    - Average Power Usage: `X Watts`
    - Peak Power Usage: `X Watts`
5. Inference Architecture Comparison:
    - Embedded Model Inference Microservice vs. Decoupled Model Serving with External Storage:
        - Embedded: Latency: `X sec`, WER: `X%`, Resource Utilization: `X`
        - Decoupled: Latency: `X sec`, WER: `X%`, Resource Utilization: `X`
    - Observations: Insert findings here
6. Profiling Insights (cProfile - Python)
    - Most Time-Consuming Functions:
        - Function `X`: `X% of execution time`
        - Function `Y`: `X% of execution time`
    - Potential Bottlenecks: `Insert findings here`
    - Optimizations Considered: `Insert recommendations here`
7. Overall Findings & Recommendations:
    - Strengths of this Configuration: `Insert key advantages`
    - Weaknesses/Limitations: `Insert any challenges observed`
    - Best Suited Use Cases: `Real-time transcription, batch processing, low-power environments, etc.`
    - Suggested Optimizations: `E.g., Reduce VRAM usage, optimize batch sizes, etc.`
