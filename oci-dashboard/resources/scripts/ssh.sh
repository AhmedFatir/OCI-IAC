#!/bin/bash

SSHCMD="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
COMPARTMENT_NAME="DevOps"
INSTANCE_NAME="jenkins_instance"

echo "Get the Compartment OCID..."
COMPARTMENT_OCID=$(oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid \
--name $COMPARTMENT_NAME --raw-output --query "data[0].id")

echo "Get the Instance OCID..."
INSTANCE_OCID=$(oci compute instance list --compartment-id $COMPARTMENT_OCID \
--query "data[?\"display-name\"=='$INSTANCE_NAME'].id | [0]" --raw-output)

echo "Get the Public IP of the Instance..."
IP=$(oci compute instance list-vnics --instance-id $INSTANCE_OCID | jq -r '.data[0]."public-ip"')

echo "SSH into the Instance..."
ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 $SSHCMD ubuntu@$IP