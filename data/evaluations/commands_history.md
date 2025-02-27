# Commands run

## Whisper

### Ubuntu

#### 1 GPU

```sh
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/gpu-whisper:latest
```

```sh
MODEL=tiny.en
INPUT=jfk-audio-inaugural-address-20-january-1961

# tiny
time whisper audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 --model tiny.en > output/whisper-tiny.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt

real    0m28.230s
user    0m38.608s
sys     0m1.986s

python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-tiny.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt evaluations

Word Error Rate (WER): 44.74%
Match Error Rate (MER): 34.66%
Word Information Lost (WIL): 44.77%
Word Information Preserved (WIP): 55.23%
Character Error Rate (CER): 54.26%
```

```sh
MODEL=base.en
INPUT=jfk-audio-inaugural-address-20-january-1961
# base
time whisper audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 --model base.en > output/whisper-base.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt

real    0m27.352s
user    0m38.796s
sys     0m2.020s

python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-base.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt evaluations

Word Error Rate (WER): 31.39%
Match Error Rate (MER): 26.21%
Word Information Lost (WIL): 34.59%
Word Information Preserved (WIP): 65.41%
Character Error Rate (CER): 33.34%

```sh
# small
MODEL=small.en
INPUT=jfk-audio-inaugural-address-20-january-1961

time whisper audio-samples/jfk-audio-inaugural-address-20-january-1961.mp3 --model small.en > output/whisper-small.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt

real    1m6.637s
user    0m55.101s
sys     0m3.160s

python3 evaluations/wer.py ground-truth/jfk-transcript-inaugural-address-20-january-1961.txt output/whisper-small.en-ubuntu-jfk-audio-inaugural-address-20-january-1961-gpu-1-2025-02-26.txt evaluations/

Word Error Rate (WER): 37.73%
Match Error Rate (MER): 30.63%
Word Information Lost (WIL): 40.61%
Word Information Preserved (WIP): 59.39%
Character Error Rate (CER): 44.43%
```