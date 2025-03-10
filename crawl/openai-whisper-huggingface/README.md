# A simple Audio Speech Recognition example

### Files
- `01-whisper-gradio.py`

This example uses OpenAI's whisper model hosted locally
using Huggingface pipelines. The UI is provided by Gradio.

The microphone input is provided via a web browser and requires
an SSL connection (i.e. https).

The code expects to find a certificate named `cert.pem` and
a key file named `key.pem`. 

Creating the self-signed certificate and key files.
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 -nodes
```

### Test Environment

- RHEL 9.4 with a working CUDA stack
- NVIDIA GPU
- Create a virtual python environment (tested with Python 3.9.18) and install 
the requirements.txt file using `pip`.
- Port 8000/tcp must be open.

#### Openshift

```bash
oc new-project whisper
oc new-app https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git --context-dir=crawl/openai-whisper-huggingface --name=asr
```

```bash
oc create route edge \
  --service asr \
  --insecure-policy='Redirect'
```
