#!/bin/bash

WORKER_IDENTIFIER='node'
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=stopped" "Name=tag:Name,Values=*${WORKER_IDENTIFIER}*" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Starting the following instances: $INSTANCE_IDS"
    aws ec2 start-instances --instance-ids $INSTANCE_IDS
    echo "Nodes are being started."
else
    echo "No stopped instances found with the name identifier of: ${WORKER_IDENTIFIER}."
fi
