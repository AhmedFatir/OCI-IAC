variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
  validation {
    condition     = length(var.tenancy_ocid) > 0
    error_message = "The tenancy_ocid variable must be set in the environment or in the terraform.tfvars file"
  }
}
variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
  validation {
    condition     = length(var.user_ocid) > 0
    error_message = "The user_ocid variable must be set in the environment or in the terraform.tfvars file"
  }
}
variable "fingerprint" {
  description = "The fingerprint of the public key"
  type        = string
  validation {
    condition     = length(var.fingerprint) > 0
    error_message = "The fingerprint variable must be set in the environment or in the terraform.tfvars file"
  }
}
variable "private_key_path" {
  description = "The path to the private key"
  type        = string
  validation {
    condition     = length(var.private_key_path) > 0
    error_message = "The private_key_path variable must be set in the environment or in the terraform.tfvars file"
  }
}
variable "region" {
  description = "The region to deploy the infrastructure"
  type        = string
  validation {
    condition     = length(var.region) > 0
    error_message = "The region variable must be set in the environment or in the terraform.tfvars file"
  }
}
