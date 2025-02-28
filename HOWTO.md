# Manual setup procedure

1. Test on RHEL with Ubuntu container
1. Test on RHEL with a UBI container
1. Test on OpenShift

## Whisper

### Whisper - Test on RHEL with a Ubuntu container

This tests Whisper in a Ubuntu container

```sh
# search for an ubuntu container base image
podman search ubuntu --list-tags

# pull and run an ubuntu image
podman run -it --name ubuntu-whisper docker.io/library/ubuntu

# as root, update apt, install python3-venv
sudo apt update

# install python
apt install -y python3-venv # you have to complete prompt

# install pip
apt install -y python3-pip

# install ffmpeg
apt install -y ffmpeg 

# install wget
apt install -y wget

# create and activate a python virtual env
python3 -m venv venv
. venv/bin/activate

# install openai-whisper
pip install openai-whisper
```

```sh
# download an audio file 
# https://www.jfklibrary.org/asset-viewer/archives/jfkwha
# https://www.jfklibrary.org/asset-viewer/archives/JFKWHA-127-002
# wget -O filename "url"

# inference
whisper kennedy_1962.mp4 --model tiny.en

```sh
# output
/venv/lib/python3.12/site-packages/whisper/transcribe.py:126: UserWarning: FP16 is not supported on CPU; using FP32 instead
  warnings.warn("FP16 is not supported on CPU; using FP32 instead")
[00:00.000 --> 00:07.000]  The present remarks at Rice Stadium in Houston, Texas, September 12, 1962.
[00:07.000 --> 00:17.700]  President Pipsis, Mr. Vice President, Governor, Congressman Thomas, Senator
[00:17.700 --> 00:27.100]  Wiley and Congressman Miller, Mr. Webb, Val, scientists, distinguished guests, ladies and gentlemen.
```

```sh
# restarting the stopped container
podman start --interactive --attach upbeat_khorana

# active the virtual env
. venv/bin/activate

# inference
whisper kennedy_1962.mp4 --model base.en
```

#### Inference

Use Cases:

1. Real-time dictation
1. Offline file dictation (can you fastforward?)

Bind Mount a Local Directory
You can mount a local directory containing your audio file to the container using the -v flag:

```sh
podman run --rm -v /path/to/local/audio:/data/audio:Z ubuntu-whisper-container venv/bin/whisper /data/audio/your_audio.mp4 --model tiny.en
```

Copy the File Into a Running Container
If the container is already running, you can copy the file into it using:

```sh
# copy
podman cp your_audio.mp4 <container_id>:/data/audio/

# inference
podman exec <container_id> venv/bin/whisper /data/audio/your_audio.mp4 --model tiny.en
```

 Use --env for Dynamic File Passing
 Modify the Containerfile to use an environment variable for the file path:

```sh
# dockerfile modification
CMD ["sh", "-c", "venv/bin/whisper $AUDIO_FILE --model tiny.en"]

# pass file as env
podman run --rm -v /path/to/local/audio:/data/audio:Z -e AUDIO_FILE=/data/audio/your_audio.mp4 ubuntu-whisper-container
```

### Performance

Time the execution
Real: Total elapsed time
User: CPU time spent in user mode
Sys: CPU time spent in kernel mode

```sh
time podman run --rm -v /path/to/local/audio:/data/audio:Z ubuntu-whisper-container venv/bin/whisper /data/audio/your_audio.mp4 --model tiny.en
```

Measure GPU Utilization (if applicable)

```sh
podman run --rm --runtime=nvidia --gpus all ubuntu-whisper-container nvidia-smi

watch -n 1 nvidia-smi
```

Measure CPU & Memory Usage
Max Resident Set Size (memory usage)
CPU Time (user/sys)
Elapsed Time (real)

```sh
podman run --rm -v /path/to/local/audio:/data/audio:Z ubuntu-whisper-container /usr/bin/time -v venv/bin/whisper /data/audio/your_audio.mp4 --model tiny.en
```

Measure Word Error Rate (WER) for Accuracy
To evaluate transcription accuracy, compare the model’s output with a ground truth transcript:

Profiling with cProfile (Python)
For deeper performance insights, profile function calls:

```sh

