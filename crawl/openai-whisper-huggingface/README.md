# A simple Audio Speech Recognition example

### Files
- `01-whisper-gradio.py`

This example uses OpenAI's whisper model hosted locally
using Huggingface pipelines. The UI is provided by Gradio.

The microphone input is provided via a web browser and requires
an SSL connection (i.e. https).

To run on non-Openshift platforms, the code expects to find a certificate named `cert.pem` and
a key file named `key.pem`. Use the command below to create the certificate and key files.

Creating the self-signed certificate and key files.
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 365 -nodes
```

### Prerequisites

- RHEL 9.4 or Openshift v4.17
- An NVIDIA GPU will speed up inference but it is not necessary.
- Create a virtual python environment (tested with Python 3.9.18) and install 
the requirements.txt file using `pip`.
- Port 8080/tcp must be open.

#### Deploy on Openshift

```bash
oc new-project whisper
oc new-app https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git --context-dir=crawl/openai-whisper-huggingface --name=asr
```

Create an Openshift router service to provide the SSL certificate.
```bash
oc create route edge \
  --service asr \
  --insecure-policy='Redirect'
```
