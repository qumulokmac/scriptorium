#!/bin/bash 

instance_id="i-08354fa6e79a029c7"

instance_profile_arn=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[*].Instances[*].IamInstanceProfile.Arn" --output text)

echo "The instance_profile_arn is: $instance_profile_arn" 

if [ -z "$instance_profile_arn" ]; then
    echo "No IAM Instance Profile attached to instance $instance_id."
    exit 1
fi

instance_profile_name=$(echo "$instance_profile_arn" | awk -F/ '{print $NF}')

echo "The instance_profile_name is: $instance_profile_name" 

role_name=$(aws iam get-instance-profile --instance-profile-name "$instance_profile_name" --query "InstanceProfile.Roles[*].RoleName" --output text)
echo "The IAM Role Name: $role_name"

echo "Managed Policies Attached to the Role:"
managed_policies=$(aws iam list-attached-role-policies --role-name "$role_name" --output json)
echo "$managed_policies" | jq -r '.AttachedPolicies[] | "- \(.PolicyName): \(.PolicyArn)"'



exit 

# Step 4: List all inline policies attached to the IAM Role
echo "Inline Policies Attached to the Role:"
inline_policy_names=$(aws iam list-role-policies --role-name "$role_name" --output text)
if [ -z "$inline_policy_names" ]; then
    echo "No inline policies found."
else
    for policy_name in $inline_policy_names; do
        policy_name=$(echo "$policy_name" | tr -d '\r')
        if [ -n "$policy_name" ]; then
            echo "- $policy_name"
            policy_document=$(aws iam get-role-policy --role-name "$role_name" --policy-name "$policy_name" --query "PolicyDocument" --output json)
            if [ $? -eq 0 ]; then
                echo "$policy_document" | jq .
            else
                echo "An error occurred while retrieving policy $policy_name."
            fi
        fi
    done
fi

echo "Script execution complete."
