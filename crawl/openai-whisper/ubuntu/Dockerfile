FROM docker.io/library/ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt update && \
    apt install -y python3 python3-pip ffmpeg wget curl && \
    rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip install --no-cache-dir openai-whisper jiwer

# Create and set working directory
WORKDIR /data

# Create env to access cached whisper models
ENV HOME=/data

# Give group write permissions
RUN chmod 0775 /data

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash"]
