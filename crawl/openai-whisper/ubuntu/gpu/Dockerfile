ARG UBUNTU_VER=22.04
ARG CUDA_VER=12.8.0
ARG IMAGE=docker.io/nvidia/cuda:${CUDA_VER}-cudnn-devel-ubuntu${UBUNTU_VER}
ARG PIP_ARGS="torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"

FROM ${IMAGE}

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt update && \
    apt install -y python3-venv python3-pip ffmpeg wget curl && \
    rm -rf /var/lib/apt/lists/*

# Install GPU version of PyTorch
RUN pip  --no-cache-dir install ${PIP_ARGS}

# Create and set working directory
WORKDIR /data

# Give group write permissions
RUN chmod 0775 /data

# Create and activate virtual environment
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir openai-whisper jiwer

ENV BASH_ENV="/data/venv/bin/activate" \
    ENV="/data/venv/bin/activate" \
    PROMPT_COMMAND=". /data/venv/bin/activate"

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash"]
