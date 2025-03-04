# Crawl

Crawl OpenAI Whisper STT model from Ubuntu on CPU to UBI on NVIDIA GPU

## Crawl procedure

In summary:

1. Access your Single Server
1. Clone this repo
1. Build the container images from Dockerfile for Ubuntu and UBI
1. Test the containers on CPU and GPU against a sample audio file
1. Run evaluation experiments
1. Build to OpenShift cluster
1. Test the containers on CPU and GPU against a sample audio file
1. Run evaluation experiments

### Single Server

```sh
# Step 0: Access your machine
ssh

# Step 1: Clone this repo
git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git

# Step 2: Move into repo
cd whitepaper-stt-evaluation-on-kubernetes 
```

### Whisper Ubuntu

```sh
# Step 0: Review the Ubuntu Dockerfile
cat crawl/openai-whisper/ubuntu/Dockerfile 

# Step 1: Build an Ubuntu CPU container image
podman build -t whisper:ubuntu crawl/openai-whisper/ubuntu/.

# Step 2: Review the available images
podman images

# Expected output
# REPOSITORY                TAG         IMAGE ID      CREATED        SIZE
# localhost/whisper         ubuntu      a2b133b6ef7f  5 seconds ago  6.65 GB
# docker.io/library/ubuntu  22.04       a24be041d957  5 weeks ago    80.4 MB

# Step 3: Run the image on CPU
podman run --rm -it \
  --name whisper-ubuntu-cpu \
  -v $(pwd)/data:/data:z \
  localhost/whisper:ubuntu /bin/bash

# Step 4: Test transcription and view the output
whisper audio-samples/harvard.wav | tee /tmp/harvard-whisper-transcription.txt

# Expected output
# 100%|█████████████████████████████████████| 1.51G/1.51G [00:46<00:00, 35.1MiB/s]
# /usr/local/lib/python3.10/dist-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
#   warnings.warn("FP16 is not supported on CPU; using FP32 instead")
# Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# Detected language: English
# [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 5: Compare output against ground truth
diff ground-truth/harvard.txt /tmp/harvard-whisper-transcription.txt

# Expected output
# 1,6c1,8
# < The stale smell of old beer lingers.
# < It takes heat to bring out the odor.
# < A cold dip restores health and zest.
# < A salt pickle tastes fine with ham.
# < Tacos al pastor are my favorite.
# < A zestful food is the hot cross bun.
# \ No newline at end of file
# ---
# > Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# > Detected language: English
# > [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# > [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# > [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# > [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# > [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# > [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 6: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have.

# Terminal 1 of 2
# Step 7: Stop the watch
Ctrl+c

# Terminal 2 of 2
# Step7: Stop the pod
exit
```

### Whisper Ubuntu on GPU

```sh
# Terminal 1 of 2
# Step 0: watch NVIDIA consumption
watch nvidia smi

# Terminal 2 of 2
# Step 1: Run the image on GPU
podman run --rm -it \
    --name whisper-ubuntu-gpu \
    -v $(pwd)/data:/data:z \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    localhost/whisper:ubuntu /bin/bash

# Terminal 2 of 2
# Step 2: Test transcription and view the output
whisper audio-samples/harvard.wav | tee /tmp/harvard-whisper-transcription.txt

# Expected output
# 100%|█████████████████████████████████████| 1.51G/1.51G [00:46<00:00, 35.1MiB/s]
# /usr/local/lib/python3.10/dist-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
#   warnings.warn("FP16 is not supported on CPU; using FP32 instead")
# Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# Detected language: English
# [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Terminal 2 of 2
# Step 3: Compare output against ground truth
diff ground-truth/harvard.txt /tmp/harvard-whisper-transcription.txt

# Expected output
# 1,6c1,8
# < The stale smell of old beer lingers.
# < It takes heat to bring out the odor.
# < A cold dip restores health and zest.
# < A salt pickle tastes fine with ham.
# < Tacos al pastor are my favorite.
# < A zestful food is the hot cross bun.
# \ No newline at end of file
# ---
# > Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# > Detected language: English
# > [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# > [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# > [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# > [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# > [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# > [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 4: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have.
- The model is downloading each time and we can pre-download the model 

# Terminal 1 of 2
# Step 4: Stop the watch
Ctrl+c

# Terminal 2 of 2
# Step 4: Stop the pod
exit
```

### Whisper UBI on CPU

