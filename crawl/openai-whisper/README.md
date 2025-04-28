# OpenAI Whisper Benchmark Guide

This guide provides instructions for evaluating OpenAI Whisper models using containerized environments for embedded microservice inference. Each directory contains setup details for a specific base image:

## Prepare Your Environment

### Provision a RHEL VM with GPUs

Follow the [provisioning guide](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md) to set up your RHEL VM.

### Clone the Repository Locally

```sh
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git && \
    cd whitepaper-stt-evaluation-on-kubernetes/ 
```

### Begin Crawl

[Next -> Ubuntu with Whisper](ubuntu/README.md)

## Resources

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
