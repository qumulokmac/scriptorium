################################################################################
#
# File: ./modules/security_group/variables.tf variables.tf 
#
################################################################################

variable "common_tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "authorized_ips" {
  type = map(object({
    ip          = string
    description = string
  }))
}

variable "common_prefix" {
  type = string
}
