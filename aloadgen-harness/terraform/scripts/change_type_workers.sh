#!/bin/bash

# File containing instance IDs (one per line)
INSTANCE_FILE="winstance_ids.txt"
NEW_INSTANCE_TYPE="i3en.xlarge"  # Replace with your desired instance type

# Check if the AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it to use this script."
    exit 1
fi

# Function to change the instance type
change_instance_type() {
    instance_id=$1
    new_type=$2

    echo "Modifying instance type for $instance_id to $new_type..."
    aws ec2 modify-instance-attribute --instance-id $instance_id --instance-type "{\"Value\": \"$new_type\"}"

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
