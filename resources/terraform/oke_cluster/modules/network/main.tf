# Fetch available OCI service IDs
data "oci_core_services" "all_oci_services" {}

resource "oci_core_vcn" "vcn_oke" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "vcn-oke"
  dns_label      = "vcnoke"
}

###################################### Internet Gateway, NAT Gateway, and Service Gateway ######################################
resource "oci_core_internet_gateway" "oke_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "oke_nat_gw" {
  compartment_id = var.compartment_id
  display_name   = "oke-nat-gw"
  vcn_id         = oci_core_vcn.vcn_oke.id
}

resource "oci_core_service_gateway" "oke_service_gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-service-gw"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }
}

###################################### Route Tables ######################################
# Route table for public subnets
resource "oci_core_route_table" "oke_public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-public-rt"

  route_rules {
    description       = "Route to Internet Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke_igw.id
  }
}

# Route table for private subnets
resource "oci_core_route_table" "oke_private_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-private-rt"

  route_rules {
    description       = "Route to NAT Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke_nat_gw.id
  }

  route_rules {
    description       = "Route to OCI Services"
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    network_entity_id = oci_core_service_gateway.oke_service_gw.id
  }
}

###################################### Subnets ######################################
# Public subnet for Load Balancers
resource "oci_core_subnet" "oke_public_subnet2" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.20.0/24"
  display_name               = "oke-public-subnet2"
  dns_label                  = "okepubsubnet2"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.oke_public_rt.id
  security_list_ids          = [oci_core_security_list.oke_lb_sl.id]
}

# Public subnet for Kubernetes API endpoint
resource "oci_core_subnet" "oke_public_subnet1" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.0.0/28"
  display_name               = "oke-public-subnet1"
  dns_label                  = "okepubsubnet1"
  prohibit_public_ip_on_vnic = "false"
  route_table_id             = oci_core_route_table.oke_public_rt.id
  security_list_ids          = [oci_core_security_list.oke_api_endpoint_sl.id]
}

# Private subnet for worker nodes
resource "oci_core_subnet" "oke_private_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.10.0/24"
  display_name               = "oke-private-subnet"
  dns_label                  = "okeprivsubnet"
  prohibit_public_ip_on_vnic = "true"
  route_table_id             = oci_core_route_table.oke_private_rt.id
  security_list_ids          = [oci_core_security_list.oke_node_sl.id]
}

###################################### Security Lists ######################################
# Security List for Load Balancers
resource "oci_core_security_list" "oke_lb_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-lb-sl"
}

# Security Lists for OKE API Endpoint
resource "oci_core_security_list" "oke_api_endpoint_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-api-endpoint-sl"
  # Egress rules
  egress_security_rules {
    description      = "Allow Kubernetes Control Plane to communicate with OKE"
    destination      = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = 443
      min = 443
    }
  }
  egress_security_rules {
    description      = "All traffic to worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  # Ingress rules
  ingress_security_rules {
    description = "External access to Kubernetes API endpoint"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = 6443
      min = 6443
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to Kubernetes API endpoint communication"
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = 6443
      min = 6443
    }
  }
  ingress_security_rules {
    description = "Kubernetes worker to control plane communication"
    protocol    = "6"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = 12250
      min = 12250
    }
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
}

# Security List for worker nodes
resource "oci_core_security_list" "oke_node_sl" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-node-sl"
  # Egress rules
  egress_security_rules {
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
    destination      = "10.0.10.0/24"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  egress_security_rules {
    description      = "Access to Kubernetes API Endpoint"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = 6443
      min = 6443
    }
  }
  egress_security_rules {
    description      = "Kubernetes worker to control plane communication"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = 12250
      min = 12250
    }
  }
  egress_security_rules {
    description      = "Path discovery"
    destination      = "10.0.0.0/28"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination      = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    protocol         = "6"
    stateless        = "false"
    tcp_options {
      max = 443
      min = 443
    }
  }
  egress_security_rules {
    description      = "ICMP Access from Kubernetes Control Plane"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol  = "1"
    stateless = "false"
  }
  egress_security_rules {
    description      = "Worker Nodes access to Internet"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }
  # Ingress rules
  ingress_security_rules {
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
    protocol    = "all"
    source      = "10.0.10.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Path discovery"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "TCP access from Kubernetes Control Plane"
    protocol    = "6"
    source      = "10.0.0.0/28"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  ingress_security_rules {
    description = "Inbound SSH traffic to worker nodes"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = 22
      min = 22
    }
  }
}

###################################### Output ######################################

output "vcn_id" {
  value = oci_core_vcn.vcn_oke.id
}

output "endpoint_subnet_id" {
  value = oci_core_subnet.oke_public_subnet1.id
}

output "lb_subnet_id" {
  value = oci_core_subnet.oke_public_subnet2.id
}

output "private_subnet_id" {
  value = oci_core_subnet.oke_private_subnet.id
}