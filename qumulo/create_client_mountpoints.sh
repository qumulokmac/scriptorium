#!/bin/bash
################################################################################
#
# Script to generate NFS client-server configuration file with unique combos
#
# This script creates a configuration file with 8 sets of unique NFS client-server
# combinations. Each set consists of 32 unique combos, ensuring that each client 
# and server pair is used only once across all sets and each client appears only 
# once per set.
#
# Author:   kmac@qumulo.com
# Date:     July 28th, 2024
# Name:     create_client_mountpoints.sh
#
################################################################################

###
# Create Client Mountpoints File
###
num_clients=32
num_servers=32
total_sets=8
unique_servers_per_client=4 

output_file="~/spec/SPECExecutable-orig/AI_mountpoints.txt"

> "$output_file"

for set_number in $(seq 0 $((total_sets - 1))); do
    start_server_index=$((set_number * unique_servers_per_client))
    for client_index in $(seq 0 $((num_clients - 1))); do
        client="worker-$client_index"
        server_index=$(( (start_server_index + client_index) % num_servers ))
        server="specai-node$server_index"
        echo "$client /mnt/$server" >> "$output_file"
    done
done

echo "Configuration file '$output_file' created, please validate."

