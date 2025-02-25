# Start to Finish User Guide

## Environments

1. Request environments from demo.redhat.com
1. [RHEL AI (GA) VM](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/rhdp.rhel-ai-vm.prod&utm_source=webapp&utm_medium=share-link)
    - Activity: `Practice / Enablement`
    - Purpose: `Trying out a technical solution`
    - Region: `us-east-2`
    - GPU Selection by Node Type: `g6.xlarge 1 x L4` OR `g6.12xlarge 4 x L4`
1. [AWS with OpenShift Open Environment](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-ocp.prod&utm_source=webapp&utm_medium=share-link)
    - Activity: `Practice / Enablement`
    - Purpose: `Trying out a technical solution`
    - Region: `us-east-2`
    - OpenShift Version: `4.17`
    - Control Plane Count: `1`
    - Control Plane Instance Type: `m6a.4xlarge`

## RHEL AI VM

1. SSH to your RHEL AI VM
1. Clone the git repo `git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git`
1. Move to your cloned git folder `cd whitepaper-stt-evaluation-on-kubernetes/`

### Run Ubuntu Dockerfile

1. Move to Ubuntu folder: `cd models/openai-whisper/ubuntu/`
1. Build the Dockerfile: `podman build --format=docker -t whisper:ubuntu models/openai-whisper/ubuntu/.`
1. List images: `podman image list`
1. Run the whisper image: `podman run -d --name whisper-ubuntu localhost/whisper:ubuntu sleep infinity`

#### Transcribe provided audio file

1. podman run --rm -v /path/to/local/audio:/data/audio:Z ubuntu-whisper-container venv/bin/whisper /data/audio/your_audio.mp4 --model tiny.en
1. `podman run -it -v $(pwd)/data/audio-samples:/data/audio:Z localhost/whisper:ubuntu /bin/bash`
1. `podman run --rm -v $(pwd)/data/audio-samples:/data/audio:Z localhost/whisper:ubuntu whisper audio/rice_university_12_september_1962.mp4 --model tiny.en > /data/transcriptions/transcribe_rice_university_12_september_1964.txt`

1. Copy files from scratch to the container /data/audio directory `podman cp scratch/rice_university_12_september_1962.mp4 ubuntu-whisper:/data/audio/`
1. Interactive terminal on the container `podman exec -it ubuntu-whisper /bin/bash`
1. Run whisper in the container`whisper /data/audio/rice_university_12_september_1962.mp4 --model base > transcribe_rice_university_12_september_1964.txt`
1. `podman run --rm -v /var/home/instruct/whitepaper-stt-evaluation-on-kubernetes/scratch/rice_university_12_september_1962.mp4:Z -e AUDIO_FILE=/data/audio/sample.mp4 whisper:ubuntu`
1. Launch another terminal ssh to server for container specs
1. Container size: `podman ps --size --sort size`
1. Resource consumption: `podman stats`

## OpenShift Env.