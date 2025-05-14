# OpenAI Whisper Benchmark Guide

This guide provides instructions for evaluating OpenAI Whisper models using containerized environments for embedded microservice inference. Each directory contains setup details for a specific base image:

## Procedure 

1. Follow the [provisioning guide](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md) to set up your RHEL VM.
1. Clone the Repository Locally
    ```sh
    git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git
    cd whitepaper-stt-evaluation-on-kubernetes/
    ```
1. Crawl OpenAI Whisper onto Linux with Ubuntu base image [Start -> Ubuntu with OpenAI Whisper](crawl/openai-whisper/ubuntu/README.md)
1. Crawl OpenI Whisper onto UBI9 from UBuntu [Next -> UBI9 with OpenAI Whisper](crawl/openai-whisper/ubi/README.md)
