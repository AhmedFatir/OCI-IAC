resource "oci_identity_compartment" "DevOps" {
  compartment_id = var.tenancy_ocid
  description    = "New compartment for DevOps infrastructure"
  name           = "DevOps"
}

module "network" {
  source         = "./modules/network"
  tenancy_ocid   = var.tenancy_ocid
  compartment_id = oci_identity_compartment.DevOps.id
}

module "compute" {
  source           = "./modules/compute"
  tenancy_ocid     = var.tenancy_ocid
  compartment_id   = oci_identity_compartment.DevOps.id
  public_subnet_id = module.network.public_subnet_id
}