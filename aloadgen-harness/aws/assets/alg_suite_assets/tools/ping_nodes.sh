#!/bin/bash
################################################################################
# Script: check_nodes_network.sh
# Purpose: Checks the network status of IP addresses obtained from a DNS query
#          of cnq.qumulo.net.
# Usage: ./check_nodes_network.sh
# Author: KMac | kmac@qumulo.com
# Date:   November 15, 2024
################################################################################

# Retrieve IP addresses from a DNS query
dns_query="cnq.qumulo.net"
ips=($(dig +short "$dns_query"))

if [[ ${#ips[@]} -eq 0 ]]; then
    echo -e "\033[31mError: No IP addresses found for $dns_query.\033[0m"
    exit 1
fi

reachable=()
unreachable=()

# Loop through each IP obtained from the DNS query and ping it
for ip in "${ips[@]}"; do
    if ping -c 1 -W 1 "$ip" &> /dev/null; then
        reachable+=("$ip")
    else
        unreachable+=("$ip")
    fi
done

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
