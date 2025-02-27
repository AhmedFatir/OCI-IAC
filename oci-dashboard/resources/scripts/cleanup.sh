#!/bin/bash

echo "Delete the Kubernetes resources..."
kubectl delete deployments.apps nginx wordpress
kubectl delete statefulsets.apps mariadb
kubectl delete services mariadb nginx wordpress
kubectl delete persistentvolumeclaims mariadb-pvc nginx-certificates-pvc wordpress-pvc
kubectl delete secrets mariadb-secret wordpress-secret
kubectl delete configmaps nginx-config

echo "Destroy the resources..."
(cd /root/resources/terraform/jenkins && terraform destroy -auto-approve)
(cd /root/resources/terraform/oke_cluster && terraform destroy -auto-approve)

echo "Remove the terraform files..."
(cd /root/resources/terraform/jenkins && rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup)
(cd /root/resources/terraform/oke_cluster && rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup)

echo "Delete the compartments..."
/root/bin/oci iam compartment delete \
--compartment-id $(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid \
--name "DevOps" --raw-output --query "data[0].id") --force

/root/bin/oci iam compartment delete \
--compartment-id $(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid \
--name "OKE" --raw-output --query "data[0].id") --force

sleep 5
echo "Waiting for the compartments to be deleted..."
while [ "$(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid --query 'data[?name==`DevOps`]."lifecycle-state"' --raw-output | jq -r '.[0]')" == "DELETING" ] \
|| [ "$(/root/bin/oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid --query 'data[?name==`OKE`]."lifecycle-state"' --raw-output | jq -r '.[0]')" == "DELETING" ]; do
  sleep 10
done
sleep 5