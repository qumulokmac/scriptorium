#!/bin/bash

################################################################################
#
# Name: get_iam_role_details.sh
# Date: July 16, 2024
# Author: kmac
# Description: Script to fetch and display IAM role details in a human-readable format.
#
################################################################################

###
# Function to display usage
###
usage() {
    echo "Usage: $0 -r role_name -o output_file"
    exit 1
}

###
# Parse command-line arguments
###
while getopts ":r:o:" opt; do
    case $opt in
        r) ROLE_NAME="$OPTARG"  # Capture the role name argument
        ;;
        o) OUTPUT_FILE="$OPTARG"  # Capture the output file argument
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
            usage
        ;;
        :) echo "Option -$OPTARG requires an argument." >&2
            usage
        ;;
    esac
done

###
# Check if role name and output file are provided
###
if [ -z "$ROLE_NAME" ] || [ -z "$OUTPUT_FILE" ]; then
    usage
fi

###
# Initialize the output file
###
echo "IAM Role Details for $ROLE_NAME" > $OUTPUT_FILE
echo "===============================" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

###
# Describe the role
###
echo "Role Description:" >> $OUTPUT_FILE
aws iam get-role --role-name $ROLE_NAME --output table >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

###
# List inline policies
###
echo "Inline Policies:" >> $OUTPUT_FILE
POLICIES=$(aws iam list-role-policies --role-name $ROLE_NAME --output text | awk '{print $2}')
for POLICY in $POLICIES; do
    echo "  - Policy Name: $POLICY" >> $OUTPUT_FILE
    echo "    Policy Document:" >> $OUTPUT_FILE
    aws iam get-role-policy --role-name $ROLE_NAME --policy-name $POLICY --output table >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
done

###
# List attached managed policies
###
echo "Attached Managed Policies:" >> $OUTPUT_FILE
ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE_NAME --output text | awk '{print $2}')
for POLICY_ARN in $ATTACHED_POLICIES; do
    POLICY_NAME=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.PolicyName' --output text)
    POLICY_VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)
    POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $POLICY_VERSION --query 'PolicyVersion.Document' --output table)

    echo "  - Policy Name: $POLICY_NAME" >> $OUTPUT_FILE
    echo "    Policy ARN: $POLICY_ARN" >> $OUTPUT_FILE
    echo "    Policy Document:" >> $OUTPUT_FILE
    echo "$POLICY_DOCUMENT" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
done

echo "Details of IAM role '$ROLE_NAME' have been saved to $OUTPUT_FILE"
