#!/bin/bash 

# az vm boot-diagnostics enable --resource-group product-eastasia-rg --name smbb-v2-eastasia-maestro --storage mystorageaccount
# az vm boot-diagnostics get-boot-log --resource-group myResourceGroup --name myVM



az vm run-command invoke --command-id RunPowerShellScript --name smbb-v2-eastasia-maestro --resource-group product-eastasia-rg --scripts @get-vm-logs.ps1

