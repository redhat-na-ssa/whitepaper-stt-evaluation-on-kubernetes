# Whisper on UBI

Some key changes in the Dockerfiles:

Overall
    -(RHEL 9)[https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/building_running_and_managing_containers/index#con_configuring-container-registries_working-with-container-registries] is more like Ubuntu 22.04 than RHEL 8 in terms of package versions, kernel, and security features.
        - ships with Linux kernel 5.14, which is closer to Ubuntu 22.04’s Linux kernel 5.15.
        - Uses glibc 2.34 (same as Ubuntu 22.04).
        - RHEL 9 and Ubuntu 22.04: OpenSSL 3, system-wide cryptographic policies.
        - RHEL 9 and Ubuntu 22.04 both include newer versions of Python (Python 3.9+), Node.js, and container tools.
    - Basic tooling, gcc gcc-c++ make automake autoconf libtool git diffutils
    - Built ffmpeg from source
    - Change permissions in order to share the volume with sample  audio files.
Minimal
    - Install Python 3.12
Platform
    - Using the Python 3.12 prebuilt language image.

## Whisper UBI on CPU

What is (UBI)[https://catalog.redhat.com/software/base-images]? 

- **Built from a subset of RHEL content:** Red Hat Universal Base images are built from a subset of normal Red Hat Enterprise Linux content.
- **Redistributable:** UBI images allow standardization for Red Hat customers, partners, ISVs, and others. With UBI images, you can build your container images on a foundation of official Red Hat software that can be freely shared and deployed.
- **Provide a set of four base images:** micro, minimal, standard, and init.
- **Provide a set of pre-built language runtime container images:** The runtime images based on Application Streams provide a foundation for applications that can benefit from standard, supported runtimes such as python, perl, php, dotnet, nodejs, and ruby.
- **Provide a set of associated DNF repositories:** DNF repositories include RPM packages and updates that allow you to add application dependencies and rebuild UBI container images.
  - The ubi-9-baseos repository holds the redistributable subset of RHEL packages you can include in your container.
  - The ubi-9-appstream repository holds Application streams packages that you can add to a UBI image to help you standardize the environments you use with applications that require particular runtimes.
  - **Adding UBI RPMs:** You can add RPM packages to UBI images from preconfigured UBI repositories. If you happen to be in a disconnected environment, you must allowlist the UBI Content Delivery Network (https://cdn-ubi.redhat.com) to use that feature. For more information, see the Red Hat Knowledgebase solution Connect to https://cdn-ubi.redhat.com.
- **Licensing:** You are free to use and redistribute UBI images, provided you adhere to the Red Hat Universal Base Image End User Licensing Agreement.

## Whisper Platform Python UBI

```sh
# Terminal 1 of 2
# Step 0: watch NVIDIA consumption
watch -n 0.1 nvidia-smi

# Step 0: Review the UBI Dockerfile
cat crawl/openai-whisper/ubi/Dockerfile

# Step 1: Build an UBI container image
podman build -t whisper:ubi9 crawl/openai-whisper/ubi/platform/.

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
    localhost/whisper:ubi9 /bin/bash

# Step 4: Test transcription and view the output
time whisper input-samples/harvard.wav --output_dir /tmp/ --model_dir /tmp/ --output_format txt --language en --task transcribe

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

# Step 6: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have. 
```

## Whisper Platform Python UBI on GPU

```sh
# Step 0: Terminal 1 of 2 - watch NVIDIA consumption
watch -n 0.1 nvidia-smi

# Step 0: Terminal 2 of 2 - Run the image on GPU
podman run --rm -it --name whisper-ubi-gpu-harvard \
    --security-opt=label=disable \
    --device nvidia.com/gpu=all \
    -v $(pwd)/data:/data:z \
    localhost/whisper:ubi /bin/bash

# Step 1: Test transcription and view the output
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

# Step 5: Compare output against ground truth
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

# Step 6: Observations
- Whisper prints metadata `Detecting language`  at the beginning, not part of the actual transcription but Whisper's internal logging
- Whisper adds timestamps before each transcribed line the ground-truth file does not have.
```
