#!/bin/bash

error_handler() {
  echo "ERROR: $1"
  echo "Executing tail -f /dev/null to keep the container running..."
  exec tail -f /dev/null
}

echo "---------------------TF---------------------"
(cd /root/resources/terraform && terraform init) || error_handler "Failed to initialize Terraform"
(cd /root/resources/terraform && terraform apply -auto-approve) || error_handler "Failed to apply Terraform"

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
mkdir -p $HOME/.kube > /dev/null 2>&1 || error_handler "Failed to create .kube directory"
/root/bin/oci ce cluster create-kubeconfig \
--cluster-id $CLUSTER_OCID --file $HOME/.kube/config \
--region $TF_VAR_region --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT > /dev/null 2>&1 || error_handler "Failed to create kubeconfig file"

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

echo "Create the .kube directory inside the instance..."
ssh $SSHCMD ubuntu@$IP "mkdir .kube" > /dev/null 2>&1 || error_handler "Failed to create remote .kube directory inside the instance"

echo "Mount the oci and kube config files inside the instance..."
scp $SSHCMD /root/.kube/config ubuntu@$IP:/home/ubuntu/.kube/config > /dev/null 2>&1 || error_handler "Failed to copy kube config"
scp -r $SSHCMD /root/.oci ubuntu@$IP:/home/ubuntu/.oci > /dev/null 2>&1 || error_handler "Failed to copy oci config"

echo "Change the key file path in the config file inside the instance..."
ssh $SSHCMD ubuntu@$IP "sed -i '6 s@root@home/ubuntu@' /home/ubuntu/.oci/config" > /dev/null 2>&1 || error_handler "Failed to update oci config path"

echo "Mount kubectl and oci-cli script inside the instance..."
scp $SSHCMD /root/resources/scripts/conf.sh ubuntu@$IP:/home/ubuntu/conf.sh > /dev/null 2>&1 || error_handler "Failed to copy conf.sh script"

echo "Install kubectl and oci-cli inside the instance..."
ssh $SSHCMD ubuntu@$IP "bash /home/ubuntu/conf.sh" > /dev/null 2>&1 || error_handler "Failed to install kubectl and oci-cli"
ssh $SSHCMD ubuntu@$IP "rm -f conf.sh kubectl kubectl.sha256 install.sh" > /dev/null 2>&1 || error_handler "Failed to cleanup installation files"

echo "Create the jenkins conf directory inside the instance..."
ssh $SSHCMD ubuntu@$IP "mkdir -p /home/ubuntu/jenkins/conf" > /dev/null 2>&1 || error_handler "Failed to create jenkins conf directory"

echo "Mount the k8s and oci config files inside the instance's jenkins conf directory..."
scp $SSHCMD /root/.kube/config ubuntu@$IP:/home/ubuntu/jenkins/conf/k8s_config > /dev/null 2>&1 || error_handler "Failed to copy k8s config"
scp $SSHCMD /root/.oci/config ubuntu@$IP:/home/ubuntu/jenkins/conf/oci_config > /dev/null 2>&1 || error_handler "Failed to copy oci config"
scp $SSHCMD /root/.oci/oci_api_key.pem ubuntu@$IP:/home/ubuntu/jenkins/conf/oci_api_key.pem > /dev/null 2>&1 || error_handler "Failed to copy oci key"

echo "Change the key file path in the config file inside the instance's jenkins conf directory..."
ssh $SSHCMD ubuntu@$IP "sed -i '6 s@root@var/jenkins_home@' /home/ubuntu/jenkins/conf/oci_config" > /dev/null 2>&1 || error_handler "Failed to update jenkins oci config path"

echo "Mount the jenkins .env file inside the instance's jenkins directory..."
echo "GITHUB_TOKEN=$GITHUB_TOKEN" > .env
scp $SSHCMD .env ubuntu@$IP:/home/ubuntu/jenkins/.env > /dev/null 2>&1 || error_handler "Failed to copy .env file"
rm -f .env > /dev/null 2>&1 || error_handler "Failed to remove local .env file"

echo "Run Jenkins..."
ssh $SSHCMD ubuntu@$IP "(cd /home/ubuntu/jenkins && docker-compose up --build -d > docker.log)" > /dev/null 2>&1 || error_handler "Failed to start Jenkins"

echo "All done. You can now access the Jenkins instance at http://$IP:8080"
exec "$@"
