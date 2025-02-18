# Fetch all availability domains dynamically
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Fetch the latest Oracle Linux image for the node pool
data "oci_core_images" "latest_oke_image" {
  compartment_id   = var.compartment_id
  operating_system = "Oracle Linux"
  shape            = "VM.Standard.E3.Flex"
  sort_by          = "TIMECREATED"
  sort_order       = "DESC"
}

# Fetch available OCI service IDs
data "oci_core_services" "all_oci_services" {

}

resource "oci_core_vcn" "vcn_oke" {
  compartment_id = var.compartment_id
  cidr_block     = "10.0.0.0/16"
  display_name   = "vcn-oke"
  dns_label      = "vcnoke"
}

resource "oci_core_internet_gateway" "oke_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "oke_nat_gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-nat-gw"
}

# Service Gateway (for access to OCI services like container registry)
resource "oci_core_service_gateway" "oke_service_gw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-service-gw"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }
}

# Route table for public subnets
resource "oci_core_route_table" "oke_public_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-public-rt"

  route_rules {
    description       = "Route to Internet Gateway"
    destination       = "0.0.0.0/0"
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
    network_entity_id = oci_core_nat_gateway.oke_nat_gw.id
  }

  route_rules {
    description       = "Route to OCI Services"
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    network_entity_id = oci_core_service_gateway.oke_service_gw.id
  }
}

# Security List with restricted inbound access
resource "oci_core_security_list" "oke_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn_oke.id
  display_name   = "oke-security-list"

  egress_security_rules {
    description      = "Allow all outbound traffic"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
  }

  ingress_security_rules {
    description = "Allow SSH Connections"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    description = "Allow Kubernetes API Access"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

# Public subnet for control plane
resource "oci_core_subnet" "oke_public_subnet1" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.0.0/24"
  display_name               = "oke-public-subnet1"
  dns_label                  = "okepubsubnet1"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_rt.id
  security_list_ids          = [oci_core_security_list.oke_security_list.id]
}

# Public subnet for Load Balancers
resource "oci_core_subnet" "oke_public_subnet2" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.1.0/24"
  display_name               = "oke-public-subnet2"
  dns_label                  = "okepubsubnet2"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.oke_public_rt.id
  security_list_ids          = [oci_core_security_list.oke_security_list.id]
}

# Private subnet for worker nodes
resource "oci_core_subnet" "oke_private_subnet" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.vcn_oke.id
  cidr_block                 = "10.0.2.0/24"
  display_name               = "oke-private-subnet"
  dns_label                  = "okeprivsubnet"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.oke_private_rt.id
  security_list_ids          = [oci_core_security_list.oke_security_list.id]
}

# OKE Cluster

resource "oci_containerengine_cluster" "DevOps_Cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.31.1"
  name               = "DevOps_Cluster"
  vcn_id             = oci_core_vcn.vcn_oke.id


  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_public_subnet1.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = true
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/12"
    }
    service_lb_subnet_ids = [oci_core_subnet.oke_public_subnet2.id]
  }
}

# OKE Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  compartment_id     = var.compartment_id
  cluster_id         = oci_containerengine_cluster.DevOps_Cluster.id
  name               = "oke_node_pool"
  kubernetes_version = "v1.31.1"
  node_shape         = "VM.Standard.E3.Flex"

  node_source_details {
    boot_volume_size_in_gbs = 50
    source_type             = "image"
    image_id                = data.oci_core_images.latest_oke_image.images[0].id
  }

  node_config_details {
    size = 3

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.oke_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.oke_private_subnet.id
    }
  }
  initial_node_labels {
    key   = "nodepool"
    value = "oke_node_pool"
  }
}
