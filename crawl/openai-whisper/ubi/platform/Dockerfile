ARG RHEL_VER=9
ARG PYTHON_VER=312
ARG IMAGE=registry.access.redhat.com/ubi${RHEL_VER}/python-${PYTHON_VER}

FROM ${IMAGE}

# Switch to root user
USER root

# Install dependencies in a single step to reduce layers
RUN yum -y install \
    gcc gcc-c++ make automake autoconf libtool git diffutils && \
    yum clean all && \
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

# Install whisper
RUN pip install --no-cache-dir -U pip==25.* && \
    pip install --no-cache-dir openai-whisper==20240930 jiwer==3.1.*

# Setup: entrypoint and other scripts over 
COPY --chmod=0755 bin /usr/local/bin

# Setup: working dir
WORKDIR /data

# Give group write permissions
RUN chmod 0775 /data

# Switch back to default user
USER 1001

# Default command to process the audio file using ffmpeg & whisper
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Labels for container catalog
LABEL \
      summary="Python 3.${PYTHON_VER} image w/ whisper + ffmpeg" \
      description="Python 3.${PYTHON_VER} image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-3.${PYTHON_VER}-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"