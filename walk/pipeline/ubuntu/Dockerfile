ARG UBUNTU_VER=22.04
ARG IMAGE=docker.io/library/ubuntu:${UBUNTU_VER}

FROM ${IMAGE}

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt update && \
    apt install -y python3-venv python3-pip ffmpeg wget curl && \
    rm -rf /var/lib/apt/lists/*

# Install GPU version of PyTorch
RUN pip  --no-cache-dir install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

# Setup: entrypoint and other scripts over 
COPY --chmod=0755 ./pipeline/ubuntu/bin /usr/local/bin

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
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Labels for container catalog
LABEL \
      summary="Ubuntu 22 image w/ whisper" \
      description="Ubuntu 22 image w/ whisper" \
      io.k8s.display-name="ubuntu-22-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"