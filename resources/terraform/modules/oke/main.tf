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

# Service Gateway (for access to OCI services like container registry)
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
    description      = "Route to OCI Services"
    destination_type = "SERVICE_CIDR_BLOCK"
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
    description = "Allow Kubernetes Control Plane to communicate with OKE"
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
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
    description = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
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

###################################### OKE Cluster and Node Pool ######################################

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

# OKE Cluster
resource "oci_containerengine_cluster" "DevOps_Cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.k8s_version
  name               = "DevOps_Cluster"
  type               = "ENHANCED_CLUSTER"
  vcn_id             = oci_core_vcn.vcn_oke.id

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  endpoint_config {
    is_public_ip_enabled = "true"
    subnet_id            = oci_core_subnet.oke_public_subnet1.id
  }
  freeform_tags = {
    "OKEclusterName" = "DevOps_Cluster"
  }
  options {
    admission_controller_options {
      is_pod_security_policy_enabled = "false"
    }
    persistent_volume_config {
      freeform_tags = {
        "OKEclusterName" = "DevOps_Cluster"
      }
    }
    service_lb_config {
      freeform_tags = {
        "OKEclusterName" = "DevOps_Cluster"
      }
    }
    service_lb_subnet_ids = [oci_core_subnet.oke_public_subnet2.id]
  }
}

# OKE Node Pool
resource "oci_containerengine_node_pool" "oke_node_pool" {
  cluster_id         = oci_containerengine_cluster.DevOps_Cluster.id
  compartment_id     = var.compartment_id
  name               = "oke_node_pool"
  kubernetes_version = var.k8s_version
  node_shape         = "VM.Standard.E3.Flex"
  freeform_tags = {
    "OKEnodePoolName" = "oke_node_pool"
  }
  initial_node_labels {
    key   = "nodepool"
    value = "oke_node_pool"
  }

  node_config_details {
    size = "3"

    freeform_tags = {
      "OKEnodePoolName" = "oke_node_pool"
    }
    node_pool_pod_network_option_details {
      cni_type = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [oci_core_subnet.oke_private_subnet.id]
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_private_subnet.id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.oke_private_subnet.id
    }

    # Availability Domain 3 is not working for the current moment

    # placement_configs {
    #   availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
    #   subnet_id           = oci_core_subnet.oke_private_subnet.id
    # }
  }
  node_eviction_node_pool_settings {
    eviction_grace_duration = "PT1H"
  }
  node_shape_config {
    memory_in_gbs = "16"
    ocpus         = "1"
  }
  node_source_details {
    source_type = "IMAGE"
    image_id    = data.oci_core_images.latest_oke_image.images[0].id
  }
}
