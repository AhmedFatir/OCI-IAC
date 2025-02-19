data "oci_core_images" "images1" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

resource "oci_core_instance" "jenkins_instance" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name = "jenkins_instance"
  shape               = "VM.Standard.E3.Flex"

  shape_config {
    memory_in_gbs = 16
    ocpus         = 1
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.images1.images[0].id
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
    display_name     = "jenkins_instance_vnic"
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    user_data           = base64encode(file("${path.module}/scripts/entrypoint.sh"))
  }
}