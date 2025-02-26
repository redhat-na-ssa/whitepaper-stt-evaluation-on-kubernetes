# Crawl

OpenAI Whisper interactive session with local audio files on a laptop/server:

- [x] Ubuntu
    - [x] CPU ~12G
    - [x] GPU ~22G
- [x] UBI
    - [ ] CPU
    - [ ] GPU

## Build CPU image

`podman build -t cpu-whisper crawl/openai-whisper/ubuntu/.`

## Build GPU image

`podman build -t gpu-whisper crawl/openai-whisper/ubuntu/gpu/.`

## Run on single GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/gpu-whisper:latest
```

## Run on multiple GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --gpus 2 \
    localhost/gpu-whisper:latest
```

## Evaluations

### Duration

```sh
time whisper audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 --model tiny.en > output/whisper-tiny-ubuntu-jfk-transcript-inaugural-address-20-january-1961-1-gpu-$(date +"%Y-%m-%d_%H-%M-%S").txt

real    0m27.260s
user    0m36.689s
sys     0m2.135s
```

### Accuracy

JiWER Metrics

```sh
python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-tiny-ubuntu-jfk-transcript-inaugural-address-20-january-1961-1-gpu-2025-02-26_20-37-29.txt
```

Resources:

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)