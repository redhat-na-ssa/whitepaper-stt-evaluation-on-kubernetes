# Whisper on Ubuntu

If you follow the steps from https://github.com/openai/whisper?tab=readme-ov-file#setup, there are some basic packages to install:

1. ffmpeg
1. Python
1. Openai-whisper

## Review the Dockerfile

```sh
cat crawl/openai-whisper/ubuntu/Dockerfile 
```

## Build the Dockerfile embedding the model

```sh
for model in tiny.en base.en small.en medium.en large turbo; do
  tag="whisper:${model}-ubuntu"
  echo "🔧 Building image: $tag"
  podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubuntu/.
done
```

NOTE: models will be saved in `/root/.cache/whisper/` in each container image

## Test the containers

### Harvard

[Harvard Speech Recognition Dataset](https://www.kaggle.com/datasets/tmshaikh/speech-recognition-data) provides a way to smoke test before running against more complex audio data.

#### tiny.en

whisper tiny.en ubuntu cpu harvard fast

```sh
# start the container on cpu
podman run --rm -it \
  --name whisper-tiny-en-ubuntu \
  -v $(pwd)/data/:/data/:z \
  whisper:tiny.en-ubuntu /bin/bash

# default whisper command
time whisper input-samples/harvard.wav \
  --model tiny.en \
  --model_dir /tmp/ \
  --output_dir metrics/ \
  --output_format txt \
  --language en \
  --task transcribe \
  --fp16 False

# calculate WER 0.00% means the transcription matches the ground truth exactly
python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate WIL 0.00% means the hypothesis is a perfect match with the reference
python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

# calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

# stop the container
exit
```

1. whisper tiny.en ubuntu cpu harvard complex

    ```sh
    # start the container on cpu
    podman run --rm -it --name whisper-tiny-en-ubuntu -v $(pwd)/data/:/data/:z whisper:tiny.en-ubuntu /bin/bash

    # default whisper command
    time whisper input-samples/harvard.wav \
    --model tiny.en \
    --model_dir /tmp/ \
    --output_dir metrics/ \
    --output_format txt \
    --language en \
    --task transcribe \
    --fp16 False \
    --beam_size 10 \
    --temperature 0 \
    --patience 2 \
    --suppress_tokens -1 \
    --compression_ratio_threshold 2.0 \
    --logprob_threshold -0.5 \
    --no_speech_threshold 0.4

    # calculate WER 0.00% means the transcription matches the ground truth exactly
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```

1. whisper tiny.en ubuntu gpu harvard fast

    ```sh
    # start the container on gpu
    podman run --rm -it --name whisper-tiny-en-ubuntu-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/data/:z whisper:tiny.en-ubuntu /bin/bash

    # default whisper command
    whisper input-samples/harvard.wav \
    --model tiny.en \
    --model_dir /tmp/ \
    --output_dir metrics/ \
    --output_format txt \
    --language en \
    --task transcribe

    # calculate WER 0.00% means the transcription matches the ground truth exactly
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```

1. whisper tiny.en ubuntu gpu harvard complex

    ```sh
    # start the container on gpu
    podman run --rm -it --name whisper-tiny-en-ubuntu-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/data/:z whisper:tiny.en-ubuntu /bin/bash

    # default whisper command
    whisper input-samples/harvard.wav \
    --model tiny.en \
    --model_dir /tmp/ \
    --output_dir metrics/ \
    --output_format txt \
    --language en \
    --task transcribe \
    --beam_size 10 \
    --temperature 0 \
    --patience 2 \
    --suppress_tokens -1 \
    --compression_ratio_threshold 2.0 \
    --logprob_threshold -0.5 \
    --no_speech_threshold 0.4

    # calculate WER 0.00% means the transcription matches the ground truth exactly
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```
