#!/usr/bin/bash
#################################################################################
# Script: show-networking.sh
# Author: kmac@qumulo.com
# Date:   August 30th, 2024
#
# Description:
#              This script lists AWS networking components.
#              The default execution lists VPCs, Subnets, Security Groups, and
#              Private Hosted Zones. With the -a or --all option, additional
#              components like Route Tables, NAT Gateways, Elastic IPs, and
#              VPC Endpoints are included.
#
################################################################################

show_main() {
    aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*cnq*" --query "Vpcs[*].{VPCID:VpcId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

    aws ec2 describe-subnets --filters "Name=tag:Name,Values=*cnq*" --query "Subnets[*].{SubnetID:SubnetId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

    aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*cnq*" --query "SecurityGroups[*].{GroupID:GroupId,GroupName:GroupName}" --output table

    aws route53 list-hosted-zones --query "HostedZones[?Config.PrivateZone==`true`].{HostedZoneID:Id,Name:Name}" --output table
}

show_all() {
    aws ec2 describe-route-tables --filters "Name=tag:Name,Values=*cnq*" --query "RouteTables[*].{RouteTableID:RouteTableId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

    aws ec2 describe-nat-gateways --filter "Name=tag:Name,Values=*cnq*" --query "NatGateways[*].{NatGatewayID:NatGatewayId,Name:Tags[?Key=='Name'].Value | [0],SubnetID:SubnetId,VPCID:VpcId}" --output table

    aws ec2 describe-addresses --filters "Name=tag:Name,Values=*cnq*" --query "Addresses[*].{PublicIP:PublicIp,AllocationID:AllocationId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

    aws ec2 describe-vpc-endpoints --filters "Name=tag:Name,Values=*cnq*" --query "VpcEndpoints[*].{EndpointID:VpcEndpointId,ServiceName:ServiceName,VPCID:VpcId,Type:VpcEndpointType}" --output table
}

all_flag=false

while getopts "a-:" opt; do
    case "${opt}" in
        a) all_flag=true ;;
        -) case "${OPTARG}" in
               all) all_flag=true ;;
               *) echo "Unknown option --${OPTARG}" ;;
           esac ;;
        *) echo "Usage: $0 [-a | --all]" ;;
    esac
done

show_main

if [ "$all_flag" = true ]; then
    show_all
fi
