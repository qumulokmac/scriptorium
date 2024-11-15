################################################################################
# 
# Ubuntu    Spec Provisioning Terraform Module
# Date:     December 8th, 2023
# Author:   kmac@qumulo.com
# Desc:     Provision multiple ubuntu VM's leveraging a prebuilt image
#
#
################################################################################

output "private_ips" {
  value = tomap({
    for name, vm in azurerm_network_interface.nic : name => vm.private_ip_address
  })
}

output "azurerm_linux_virtual_machine" {
  value = "${azurerm_linux_virtual_machine.linux_vm.*.name}"
}
