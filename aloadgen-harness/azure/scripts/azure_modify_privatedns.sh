#!/bin/bash
################################################################################
# Script: azure_modify_privatedns.sh
# Purpose: Updates a private DNS zone in Azure by replacing existing A records
#          with new IPs read from a file.
# Usage: ./azure_modify_privatedns.sh
# Author: KMac | kmac@qumulo.com
# Date:   November 15, 2024
#
# Version: 111524.1006
#
################################################################################

RESOURCE_GROUP="product-eastus2-rg"
DNS_ZONE="qumulo.net"
RECORD_SET="cnq"
FQDN="${RECORD_SET}.${DNS_ZONE}"

IP_FILE="nodes.conf"

if [[ ! -f "$IP_FILE" ]]; then
    echo -e "\033[31mError: File $IP_FILE not found.\033[0m" >&2
    exit 1
fi

echo "Reading IP addresses from $IP_FILE..."
NEW_IPS=($(cat "$IP_FILE"))
if [[ $? -ne 0 ]]; then
    echo -e "\033[31mError: Failed to read IP addresses from the file.\033[0m" >&2
    exit 1
fi

if [[ ${#NEW_IPS[@]} -eq 0 ]]; then
    echo -e "\033[33mNo IP addresses found in the file.\033[0m"
    exit 0
fi

echo -e "\033[32mFound the following node private IP addresses:\033[0m ${NEW_IPS[@]}"

echo "Retrieving existing DNS entries for: ${FQDN}..."
CURRENT_DNS_ENTRIES=$(az network private-dns record-set a show --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE --name $RECORD_SET --query "aRecords[].ipv4Address" -o tsv 2>/dev/null)
if [[ $? -ne 0 ]]; then
    echo -e "\033[31mError: Failed to retrieve existing DNS entries.\033[0m" >&2
    exit 1
fi

# Convert IPs to JSON format required by Azure CLI
IP_JSON_ARRAY=$(printf '{"ipv4Address": "%s"},' "${NEW_IPS[@]}" | sed 's/,$//')

echo "Updating DNS record set with new IPs..."
az network private-dns record-set a update \
    --resource-group $RESOURCE_GROUP \
    --zone-name $DNS_ZONE \
    --name $RECORD_SET \
    --set aRecords="[$IP_JSON_ARRAY]" > /dev/null

if [[ $? -ne 0 ]]; then
    echo -e "\033[31mError: Failed to update the DNS record set.\033[0m" >&2
    exit 1
fi

echo -e "\033[32mDNS record set ${RECORD_SET} successfully updated in ${DNS_ZONE}.\033[0m"
echo -e "\n\033[34mDisplaying the current record and associated IP addresses for ${FQDN}:\033[0m"

UPDATED_RECORD=$(az network private-dns record-set a show --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE --name $RECORD_SET --query "aRecords[].ipv4Address" -o tsv)

if [[ -n "$UPDATED_RECORD" ]]; then
    echo -e "\033[32mCurrent IP addresses in ${FQDN}:\033[0m"
    for IP in $UPDATED_RECORD; do
        echo "$IP"
    done
else
    echo -e "\033[33mNo IP addresses found in ${FQDN}.\033[0m"
fi

echo -e "\033[32mOperation completed successfully.\033[0m"