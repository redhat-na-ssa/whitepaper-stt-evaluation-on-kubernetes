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
podman run -it docker.io/library/ubuntu

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

### Whisper - Test on RHEL with UBI container

This tests pip installs Whisper in a virtual environment and runs it from the command line with a local .mp4 file

```
# create virtual env
python -m venv venv

# activate that virtual env
. venv/bin/activate

# pip install whisper
pip install -U openai-whisper

sudo yum update

sudo yum groupinstall "Development Tools"

sudo yum install glibc gcc gcc-c++ autoconf automake libtool git make nasm pkgconfig SDL-devel \
a52dec a52dec-devel alsa-lib-devel faac faac-devel faad2 faad2-devel freetype-devel giflib gsm gsm-devel \
imlib2 imlib2-devel lame lame-devel libICE-devel libSM-devel libX11-devel libXau-devel libXdmcp-devel \
libXext-devel libXrandr-devel libXrender-devel libXt-devel libogg libvorbis vorbis-tools mesa-libGL-devel \
mesa-libGLU-devel xorg-x11-proto-devel zlib-devel libtheora theora-tools ncurses-devel libdc1394 libdc1394-devel \
amrnb-devel amrwb-devel opencore-amr-devel

# install ffmpeg
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
./configure --enable-gpl --enable-libx264 --enable-libfdk-aac --enable-nonfree --disable-x86asm
make
sudo make install
ffmpeg -version

# download audio file - we used "Address at Rice University in Houston, Texas on the Nation's Space Effort, 12 September 1962"
https://www.jfklibrary.org/asset-viewer/archives/jfkwha

# install rust tools
pip install setuptools-rust

# run whisper turbo model - don't start with turbo
# Available models https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages 
whisper kennedy_rice_1962_speech.mp4 --model tiny.en
```

### Whisper - Test on OpenShift with a UBI container

This tests Whisper in a UBI container on OpenShift

```
```

## Reference

- [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages)
- https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871
- [ffmpeg install](https://github.com/FFmpeg/FFmpeg/blob/master/INSTALL.md3)