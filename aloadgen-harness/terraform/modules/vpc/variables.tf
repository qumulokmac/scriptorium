################################################################################
#
# File: ./modules/vpc/variables.tf variables.tf 
#
################################################################################

variable "common_tags" {
  type = map(string)
}

variable "region" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "common_prefix" {
  type = string
}
