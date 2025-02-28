ARG RHEL_VER=8
#ARG IMAGE=nvidia/cuda:12.8.0-cudnn-devel-ubi8:12.8.0-cudnn-devel-ubi8
ARG IMAGE=nvidia/cuda:12.8.0-cudnn-devel-ubi8:12.8.0-cudnn-devel-ubi8@sha256:d38778c859b3b8bfb5b47f1736b9d6a0c89308e283d1a0e09ade7b4c5168ff68

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
      summary="Python 3.9 image w/ whisper + ffmpeg" \
      description="Python 3.9 image w/ whisper + ffmpeg" \
      io.k8s.display-name="python-3.9-whisper" \
      org.opencontainers.image.description.vendor="openai" \
      org.opencontainers.image.description="A container for speech to text" \
      org.opencontainers.image.source="https://github.com/redhat-na-ssa"
