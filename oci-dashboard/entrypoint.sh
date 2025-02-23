#!/bin/bash

echo "---------------------TF---------------------"
(cd /root/resources/terraform/jenkins && terraform init)
(cd /root/resources/terraform/jenkins && terraform apply -auto-approve)
(cd /root/resources/terraform/oke_cluster && terraform init)
(cd /root/resources/terraform/oke_cluster && terraform apply -auto-approve)

echo "---------------------OKE---------------------"
OKE_COMPARTMENT_NAME="OKE"
CLUSTER_NAME="DevOps_Cluster"

echo "Get the OKE Compartment OCID..."
OKE_COMPARTMENT_OCID=$(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid \
--name $OKE_COMPARTMENT_NAME --raw-output --query "data[0].id")

echo "Get the Cluster OCID..."
CLUSTER_OCID=$(/root/bin/oci ce cluster list --compartment-id $OKE_COMPARTMENT_OCID \
--query "data[?\"name\"=='$CLUSTER_NAME'].id | [0]" --raw-output)

echo "Create the kubeconfig file..."
mkdir -p $HOME/.kube
/root/bin/oci ce cluster create-kubeconfig \
--cluster-id $CLUSTER_OCID --file $HOME/.kube/config \
--region $TF_VAR_region --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT > /dev/null 2>&1

echo "---------------------DEV---------------------"
DEV_OPS_COMPARTMENT_NAME="DevOps"
INSTANCE_NAME="jenkins_instance"

echo "Get the DevOps Compartment OCID..."
DEV_OPS_COMPARTMENT_OCID=$(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid \
--name $DEV_OPS_COMPARTMENT_NAME --raw-output --query "data[0].id")

echo "Get the Instance OCID..."
INSTANCE_OCID=$(/root/bin/oci compute instance list --compartment-id $DEV_OPS_COMPARTMENT_OCID \
--query "data[?\"display-name\"=='$INSTANCE_NAME'].id | [0]" --raw-output)

echo "Get the Public IP of the Instance..."
IP=$(/root/bin/oci compute instance list-vnics --instance-id $INSTANCE_OCID | jq -r '.data[0]."public-ip"')

echo "---------------------CNF---------------------"
SSHCMD="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "Create the .kube directory..."
ssh $SSHCMD ubuntu@$IP "mkdir .kube" > /dev/null 2>&1

echo "Mount the oci and kube config files..."
scp $SSHCMD /root/.kube/config ubuntu@$IP:/home/ubuntu/.kube/config > /dev/null 2>&1
scp -r $SSHCMD /root/.oci ubuntu@$IP:/home/ubuntu/.oci > /dev/null 2>&1

echo "Change the key file path in the config file..."
ssh $SSHCMD ubuntu@$IP "sed -i '6 s@root@home/ubuntu@' /home/ubuntu/.oci/config" > /dev/null 2>&1

echo "Mount kubectl and oci-cli script..."
scp $SSHCMD /root/resources/scripts/conf.sh ubuntu@$IP:/home/ubuntu/conf.sh > /dev/null 2>&1

echo "Install kubectl and oci-cli..."
ssh $SSHCMD ubuntu@$IP "bash /home/ubuntu/conf.sh" > /dev/null 2>&1
ssh $SSHCMD ubuntu@$IP "rm -f conf.sh kubectl kubectl.sha256 install.sh" > /dev/null 2>&1

echo "All done. You can now access the Jenkins instance at http://$IP:8080"
exec "$@"
