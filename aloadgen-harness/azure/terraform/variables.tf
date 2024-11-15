################################################################################
# 
# Ubuntu    Spec Provisioning Terraform Module
# Date:     December 8th, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple ubuntu VM's leveraging a prebuilt image
#
#
# Be sure to update the defaults with your specific values.
###
################################################################################

variable "common_prefix" {
  type        = string
  description = "Prefix for all resources deployed by this project."
  default     = "YOUR_PREFIX"
}

variable "num_vms" {
  type        = number
  description = "Number of VM's"
  default     = 1
}

variable "vmsize" {
  type        = string
  description = "Virtual Machine Size for the Servers"
  default     = "Standard_D16ds_v5"
}

variable "ubuntu_image_reference" {
  type = map(string)
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
variable "admin_username" {
  type        = string
  description = "Local admin username"
  default     = "qumulo"
}
variable "rgname" {
  type        = string
  description = "RG Name "
  default     = "YOUR_RG_NAME"
}
variable "location" {
  type        = string
  description = "Microsoft Region/Location"
  default     = "eastus2"
}

variable "zone" {
  type        = string
  description = "Zone in the region you would like to deploy the Azure Native Qumulo cluster in"
  default     = "1"
}

variable "worker_subnet" {
  type        = string
  description = "Subnet to deploy worker VM's too - should be in the same vNet as the cluster"
  default     = "/subscriptions/YOUR_SUB_UUID_HERE/resourceGroups/YOUR_RG_NAME/providers/Microsoft.Network/virtualNetworks/YOUR_VNET_NAME_HERE/subnets/YOUR_WORKER_SUBNET_HERE"
}

variable "authorized_ip_addresses" {
  type        = list
  description = "Ip addresses for the workstations that need access to the harness"
  default     = ["1.3.2.172/32", "8.15.1.2/32", "3.4.2.8", "2.22.8.2"]
}
