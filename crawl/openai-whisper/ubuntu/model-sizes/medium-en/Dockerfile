FROM docker.io/library/ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install required dependencies
RUN apt update && \
    apt install -y python3 python3-pip ffmpeg wget curl && \
    rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip install --no-cache-dir openai-whisper jiwer

# Pre-download the Whisper model (choose one: tiny, tiny.en, base, base.en, small, small.en, medium.en, medium, large, turbo)
RUN mkdir -p /root/.cache/whisper && \
    python3 -c "import whisper; whisper.load_model('medium.en')"

# Create and set working directory
WORKDIR /data

# Give group write permissions
RUN chmod 0775 /data

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash"]
