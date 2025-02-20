resource "oci_identity_compartment" "OKE" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for OKE cluster"
  name           = "OKE"
}

module "network" {
  source         = "./modules/network"
  compartment_id = oci_identity_compartment.OKE.id
}

module "cluster" {
  source             = "./modules/cluster"
  k8s_version        = "v1.31.1"
  compartment_id     = oci_identity_compartment.OKE.id
  vcn_id             = module.network.vcn_id
  endpoint_subnet_id = module.network.endpoint_subnet_id
  lb_subnet_id       = module.network.lb_subnet_id
  private_subnet_id  = module.network.private_subnet_id
}