# Experimenting vLLM on UBI

## Manually Building Container

```bash
# (Optional) This will remove all unused images, containers, volumes, and networks — so only run it if you're okay with cleanup.
# podman system prune --all --volumes --force

# Pull UBI9-minimal
podman pull nvcr.io/nvidia/cuda:12.6.1-base-ubi9

# Run it
podman run --rm -it nvcr.io/nvidia/cuda:12.6.1-base-ubi9 /bin/bash -c 'cat /etc/os-release'

# Interactive buildout
podman run --rm -it nvcr.io/nvidia/cuda:12.6.1-base-ubi9 /bin/bash

# Install packages
dnf install -y \
    python3 \
    python3-pip \
    gcc \
    git \
    make \
    libffi-devel \
    openssl-devel && \
    dnf clean all

# Install python packages
pip install vllm==0.8.5.post1 vllm[audio]==0.8.5.post1 huggingface_hub

# Build it
podman build --squash -t vllm-ubi9-audio ubi9-minimal/.

# GPU
# --security-opt=label=disable 
# --device nvidia.com/gpu=all 

# Run it 
podman run --rm -it \
  -p 8000:8000 \
  vllm-ubi9-audio \
  --model mistralai/Mistral-7B-v0.1 \
  --dtype float16 \
  --device auto

# Run it
podman run --rm -it \
  --security-opt=label=disable \
  --device nvidia.com/gpu=all \
  -p 8000:8000 \
  vllm-ubi9-audio \
  --model /models/whisper-tiny.en \
  --served-model-name openai/whisper-tiny.en \
  --task transcription
```