#!/bin/bash

spot_request_ids=$(aws ec2 describe-spot-instance-requests \
    --query "SpotInstanceRequests[?State=='active' || State=='open'].SpotInstanceRequestId" \
    --output text)

if [ -z "$spot_request_ids" ]; then
    echo "No active or open spot instance requests found."
    exit 0
fi

echo "Cancelling spot instance requests..."
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $spot_request_ids

instance_ids=$(aws ec2 describe-spot-instance-requests \
    --spot-instance-request-ids $spot_request_ids \
    --query "SpotInstanceRequests[].InstanceId" \
    --output text)

if [ -n "$instance_ids" ]; then
    echo "Terminating spot instances..."
    aws ec2 terminate-instances --instance-ids $instance_ids
else
    echo "No instances associated with the spot requests."
fi

echo "Spot instances cancelled and deleted."