```

### Whisper - Test on RHEL with UBI8 container

This tests pip installs Whisper in a virtual environment and runs it from the command line with a local .mp4 file

Step 1: Write a Whisper UBI8 Image

```sh
FROM registry.redhat.io/ubi8/python-39

# Switch to root user
USER root

# Install dependencies in a single step to reduce layers
RUN yum -y install \
    gcc gcc-c++ make automake autoconf libtool git \
    && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum

# Clone and build FFmpeg in one step
RUN git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git ffmpeg && \
    cd ffmpeg && \
    ./configure --disable-x86asm && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf ffmpeg

# Install whisper
RUN pip install openai-whisper

# Switch back to default user
USER default

# Default command to process the audio file using ffmpeg & whisper
CMD ["/bin/bash", "-c", "if [ -n \"$AUDIO_FILE\" ]; then ffmpeg -i \"$AUDIO_FILE\" -ar 16000 -ac 1 -c:a pcm_s16le /app/processed.wav && whisper /app/processed.wav; else exec /bin/bash; fi"]
```

Build the Whisper Image

```sh
podman login registry.redhat.io

podman build --format=docker -t ubi8-whisper ubi8/.
```

Run the image

```sh
podman run --name whisper --rm -it \
    -v $(pwd)/sample.wav:/app/sample.wav \
    -e AUDIO_FILE=/app/sample.wav \
    my_ffmpeg_whisper_image
```

### Whisper - Test on OpenShift with a UBI container

This tests Whisper in a UBI container on OpenShift

```sh
APP_NAME=whisper
APP_LABEL="app.kubernetes.io/part-of=${APP_NAME}"

oc new-project "${APP_NAME}"

# configure new build config
oc new-build \
  -n "${NAMESPACE}" \
  --name "${APP_NAME}" \
  -l "${APP_LABEL}" \
  --strategy docker \
  --binary

# patch image stream to resolve local
oc patch imagestream \
  "${APP_NAME}" \
   --type=merge \
  --patch '{"spec":{"lookupPolicy":{"local":true}}}'

# start build from local folder
oc start-build \
  -n "${NAMESPACE}" \
  "${APP_NAME}" \
  --follow \
  --from-dir ubi

# run a container on openshift like docker
oc run \
  -it --rm \
  --image whisper \
  --restart=Never \
  whisper -- /bin/bash
```

### - Test on OpenShift with vLLM

New project

```sh
oc new-project whisper-tiny
```

Create a Persistent Volume for model

```sh
oc create -f ocp/vllm/pv.yaml
```

Create a vLLM deployment with whisper

```sh
oc create -f ocp/vllm/deployment.yaml
```

Expose API

```sh
oc expose deploy whisper-tiny
oc expose svc whisper-tiny --target-port 8000
```

Smoke test

```sh
WHISPER_ENDPOINT=$(oc get route whisper-tiny --template='http://{{.spec.host}}')
curl $WHISPER_ENDPOINT/v1/models
```

Smoke test API

> Note this will throw an Internal Server Error at the moment: https://github.com/vllm-project/vllm/pull/12909

```sh
curl -X POST $WHISPER_ENDPOINT/v1/audio/transcriptions \                           
-H 'accept: application/json' \ 
-H 'Content-Type: multipart/form-data' \
-F 'file=@test.mp4;type=audio/mpeg' \
-F 'model=openai/whisper-tiny' \
-F 'response_format=json' \
-F 'stream=true'
```

### Test on OpenShift with Triton
> TODO

### Test on OpenShift with NIM
> TODO

## Faster Whisper

### Test on RHEL with Ubuntu container

> Note: This test does not require GPUs

```sh
podman run \
  --rm \
  --detach \
  --publish 8000:8000 \
  --name speaches \
  --volume hf-hub-cache:/home/ubuntu/.cache/huggingface/hub \
  ghcr.io/speaches-ai/speaches:latest-cpu
