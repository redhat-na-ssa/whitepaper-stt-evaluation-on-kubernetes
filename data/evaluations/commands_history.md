# Commands run

## Whisper

### Ubuntu

#### 1 GPU

```sh
# podman run
podman run --rm -it \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper-gpu:ubuntu

## run
bash evaluations/transcribe.sh medium.en jfk-audio-rice-university-12-september-1962
real    3m14.185s
user    2m9.806s
sys     0m6.838s

```