# USAGE 
# No model preloading (downloads at runtime):
# docker build -t whisper-runtime .
# Preload a model at build time (e.g. base):
# docker build --build-arg MODEL_SIZE=base -t whisper-base .

ARG OS_VER=22.04
ARG IMAGE=docker.io/library/ubuntu:${OS_VER}
FROM ${IMAGE}

ARG PYTHON_VER=3.10

# ADDED you can use the same Dockerfile for:
# Minimal builds with runtime model download
# Preloaded models for faster startup or air-gapped environments
ARG MODEL_SIZE  # Optional model download at build time

# Switch to root for OS dependencies
USER root

# Set non-interactive mode for apt
ARG DEBIAN_FRONTEND=noninteractive

# Install OS dependencies in a single step to reduce layers
RUN apt update && \
    apt install -y python${PYTHON_VER} python${PYTHON_VER}-venv python${PYTHON_VER}-dev \
      python3-pip ffmpeg wget curl tzdata time strace numactl bc && \
    rm -rf /var/lib/apt/lists/*

# Install python packages
RUN pip${PYTHON_VER} install --no-cache-dir --upgrade pip==25.* && \
    pip${PYTHON_VER} install --no-cache-dir openai-whisper==20240930 jiwer==3.1.*

# Create and set working directory
WORKDIR /data
ENV HOME=/data

# Give group write permissions
RUN chmod 0775 /data

# ADDED Conditionally preload the whisper model if MODEL_SIZE is provided
RUN if [ -n "$MODEL_SIZE" ]; then \
      echo "Downloading Whisper model: $MODEL_SIZE" && \
      python${PYTHON_VER} -c "import whisper; whisper.load_model('$MODEL_SIZE')"; \
    else \
      echo "No MODEL_SIZE provided. Skipping model download."; \
    fi

# Default command to process the audio file using ffmpeg & whisper
#CMD ["/bin/bash", "umask", "0002"]

# ADDED # Default command (loads tiny.en at runtime)
CMD ["python3", "-c", "import whisper; whisper.load_model('tiny.en'); print('Model ready.')"]

# Labels for container catalog
LABEL \
      summary="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      description="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-${PYTHON_VER}-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
