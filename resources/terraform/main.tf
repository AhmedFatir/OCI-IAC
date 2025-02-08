resource "oci_identity_compartment" "DevOps" {
  compartment_id = var.tenancy_ocid
  description    = "New compartment for DevOps infrastructure"
  name           = "DevOps"
}

module "network_and_security" {
  source         = "./modules/network_and_security"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = oci_identity_compartment.DevOps.id
}

module "compute" {
  source           = "./modules/compute"
  tenancy_ocid     = var.tenancy_ocid
  compartment_id   = oci_identity_compartment.DevOps.id
  public_subnet_id = module.network_and_security.public_subnet_id
}