```

Smoke test

> Note: You can also access the server's web browser using a UI and upload an audio file there

```sh
ENDPOINT_URL='http://localhost:8000'  # replace with VM endpoint
curl $ENDPOINT_URL/v1/models
```

Smoke test audio file

```sh
curl -X POST $ENDPOINT_URL/v1/audio/transcriptions -H 'accept: application/json' -F 'model=Systran/faster-whisper-tiny.en' -F 'stream=true' -F 'file=@test.mp4'
``` 

### Test on OpenShift with Ubuntu container 

New project

```sh
oc new-project faster-whisper
```

Build the Faster Whisper server

```sh
oc create -f ocp/faster-whisper/imagestream.yaml
oc create -f ocp/faster-whisper/buildconfig.yaml
```

Follow the build and wait for completion

```sh
oc logs -f faster-whisper-1-build 
```

Create a SA and assign `anyuid` permissions

```sh
oc create sa sa-with-anyuid
oc adm policy add-scc-to-user anyuid -z sa-with-anyuid
```

Create Faster Whisper model server

```sh
oc create -f ocp/faster-whisper/deployment.yaml
```

Expose API

```sh
oc expose deploy faster-whisper-server
oc expose svc faster-whisper-server --target-port 8000
```

Smoke test

```sh
FASTER_WHISPER_ENDPOINT=$(oc get route faster-whisper-server --template='http://{{.spec.host}}')
curl $FASTER_WHISPER_ENDPOINT/v1/models
```

Smoke test audio file

```sh
curl -X POST $FASTER_WHISPER_ENDPOINT/v1/audio/transcriptions -H 'accept: application/json' -F 'model=Systran/faster-whisper-tiny.en' -F 'stream=true' -F 'file=@test.mp4'
```

## Riva

Export NGC credentials

```sh
export NGC_API_KEY="<YOUR NGC API KEY>"
```

Download helm chart

```sh
helm fetch https://helm.ngc.nvidia.com/nvidia/riva/charts/riva-api-2.18.0.tgz \
        --username=\$oauthtoken --password=$NGC_API_KEY --untar
```

Edit the `values.yaml` with

1. `ngcCredentials` put in your `NGC_API_KEY` and `email`
1. `persistentVolumeClaim` - change `usePVC` to `true` and set `storageClassName` (e.g. `gp3-csi` in AWS) and set `storageAccessMode` to `ReadWriteOnce`


Create project

```sh
oc new-project riva
```

Assign RBAC permissions to service account for riva

```sh
oc adm policy add-scc-to-user nonroot-v2 -z default
```

Deploy


```sh
helm install riva-api riva-api
```

Fix secret

> There is a bug in the helm chart and requires to manually create the model pull secret

```sh
oc create secret generic modelpullsecret --from-literal=apikey=$NGC_API_KEY
```

Riva exposes a gRPC API instead of HTTP, so it needs a client

```sh
oc create -f ocp/riva/client.yaml
```

Exec into pod

```sh
export cpod=`oc get pods | cut -d " " -f 1 | grep riva-client`
oc exec --stdin --tty $cpod /bin/bash
```

From inside the shell

```sh
riva_streaming_asr_client --print_transcripts    --audio_file=/opt/riva/wav/en-US_sample.wav    --automatic_punctuation=true    --riva_uri=riva-api:50051
```

## Reference

- [Whisper GitHub](https://github.com/openai/whisper?tab=readme-ov-file#available-models-and-languages)
- <https://tex.stackexchange.com/questions/101717/converting-markdown-to-latex-in-latex#246871>
- [ffmpeg install](https://github.com/FFmpeg/FFmpeg/blob/master/INSTALL.md3)
