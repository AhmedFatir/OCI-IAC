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
  vcn_id             = var.vcn_id

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }
  endpoint_config {
    is_public_ip_enabled = "true"
    subnet_id            = var.endpoint_subnet_id
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
    service_lb_subnet_ids = [var.lb_subnet_id]
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
      cni_type       = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [var.private_subnet_id]
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = var.private_subnet_id
    }
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = var.private_subnet_id
    }

    # Availability Domain 3 is not working for the current moment

    # placement_configs {
    #   availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
    #   subnet_id           = var.private_subnet_id
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
