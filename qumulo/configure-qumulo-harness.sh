#!/usr/bin/bash

WORKERSCONF="/home/qumulo/tools/workers.conf"
NODESCONF="/home/qumulo/tools/nodes.conf"

echo "Creating $WORKERSCONF file..."
REGION=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-12-01" | jq -r '.compute.location')
if [ -z ${REGION} ]; then
    echo "Failed to retrieve region information."
    exit 1
fi

RESOURCE_GROUP="product-${REGION}-rg"

az vm list-ip-addresses --resource-group ${RESOURCE_GROUP} --output json | jq '.[] | .virtualMachine.name' | grep -v maestro | sed -e 's/\"//g' > "$WORKERSCONF"

echo -e "\n\nThe following worker names have been added to the $WORKERSCONF file:\n"
cat "$WORKERSCONF"

declare -a CLUSTERS=( $(az resource list --resource-type "Qumulo.Storage/fileSystems" -o json  | jq -r '.[] | .name') )

if [ ${#CLUSTERS[@]} -eq 1 ]; then
    ANQ_CLUSTER=${CLUSTERS[0]}
else
    declare -a OPTIONS=()
    index=0
    echo -e "\nMultiple ANQ clusters found. Please select the cluster to use in this harness:\n"
    for cluster in "${CLUSTERS[@]}"
    do
        echo "${index}: $cluster"
        OPTIONS[$index]=$cluster
        ((index++))
    done

    echo -n -e "\n   > "
    read -r answer
    echo ""

    ANQ_CLUSTER=${OPTIONS[$answer]}
fi

az network nic list -o json | jq --arg name "${ANQ_CLUSTER}" '.[] | select(.name | startswith($name)).ipConfigurations[0].privateIPAddress' | sed -e 's/\"//g' > "$NODESCONF"

echo -e "\n\nThe following entries have been added to the nodes.conf file for cluster ${ANQ_CLUSTER}:\n"
cat "$NODESCONF"
