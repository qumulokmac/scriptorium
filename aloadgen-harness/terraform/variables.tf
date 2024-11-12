################################################################################
#
# File: ./variables.tf variables.tf 
#
################################################################################

variable "common_prefix" {
  type        = string
  description = "Prefix for all resources deployed by this project."
  default     = "alg"
}

variable "num_ubuntu_instances" {
  type        = number
  description = "Number of Ubuntu instances to deploy"
  default     = 0
}

variable "num_windows_instances" {
  type        = number
  description = "Number of Windows instances to deploy"
  default     = 0
}

variable "region" {
  type        = string
  description = "AWS Region to deploy the resources in."
  default     = "us-east-1"
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "instance_types" {
  type = map(string)
  default = {
    ubuntu  = "i4i.32xlarge"
    windows = "i4i.8xlarge"
  }
}

variable "key_name" {
  type        = string
  description = "Path to the SSH public key."
  default     = "grumpquat"
}

variable "authorized_ips" {
  type = map(object({
    ip          = string
    description = string
  }))
  description = "Map of authorized IP addresses and their descriptions"
  default = {
    kmac_home = {
      ip          = "98.193.213.172/32"
      description = "KMac's home public IP address"
    }
  }
}

variable "admin_password" {
  type        = string
  description = "The Windows Administrator password."
  default     = "Grumpquat123!!!"
}

