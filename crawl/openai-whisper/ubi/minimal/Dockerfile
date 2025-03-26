ARG OS_VER=9
ARG IMAGE=registry.access.redhat.com/ubi${OS_VER}/ubi-minimal
FROM ${IMAGE}

ARG PYTHON_VER=3.11

# Switch to root for OS dependencies
USER root

# Install OS dependencies in a single step to reduce layers
RUN microdnf -y install python${PYTHON_VER} python${PYTHON_VER}-pip \
      gcc gcc-c++ make automake autoconf libtool git diffutils  && \
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
        --disable-ffprobe \
        --disable-doc \
        --disable-x86asm && \
      make -j"$(nproc)" && \
      make install && \
    cd .. && \
      rm -rf ffmpeg

# Install python packages
RUN pip${PYTHON_VER} install --no-cache-dir --upgrade pip==25.* && \
    pip${PYTHON_VER} install --no-cache-dir openai-whisper==20240930 jiwer==3.1.*

# Setup: entrypoint and other scripts over 
COPY --chmod=0755 bin /usr/local/bin

# Setup: working dir
WORKDIR /data

# Give group write permissions
RUN chmod 0775 /data

# Switch to non-root user
USER 1001

# Default command to process the audio file using ffmpeg & whisper
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Labels for container catalog
LABEL \
      summary="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      description="Python ${PYTHON_VER} image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-${PYTHON_VER}-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
