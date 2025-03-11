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
