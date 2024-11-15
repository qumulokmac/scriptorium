################################################################################
# 
# 
# Copyright (c) 2022 Qumulo, Inc. All rights reserved.
# 
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
# 
#
# Name:     Spec Ubuntu Server Benchmark Provisioning Terraform Module
# Date:     December 2nd, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple azurerm_linux_virtual_machine's leveraging a gallery image
#
################################################################################

###
# Network Security Group
###
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.common_prefix}-nsg"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"

  security_rule {
    name                       = "AllowTMEremoteSSHAccess"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = "${var.authorized_ip_addresses}"
    destination_address_prefix = "*"
  }
}

# resource "azurerm_proximity_placement_group" "ppg" {
#   name                = "${var.common_prefix}-ppg"
#   location            = "${var.location}"
#   resource_group_name = "${var.rgname}"
#   allowed_vm_sizes    = ["${var.vmsize}"]
#   zone                = "${var.zone}"
# }

###
# Private NICs
###
resource "azurerm_network_interface" "nic" {
  count               = "${var.num_vms}"
  name                = "${var.common_prefix}-nic${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "${var.common_prefix}-niccfg-${count.index}"
    subnet_id                     = "${var.worker_subnet}"
    private_ip_address_allocation = "Dynamic"
  }
}

###
# NIC Association (NIC -> NSG)
###
resource "azurerm_network_interface_security_group_association" "nic-nsg-assn" {
  count                     = "${var.num_vms}"
  network_interface_id      = "${azurerm_network_interface.nic.*.id[count.index]}"
  network_security_group_id = azurerm_network_security_group.nsg.id
}

###
# Linux VM"s
###

data "azurerm_ssh_public_key" "product-sshkey" {
  name                = "product-${var.location}-sshkey"
  resource_group_name   = "${var.rgname}"
}
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                 = "${var.num_vms}"
  name                  = "${var.common_prefix}-${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${var.rgname}"
  network_interface_ids = ["${azurerm_network_interface.nic.*.id[count.index]}"]
  size                  = "${var.vmsize}" 
  zone                  = "${var.zone}"  
  computer_name         = "${var.common_prefix}-${count.index}"
  admin_username        = "${var.admin_username}"

  source_image_reference {
    publisher = var.ubuntu_image_reference["publisher"]
    offer     = var.ubuntu_image_reference["offer"]
    sku       = var.ubuntu_image_reference["sku"]
    version   = var.ubuntu_image_reference["version"]
  }

  os_disk {
    name                 = "${var.common_prefix}-osdisk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username  = "${var.admin_username}" 
    public_key = data.azurerm_ssh_public_key.product-sshkey.public_key
  }

  custom_data = base64encode(file("${path.module}/azure_linux_ud.sh"))
}

################################################################################
# Maestro Server, Public & Private IP"s, Association, VM
################################################################################

resource "azurerm_public_ip" "maestro_publicip" {
  name                = "${var.common_prefix}-maestro-pip"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["${var.zone}"]

}
resource "azurerm_network_interface" "maestro_nic" {
  name                = "${var.common_prefix}-maestro-nic"
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "${var.common_prefix}-maestro-niccfg"
    subnet_id                     = "${var.worker_subnet}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.maestro_publicip.id
  }
}
resource "azurerm_network_interface_security_group_association" "maestro-nic-nsg-assn" {
  network_interface_id      = azurerm_network_interface.maestro_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

###
# Maestro Linux VM
###
resource "azurerm_linux_virtual_machine" "maestro_vm" {
  name                  = "${var.common_prefix}-${var.location}-maestro"
  computer_name         = "${var.common_prefix}-${var.location}-maestro"
  admin_username        = "${var.admin_username}" 
  location            = "${var.location}"
  resource_group_name = "${var.rgname}"
  # priority              = "Spot"
  # eviction_policy       = "Deallocate"
  network_interface_ids = [azurerm_network_interface.maestro_nic.id]
  size                  = "${var.vmsize}" 
  zone                  = "${var.zone}"


  source_image_reference {
    publisher = var.ubuntu_image_reference["publisher"]
    offer     = var.ubuntu_image_reference["offer"]
    sku       = var.ubuntu_image_reference["sku"]
    version   = var.ubuntu_image_reference["version"]
  }
  
  os_disk {
    name                 = "${var.common_prefix}-maestro-${var.location}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username         = "${var.admin_username}" 
    public_key = data.azurerm_ssh_public_key.product-sshkey.public_key
  }
  custom_data = base64encode(file("${path.module}/azure_linux_ud.sh"))
}
