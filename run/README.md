# Run

Deploy STT services using API model servers that pull models from external storage.

STT models are **decoupled** from the containerized API servers that host them.

||OpenAI Whisper|Faster-Whisper|Nvidia Canary|
|-|-|-|-|
|vLLM|Supported*|Not Supported|Not Supported
|Speaches.ai (Faster Whisper Server)|Supported|Supported|Not Supported
|Nvidia Riva|Supported**|Not Supported|Supported

*There is a bug today with loading Whisper models in vLLM, see below  
**Nvidia optimized version of Whisper


## How to use this guide

Each section provides procedures for deploying a unique model server. 

The section will show how to request STT transcriptions using **different models**.

Feel free to try different models!

### vLLM Model Server

> IMPORTANT NOTE: At this time, vLLM cannot run Whisper or Faster Whisper models successfully. The specific issues are called out below in the instructions.

The vLLM server can only host one model at a time, please see this [GitHub Issue](https://github.com/vllm-project/vllm/issues/299).

A separate vLLM server must be deployed for each model type.

Create a new project

```sh
oc new-project vllm-server
```

Assign policy to allow vLLM SA to run as root

```sh
oc adm policy add-scc-to-user anyuid -z default
```

#### Model - Whisper Tiny

Create PVC for downloaded model

```sh
oc create -f ocp/vllm/whisper-tiny-pv.yaml
```

Create a vLLM deployment with whisper tiny

```sh
oc create -f ocp/vllm/whisper-tiny.yaml
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

> IMPORTANT NOTE: This does not work right now as there is an Internal Server Error: https://github.com/vllm-project/vllm/pull/12909

```sh
curl -X POST $WHISPER_ENDPOINT/v1/audio/transcriptions \                           
-H 'accept: application/json' \ 
-H 'Content-Type: multipart/form-data' \
-F 'file=@test.mp4;type=audio/mpeg' \
-F 'model=openai/whisper-tiny' \
-F 'response_format=json' \
-F 'stream=true'
```

#### Model - Faster Whisper

> IMPORTANT NOTE: The vLLM deployment will fail because the model architecture for Faster Whisper (Voice Activity Detector) is not supported in vLLM at this time: https://github.com/vllm-project/vllm/issues/13866

Create PVC for downloaded model

```sh
oc create -f ocp/vllm/faster-whisper-tiny-pv.yaml
```

Create a vLLM deployment with faster whisper tiny

```sh
oc create -f ocp/vllm/faster-whisper-tiny.yaml
```

Expose API

```sh
oc expose deploy faster-whisper-tiny
oc expose svc faster-whisper-tiny --target-port 8000
```

Smoke test

```sh
FASTER_WHISPER_ENDPOINT=$(oc get route faster-whisper-tiny --template='http://{{.spec.host}}')
curl $FASTER_WHISPER_ENDPOINT/v1/models
```

Smoke test API

> IMPORTANT NOTE: This does not work right now as there is an Internal Server Error: https://github.com/vllm-project/vllm/pull/12909

```sh
curl -X POST $FASTER_WHISPER_ENDPOINT/v1/audio/transcriptions \
-H 'accept: application/json' \
-H 'Content-Type: multipart/form-data' \
-F 'file=@test.mp4;type=audio/mpeg' \
-F 'model=Systran/faster-whisper-tiny' \
-F 'response_format=json' \
-F 'stream=true'
```

### Speaches.ai Model Server (formerly Faster Whisper Server)

Create new project

```sh
oc new-project speaches-server
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
SPEACHES_ENDPOINT=$(oc get route faster-whisper-server --template='http://{{.spec.host}}')
curl $SPEACHES_ENDPOINT/v1/models
```

#### Model - Whisper

Smoke test audio file

```sh
curl -X POST $FASTER_WHISPER_ENDPOINT/v1/audio/transcriptions -H 'accept: application/json' -F 'model=openai/whisper-tiny' -F 'stream=true' -F 'file=@test.mp4'
```

#### Model - Faster Whisper


Smoke test audio file

```sh
curl -X POST $FASTER_WHISPER_ENDPOINT/v1/audio/transcriptions -H 'accept: application/json' -F 'model=Systran/faster-whisper-tiny.en' -F 'stream=true' -F 'file=@test.mp4'
```

### NVIDIA Riva 

Create an account on ngc.nvidia.com

Export NGC credentials

```sh
export NGC_API_KEY="<YOUR NGC API KEY>"
```

Download helm chart

```sh
helm fetch https://helm.ngc.nvidia.com/nvidia/riva/charts/riva-api-2.19.0.tgz \
        --username=\$oauthtoken --password=$NGC_API_KEY --untar
```

Edit the `values.yaml` with

1. `ngcCredentials` put in your `NGC_API_KEY` and `email`
1. `persistentVolumeClaim` change `usePVC` to `true` and set `storageClassName` (e.g. `gp3-csi` in AWS) and set `storageAccessMode` to `ReadWriteOnce`
1. Append the following models under `ngcModelConfigs.triton0.models`:

> Note: Uncomment the model you want loaded into Riva. In the example below, we are loading the [Canary 1B](https://build.nvidia.com/nvidia/canary-1b-asr) model:

```text
      - nvidia/riva/rmir_asr_canary_1b_ofl:2.19.0
      # - nvidia/riva/rmir_asr_canary_0-6b_turbo_ofl:2.19.0
      # - nvidia/riva/rmir_asr_whisper_large_ofl:2.19.0
```

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

Get a reference to the client pod

```sh
RIVA_CLIENT=$(oc get pods -l app=rivaasrclient -o jsonpath='{.items[0].metadata.name}')
```

Run a transcription smoke test

```sh
oc exec $RIVA_CLIENT -- clients/riva_streaming_asr_client --print_transcripts --audio_file=/opt/riva/wav/en-US_sample.wav --automatic_punctuation=true --riva_uri=riva-api:50051
```

Run a streaming transcription

```sh
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file.py --input-file /opt/riva/wav/en-US_sample.wav --server riva-api:50051
```

Run an offline transcription

```sh
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file_offline.py --input-file /opt/riva/wav/en-US_sample.wav --server riva-api:50051
```

List available ASR models in your Riva server

```sh
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file.py --list-models --server riva-api:50051
```

#### Model - Canary

> Canary only offers offline transcription in Riva

```bash
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file_offline.py --model-name canary-1b-multi-asr-offline-asr-bls-ensemble\
  --input-file /opt/riva/wav/en-US_sample.wav --server riva-api:50051
```

#### Model - Conformer

Run a streaming transcription with the conformer streaming model

```sh
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file.py --model-name conformer-en-US-asr-streaming-asr-bls-ensemble\
  --input-file /opt/riva/wav/en-US_sample.wav --server riva-api:50051
```

#### Model - Parakeet

Run a streaming transcription with the parakeet streaming model

```sh
oc exec $RIVA_CLIENT -- python3 examples/transcribe_file.py --model-name parakeet-0.6b-en-US-asr-streaming-throughput-asr-bls-ensemble\
  --input-file /opt/riva/wav/en-US_sample.wav --server riva-api:50051
```

**Optional: Transcribe live with an audio mic**

> Note: This requires you to download the repo to your machine that has an audio mic

In one terminal,

```sh
oc port-forward service/riva-api 8443:riva-speech
```

In another terminal:

Clone the repo

```sh
git clone git@github.com:nvidia-riva/python-clients.git
cd python-clients
```

Install Python Audio

```sh
pipenv install pyaudio
```

Install dependencies

```sh
pipenv install -r requirements.txt
```

Install Riva Client

```sh
pipenv install nvidia-riva-client
```

Activate shell

```sh
pipenv shell
```

Run Audio mic transcription

```sh
python3 scripts/asr/transcribe_mic.py --server localhost:8443
```

## Appendix

#### DEBUGGING ONLY: Speaches.ai Model Server on RHEL with Ubuntu container

These instructions are here solely to test the speaches model server outside of OCP, if needed

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
ENDPOINT_URL='http://localhost:8000'  # replace with RHEL endpoint
curl $ENDPOINT_URL/v1/models
```

Smoke test audio file

```sh
curl -X POST $ENDPOINT_URL/v1/audio/transcriptions -H 'accept: application/json' -F 'model=Systran/faster-whisper-tiny.en' -F 'stream=true' -F 'file=@test.mp4'
``` 