```sh
# Step 0: Review the UBI Dockerfile
cat crawl/openai-whisper/ubi/Dockerfile

# Step 1: Build an UBI container image
podman build -t whisper:ubi crawl/openai-whisper/ubi/.

# Step 2: Review the available images
podman images

# Expected output
# REPOSITORY                                 TAG         IMAGE ID      CREATED             SIZE
# localhost/whisper                          ubi         bf845e793179  About a minute ago  7.06 GB
# localhost/whisper                          ubuntu      23908f6da923  11 minutes ago      6.65 GB
# registry.access.redhat.com/ubi8/python-39  <none>      b88c25db9cfd  2 weeks ago         917 MB
# docker.io/library/ubuntu                   22.04       a24be041d957  5 weeks ago         80.4 MB

# Step 3: Run the image on CPU
podman run --rm -it --name whisper-ubi-cpu \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi /bin/bash

# Step 4: Test transcription and view the output
whisper audio-samples/harvard.wav --output_dir /tmp/ --model_dir /tmp/

# Expected output
# 100%|█████████████████████████████████████| 1.51G/1.51G [00:46<00:00, 35.1MiB/s]
# /usr/local/lib/python3.10/dist-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
#   warnings.warn("FP16 is not supported on CPU; using FP32 instead")
# Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# Detected language: English
# [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 5: Compare output against ground truth
diff ground-truth/harvard.txt /tmp/harvard-whisper-transcription.txt

# Expected output
# 1,6c1,8
# < The stale smell of old beer lingers.
# < It takes heat to bring out the odor.
# < A cold dip restores health and zest.
# < A salt pickle tastes fine with ham.
# < Tacos al pastor are my favorite.
# < A zestful food is the hot cross bun.
# \ No newline at end of file
# ---
# > Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# > Detected language: English
# > [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# > [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# > [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# > [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# > [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# > [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 6: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have. 
- Need to build the images with the models.
```

### Whisper UBI on GPU

```sh
# Step 0: Terminal 1 of 2 - watch NVIDIA consumption
watch nvidia smi

# Step 0: Terminal 2 of 2 - Run the image on GPU
podman run --rm -it --name whisper-ubi-gpu-harvard \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi /bin/bash

# Step 1: Test transcription and view the output
whisper audio-samples/harvard.wav --output_dir /tmp/ --model_dir /tmp/

# Expected output
# 100%|█████████████████████████████████████| 1.51G/1.51G [00:46<00:00, 35.1MiB/s]
# /usr/local/lib/python3.10/dist-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
#   warnings.warn("FP16 is not supported on CPU; using FP32 instead")
# Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# Detected language: English
# [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 5: Compare output against ground truth
diff ground-truth/harvard.txt /tmp/harvard-whisper-transcription.txt

# Expected output
# 1,6c1,8
# < The stale smell of old beer lingers.
# < It takes heat to bring out the odor.
# < A cold dip restores health and zest.
# < A salt pickle tastes fine with ham.
# < Tacos al pastor are my favorite.
# < A zestful food is the hot cross bun.
# \ No newline at end of file
# ---
# > Detecting language using up to the first 30 seconds. Use `--language` to specify the language
# > Detected language: English
# > [00:00.800 --> 00:03.620]  The stale smell of old beer lingers.
# > [00:04.420 --> 00:06.200]  It takes heat to bring out the odor.
# > [00:07.040 --> 00:09.360]  A cold dip restores health and zest.
# > [00:09.980 --> 00:12.060]  A salt pickle tastes fine with ham.
# > [00:12.660 --> 00:14.360]  Tacos al pastor are my favorite.
# > [00:15.120 --> 00:17.500]  A zestful food is the hot cross bun.

# Step 6: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have.
```

## Benchmarking

### Harvard data

TODO for evaluation.py check FP

