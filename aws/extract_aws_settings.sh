#!/usr/bin/bash
################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# Name:     extract_aws_settings.sh
# Date:     2024-07-22
# Author:   kmac@qumulo.com
#
# Notes:
# - This script uses the AWS CLI to extract settings for resources in the
#   existing environment and outputs the details in JSON format.
#
################################################################################

HARNESS_BASE_NAME="specai"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

LOG_DIR_BASE="/home/qumulo/logs/${HARNESS_BASE_NAME}"
OUTPUT_DIR="${LOG_DIR_BASE}/aws"

mkdir -p ${OUTPUT_DIR}

log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1"
}

extract_resource_details() {
    RESOURCE_TYPE=$1
    RESOURCE_ID=$2
    
    case ${RESOURCE_TYPE} in
        ec2)
            log_message "Extracting details for EC2 instance: ${RESOURCE_ID}"
            aws ec2 describe-instances --instance-ids ${RESOURCE_ID} --output json > ${OUTPUT_DIR}/${RESOURCE_ID}.json
            ;;
        ebs)
            log_message "Extracting details for EBS volume: ${RESOURCE_ID}"
            aws ec2 describe-volumes --volume-ids ${RESOURCE_ID} --output json > ${OUTPUT_DIR}/${RESOURCE_ID}.json
            aws ec2 describe-tags --filters "Name=resource-id,Values=${RESOURCE_ID}" --output json >> ${OUTPUT_DIR}/${RESOURCE_ID}.json
            ;;
        *)
            log_message "Unsupported resource type: ${RESOURCE_TYPE}"
            ;;
    esac
}

log_message "Listing EC2 instances..."
EC2_INSTANCE_IDS=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)

for INSTANCE_ID in ${EC2_INSTANCE_IDS}; do
    extract_resource_details "ec2" ${INSTANCE_ID}
done

log_message "Listing EBS volumes..."
EBS_VOLUME_IDS=$(aws ec2 describe-volumes --query 'Volumes[*].VolumeId' --output text)

for VOLUME_ID in ${EBS_VOLUME_IDS}; do
    extract_resource_details "ebs" ${VOLUME_ID}
done


log_message "Resource details extraction completed. JSON files are available in ${OUTPUT_DIR}"

