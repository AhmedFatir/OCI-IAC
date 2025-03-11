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

variable "vcn_id" {
  type        = string
  description = "value of the VCN OCID"
  validation {
    condition     = length(var.vcn_id) > 0
    error_message = "You must provide a valid OCID for the VCN"
  }
}

variable "endpoint_subnet_id" {
  type        = string
  description = "value of the K8s API endpoint subnet OCID"
  validation {
    condition     = length(var.endpoint_subnet_id) > 0
    error_message = "You must provide a valid OCID for the endpoint subnet"
  }
}

variable "lb_subnet_id" {
  type        = string
  description = "value of the Load Balancer subnet OCID"
  validation {
    condition     = length(var.lb_subnet_id) > 0
    error_message = "You must provide a valid OCID for the Load Balancer subnet"
  }
}

variable "private_subnet_id" {
  type        = string
  description = "value of the private subnet OCID"
  validation {
    condition     = length(var.private_subnet_id) > 0
    error_message = "You must provide a valid OCID for the private subnet"
  }
}