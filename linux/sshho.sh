#!/bin/bash

# List of servers to collect SSH public keys from
servers=("sut6621" "sut6623" "sut6624" "sut6626")

# File to store all public keys
output_file="all_authorized_keys"

# Clear the output file if it exists
> $output_file

# Loop through each server and collect the public key
for server in "${servers[@]}"; do
    echo "Collecting SSH key from $server"
    ssh $server 'cat ~/.ssh/id_rsa.pub' >> $output_file
done

echo "All SSH keys collected in $output_file"

for server in "${servers[@]}"; do
        echo "Copying authorized_keys to $server"
        scp all_authorized_keys $server:~/.ssh/authorized_keys
done

for server in "${servers[@]}"; do
            ssh $server 'chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'
    done
root@sut6626:~#
