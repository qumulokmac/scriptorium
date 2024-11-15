################################################################################
#
# File: ./modules/ec2_instances/variables.tf variables.tf 
#
################################################################################

variable "region" {
  type        = string
  description = "AWS Region to deploy the resources in."
}

variable "common_tags" {
  type = map(string)
}

variable "num_windows_instances" {
  type = number
}

variable "num_ubuntu_instances" {
  type = number
}

variable "ubuntu_ami_id" {
  type = string
}

variable "windows_ami_id" {
  type = string
}

variable "instance_types" {
  type = map(string)
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "grumpquatkey"
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "nat_eip" {
  type = string
}

variable "common_prefix" {
  type = string
}

variable "admin_password" {
  description = "The administrator password for Windows instances."
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC where the instances will be created."
  type        = string
}

