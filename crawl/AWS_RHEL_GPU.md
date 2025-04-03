# Unstructured Notes

### Links

- https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html
- https://docs.nvidia.com/cuda/cuda-installation-guide-linux
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

## Create RHEL VM in AWS

Create [AWS Blank Open Environment (RHDS)](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link)

### Optional: Setup `aws` cli

```sh
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

NOTE: AWS CloudShell 

### Setup EC2 RHEL GPU Instance

Optional: setup SSH key of choice

NOTE: `bootstrap_aws.sh` below will create ed25519 key

```sh
# setup pub key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXLGAxOZLWpV1WWRu4GnFWEHVmLiSeXsMoChi4rXvDl cory@kowdora" > /tmp/id.pub

# import ssh key
aws ec2 import-key-pair --key-name "${AWS_KEY_NAME}" --public-key-material fileb:///tmp/id.pub
```

```sh
# create ec2 install with g6.xlarge
./bootstrap_aws.sh
```

### Setup NVIDIA Software / CUDA / Drivers

```sh
# update all the things
sudo dnf -y upgrade

reboot
```

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

reboot
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
