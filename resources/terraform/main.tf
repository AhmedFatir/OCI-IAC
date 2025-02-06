// New Compartment
resource "oci_identity_compartment" "DevOps" {
  compartment_id = var.tenancy_ocid
  description    = "New compartment for DevOps infrastructure"
  name           = "DevOps"
}

// Virtual Cloud Network
resource "oci_core_vcn" "vcn1" {
  compartment_id = oci_identity_compartment.DevOps.id
  cidr_block     = "10.0.0.0/16"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}

// Public Subnet
resource "oci_core_subnet" "public_subnet1" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "public-subnet1"
  dns_label      = "pubsubnet1"
}

// Private Subnet
resource "oci_core_subnet" "private_subnet1" {
  compartment_id             = oci_identity_compartment.DevOps.id
  vcn_id                     = oci_core_vcn.vcn1.id
  cidr_block                 = "10.0.2.0/24"
  display_name               = "private-subnet1"
  dns_label                  = "privsubnet1"
  prohibit_public_ip_on_vnic = true
  availability_domain        = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

// Security List
resource "oci_core_security_list" "public_sl" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "public-sl"

  // Allow inbound SSH traffic
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  // Allow outbound traffic
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "ALL"
  }
}

// Route Table for Public Subnet
resource "oci_core_route_table" "public_rt" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "public-route-table"

  route_rules {
    destination        = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
  depends_on = [oci_core_subnet.public_subnet1]
}

// Route Table for private subnet
resource "oci_core_route_table" "private_rt" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "private-route-table"

  route_rules {
    destination        = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.natgw.id
  }
  depends_on = [oci_core_subnet.private_subnet1]
}

// NAT Gateway
resource "oci_core_nat_gateway" "natgw" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "nat-gateway"
}

// Internet Gateway
resource "oci_core_internet_gateway" "igw" {
  compartment_id = oci_identity_compartment.DevOps.id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "internet-gateway"
  enabled        = true
}

// Instance
resource "oci_core_instance" "instance1" {
  compartment_id      = oci_identity_compartment.DevOps.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard2.1"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.images1.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet1.id
    display_name     = "instance1_vnic"
    assign_public_ip = true
  }
  // addin the ssh key
  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
  }

  display_name = "instance1"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "images1" {
  compartment_id           = oci_identity_compartment.DevOps.id
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = "VM.Standard2.1"
}