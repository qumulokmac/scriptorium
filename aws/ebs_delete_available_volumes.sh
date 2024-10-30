#!/bin/bash

# Get the list of all unattached EBS volumes (status: available)
volume_ids=$(aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].VolumeId' --output text)

# Loop through each volume ID and delete it
for volume_id in $volume_ids; do
    echo "Deleting volume: $volume_id"
    aws ec2 delete-volume --volume-id $volume_id
done

echo "All unattached volumes have been deleted."
