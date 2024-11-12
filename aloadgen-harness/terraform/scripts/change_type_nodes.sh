#!/bin/bash

INSTANCE_FILE="instance_ids.txt"
NEW_INSTANCE_TYPE="i3en.xlarge"  # Replace with your desired instance type

if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it to use this script."
    exit 1
fi

change_instance_type() {
    instance_id=$1
    new_type=$2

    echo "Modifying instance type for $instance_id to $new_type..."
    aws ec2 modify-instance-attribute --instance-id $instance_id --instance-type "{\"Value\": \"$new_type\"}"

    # Start the instance
    # echo "Starting instance $instance_id..."
    # aws ec2 start-instances --instance-ids $instance_id > /dev/null
    # aws ec2 wait instance-running --instance-ids $instance_id
    # echo "Instance $instance_id started successfully with type $new_type."
}

if [ -f "$INSTANCE_FILE" ]; then
    while IFS= read -r instance_id; do
        if [ -n "$instance_id" ]; then
            change_instance_type "$instance_id" "$NEW_INSTANCE_TYPE"
        fi
    done < "$INSTANCE_FILE"
else
    echo "Instance file $INSTANCE_FILE not found."
    exit 1
fi
