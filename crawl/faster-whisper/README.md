# Faster Whisper

## Build Dockerfiles

```sh
# build the images for faster-whisper 
podman build -t faster-whisper:ubuntu crawl/faster-whisper/ubuntu/.
podman build -t faster-whisper:ubi9 crawl/faster-whisper/ubi/platform/.
podman build -t faster-whisper:ubi9-minimal crawl/faster-whisper/ubi/minimal/.
```