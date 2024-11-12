#!/bin/bash

WORKER_IDENTIFIER='node'
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*${WORKER_IDENTIFIER}*" \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo "Stopping the following instances: $INSTANCE_IDS"
    aws ec2 stop-instances --instance-ids $INSTANCE_IDS
    echo "Instances are being stopped."
else
    echo "No running instances found with the name identifier of: ${WORKER_IDENTIFIER}."
fi
