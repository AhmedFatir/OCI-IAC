resource "oci_identity_compartment" "OKE" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for OKE cluster"
  name           = "OKE"
}

resource "oci_identity_compartment" "DevOps" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for DevOps infrastructure"
  name           = "DevOps"
}

module "DevOps-network" {
  source         = "./jenkins/network"
  compartment_id = oci_identity_compartment.DevOps.id
}

module "compute" {
  source           = "./jenkins/compute"
  compartment_id   = oci_identity_compartment.DevOps.id
  public_subnet_id = module.DevOps-network.public_subnet_id
}

module "OKE-network" {
  source         = "./oke_cluster/network"
  compartment_id = oci_identity_compartment.OKE.id
}

module "cluster" {
  source             = "./oke_cluster/cluster"
  k8s_version        = "v1.31.1"
  compartment_id     = oci_identity_compartment.OKE.id
  vcn_id             = module.OKE-network.vcn_id
  endpoint_subnet_id = module.OKE-network.endpoint_subnet_id
  lb_subnet_id       = module.OKE-network.lb_subnet_id
  private_subnet_id  = module.OKE-network.private_subnet_id
}
