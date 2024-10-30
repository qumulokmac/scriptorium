#!/bin/bash

################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# Name:     check_imds-status.sh
# Date:     July 17th 2024
# Author:   kmac@qumulo.com
#
# Notes:
# - This script checks the IMDSv2 status for all EC2 instances every 65 seconds.
# - If an instance is not set to "HttpTokens: required", an alert is sent via SNS.
# - The script prints a dot (.) every 5 seconds while waiting for the next check.
#
################################################################################

SNS_TOPIC_ARN="arn:aws:sns:us-east-2:611063820562:IMDSv2Alerts"
SLEEP_INTERVAL=65
DOT_INTERVAL=5

# Subscribe email to SNS Topic (run this once, then comment out or remove)
# aws sns subscribe --topic-arn "$SNS_TOPIC_ARN" --protocol email --notification-endpoint kmac@qumulo.com --region us-east-2

check_imdsv2_status() {
    instance_ids=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-2)

    for instance_id in $instance_ids; do
        echo "Checking instance ID: $instance_id at $(date)"
        metadata_options=$(aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[*].MetadataOptions" --output json --region us-east-2)
        http_tokens=$(echo $metadata_options | jq -r '.[0][0].HttpTokens')

        if [ "$http_tokens" != "required" ]; then
            echo "Alert: Instance ID $instance_id has HttpTokens set to $http_tokens"
            alert_message="Instance ID $instance_id has HttpTokens set to $http_tokens"
            # aws sns publish --topic-arn "$SNS_TOPIC_ARN" --message "$alert_message" --subject "!!!! IMDSv2 Alert !!!! EC2 Instance $instance_id is not set to required!" --region us-east-2
            echo "!!!! IMDSv2 Alert !!!! EC2 Instance $instance_id is not set to required!" 
        else
            echo "All is well with instance $instance_id."
        fi
    done
}

while true; do
    check_imdsv2_status
    echo -n "Sleeping for $SLEEP_INTERVAL seconds..."
    for ((i=0; i<$SLEEP_INTERVAL; i+=$DOT_INTERVAL)); do
        sleep $DOT_INTERVAL
        echo -n "."
    done
    echo ""
done
