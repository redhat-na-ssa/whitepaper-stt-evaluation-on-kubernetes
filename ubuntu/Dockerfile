FROM docker.io/library/ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt update && \
    apt install -y python3-venv python3-pip ffmpeg wget curl && \
    rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /data

# Create and activate virtual environment
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir openai-whisper jiwer


ENV BASH_ENV="/data/venv/bin/activate" \
    ENV="/data/venv/bin/activate" \
    PROMPT_COMMAND=". /data/venv/bin/activate"

# Run inference
CMD [ "/bin/bash" ]