# Setup RHEL with NVIDIA GPU

## Create RHEL VM in AWS

In your browser:

1. Go to the [demo catalog](https://demo.redhat.com).
2. Select [**Open Environments**](https://catalog.demo.redhat.com/catalog?category=Open_Environments).
3. Request an <a href="https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-linktarget=" target="_blank">**AWS Blank Open Environment**</a>.
4. Set **Activity** to `Practice / Enablement`.
5. Set **Purpose** to `Trying out a technical solution`.
6. [x] Check the cost disclaimer.
7. Click **Order**.
8. Wait for the provisioning email with the subject:
   `RHDP service AWS Blank Open Environment ---- is ready`.

---

## Export access key temporarily

## (Optional) Set Up `aws` CLI

TODO Export env. variables to temporary ___ env.

**Skip this section if using AWS CloudShell.**

> 💡 Prerequisite: Clone the GitHub repository.

From the repo root (`whitepaper-stt-evaluation-on-kubernetes`):

1. Run `aws configure` and enter your credentials.

2. Use the **AWS Access Key ID** and **Secret Access Key** from your environment email.

3. *(Optional)* Change `INSTANCE_TYPE=g6.xlarge` if desired.

4. Run the provisioning script:

   ```sh
   ./crawl/provision_rhel_aws.sh
   ```

5. Wait for completion; it will print the `ssh` login command.

Example:

```sh
AWS Access Key ID [****************G6M5]:
AWS Secret Access Key [****************vzRg]:
Default region name [us-east-2]:
Default output format [text]:
```

---

## 🔑 (Optional) Set Up SSH Key

> *Note: `provision_rhel_aws.sh` auto-generates an ed25519 key if not found.*

To use your own key:

```sh
# Example: add your pub key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXLGAxOZLWpV1WWRu4GnFWEHVmLiSeXsMoChi4rXvDl cory@kowdora" > /tmp/id.pub

# Import into AWS
aws ec2 import-key-pair --key-name "${AWS_KEY_NAME:-my-key}" --public-key-material fileb:///tmp/id.pub
```

---

## Provision EC2 RHEL GPU Instance

TODO: Use the RHUI

```sh
# Default: g6.12xlarge (L4 GPU)
export INSTANCE_TYPE=g6.12xlarge

# Examples:
# g4dn.12xlarge (T4 GPU)
# g5.12xlarge (A10 GPU)
# p5.48xlarge (H100 GPU)

./crawl/provision_rhel_aws.sh

# you may have to rerun the .sh command above to get your connection details
# Connect via...
#     ssh user@...amazonaws.com

```

---

## Install NVIDIA Software / CUDA / Drivers

```sh
# Update system
sudo dnf -y upgrade

# Python & basic dev tools
sudo dnf -y install gcc python3-devel
pip install --no-binary :all: psutil

# Other tools
sudo dnf -y install git screen sysstat

# Kernel source
sudo dnf -y install kernel-devel-matched kernel-headers

# Enable OS repos
sudo subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms \
                                --enable=rhel-9-for-x86_64-baseos-rpms \
                                --enable=codeready-builder-for-rhel-9-x86_64-rpms

# EPEL
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo rpm --erase gpg-pubkey-7fa2af80*

# NVIDIA repo
sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
sudo rpm --import https://developer.download.nvidia.com/compute/cuda/repos/fedora39/x86_64/D42D0685.pub

# GPU driver (proprietary)
sudo dnf module -y install nvidia-driver:latest-dkms

# Reboot to load the driver
sudo reboot
```

**(Optional) Manually upgrade driver:**

```sh
sudo dkms status && \
sudo dkms install $(sudo dkms status | awk -F: '/nvidia/{print $1}' | head) && \
sudo reboot
```

TODO systemd oneshot unit that runs a CDI every reboot so podman works `sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml`

---

## Set Up `podman`

```sh
sudo dnf upgrade -y
sudo dnf install -y skopeo podman buildah gcc git screen sysstat

# NVIDIA container toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo dnf config-manager --enable nvidia-container-toolkit-experimental
sudo dnf install -y nvidia-container-toolkit

# Generate CDI config
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list
```

---

## Test NVIDIA Software / CUDA / Drivers

**Ubuntu container:**

```sh
podman run --rm \
  --device nvidia.com/gpu=all \
  --security-opt=label=disable docker.io/library/ubuntu nvidia-smi -L
```

**UBI9 container:**

```sh
podman run --rm \
  --device nvidia.com/gpu=all \
  --security-opt=label=disable registry.access.redhat.com/ubi9 nvidia-smi -L
```

> **If you hit this error, re-run `nvidia-smi` to fix it:**

```sh
Error: setting up CDI devices: failed to inject devices: failed to stat CDI host device "/dev/nvidia-uvm": no such file or directory

# Fix:
nvidia-smi
```

---

## (Optional) Set Up `aws` CLI

**Skip this section if using AWS CloudShell.**

> 💡 Prerequisite: Clone the GitHub repository.

From the repo root (`whitepaper-stt-evaluation-on-kubernetes`):

1. Run `aws configure` and enter your credentials.

2. Use the **AWS Access Key ID** and **Secret Access Key** from your environment email.

3. *(Optional)* Change `INSTANCE_TYPE=g6.xlarge` if desired.

4. Run the provisioning script:

   ```sh
   ./crawl/provision_rhel_aws.sh
   ```

5. Wait for completion; it will print the `ssh` login command.

Example:

```sh
AWS Access Key ID [****************G6M5]:
AWS Secret Access Key [****************vzRg]:
Default region name [us-east-2]:
Default output format [text]:
```

---

## 🔑 (Optional) Set Up SSH Key

> *Note: `provision_rhel_aws.sh` auto-generates an ed25519 key if not found.*

To use your own key:

```sh
# Example: add your pub key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXLGAxOZLWpV1WWRu4GnFWEHVmLiSeXsMoChi4rXvDl cory@kowdora" > /tmp/id.pub

# Import into AWS
aws ec2 import-key-pair --key-name "${AWS_KEY_NAME:-my-key}" --public-key-material fileb:///tmp/id.pub
```

---

| [⬅️ Previous: Main README](./README.md) | [➡️ Next: Ubuntu with Whisper](./openai-whisper/ubuntu/README.md) |
| --------------------------------------- | ----------------------------------------------------------------- |

---

## 🔗 Helpful Links

* [NVIDIA Driver Install Guide](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html)
* [CUDA Install Guide (Linux)](https://docs.nvidia.com/cuda/cuda-installation-guide-linux)
* [NVIDIA Container Toolkit (CDI Support)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html)
* [NVIDIA Container Toolkit (Install Guide)](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
