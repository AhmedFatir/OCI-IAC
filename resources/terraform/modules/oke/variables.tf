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

variable "k8s_version" {
  type        = string
  description = "Kubernetes version"
  default     = "v1.31.1"
  validation {
    condition     = length(var.k8s_version) > 0
    error_message = "You must provide a valid Kubernetes version"
  }
}