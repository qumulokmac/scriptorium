#!/bin/bash
################################################################################
# Script: check_nodes_network.sh
# Purpose: Checks the network status of IP addresses listed in nodes.conf.
# Usage: ./check_nodes_network.sh
# Author: KMac | kmac@qumulo.com
# Date:   November 6, 2024
################################################################################

input_file="nodes.conf"
reachable=()
unreachable=()

# Loop through each IP in the file and ping it
while IFS= read -r ip; do
    if ping -c 1 -W 1 "$ip" &> /dev/null; then
        reachable+=("$ip")
    else
        unreachable+=("$ip")
    fi
done < "$input_file"

# Print the report
echo -e "\nNetwork Status Report"
echo "----------------------"
echo -e "Reachable IPs:"
for ip in "${reachable[@]}"; do
    echo "$ip"
done

echo -e "\nUnreachable IPs:"
for ip in "${unreachable[@]}"; do
    echo "$ip"
done

exit 0
