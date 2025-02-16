resource "oci_core_vcn" "vcn1" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}

resource "oci_core_subnet" "public_subnet1" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.vcn1.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "public-subnet1"
  dns_label         = "pubsubnet1"
  security_list_ids = [oci_core_security_list.public_sl.id]
  route_table_id    = oci_core_route_table.public_rt.id
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "public-sl"

  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  ingress_security_rules {
    description = "Allow TCP traffic for SSH"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    description = "Allow HTTP traffic for Jenkins"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 8080
      max = 8080
    }
  }
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  display_name   = "public-rt"
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination       = "0.0.0.0/0"
  }
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
