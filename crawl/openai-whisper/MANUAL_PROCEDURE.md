# Manual Procedure

## Request Env.

From your browser:

1. go to demo Catalog at (demo.redhat.com)[demo.redhat.com]
1. select (Open Environments)[https://catalog.demo.redhat.com/catalog?category=Open_Environments]
1. request (AWS Blank Open Environment)[https://catalog.demo.redhat.com/catalog?category=Open_Environments&item=babylon-catalog-test%2Fsandboxes-gpte.rosa.test]
1. set `Activity` to `Practice / Enablement`
1. set `Purpose` to `Trying out a technical solution`
1. `check` the cost disclaimer
1. select `Order`
1. wait for environment to provision - e-mail subject `RHDP service AWS Blank Open Environment ---- is ready`

## Configure Env.

Prerequisite the github repository is cloned.

From the root directory of whitepaper-stt-evaluation-on-kubernetes:

1. run `aws configure`
1. update your `AWS Access Key ID` and `AWS Secret Access Key` from the confirmation e-mail
1. (optional) change the `INSTANCE_TYPE=g6.xlarge` variable
1. execute the provisioning script `./crawl/provision_rhel_aws.sh`
1. wait for completion to get `ssh` login command
1. `ssh` to server
1. setup NVIDIA software `sudo dnf -y upgrade && sudo reboot`
1. `ssh` to server and upgrade

    ```sh
    # update all the things
    sudo dnf -y upgrade

    sudo reboot
    ```
1. `ssh` to server and setup NVIDIA software

    ```sh
    # install kernel source
    sudo dnf -y install kernel-devel-matched kernel-headers

    # setup os repos
    sudo subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
    sudo subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
    sudo subscription-manager repos --enable=codeready-builder-for-rhel-9-x86_64-rpms
    sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    sudo rpm --erase gpg-pubkey-7fa2af80*

    # setup nvidia repos
    sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
    sudo rpm --import https://developer.download.nvidia.com/compute/cuda/repos/fedora39/x86_64/D42D0685.pub

    # setup gpu drivers
    # sudo dnf -y install nvidia-driver-assistant
    # sudo nvidia-driver-assistant --install

    # open kernel modules
    # sudo dnf module install nvidia-driver:open-dkms
    # sudo dnf install nvidia-driver-cuda kmod-nvidia-open-dkms

    # proprietary kernel modules
    sudo dnf module -y install nvidia-driver:latest-dkms
    # dnf install nvidia-driver-cuda kmod-nvidia-latest-dkms

    sudo dkms status
    sudo dkms install nvidia/570.124.06

    sudo reboot
    ```

1. `ssh` to server and setup podman

    ```sh
    sudo dnf upgrade -y
    sudo dnf install -y skopeo podman buildah gcc

    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
    sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

    sudo dnf-config-manager --enable nvidia-container-toolkit-experimental

    sudo dnf install -y nvidia-container-toolkit

    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    nvidia-ctk cdi list
    ```

1. test containers with CUDA
    ```sh
    #  run with ubuntu
    podman run --rm \
    --device nvidia.com/gpu=all \
    --security-opt=label=disable docker.io/library/ubuntu nvidia-smi -L

    # run with ubi9
    podman run --rm \
    --device nvidia.com/gpu=all \
    --security-opt=label=disable registry.access.redhat.com/ubi9 nvidia-smi -L
    ```

## Whisper container images

1. install git `sudo yum install -y git`
1. clone the repo `git clone https://github.com/redhat-na-ssa/whitepaper-stt-evaluation-on-kubernetes.git`
1. move to directory `cd whitepaper-stt-evaluation-on-kubernetes/`
1. build images

    ```sh
    # Minimal builds with runtime model download
    podman build -t whisper:ubuntu crawl/openai-whisper/ubuntu/.
    podman build -t whisper:ubi9 crawl/openai-whisper/ubi/platform/.
    podman build -t whisper:ubi9-minimal crawl/openai-whisper/ubi/minimal/.

    # list images
    podman images
    ```

1. (optional) Preloaded models for faster startup or air-gapped environments

    IMPORTANT: you may run out of disk space if you attempt to run all of the builds.

    ```sh
    # ubuntu whisper models
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubuntu"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubuntu/.
    done
    ```

    ```sh
    # ubi9-platform whisper
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubi9"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi/platform/.
    done
    ```

    ```sh
    # ubi9-minimal whisper
    for model in tiny.en base.en small.en medium.en large turbo; do
    tag="whisper-${model}:ubi9-minimal"
    echo "🔧 Building image: $tag"
    podman build --build-arg MODEL_SIZE=$model -t $tag crawl/openai-whisper/ubi/minimal/.
    done
    ```

1. launch host metrics
1. execute base test