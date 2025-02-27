# Crawl

OpenAI Whisper interactive session with local audio files on a laptop/server:

- [x] Ubuntu
    - [x] CPU ~12G
    - [x] GPU ~22G
- [x] UBI
    - [ ] CPU
    - [ ] GPU

## Ubuntu

### Build CPU image

`podman build -t whisper-cpu:ubuntu crawl/openai-whisper/ubuntu/.`

### Build GPU image

`podman build -t whisper-gpu:ubuntu crawl/openai-whisper/ubuntu/gpu/.`

### Run on single GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper-gpu:ubuntu
```

### Run on multiple GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --gpus 2 \
    localhost/whisper-gpu:ubuntu
```

### Run the STT model against .mp3 files

MODEL options:
- tiny.en, tiny, base.en, base, small.en, small, medium.en, medium, large, turbo

AUDIO options:

1. jfk-audio-inaugural-address-20-january-1961
1. jfk-audio-rice-university-12-september-1962

```sh
bash transcribe.sh medium.en jfk-audio-rice-university-12-september-1962
```


Resources:

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)