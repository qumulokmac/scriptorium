#!/bin/bash

# Ensure AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "AWS CLI not installed. Please install AWS CLI first."
    exit 1
fi

# Function to print security group details
print_security_group() {
    local sg_id=$1
    local sg_name=$2

    echo "Security Group Name: $sg_name"
    echo "Security Group ID: $sg_id"
    echo "======================="

    # Print security group details
    aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,Description:Description,VpcId:VpcId}' --output table

    # Print tags
    echo "Tags:"
    aws ec2 describe-tags --filters "Name=resource-id,Values=$sg_id" --query 'Tags[*].{Key:Key,Value:Value}' --output table

    # Print inbound rules
    echo "Inbound Rules:"
    aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[*].IpPermissions' --output json | python3 -c "
import sys, json
for rule in json.load(sys.stdin)[0]:
    print(f\"Protocol: {rule['IpProtocol']}\")
    print(f\"From Port: {rule.get('FromPort', 'All')}\")
    print(f\"To Port: {rule.get('ToPort', 'All')}\")
    if 'IpRanges' in rule:
        for ip_range in rule['IpRanges']:
            print(f\"Source: {ip_range['CidrIp']}\")
    if 'UserIdGroupPairs' in rule:
        for group_pair in rule['UserIdGroupPairs']:
            print(f\"Source Security Group: {group_pair['GroupId']}\")
    print('')"

    # Print outbound rules
    echo "Outbound Rules:"
    aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[*].IpPermissionsEgress' --output json | python3 -c "
import sys, json
for rule in json.load(sys.stdin)[0]:
    print(f\"Protocol: {rule['IpProtocol']}\")
    print(f\"From Port: {rule.get('FromPort', 'All')}\")
    print(f\"To Port: {rule.get('ToPort', 'All')}\")
    if 'IpRanges' in rule:
        for ip_range in rule['IpRanges']:
            print(f\"Destination: {ip_range['CidrIp']}\")
    if 'UserIdGroupPairs' in rule:
        for group_pair in rule['UserIdGroupPairs']:
            print(f\"Destination Security Group: {group_pair['GroupId']}\")
    print('')"

    echo ""
}

# Security Group: default
echo "======================="
print_security_group "sg-0055c802e376a5f69" "default"

# Security Group: specai-workers-sg
echo "======================="
print_security_group "sg-0d99f9c248d2260ac" "specai-workers-sg"

# Security Group: specai-maestro-sg
echo "======================="
print_security_group "sg-0d379f22b4784fe2a" "specai-maestro-sg"

# Security Group: specai-clusters-sg
echo "======================="
print_security_group "sg-023f61f14ba5fbba2" "specai-clusters-sg"
