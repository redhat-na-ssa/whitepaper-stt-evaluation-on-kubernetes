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

1. Move to Ubuntu folder: `cd ubuntu/`
1. Build the Dockerfile: `podman build --format=docker -t whisper:ubuntu .`
1. List images: `podman image list`
1. Run the whisper image: `podman run -d --name ubuntu-whisper localhost/whisper:ubuntu sleep infinity`

#### Get Audio and Transcript to Evaluate

/Users/davidmarcus/GitHub/whitepaper-stt-evaluation-on-kubernetes/scratch

1. From root dir, create scratch dir `mkdir scratch`
1. Get an audio file from [JFK Historic Speeches](https://www.jfklibrary.org/learn/about-jfk/historic-speeches)
    - `curl -o scratch/rice_university_12_september_1962.mp4 "https://house-fastly-signed-us-east-1-prod.brightcovecdn.com/media/v1/pmp4/static/clear/6057940510001/34e103a2-a476-4277-ae85-cab71eee38b6/6b13d19c-a4a4-41dd-bdce-27c92ce165a8/main.mp4?fastly_token=NjdiZDQyNThfOWNkMDlmZDk1YzBmNGM3MzZlMjQxNzhkNzkzNDgwMzFmYjRkZjVlMDBhZjQ0OGE0Zjg1ZDBjZjliZWQ1NzJhZV8vL2hvdXNlLWZhc3RseS1zaWduZWQtdXMtZWFzdC0xLXByb2QuYnJpZ2h0Y292ZWNkbi5jb20vbWVkaWEvdjEvcG1wNC9zdGF0aWMvY2xlYXIvNjA1Nzk0MDUxMDAwMS8zNGUxMDNhMi1hNDc2LTQyNzctYWU4NS1jYWI3MWVlZTM4YjYvNmIxM2QxOWMtYTRhNC00MWRkLWJkY2UtMjdjOTJjZTE2NWE4L21haW4ubXA0"`
    - `curl -o scratch/inaugural_address_20_january_1961.mp3 "https://house-fastly-signed-us-east-1-prod.brightcovecdn.com/media/v1/pmp4/static/clear/6057940510001/295ff207-8b2f-431c-a030-310e9d3756d7/f5701595-6475-4223-acf2-138916bc616a/main.mp4?fastly_token=NjdiZDQ4MTNfMTAwMDdhNDBmNzhjYmU0YzI0ZTM3OWMwN2JmMjg3NDBhNWFmYjAzZDNkYzRiZjVjMGQxYjlhNmI3YjQwM2JiOF8vL2hvdXNlLWZhc3RseS1zaWduZWQtdXMtZWFzdC0xLXByb2QuYnJpZ2h0Y292ZWNkbi5jb20vbWVkaWEvdjEvcG1wNC9zdGF0aWMvY2xlYXIvNjA1Nzk0MDUxMDAwMS8yOTVmZjIwNy04YjJmLTQzMWMtYTAzMC0zMTBlOWQzNzU2ZDcvZjU3MDE1OTUtNjQ3NS00MjIzLWFjZjItMTM4OTE2YmM2MTZhL21haW4ubXA0"`
1. Copy files from scratch to the container /data/audio directory `podman cp scratch/rice_university_12_september_1962.mp4 ubuntu-whisper:/data/audio/`
1. Interactive terminal on the container `podman exec -it ubuntu-whisper /bin/bash`
1. Run whisper in the container`whisper /data/audio/rice_university_12_september_1962.mp4 --model base > transcribe_rice_university_12_september_1964.txt`
1. `podman run --rm -v /var/home/instruct/whitepaper-stt-evaluation-on-kubernetes/scratch/rice_university_12_september_1962.mp4:Z -e AUDIO_FILE=/data/audio/sample.mp4 whisper:ubuntu`
1. Launch another terminal ssh to server for container specs
1. Container size: `podman ps --size --sort size`
1. Resource consumption: `podman stats`

## OpenShift Env.