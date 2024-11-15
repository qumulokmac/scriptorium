#!/bin/bash

echo "Workers: "
workers=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,stopped,shutting-down,stopping" "Name=tag:Name,Values=*ubuntu*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value | [0], PrivateIpAddress, State.Name]" \
    --output json | jq -r '.[] | @tsv'|sort -V)
echo "$workers"

worker_count=$(echo "$workers" | wc -l)
echo ""

echo "Nodes: "
nodes=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,stopped,shutting-down,stopping" "Name=tag:Name,Values=*node*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value | [0], PrivateIpAddress, State.Name]" \
    --output json | jq -r '.[] | @tsv'|sort -V)
echo "$nodes"

node_count=$(echo "$nodes" | wc -l)
echo ""

echo "Bastion: "
bastion=$(aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running,stopped,shutting-down,stopping" "Name=tag:Name,Values=*bastion*" \
    --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value | [0], PrivateIpAddress, PublicIpAddress, State.Name]" \
    --output text)
echo "$bastion"

bastion_count=$(echo "$bastion" | wc -l)
echo ""

echo "Summary of totals:"
echo "Total Workers: $worker_count"
echo "Total Nodes: $node_count"
echo "Total Bastion: $bastion_count"
