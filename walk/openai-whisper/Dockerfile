ARG OS_VER=9
ARG IMAGE=registry.access.redhat.com/ubi${OS_VER}/ubi-minimal
FROM ${IMAGE}

# Python 3.11 is not included in the base UBI 9 repositories
ARG PYTHON_VER=3.9

# ADDED you can use the same Dockerfile for:
# Minimal builds with runtime model download
# Preloaded models for faster startup or air-gapped environments
ARG MODEL_SIZE  # Optional model download at build time

# Switch to root for OS dependencies
USER root

# Install OS dependencies in a single step to reduce layers
RUN microdnf -y install \
    python${PYTHON_VER} python${PYTHON_VER}-pip \
    gcc gcc-c++ make automake autoconf libtool git diffutils \
    time strace numactl bc && \
    microdnf clean all && \
    rm -rf /var/cache/yum

# Clone and build FFmpeg in one step
RUN git clone https://git.ffmpeg.org/ffmpeg.git \
      --branch "release/7.1" \
      --depth 1  \
      ffmpeg && \
    cd ffmpeg && \
      ./configure --help && \
      ./configure \
        --enable-gpl \
        --disable-ffplay \
        #--disable-ffprobe \
        --disable-doc \
        --disable-x86asm && \
      make -j"$(nproc)" && \
      make install && \
    cd .. && \
      rm -rf ffmpeg

# Install python packages
RUN pip${PYTHON_VER} install --no-cache-dir --upgrade pip==25.* && \
    pip${PYTHON_VER} install --no-cache-dir openai-whisper==20240930 jiwer==3.1.* flask

# Setup: Expose an HTTP endpoint that accepts audio and returns transcribed text.
COPY app.py /app/app.py

# Setup: entrypoint and other scripts over 
COPY --chmod=0755 bin /usr/local/bin

# Setup: working dir
WORKDIR /app
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

# Switch to non-root user
USER 1001

# Default command to process the audio file using ffmpeg & whisper
# ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["python", "app.py"]

# Labels for container catalog
LABEL \
      summary="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      description="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-${PYTHON_VER}-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
