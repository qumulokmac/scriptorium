
# az sig create --resource-group crucible --gallery-name product_build_images --description "Qumulo Product Team Build Images" --location eastus --publisher-email "kmcdonald@qumulo.com" 

###
# Creating an image to share 
###

tenantID="3fa909c1-1b1f-4ebb-8953-cdc139fb2112"
subID="2f0fe240-4ebb-45eb-8307-9f54ae213157"
sourceImageID="/subscriptions/2f0fe240-4ebb-45eb-8307-9f54ae213157/resourceGroups/crucible/providers/Microsoft.Compute/images/maestro-image-20231128"

az account set --subscription $subID

# az sig image-version create --gallery-image-definition maestro --gallery-image-version 1.0.0 --gallery-name product_build_images --resource-group crucible --image-version $sourceImageID



