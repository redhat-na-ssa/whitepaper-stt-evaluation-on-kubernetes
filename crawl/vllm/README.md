# vLLM Crawl Guide

This guide provides instructions for crawling vLLM model serve using containerized environments for embedded inference micrservices and decoupled model serving from Ubuntu to UBI. Each directory contains setup details for a specific base image:

## Procedure

1. Follow the [provisioning guide](https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes/blob/main/walk/RHEL_GPU.md) to set up your RHEL VM.
1. Clone the Repository Locally

    ```bash
    git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git && cd whitepaper-stt-evaluation-on-kubernetes/
    ``` 
1. Crawl vLLM onto Linux with Ubuntu base image for decoupled and embedded models [Start -> Ubuntu with vLLM](../vllm/ubuntu/README.md)
1. Crawl vLLM onto UBI9 from UBuntu for decoupled and embedded models [Next -> UBI9 with vLLM](../vllm/ubi9/README.md)
