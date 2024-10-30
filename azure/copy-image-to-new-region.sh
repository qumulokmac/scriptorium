


# az extension add --name image-copy-extension

az image copy --source-resource-group product-eastus2-rg --source-object-name SPECStorage2020-image-eastus2-20240308 --target-location eastus --target-resource-group crucible --cleanup


###
# https://github.com/Azure/azure-cli/issues/25431
# If you deleted th source VM disk, follow this peocedure: 
###
- First, create a new virtual machine vm_temp by the image MyHPCImage-7.
- Then, create a new image image_new for the virtual machine vm_temp.
- Finally, use the new image image_new to perform a copy operation.

