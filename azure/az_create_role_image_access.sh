
Name                          CloudName    SubscriptionId                        TenantId                              State    IsDefault
----------------------------  -----------  ------------------------------------  ------------------------------------  -------  -----------
QaaS Staging Clusters         AzureCloud   7418a6db-97af-4ae5-8633-c2549a0fdd3f  3fa909c1-1b1f-4ebb-8953-cdc139fb2112  Enabled  False
azure-qumulo-product          AzureCloud   2f0fe240-4ebb-45eb-8307-9f54ae213157  3fa909c1-1b1f-4ebb-8953-cdc139fb2112  Enabled  False
azure-qumulo-product-vpn      AzureCloud   46a5411a-cc0e-4001-a8ef-b00ceaf6d9bf  3fa909c1-1b1f-4ebb-8953-cdc139fb2112  Enabled  False
qumulo-cloud-sa               AzureCloud   03a3547d-beb4-45f7-96ea-e6559202f2d2  3fa909c1-1b1f-4ebb-8953-cdc139fb2112  Enabled  False
azure-vnet-injection-testing  AzureCloud   197c6192-5f11-435f-8ec5-252eef740dfc  7ec8df94-fa8b-4bd4-9d8a-2784709108ac  Enabled  True


subscriptionID=2f0fe240-4ebb-45eb-8307-9f54ae213157
imageResourceGroup=crucible

###
# What to use here ... 
###
identityName="aibIdentity"

curl https://raw.githubusercontent.com/azure/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

# Create a unique role name to avoid clashes in the same Azure Active Directory domain
imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')

# Update the JSON definition using stream editor
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

# Create a custom role from the sample aibRoleImageCreation.json description file.
az role definition create --role-definition ./aibRoleImageCreation.json

# Get the user-assigned managed identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $identityName --query clientId -o tsv)

# Grant the custom role to the user-assigned managed identity for Azure Image Builder.
az role assignment create --assignee $imgBuilderCliId --role $imageRoleDefName --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