```sh
# Terminal 1 of 2
nohup python3 data/evaluations/gpu_logger.py &

# Terminal 2 of 2

## Whisper Ubuntu CPU
podman run --rm -it --name whisper-ubuntu-cpu -v $(pwd)/data:/data:z localhost/whisper:ubuntu /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluations/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluations/evaluation.py --model_name $model
done

## Review the data captured runn `sort -u /tmp/*.csv`

## Copy the .csv data to local output dir
cp /tmp/*.csv output/.

## Whisper Ubuntu GPU
podman run --rm -it --name whisper-ubuntu-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data:/data:z localhost/whisper:ubuntu /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluations/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluations/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
cp /tmp/*.csv output/.

## Whisper UBI CPU
podman run --rm -it --name whisper-ubi-cpu -v $(pwd)/data:/data:z localhost/whisper:ubi /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluations/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluations/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
## You may have to chmod 777 data/output
cp /tmp/*.csv output/.

## Whisper UBI GPU
podman run --rm -it --name whisper-ubi-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data:/data:z localhost/whisper:ubi /bin/bash

## For loop through each model twice to capture pre-downloaded performance
for model in tiny.en base.en small.en medium.en large turbo; do
  # First run
  python3 evaluations/evaluation.py --model_name $model
  # Second run with models cached
  python3 evaluations/evaluation.py --model_name $model
done

## Copy the .csv data to local output dir
## You may have to chmod 777 data/output
cp /tmp/*.csv output/.

# Step 0: Copy output to host from pod
cp output/pod_gpu_usage.csv .

# Step 0: Stop the gpu_logger.py script
ps aux | grep gpu_logger
```

## Whisper Optimizations

### Best Initial Test Command

```sh
whisper ground-truth/jfk-audio-inaugural-address-20-january-1961.txt \
    --model large \
    --language en \
    --beam_size 10 \
    --temperature 0 \
    --patience 2 \
    --suppress_tokens -1 \
    --compression_ratio_threshold 2.0 \
    --logprob_threshold -0.5 \
    --no_speech_threshold 0.4
```

Initial experimentation parameters:

- Try a larger model (medium or large) if you are using tiny, base, or small.
- If you know the language, set it explicitly to avoid misdetections.
- Adjust decoding:
  - Beam Search (--beam_size): Increases accuracy by considering multiple possibilities.
  - Temperature (--temperature): Lower values (0-0.2) make outputs more deterministic.
  - Patience (--patience): Allows the model to explore better alternatives.
- Avoids unwanted symbols that could lower accuracy.
- Improve robustness against hallucinations:
  - Compression Ratio Threshold (--compression_ratio_threshold): Filters out bad transcriptions.
  - Log Probability Threshold (--logprob_threshold): Removes segments with low confidence.
  - No Speech Threshold (--no_speech_threshold): Filters out silent parts.
- Enable word timestamps:
  - Useful for reviewing accuracy at the word level.

### Here’s a breakdown of some key Whisper parameters and what they do:

```sh
# Basic Parameters
audio: The input audio file(s) to be transcribed.
--model MODEL: Specifies which Whisper model to use. Example values: tiny, base, small, medium, large, turbo (default: turbo).
--model_dir MODEL_DIR: Path where model files are stored (default is ~/.cache/whisper).
--device DEVICE: Hardware for processing. Options:
cpu (default) for CPU usage.
cuda or mps for GPU acceleration (if available).
Output Parameters
--output_dir OUTPUT_DIR: Where to save the output files.
--output_format {txt,vtt,srt,tsv,json,all}: Format of the transcription output.
txt: Plain text.
vtt: WebVTT (subtitles).
srt: SubRip (subtitles).
tsv: Tab-separated values.
json: JSON format.
all: Saves in all formats.


# Transcription & Translation
--task {transcribe,translate}:
    transcribe: Converts spoken audio to text in the same language.
    translate: Translates non-English audio to English.
--language <language>: Manually specify the spoken language (e.g., en for English). If omitted, Whisper auto-detects.

# Decoding Parameters (Affecting Accuracy & Speed)
--temperature TEMPERATURE: Controls randomness (default 0 means deterministic, higher values increase variation).
--best_of BEST_OF: Number of candidates when using sampling (temperature > 0).
--beam_size BEAM_SIZE: Number of beams for beam search (used when temperature = 0).
--patience PATIENCE: Affects beam search, allowing it to consider longer alternatives (default 1.0).
--length_penalty LENGTH_PENALTY: Adjusts preference for shorter or longer transcriptions.

# Error Handling & Robustness
--temperature_increment_on_fallback TEMPERATURE_INCREMENT_ON_FALLBACK: Increases temperature when decoding fails, making the model try different outputs.
--compression_ratio_threshold COMPRESSION_RATIO_THRESHOLD: Helps detect hallucinations (false transcriptions) by analyzing compression ratios.
--logprob_threshold LOGPROB_THRESHOLD: If average log probability of words is too low, the output is considered unreliable.
--no_speech_threshold NO_SPEECH_THRESHOLD: If the probability of silence (<|nospeech|>) is high, the segment is skipped.

# Formatting & Word Timing
--word_timestamps WORD_TIMESTAMPS: Enables word-level timestamps (default: False).
--prepend_punctuations & --append_punctuations: Defines how punctuation is attached to words when using --word_timestamps True.
--highlight_words HIGHLIGHT_WORDS: Underlines words in subtitles as they are spoken.

# Performance Tweaks
--threads THREADS: Number of CPU threads to use.
--fp16 FP16: Uses 16-bit floating-point precision for inference (default: True for GPUs, False for CPU).
--clip_timestamps CLIP_TIMESTAMPS: Allows processing only specific audio segments.
```

## Resources

- [Official NVIDIA docs](https://docs.nvidia.com/ai-enterprise/deployment/rhel-with-kvm/latest/podman.html)
- [Allow access to host GPU](https://thenets.org/how-to-use-nvidia-gpu-on-podman-rhel-fedora/)
- [Dataset](https://www.openslr.org/12)