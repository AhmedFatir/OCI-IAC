variable "tenancy_ocid" {
  type        = string
  description = "value of the tenancy OCID"
  validation {
    condition     = length(var.tenancy_ocid) > 0
    error_message = "You must provide a valid OCID for the tenancy"
  }
}

variable "compartment_id" {
  type        = string
  description = "value of the compartment OCID"
  validation {
    condition     = length(var.compartment_id) > 0
    error_message = "You must provide a valid OCID for the compartment"
  }
}

variable "public_subnet_id" {
  type        = string
  description = "value of the public subnet OCID"
  validation {
    condition     = length(var.public_subnet_id) > 0
    error_message = "You must provide a valid OCID for the public subnet"
  }
}

variable "default_image_id" {
  description = "Fallback image id when no matching image is found"
  type        = string
  default     = ""
}

