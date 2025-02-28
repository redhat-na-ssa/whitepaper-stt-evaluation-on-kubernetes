# Crawl

OpenAI Whisper interactive session with local audio files on a laptop/server:

- [x] Ubuntu
    - [x] CPU ~6G
    - [x] GPU ~22G
- [x] UBI
    - [ ] CPU
    - [ ] GPU

## Ubuntu

### Build CPU image

`podman build -t whisper-cpu:ubuntu crawl/openai-whisper/ubuntu/.`

### Build GPU image

`podman build -t whisper-gpu:ubuntu crawl/openai-whisper/ubuntu/gpu/.`

### Execute on single CPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    localhost/whisper-cpu:ubuntu
```

### Execute on single GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper-gpu:ubuntu
```

### Execute transcriptions

Whisper MODEL options:
- tiny.en, tiny, base.en, base, small.en, small, medium.en, medium, large, turbo

AUDIO options:

1. jfk-audio-inaugural-address-20-january-1961
1. jfk-audio-rice-university-12-september-1962

```sh
# launch whisper-cpu:ubuntu pod
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    localhost/whisper-cpu:ubuntu

# launch whisper-gpu:ubuntu pod
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper-gpu:ubuntu

# different model sizes transcribing jfk-audio-inaugural-address-20-january-1961
python3 evaluations/script.py \
        --model whisper \
        --model_size tiny.en \
        --base_image ubuntu \
        --platform ubuntu \
        --processor gpu \
        --input_file audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 \
        ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
        output

```

## Resources:

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
- [Dataset](https://www.openslr.org/12)