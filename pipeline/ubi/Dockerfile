# Updating Image to point to Unauthenticated version
ARG IMAGE=registry.access.redhat.com/ubi8/python-39@sha256:24be696023cf97eca8da81112ca917de1e2e1ed6e57b285b8d0f2cd1ff91b1f9

FROM ${IMAGE}

# Switch to root user
USER root

# Install dependencies in a single step to reduce layers
RUN yum -y install \
    gcc gcc-c++ make automake autoconf libtool git diffutils && \
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %{rhel}).noarch.rpm && \
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
COPY --chmod=0755 ./pipeline/ubi/bin /usr/local/bin

# Setup: working dir
WORKDIR --chmod=0775 /data

# Switch back to default user
USER 1001

# Default command to process the audio file using ffmpeg & whisper
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Labels for container catalog
LABEL \
      summary="Python 3.9 image w/ whisper + ffmpeg" \
      description="Python 3.9 image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-3.9-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
