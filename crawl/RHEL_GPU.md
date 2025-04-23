# Setup RHEL with Nvidia GPU

## Create RHEL VM in AWS

From your browser:

1. go to demo Catalog at [demo.redhat.com](demo.redhat.com)
1. select [Open Environments](https://catalog.demo.redhat.com/catalog?category=Open_Environments)
1. request <a href="https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-linktarget=" target="_blank">AWS Blank Open Environment</a>
1. set `Activity` to `Practice / Enablement`
1. set `Purpose` to `Trying out a technical solution`
1. `check` the cost disclaimer
1. select `Order`
1. wait for environment to provision - e-mail subject `RHDP service AWS Blank Open Environment ---- is ready`

### Optional: Setup `aws` cli

This section is optional and **not** required if using AWS CloudShell.

Prerequisite the github repository is cloned.

From the root directory of whitepaper-stt-evaluation-on-kubernetes:

1. run `aws configure` and enter information
1. update your `AWS Access Key ID` and `AWS Secret Access Key` from the confirmation e-mail
1. (optional) change the `INSTANCE_TYPE=g6.xlarge` variable
1. execute the provisioning script `./crawl/provision_rhel_aws.sh`
1. wait for completion to get `ssh` login command

```output
# example output
AWS Access Key ID [****************G6M5]: 
AWS Secret Access Key [****************vzRg]: 
Default region name [us-east-2]: 
Default output format [text]:
```

### Setup EC2 RHEL GPU Instance

#### Optional: setup SSH key of choice

NOTE: `provision_rhel_aws.sh` below will create ed25519 key if it does not exist already

```sh
# setup pub key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXLGAxOZLWpV1WWRu4GnFWEHVmLiSeXsMoChi4rXvDl cory@kowdora" > /tmp/id.pub

# import ssh key
aws ec2 import-key-pair --key-name "${AWS_KEY_NAME:-my-key}" --public-key-material fileb:///tmp/id.pub
```

```sh
# create ec2 install with g6.xlarge
export INSTANCE_TYPE=g6.12xlarge

# other instances g4dn=T4, g5=A10, p5=H100
# export INSTANCE_TYPE=g4dn.12xlarge
# export INSTANCE_TYPE=g5.12xlarge
# export INSTANCE_TYPE=p5.48xlarge

./crawl/provision_rhel_aws.sh
```

### Setup NVIDIA Software / CUDA / Drivers

```sh
# update all the things
sudo dnf -y upgrade

# install python things
sudo dnf -y install gcc python3-devel
pip install --no-binary :all: psutil

# install other software
sudo dnf -y install git screen sysstat

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

# upgraded driver
sudo dkms install nvidia/570.133.20

sudo reboot
```

### Setup `podman`

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

### Test NVIDIA Software / CUDA / Drivers

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

|[Previous <- Main README](./openai-whisper/README.md)|[Next -> Ubuntu with Whisper](./openai-whisper/ubuntu/README.md)|
|-|-|

## Links

- https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html
- https://docs.nvidia.com/cuda/cuda-installation-guide-linux
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
