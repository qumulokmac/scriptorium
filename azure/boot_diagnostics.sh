

az storage account create --name tmewinbootdiagnostics --resource-group product-eastasia-rg --location eastasia --sku Standard_LRS --kind StorageV2

# az vm boot-diagnostics enable --resource-group myResourceGroup --name myVM --storage mydiagstorage


###
# download the logs
###

az vm run-command invoke --command-id RunPowerShellScript --name myVM --resource-group myResourceGroup --scripts "Compress-Archive -Path C:\eventlogs_application.csv,C:\eventlogs_system.csv -DestinationPath C:\eventlogs.zip"
az vm run-command invoke --command-id RunPowerShellScript --name myVM --resource-group myResourceGroup --scripts "Start-BitsTransfer -Source C:\eventlogs.zip -Destination https://tmewinbootdiagnostics.blob.core.windows.net/bootdiagnostics-smbbv20-ef6ba449-7d36-4d55-88d7-6dd5784bdf46/eventlogs.zip"

