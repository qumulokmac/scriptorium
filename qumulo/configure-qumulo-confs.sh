#!/usr/bin/bash
######################################################################
# configure-qumulo-confs.sh
#
# kmac@qumulo.com
# May 8th, 2024
######################################################################

WORKERSCONF='/home/qumulo/test-workers.conf'
NODESCONF='/home/qumulo/test-nodes.conf'

check_error() {
    local exit_code=$?
    local error_message="$1"
    if [ $exit_code -ne 0 ]; then
        echo "Error: $error_message"
        exit $exit_code
    fi
}

echo "Creating $WORKERSCONF file..."
REGION=$(curl -s -H Metadata:true 'http://169.254.169.254/metadata/instance?api-version=2017-12-01' | jq -r '.compute.location')
check_error 'Failed to retrieve region information.'

RESOURCE_GROUP="product-${REGION}-rg"

az vm list-ip-addresses --resource-group ${RESOURCE_GROUP} --output json | jq '.[] | .virtualMachine.name' | grep -v maestro | sed -e 's/\"//g' > "$WORKERSCONF"
check_error 'Failed to retrieve worker information.'

echo -e "\n\nThe following worker names have been added to the $WORKERSCONF file:\n"
cat "$WORKERSCONF"

declare -a CLUSTERS=( $(az resource list --resource-type 'Qumulo.Storage/fileSystems' -o json  | jq -r '.[] | .name') )
check_error 'Failed to retrieve Qumulo cluster information.'

if [ ${#CLUSTERS[@]} -eq 1 ]; then
    ANQ_CLUSTER=${CLUSTERS[0]}
else
    declare -a OPTIONS=()
    index=0
    echo -e "\nPlease select the ANQ cluster to use in this harness:\n"
    for cluster in "${CLUSTERS[@]}"
    do
        echo "${index}: $cluster"
        OPTIONS["$index"]="$cluster"
        ((index++))
    done

    echo -n -e "\n   > "
    read -r answer
    echo ""

    ANQ_CLUSTER=${OPTIONS[$answer]}
fi

az network nic list -o json | jq --arg name "${ANQ_CLUSTER}" '.[] | select(.name | startswith($name)).ipConfigurations[0].privateIPAddress' | sed -e 's/\"//g' > "$NODESCONF"
check_error "Failed to retrieve network interface information for cluster $ANQ_CLUSTER."

echo -e "\n\nThe following entries have been added to the nodes.conf file for cluster ${ANQ_CLUSTER}:\n"
cat "$NODESCONF"
