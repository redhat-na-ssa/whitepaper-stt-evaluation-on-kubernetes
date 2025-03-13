# Whisper on Ubuntu

If you follow the steps from https://github.com/openai/whisper?tab=readme-ov-file#setup, there are some basic packages to install:

1. ffmpeg
1. Python
1. Openai-whisper

Some key changes in the Dockerfile:

- Set Python 3.12 as default: Ensures scripts use the right Python version.
    - Ubuntu 22.04 only includes Python 3.10 in its official repositories. To install Python 3.12, you need to add a custom repository or build it from source. The easiest way is to use the deadsnakes PPA.
    - Added software-properties-common: Required to add PPAs.
    - Added python3.12-venv and python3.12-dev: Useful for virtual environments and compiling packages.
- Preconfigure the timezone by linking /etc/localtime and setting /etc/timezone to Etc/UTC (or any desired timezone).
- Ensure DEBIAN_FRONTEND=noninteractive is set to prevent interactive prompts.
- Run dpkg-reconfigure -f noninteractive tzdata to apply the changes without user input.
- Used deadsnakes PPA: This provides Python 3.12.
- Upgraded pip: Avoids potential issues with package installations.

### Whisper Ubuntu

```sh
# Terminal 1 of 2
# Step 0: watch NVIDIA consumption
watch -n 0.1 nvidia-smi

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

# TODO set umask to 0002

# Step 4: Test transcription and view the output
whisper input-samples/harvard.wav

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

# Step 5: Basic improvements

# Write output to /tmp directory
# Format the output to txt
# Set the task to transcribe
# Set language to english
# Set FP FP16 is not supported on CPU; using FP32 instead
time whisper input-samples/harvard.wav

# Expected Output
# real    0m13.340s
# user    2m29.528s
# sys     0m11.067s

time whisper input-samples/harvard.wav --output_dir /tmp/ --output_format txt --language en --task transcribe

# Expected Output
# real    0m11.990s
# user    1m58.327s
# sys     0m10.308s

# Step 5: Compare output against ground truth
diff --strip-trailing-cr ground-truth/harvard.txt /tmp/harvard.txt

# The diff output you posted indicates that the only difference between the two files is a missing newline at the end of /tmp/harvard.txt.

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
- Changing the model size with --model parameter

# Terminal 1 of 2
# Step 4: Stop the watch
Ctrl+c

# Terminal 2 of 2
# Step7: Stop the pod
exit
```

### Whisper Ubuntu on GPU

TODO test on RHEL VM on AWS with GPU (NOT RHEL AI image)

```sh
# Terminal 1 of 2
# Step 0: watch NVIDIA consumption
watch -n 0.1 nvidia-smi

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
time whisper input-samples/harvard.wav --output_dir /tmp/ --output_format txt --language en --task transcribe

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
diff ground-truth/harvard.txt /tmp/harvard.txt

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