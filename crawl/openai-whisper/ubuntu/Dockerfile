ARG OS_VER=22.04
ARG IMAGE=docker.io/library/ubuntu:${OS_VER}
FROM ${IMAGE}

ARG PYTHON_VER=3.10

# Switch to root for OS dependencies
USER root

# Set non-interactive mode for apt
ARG DEBIAN_FRONTEND=noninteractive

# Install OS dependencies in a single step to reduce layers
RUN apt update && \
    apt install -y python${PYTHON_VER} python${PYTHON_VER}-venv python${PYTHON_VER}-dev \
      python3-pip ffmpeg wget curl tzdata && \
    rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip${PYTHON_VER} install --no-cache-dir --upgrade pip==25.* && \
    pip${PYTHON_VER} install --no-cache-dir openai-whisper==20240930 jiwer==3.1.*

# Create and set working directory
WORKDIR /data
ENV HOME=/data

# Give group write permissions
RUN chmod 0775 /data

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash", "umask", "0002"]

# Labels for container catalog
LABEL \
      summary="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      description="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-${PYTHON_VER}-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
