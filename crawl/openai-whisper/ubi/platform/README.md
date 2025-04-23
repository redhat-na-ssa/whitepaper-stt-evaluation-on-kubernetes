# Whisper on UBI

## What is (UBI)[https://catalog.redhat.com/software/base-images]? 

- **Built from a subset of RHEL content:** Red Hat Universal Base images are built from a subset of normal Red Hat Enterprise Linux content.
- **Redistributable:** UBI images allow standardization for Red Hat customers, partners, ISVs, and others. With UBI images, you can build your container images on a foundation of official Red Hat software that can be freely shared and deployed.
- **Provide a set of four base images:** micro, minimal, standard, and init.
- **Provide a set of pre-built language runtime container images:** The runtime images based on Application Streams provide a foundation for applications that can benefit from standard, supported runtimes such as python, perl, php, dotnet, nodejs, and ruby.
- **Provide a set of associated DNF repositories:** DNF repositories include RPM packages and updates that allow you to add application dependencies and rebuild UBI container images.
  - The ubi-9-baseos repository holds the redistributable subset of RHEL packages you can include in your container.
  - The ubi-9-appstream repository holds Application streams packages that you can add to a UBI image to help you standardize the environments you use with applications that require particular runtimes.
  - **Adding UBI RPMs:** You can add RPM packages to UBI images from preconfigured UBI repositories. If you happen to be in a disconnected environment, you must allowlist the UBI Content Delivery Network (https://cdn-ubi.redhat.com) to use that feature. For more information, see the Red Hat Knowledgebase solution Connect to https://cdn-ubi.redhat.com.
- **Licensing:** You are free to use and redistribute UBI images, provided you adhere to the Red Hat Universal Base Image End User Licensing Agreement.

# Whisper on UBI

Some of the packages that were as simple as a `pip install` on Ubuntu are not available and require a little more effort:

1. ffmpeg
1. Python
1. Openai-whisper

We also have the option of building a minimal container.

## Review the Dockerfiles

Some key changes in the Dockerfiles:

Overall
    -(RHEL 9)[https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/building_running_and_managing_containers/index#con_configuring-container-registries_working-with-container-registries] is more like Ubuntu 22.04 than RHEL 8 in terms of package versions, kernel, and security features.
        - ships with Linux kernel 5.14, which is closer to Ubuntu 22.04’s Linux kernel 5.15.
        - Uses glibc 2.34 (same as Ubuntu 22.04).
        - RHEL 9 and Ubuntu 22.04: OpenSSL 3, system-wide cryptographic policies.
        - RHEL 9 and Ubuntu 22.04 both include newer versions of Python (Python 3.9+), Node.js, and container tools.
    - Basic tooling, gcc gcc-c++ make automake autoconf libtool git diffutils
    - Built ffmpeg from source
    - Change permissions in order to share the volume with sample  audio files

```sh
# review the platform dockerfile
cat crawl/openai-whisper/ubi/platform/Dockerfile  
```

## Build the Dockerfile embedding the model
    
```sh
# build the platform dockerfile
for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper:${model}-ubi9-minimal"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi/platform/.
done
```

## Test the UBI9 containers

### Harvard

#### tiny.en

1. whisper tiny.en ubi9 cpu harvard fast

    ```sh
    # start the container on cpu
    podman run --rm -it --name whisper-tiny-en-ubi9 -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubi9 /bin/bash

    # default whisper command
    time whisper /outside/input-samples/harvard.wav \
    --model tiny.en \
    --model_dir /tmp/ \
    --output_dir metrics/ \
    --output_format txt \
    --language en \
    --task transcribe \
    --fp16 False \
    --threads 8

    # calculate WER 0.00% means the transcription matches the ground truth exactly
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```

1. whisper tiny.en ubi9 cpu harvard complex

    ```sh
    # start the container on cpu
    podman run --rm -it --name whisper-tiny-en-ubi9 -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubi9 /bin/bash

    # default whisper command
    time whisper /outside/input-samples/harvard.wav \
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
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```

1. whisper tiny.en ubi9 gpu harvard fast

    ```sh
    # start the container on gpu
    podman run --rm -it --name whisper-tiny-en-ubi9-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubi9 /bin/bash

    # default whisper command
    whisper input-samples/harvard.wav \
    --model tiny.en \
    --model_dir /tmp/ \
    --output_dir metrics/ \
    --output_format txt \
    --language en \
    --task transcribe

    # calculate WER 0.00% means the transcription matches the ground truth exactly
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```

1. whisper tiny.en ubi9 gpu harvard complex

    ```sh
    # start the container on gpu
    podman run --rm -it --name whisper-tiny-en-ubi9-gpu --security-opt=label=disable --device nvidia.com/gpu=all -v $(pwd)/data/:/outside/:z whisper:tiny.en-ubi9 /bin/bash

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
    python3 -c "from jiwer import wer; print(f'WER: {wer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"
    
    # calculate MER 0.00% means there were no substitutions, deletions, or insertions and an exact match
    python3 -c "from jiwer import mer; print(f'MER: {mer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate WIL 0.00% means the hypothesis is a perfect match with the reference
    python3 -c "from jiwer import wil; print(f'WIL: {wil(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')"

    # calculate CER 0.00% means characters in your hypothesis match the characters in your reference exactly
    python3 -c "from jiwer import cer; print(f'CER: {cer(open(\"/outside/ground-truth/harvard.txt\").read(), open(\"metrics/harvard.txt\").read()):.2%}')

    # stop the container
    exit
    ```


|[Previous <- Ubuntu with Whisper](ubuntu/README.md)|[Next -> UBI9 Platform with Whisper](../ubi/platform/README.md)|
|-|-|