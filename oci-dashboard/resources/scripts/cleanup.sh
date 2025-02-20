#!/bin/bash

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
