#!/bin/bash

INSTANCE_NAME="RHEL GPU Instance"
INSTANCE_TYPE=${INSTANCE_TYPE:-g6.xlarge}
SG_NAME=ssh-ingress

echo "This script is untested - hit <CTRL> + C to abort"
sleep 6

# create and get default vpc id
VPC_ID=$(aws ec2 create-default-vpc \
  --query Vpc.VpcId \
  --output text)

# query default vpc id
VPC_ID=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[*].VpcId' \
  --output text)

# create security group
aws ec2 create-security-group \
  --group-name "${SG_NAME}" \
  --description "${INSTANCE_NAME} created at $(date)" \
  --vpc-id "$VPC_ID"

# get security group
SG_ID=$(aws ec2 describe-security-groups \
  --filter Name=vpc-id,Values="${VPC_ID}" \
  Name=group-name,Values="${SG_NAME}" \
  --query 'SecurityGroups[*].[GroupId]' \
  --output text)

# allow ssh on security group
aws ec2 authorize-security-group-ingress \
  --group-id "${SG_ID}" \
  --ip-permissions '{"IpProtocol":"tcp","FromPort":22,"ToPort":22,"IpRanges":[{"CidrIp":"0.0.0.0/0"}]}'

# setup pub key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIXLGAxOZLWpV1WWRu4GnFWEHVmLiSeXsMoChi4rXvDl cory@kowdora" > /tmp/id.pub

# import ssh key
aws ec2 import-key-pair --key-name my-key --public-key-material fileb:///tmp/id.pub

# create ec2 install with g6.xlarge
aws ec2 run-instances \
  --image-id "ami-002acc74c401fa86b" \
  --instance-type "${INSTANCE_TYPE}" \
  --key-name "my-key" \
  --block-device-mappings '{"DeviceName":"/dev/sda1","Ebs":{"Encrypted":false,"DeleteOnTermination":true,"Iops":3000,"SnapshotId":"snap-0a4b0a8e5fc325041","VolumeSize":100,"VolumeType":"gp3","Throughput":125}}' \
  --network-interfaces '{"AssociatePublicIpAddress":true,"DeviceIndex":0,"Groups":["'"${SG_ID}"'"]}' \
  --tag-specifications '{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"'"${INSTANCE_NAME}"'"}]}' \
  --metadata-options '{"HttpEndpoint":"enabled","HttpPutResponseHopLimit":2,"HttpTokens":"required"}' \
  --private-dns-name-options '{"HostnameType":"ip-name","EnableResourceNameDnsARecord":true,"EnableResourceNameDnsAAAARecord":false}' \
  --count "1"

# get instance dns name
EC2_HOSTNAME=$(aws ec2 describe-instances \
  --filter "Name=tag:Name,Values=${INSTANCE_NAME}" \
  --filter "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].PublicDnsName' \
  --output text)

echo "${EC2_HOSTNAME}"

# ssh into instance
ssh ec2-user@"${EC2_HOSTNAME}"