#!/bin/bash

INSTANCE_NAME="RHEL GPU Instance"
INSTANCE_TYPE=${INSTANCE_TYPE:-g6.xlarge}
SG_NAME=ssh-ingress

echo "This script is untested - hit <CTRL> + C to abort"
sleep 6

aws_get_default_vpc(){
  # query default vpc id

  VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[*].VpcId' \
  --output text)
}

aws_create_default_vpc(){
  # create and get default vpc id

  VPC_ID=$(aws ec2 create-default-vpc \
  --query Vpc.VpcId \
  --output text)

  echo "${VPC_ID}"
}

aws_get_sg_ssh(){
  # get security group

  SG_ID=$(aws ec2 describe-security-groups \
    --filter Name=vpc-id,Values="${VPC_ID}" \
    Name=group-name,Values="${SG_NAME}" \
    --query 'SecurityGroups[*].[GroupId]' \
    --output text)
}

aws_create_sg_ssh(){

  # create security group
  aws ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "${INSTANCE_NAME} created at $(date)" \
    --vpc-id "$VPC_ID"

  # allow ssh on security group
  aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --ip-permissions '{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}'
}

aws_create_ssh_key(){
  AWS_KEY_NAME=${1:-my-key}

  aws describe-key-pairs \
    --key-names "${AWS_KEY_NAME}" && return 0

  # setup pub key
  SSH_KEY_PATH=${SSH_KEY_PATH:-${HOME}/.ssh/id_ed25519}
  [ -e "${SSH_KEY_PATH}" ] || ssh-keygen -t ed25519 -q -f "${SSH_KEY_PATH}" -N ""

  # import ssh key
  aws ec2 import-key-pair --key-name "${AWS_KEY_NAME}" --public-key-material fileb://${SSH_KEY_PATH}.pub
}

aws_create_ec2_rhel(){
  [ -z "$INSTANCE_NAME}" ] && return 0
  [ -z "$INSTANCE_TYPE}" ] && return 0
  [ -z "${SG_ID}" ] && aws_get_sg_ssh
  AWS_KEY_NAME="${AWS_KEY_NAME:-my-key}"

  # create ec2 instance
  aws ec2 run-instances \
    --image-id "ami-002acc74c401fa86b" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${AWS_KEY_NAME}" \
    --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-0a4b0a8e5fc325041","VolumeSize":100,"VolumeType":"gp3","Throughput":125}}' \
    --network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["'"${SG_ID}"'"]}' \
    --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"'"${INSTANCE_NAME}"'"}]}' \
    --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
    --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
    --count "1"
}

aws_get_ec2_rhel_hostname(){
  # get instance dns name
  EC2_HOSTNAME=$(aws ec2 describe-instances \
    --filter "Name=tag:Name,Values=${INSTANCE_NAME}" \
    --filter "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].PublicDnsName' \
    --output text)

  echo "${EC2_HOSTNAME}"

  # ssh into instance
  echo "Connect via...
    ssh ec2-user@${EC2_HOSTNAME}
  "
}

aws_get_default_vpc || aws_create_default_vpc
aws_get_sg_ssh      || aws_create_sg_ssh
aws_create_ssh_key
aws_get_ec2_rhel_hostname || aws_create_ec2_rhel