#!/bin/bash

INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=stopped" "Name=tag:Name,Values=*holder*,*ubuntu*" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Stopping the following instances: $INSTANCE_IDS"
    aws ec2 start-instances --instance-ids $INSTANCE_IDS
    echo "Instances are being started."
else
    echo "No matching instances found."
fi
