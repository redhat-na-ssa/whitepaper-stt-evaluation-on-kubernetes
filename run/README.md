# Run

Deploy STT services using API model servers that pull models from external storage.

STT models are **decoupled** from the containerized API servers that host them.

> TODO: Add an image

## How to use this guide

Each section provides procedures for deploying a unique model server. 

The section will show how to request STT transcriptions using **different models**.

Feel free to try different models!

### vLLM Model Server

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

#### Model - Faster Whisper

> TODO: Test

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

> Note this will throw an Internal Server Error at the moment: https://github.com/vllm-project/vllm/pull/12909

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

#### DEBUGGING ONLY: RHEL with Ubuntu container

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

### NVIDIA Riva 

Create an account on ngc.nvidia.com

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
1. `persistentVolumeClaim` change `usePVC` to `true` and set `storageClassName` (e.g. `gp3-csi` in AWS) and set `storageAccessMode` to `ReadWriteOnce`

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

> TODO: Try different models

