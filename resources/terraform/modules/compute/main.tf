# data "oci_core_images" "images1" {
#   compartment_id           = var.compartment_id
#   operating_system         = "Debian"
#   operating_system_version = "10"
#   shape                    = "VM.Standard2.1"
# }

data "oci_core_images" "images1" {
  compartment_id           = oci_identity_compartment.DevOps.id
  operating_system         = "Oracle Linux"
  operating_system_version = "7.9"
  shape                    = "VM.Standard2.1"
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

resource "oci_core_instance" "instance1" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  shape               = "VM.Standard2.1"

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.images1.images[0].id
  }

  create_vnic_details {
    subnet_id        = var.public_subnet_id
    display_name     = "instance1_vnic"
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/id_rsa.pub")
    # user_data           = base64encode(file("${path.module}/scripts/entrypoint.sh"))
  }

  display_name = "instance1"
}
