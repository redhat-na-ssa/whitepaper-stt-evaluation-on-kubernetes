FROM docker.io/library/ubuntu:22.04
ENV PYTHON_VER=3.10

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone to avoid tzdata configuration prompt
RUN apt update && \
    apt install -y python3.${PYTHON_VER} python${PYTHON_VER}-venv python${PYTHON_VER}-dev \
      python3-pip ffmpeg wget curl tzdata && \
    rm -rf /var/lib/apt/lists/*

# Reconfigure tzdata silently
RUN dpkg-reconfigure -f noninteractive tzdata

# Upgrade pip to the latest version
RUN python3 -m pip install --no-cache-dir --upgrade pip

# Install python packages
RUN pip install --no-cache-dir openai-whisper jiwer

# Create and set working directory
WORKDIR /data

# Create env to access cached whisper models
ENV HOME=/data

# Give group write permissions
RUN chmod 0775 /data

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash", "umask", "0002"]
