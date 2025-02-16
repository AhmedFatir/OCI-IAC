
# Get the Compartment OCID
COMPARTMENT_OCID=$(oci iam compartment list --compartment-id $TF_VAR_tenancy_ocid --name "DevOps" --raw-output --query "data[0].id")
# Get the Instance OCID
INSTANCE_OCID=$(oci compute instance list --compartment-id $COMPARTMENT_OCID --query "data[?\"display-name\"=='instance1'].id | [0]" --raw-output)
# Get the Public IP of the Instance
IP=$(oci compute instance list-vnics --instance-id $INSTANCE_OCID | jq -r '.data[0]."public-ip"')
# SSH into the Instance
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$(IP)