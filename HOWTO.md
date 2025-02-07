# Manual setup procedure

1. Test on RHEL with Ubuntu container
1. Test on RHEL with a UBI container
1. Test on OpenShift

## Whisper

### Whisper - Test on RHEL with a Ubuntu container

This tests Whisper in a Ubuntu container

```
# search for an ubuntu container base image
podman search ubuntu --list-tags

# pull and run an ubuntu image
podman run -it --name ubuntu-whisper docker.io/library/ubuntu

# as root, update apt, install python3-venv
sudo apt update

# install python
apt install -y python3-venv # you have to complete prompt

# install pip
apt install -y python3-pip

# install ffmpeg
apt install -y ffmpeg 

# install wget
apt install -y wget

# create and activate a python virtual env
python3 -m venv venv
. venv/bin/activate

# install openai-whisper
pip install openai-whisper

# download an audio file https://www.jfklibrary.org/asset-viewer/archives/jfkwha
# wget -O filename url

# inference
whisper kennedy_1962.mp4 --model tiny.en

# output
/venv/lib/python3.12/site-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
  warnings.warn("FP16 is not supported on CPU; using FP32 instead")
[00:00.000 --> 00:07.000]  The present remarks at Rice Stadium in Houston, Texas, September 12, 1962.
[00:07.000 --> 00:17.700]  President Pipsis, Mr. Vice President, Governor, Congressman Thomas, Senator
[00:17.700 --> 00:27.100]  Wiley and Congressman Miller, Mr. Webb, Val, scientists, distinguished guests, ladies and gentlemen.

# restarting the stopped container
podman start --interactive --attach upbeat_khorana

# active the virtual env
. venv/bin/activate

# inference
whisper kennedy_1962.mp4 --model base.en
```

#### Inference

Use Cases:

1. Real-time dictation
1. Offline file dictation (can you fastforward?)

Bind Mount a Local Directory
You can mount a local directory containing your audio file to the container using the -v flag:
```sh
podman run --rm -v /path/to/local/audio:/app/audio:Z ubuntu-whisper-container venv/bin/whisper /app/audio/your_audio.mp4 --model tiny.en
```

Copy the File Into a Running Container
If the container is already running, you can copy the file into it using:
```sh
# copy
podman cp your_audio.mp4 <container_id>:/app/audio/

# inference
podman exec <container_id> venv/bin/whisper /app/audio/your_audio.mp4 --model tiny.en
```

 Use --env for Dynamic File Passing
 Modify the Containerfile to use an environment variable for the file path:

```sh

# dockerfile modification
CMD ["sh", "-c", "venv/bin/whisper $AUDIO_FILE --model tiny.en"]

# pass file as env
podman run --rm -v /path/to/local/audio:/app/audio:Z -e AUDIO_FILE=/app/audio/your_audio.mp4 ubuntu-whisper-container
```

### Performance

Time the execution
Real: Total elapsed time
User: CPU time spent in user mode
Sys: CPU time spent in kernel mode
```sh
time podman run --rm -v /path/to/local/audio:/app/audio:Z ubuntu-whisper-container venv/bin/whisper /app/audio/your_audio.mp4 --model tiny.en
```

Measure GPU Utilization (if applicable)
```sh
podman run --rm --runtime=nvidia --gpus all ubuntu-whisper-container nvidia-smi

watch -n 1 nvidia-smi
```

Measure CPU & Memory Usage
Max Resident Set Size (memory usage)
CPU Time (user/sys)
Elapsed Time (real)
```sh
podman run --rm -v /path/to/local/audio:/app/audio:Z ubuntu-whisper-container /usr/bin/time -v venv/bin/whisper /app/audio/your_audio.mp4 --model tiny.en
```

Measure Word Error Rate (WER) for Accuracy
To evaluate transcription accuracy, compare the model’s output with a ground truth transcript:

Profiling with cProfile (Python)
For deeper performance insights, profile function calls:
```sh

```

### Whisper - Test on RHEL with UBI8 container

This tests pip installs Whisper in a virtual environment and runs it from the command line with a local .mp4 file

Step 1: Write a Whisper UBI8 Image

```sh
FROM registry.redhat.io/ubi8/python-39

# Switch to root user
USER root

# Install dependencies in a single step to reduce layers
RUN yum -y install \
    gcc gcc-c++ make automake autoconf libtool git \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum

# Clone and build FFmpeg in one step
RUN git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git ffmpeg && \
    cd ffmpeg && \
    ./configure --disable-x86asm && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf ffmpeg

# Install whisper
RUN pip install openai-whisper

# Switch back to default user
USER default

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash", "-c", "if [ -n \"$AUDIO_FILE\" ]; then ffmpeg -i \"$AUDIO_FILE\" -ar 16000 -ac 1 -c:a pcm_s16le /app/processed.wav && whisper /app/processed.wav; else exec /bin/bash; fi"]
```

Build the Whisper Image
```sh
podman login registry.redhat.io

podman build --format=docker -t ubi8-whisper ubi8/.
```

Run the image
```sh
podman run --name whisper --rm -it \
    -v $(pwd)/sample.wav:/app/sample.wav \
    -e AUDIO_FILE=/app/sample.wav \
    my_ffmpeg_whisper_image
```

### Whisper - Test on OpenShift with a UBI container

This tests Whisper in a UBI container on OpenShift

```
```

## Reference

- [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages)
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
- [ffmpeg install](https://github.com/FFmpeg/FFmpeg/blob/master/INSTALL.md3)