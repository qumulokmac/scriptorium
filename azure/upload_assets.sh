#!/bin/bash
################################################################################
#
#
#
#
################################################################################
STORAGEACCTNAME="tmeresources"
CONTAINER="backups"
RGNAME="product-eastasia-rg"
AZURE_STORAGE_KEY=$(az storage account keys list --resource-group $RGNAME --account-name $STORAGEACCTNAME --query '[0].value' --output tsv)
EXPIRY_DATE=$(date -u -v+2y "+%Y-%m-%dT%H:%MZ")

FILES=("smbbench-fio.zip", "smbbench-software.zip", "smbbench-qumulo-home.zip" )

for FILENAME in i"${FILES[@]}"
do
	echo "Uploading $FILENAME to blob in $STORAGEACCTNAME/$CONTAINER"
	az storage blob upload --account-name tmeresources --container-name assets --name $FILENAME--file $FILENAME --overwrite
	echo "Upload of $FILENAME returned: $_"

done

echo "Creating SAS Tokens"


for FILENAME in "${blobs[@]}"
do
    echo "Generate the SAS token for $FILENAME in $STORAGEACCTNAME/$CONTAINER"
    SASTOKEN=$(az storage blob generate-sas --account-name $STORAGEACCTNAME --container-name $CONTAINER --name $FILENAME--permissions r --expiry $EXPIRY_DATE --account-key $AZURE_STORAGE_KEY --https-only --output tsv)

    echo "Constructing the pre-signed URL for $FILENAME in $STORAGEACCTNAME/$CONTAINER"
    BLOBURL=$(az storage blob url --account-name $STORAGEACCTNAME --container-name $CONTAINER --name $FILENAME --output tsv)
    PRESIGNEDURL="${BLOBURL}?${SASTOKEN}"

    # Output the pre-signed URL
    echo "Pre-Signed URL for $FILENAME: $PRESIGNEDURL"

done
