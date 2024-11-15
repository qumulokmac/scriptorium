#!/bin/bash
################################################################################
# Script: cancel-spot-instances.sh
# Author: kmac@qumulo.com
# Date:   August 30th, 2024
#
# Description: This script cancels the spot instance requests and terminates
#              the corresponding EC2 instances provided as a comma-separated list.
#
# Operations:
# - Parse the provided instance IDs from the command line.
# - Cancel the spot instance requests associated with the provided instance IDs.
# - Terminate the EC2 instances corresponding to the provided instance IDs.
#
# Usage: ./cancel-spot-instances.sh -i i-1234567890abcdef0,i-0987654321fedcba0
################################################################################


usage() {
    echo "Usage: $0 -i <instance_ids>"
    echo "Example: $0 -i i-1234567890abcdef0,i-0987654321fedcba0"
    exit 1
}

while getopts ":i:" opt; do
    case ${opt} in
        i)
            instance_ids=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

if [ -z "$instance_ids" ]; then
    echo "No instance IDs provided. Please provide a list of instance IDs."
    usage
fi

instance_ids_space_separated=$(echo $instance_ids | tr ',' ' ')

spot_request_ids=$(aws ec2 describe-spot-instance-requests \
    --filters "Name=instance-id,Values=$instance_ids_space_separated" \
    --query "SpotInstanceRequests[?State=='active' || State=='open'].SpotInstanceRequestId" \
    --output text)

if [ -z "$spot_request_ids" ]; then
    echo "No active or open spot instance requests found for the provided instance IDs."
    exit 0
fi

echo "Cancelling spot instance requests..."
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $spot_request_ids

echo "Terminating spot instances..."
aws ec2 terminate-instances --instance-ids $instance_ids_space_separated

echo "Spot instances cancelled and deleted."
