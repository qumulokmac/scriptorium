#!/bin/bash

# Define the role name
ROLE_NAME="cnqdemo-ec2-ssm-role"

# Step 1: Detach all attached policies
attached_policies=$(aws iam list-attached-role-policies --role-name $ROLE_NAME --query "AttachedPolicies[].PolicyArn" --output text)

if [ -n "$attached_policies" ]; then
    echo "Detaching policies from role $ROLE_NAME..."
    for policy_arn in $attached_policies; do
        aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $policy_arn
        echo "Detached policy $policy_arn"
    done
else
    echo "No attached policies found for role $ROLE_NAME."
fi

# Step 2: Delete all inline policies
inline_policies=$(aws iam list-role-policies --role-name $ROLE_NAME --query "PolicyNames[]" --output text)

if [ -n "$inline_policies" ]; then
    echo "Deleting inline policies from role $ROLE_NAME..."
    for policy_name in $inline_policies; do
        aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $policy_name
        echo "Deleted inline policy $policy_name"
    done
else
    echo "No inline policies found for role $ROLE_NAME."
fi

# Step 3: Delete the IAM role
echo "Deleting IAM role $ROLE_NAME..."
aws iam delete-role --role-name $ROLE_NAME

if [ $? -eq 0 ]; then
    echo "Role $ROLE_NAME deleted successfully."
else
    echo "Failed to delete role $ROLE_NAME."
fi
