resource "oci_identity_compartment" "DevOps" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for DevOps infrastructure"
  name           = "DevOps"
}

module "network" {
  source         = "./modules/network"
  compartment_id = oci_identity_compartment.DevOps.id
}

module "compute" {
  source           = "./modules/compute"
  compartment_id   = oci_identity_compartment.DevOps.id
  public_subnet_id = module.network.public_subnet_id
}