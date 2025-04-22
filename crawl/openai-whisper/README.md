# OpenAI Whisper Benchmark Guide

This guide provides instructions for evaluating OpenAI Whisper models using containerized environments for embedded microservice inference. Each directory contains setup details for a specific base image:

## Prepare Your Environment

### Provision a RHEL VM with GPUs

Follow the [provisioning guide](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/crawl/RHEL_GPU.md) to set up your RHEL VM.

### Clone the Repository

```sh
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git
```

### Begin Crawl

Proceed to:

1. [Ubuntu with Whisper](ubuntu/README.md)
1. [UBI9 with Whisper](ubi/platform/README.md)
1. [UBI9-minimal with Whisper](ubi/minimal/README.md)

## Resources

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
