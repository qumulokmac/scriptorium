#!/bin/bash
################################################################################
# Script: upload_qcore.sh
# Purpose: Generate a SAS token, construct the destination URL, and upload a
#          Qumulo Core `.deb` package to an Azure Storage container using AzCopy.
################################################################################

# Constants
QFS_VERSION="7.4.1"
SOURCE_FILE="/home/kmac/bits/qumulo-core.deb"
STORAGE_ACCOUNT="cnqutilitybucketseasia"
CONTAINER_NAME="bits"
LOG_FILE="/tmp/azcopy_qcore_$(date +%Y%m%d_%H%M%S).log"
EXPIRY_DATE=$(date -d "+7 days" +%Y-%m-%d)

# Check AzCopy availability
if ! command -v azcopy &>/dev/null; then
    echo "Error: AzCopy is not installed or not in PATH. Please install it to proceed." >&2
    exit 1
fi

# Retrieve the storage account key
ACCOUNT_KEY=$(az storage account keys list --account-name "${STORAGE_ACCOUNT}" --query "[0].value" -o tsv)
if [[ -z "$ACCOUNT_KEY" ]]; then
    echo "Error: Failed to retrieve storage account key for ${STORAGE_ACCOUNT}." >&2
    exit 1
fi

# Generate SAS token
SASTOKEN=$(az storage container generate-sas \
    --account-name "${STORAGE_ACCOUNT}" \
    --name "${CONTAINER_NAME}" \
    --permissions rlcw \
    --expiry "${EXPIRY_DATE}" \
    --account-key "${ACCOUNT_KEY}" \
    --output tsv)
if [[ -z "$SASTOKEN" ]]; then
    echo "Error: Failed to generate SAS token." >&2
    exit 1
fi

# Construct destination URL
DEST="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${CONTAINER_NAME}/images/${QFS_VERSION}/qumulo-core.deb?${SASTOKEN}"
echo "Generated SAS Token and constructed destination URL: ${DEST}"

# Validate source file existence
if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "Error: Source file ${SOURCE_FILE} does not exist." >&2
    exit 1
fi

# Upload file
echo "Starting upload of ${SOURCE_FILE} to Azure Storage..."
azcopy copy "${SOURCE_FILE}" "${DEST}" | tee -a "${LOG_FILE}" 2>&1

# Verify upload success
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    echo "Error: AzCopy upload failed. Check the log file for details: ${LOG_FILE}" >&2
    exit 1
fi

# Success message
echo "Upload completed successfully. The file ${SOURCE_FILE} has been uploaded to:"
echo "${DEST}"
echo "Log details are available in ${LOG_FILE}."