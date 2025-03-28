# Unstructured Notes

## Create RHEL VM in AWS

[AWS Blank Open Environment](https://catalog.demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-open.prod&utm_source=webapp&utm_medium=share-link)

### Links

- https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html
- https://docs.nvidia.com/cuda/cuda-installation-guide-linux
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html
- https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html

```sh
VPC_ID=$(aws ec2 create-default-vpc --query Vpc.VpcId --output text)
SG_NAME=rhel-gpu-test

# create security group
aws ec2 create-security-group \
  --group-name "${SG_NAME}" \
  --description "RHEL GPU TEST created at $(date)" \
  --vpc-id "$VPC_ID"

# get security group
SG_ID=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=${VPC_ID} Name=group-name,Values=${SG_NAME} --query 'SecurityGroups[*].[GroupId]' --output text)

# allow ssh on security group
aws ec2 authorize-security-group-ingress \
  --group-id "${SG_ID}" \
  --ip-permissions '{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}'

# import ssh key
aws ec2 import-key-pair --key-name my-key --public-key-material fileb:///tmp/id.pub

# create ec2 install with g6.xlarge
aws ec2 run-instances \
  --image-id "ami-002acc74c401fa86b" \
  --instance-type "g6.xlarge" \
  --key-name "my-key" \
  --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-0a4b0a8e5fc325041","VolumeSize":100,"VolumeType":"gp3","Throughput":125}}' \
  --network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["'${SG_ID}'"]}' \
  --credit-specification '{"CpuCredits":"standard"}' \
  --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"RHEL GPU Test"}]}' \
  --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
  --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
  --count "1"
```

### Setup NVIDIA Software / CUDA / Drivers

```sh
sudo dnf install -y gcc
```

```sh
lspci | grep -i nvidia
uname -m && cat /etc/*release
gcc --version
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

dkms status
dkms install nvidia/570.124.06
```

### Setup `podman`

```sh
sudo dnf upgrade -y
sudo dnf install skopeo podman buildah gcc
```

```sh
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo dnf-config-manager --enable nvidia-container-toolkit-experimental

sudo dnf install -y nvidia-container-toolkit
```

```sh
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
