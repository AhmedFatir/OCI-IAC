data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_vcn" "vcn1" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}

resource "oci_core_subnet" "public_subnet1" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "public-subnet1"
  dns_label      = "pubsubnet1"
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "public-sl"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 50000
      max = 50000
    }
  }

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "ALL"
  }
}

resource "oci_core_default_route_table" "default_rt" {
  manage_default_resource_id = oci_core_vcn.vcn1.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
  }
}

resource "oci_core_nat_gateway" "natgw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "nat-gateway"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "internet-gateway"
  enabled        = true
}

output "public_subnet_id" {
  value = oci_core_subnet.public_subnet1.id
}
