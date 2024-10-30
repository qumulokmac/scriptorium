#!/opt/homebrew/bin/bash -
################################################################################
#
# Name: manage_aws_resources.sh
# Date: July 16, 2024
# Author: kmac
# Description: Script to list or delete AWS resources containing a specified basename.
#
################################################################################

###
# Usage function
###
usage() {
    echo "Usage: $0 -b BASENAME -a ACTION"
    echo "  -b BASENAME  The basename to search for in AWS resources."
    echo "  -a ACTION    The action to perform: list or delete."
    exit 1
}

###
# Parse command line arguments
###
while getopts ":b:a:" opt; do
    case ${opt} in
        b)
            BASENAME=$OPTARG
            ;;
        a)
            ACTION=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$BASENAME" ] || [ -z "$ACTION" ]; then
    usage
fi

###
# Function to list resources
###
list_resources() {
    echo "Listing AWS resources containing the name: $BASENAME"
    echo "==================================================="

    ###
    # List EC2 instances
    ###
    echo "EC2 Instances:"
    aws ec2 describe-instances --query "Reservations[*].Instances[?contains(Tags[?Key=='Name'].Value | [0], '$BASENAME')].[InstanceId, InstanceType, State.Name, Tags]" --output table

    ###
    # List S3 buckets
    ###
    echo "S3 Buckets:"
    aws s3api list-buckets --query "Buckets[?contains(Name, '$BASENAME')].[Name]" --output table

    ###
    # List IAM roles
    ###
    echo "IAM Roles:"
    aws iam list-roles --query "Roles[?contains(RoleName, '$BASENAME')].[RoleName, Arn]" --output table

    ###
    # List IAM instance profiles
    ###
    echo "IAM Instance Profiles:"
    aws iam list-instance-profiles --query "InstanceProfiles[?contains(InstanceProfileName, '$BASENAME')].[InstanceProfileName, Arn]" --output table

    ###
    # List DynamoDB tables
    ###
    echo "DynamoDB Tables:"
    aws dynamodb list-tables --query "TableNames[?contains(@, '$BASENAME')]" --output table

    ###
    # List Security Groups
    ###
    echo "Security Groups:"
    aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '$BASENAME')].[GroupId, GroupName, Description]" --output table

    ###
    # List ENIs
    ###
    echo "Elastic Network Interfaces:"
    aws ec2 describe-network-interfaces --query "NetworkInterfaces[?contains(Description, '$BASENAME')].[NetworkInterfaceId, Description, Status]" --output table

    ###
    # List EBS volumes
    ###
    echo "EBS Volumes:"
    aws ec2 describe-volumes --query "Volumes[?Tags && contains(Tags[?Key=='Name'].Value | [0], '$BASENAME')].[VolumeId, State, Size, VolumeType]" --output table

    ###
    # List NLBs
    ###
    echo "Network Load Balancers:"
    aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, '$BASENAME')].[LoadBalancerArn, LoadBalancerName, State.Code]" --output table

    ###
    # List ALB target group attachments
    ###
    echo "ALB Target Group Attachments:"
    aws elbv2 describe-target-health --query "TargetHealthDescriptions[?contains(Target.Id, '$BASENAME')].[Target.Id, TargetHealth.State]" --output table

    ###
    # List CloudWatch dashboards
    ###
    echo "CloudWatch Dashboards:"
    aws cloudwatch list-dashboards --query "DashboardEntries[?contains(DashboardName, '$BASENAME')].[DashboardName]" --output table

    ###
    # List CloudWatch log groups
    ###
    echo "CloudWatch Log Groups:"
    aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '$BASENAME')].[logGroupName]" --output table

    ###
    # List CloudWatch metric alarms
    ###
    echo "CloudWatch Metric Alarms:"
    aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName, '$BASENAME')].[AlarmName, StateValue]" --output table

    ###
    # List Resource Groups
    ###
    echo "Resource Groups:"
    aws resource-groups list-groups --query "GroupIdentifiers[?contains(GroupName, '$BASENAME')].[GroupName]" --output table

    ###
    # List Route 53 records
    ###
    echo "Route 53 Records:"
    aws route53 list-resource-record-sets --query "ResourceRecordSets[?contains(Name, '$BASENAME')].[Name, Type]" --output table

    ###
    # List Route 53 zones
    ###
    echo "Route 53 Zones:"
    aws route53 list-hosted-zones --query "HostedZones[?contains(Name, '$BASENAME')].[Id, Name]" --output table

    ###
    # List Secrets Manager secrets
    ###
    echo "Secrets Manager Secrets:"
    aws secretsmanager list-secrets --query "SecretList[?contains(Name, '$BASENAME')].[Name]" --output table

    ###
    # List SSM Parameter Store entries
    ###
    echo "SSM Parameter Store Entries:"
    aws ssm describe-parameters --query "Parameters[?contains(Name, '$BASENAME')].[Name, Type, LastModifiedDate]" --output table
}

###
# Function to delete resources
###
delete_resources() {
    echo "Deleting AWS resources containing the name: $BASENAME"
    echo "==================================================="

    ###
    # Delete EC2 instances
    ###
    echo "Deleting EC2 Instances:"
    INSTANCE_IDS=$(aws ec2 describe-instances --query "Reservations[*].Instances[?contains(Tags[?Key=='Name'].Value | [0], '$BASENAME')].[InstanceId]" --output text)
    for INSTANCE in $INSTANCE_IDS; do
        aws ec2 terminate-instances --instance-ids $INSTANCE
    done

    ###
    # Delete S3 buckets
    ###
    echo "Deleting S3 Buckets:"
    BUCKET_NAMES=$(aws s3api list-buckets --query "Buckets[?contains(Name, '$BASENAME')].[Name]" --output text)
    for BUCKET in $BUCKET_NAMES; do
        aws s3 rb s3://$BUCKET --force
    done

    ###
    # Delete IAM roles and instance profiles
    ###
    echo "Deleting IAM Roles and Instance Profiles:"
    ROLE_NAMES=$(aws iam list-roles --query "Roles[?contains(RoleName, '$BASENAME')].[RoleName]" --output text)
    for ROLE in $ROLE_NAMES; do
        POLICY_NAMES=$(aws iam list-attached-role-policies --role-name $ROLE --query "AttachedPolicies[*].PolicyArn" --output text)
        for POLICY in $POLICY_NAMES; do
            aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY
        done
        INSTANCE_PROFILE_NAMES=$(aws iam list-instance-profiles-for-role --role-name $ROLE --query "InstanceProfiles[*].InstanceProfileName" --output text)
        for INSTANCE_PROFILE in $INSTANCE_PROFILE_NAMES; do
            aws iam remove-role-from-instance-profile --instance-profile-name $INSTANCE_PROFILE --role-name $ROLE
        done
        aws iam delete-role --role-name $ROLE
    done

    ###
    # Delete DynamoDB tables
    ###
    echo "Deleting DynamoDB Tables:"
    TABLE_NAMES=$(aws dynamodb list-tables --query "TableNames[?contains(@, '$BASENAME')]" --output text)
    for TABLE in $TABLE_NAMES; do
        aws dynamodb delete-table --table-name $TABLE
    done

    ###
    # Delete Security Groups
    ###
    echo "Deleting Security Groups:"
    SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --query "SecurityGroups[?contains(GroupName, '$BASENAME')].[GroupId]" --output text)
    for SG in $SECURITY_GROUP_IDS; do
        ###
        # Check for dependencies
        ###
        ENI_IDS=$(aws ec2 describe-network-interfaces --query "NetworkInterfaces[?Groups[?GroupId=='$SG']].[NetworkInterfaceId]" --output text)
        for ENI in $ENI_IDS; do
            ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text)
            if [ "$ATTACHMENT_ID" != "None" ]; then
                aws ec2 detach-network-interface --attachment-id $ATTACHMENT_ID
            fi
            aws ec2 delete-network-interface --network-interface-id $ENI
        done

        aws ec2 delete-security-group --group-id $SG
    done

    ###
    # Delete ENIs
    ###
    echo "Deleting Elastic Network Interfaces:"
    ENI_IDS=$(aws ec2 describe-network-interfaces --query "NetworkInterfaces[?contains(Description, '$BASENAME')].[NetworkInterfaceId]" --output text)
    for ENI in $ENI_IDS; do
        ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text)
        if [ "$ATTACHMENT_ID" != "None" ]; then
            aws ec2 detach-network-interface --attachment-id $ATTACHMENT_ID
        fi
        aws ec2 delete-network-interface --network-interface-id $ENI
    done

    ###
    # Delete EBS Volumes
    ###
    echo "Deleting EBS Volumes:"
    VOLUME_IDS=$(aws ec2 describe-volumes --query "Volumes[?Tags && contains(Tags[?Key=='Name'].Value | [0], '$BASENAME')].[VolumeId]" --output text)
    for VOLUME in $VOLUME_IDS; do
        aws ec2 delete-volume --volume-id $VOLUME
    done

    ###
    # Delete Network Load Balancers
    ###
    echo "Deleting Network Load Balancers:"
    LB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, '$BASENAME')].[LoadBalancerArn]" --output text)
    for LB_ARN in $LB_ARNS; do
        aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
    done

    ###
    # Delete ALB Target Group Attachments
    ###
    echo "Deleting ALB Target Group Attachments:"
    TARGET_GROUP_ARNS=$(aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName, '$BASENAME')].[TargetGroupArn]" --output text)
    for TG_ARN in $TARGET_GROUP_ARNS; do
        TARGET_IDS=$(aws elbv2 describe-target-health --target-group-arn $TG_ARN --query "TargetHealthDescriptions[*].Target.Id" --output text)
        for TARGET_ID in $TARGET_IDS; do
            aws elbv2 deregister-targets --target-group-arn $TG_ARN --targets Id=$TARGET_ID
        done
        aws elbv2 delete-target-group --target-group-arn $TG_ARN
    done

    ###
    # Delete CloudWatch Dashboards
    ###
    echo "Deleting CloudWatch Dashboards:"
    DASHBOARD_NAMES=$(aws cloudwatch list-dashboards --query "DashboardEntries[?contains(DashboardName, '$BASENAME')].[DashboardName]" --output text)
    for DASHBOARD_NAME in $DASHBOARD_NAMES; do
        aws cloudwatch delete-dashboards --dashboard-names $DASHBOARD_NAME
    done

    ###
    # Delete CloudWatch Log Groups
    ###
    echo "Deleting CloudWatch Log Groups:"
    LOG_GROUP_NAMES=$(aws logs describe-log-groups --query "logGroups[?contains(logGroupName, '$BASENAME')].[logGroupName]" --output text)
    for LOG_GROUP_NAME in $LOG_GROUP_NAMES; do
        aws logs delete-log-group --log-group-name $LOG_GROUP_NAME
    done

    ###
    # Delete CloudWatch Metric Alarms
    ###
    echo "Deleting CloudWatch Metric Alarms:"
    ALARM_NAMES=$(aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName, '$BASENAME')].[AlarmName]" --output text)
    for ALARM_NAME in $ALARM_NAMES; do
        aws cloudwatch delete-alarms --alarm-names $ALARM_NAME
    done

    ###
    # Delete Resource Groups
    ###
    echo "Deleting Resource Groups:"
    GROUP_NAMES=$(aws resource-groups list-groups --query "GroupIdentifiers[?contains(GroupName, '$BASENAME')].[GroupName]" --output text)
    for GROUP_NAME in $GROUP_NAMES; do
        aws resource-groups delete-group --group-name $GROUP_NAME
    done

    ###
    # Delete Route 53 Records and Zones
    ###
    echo "Deleting Route 53 Records and Zones:"
    ZONE_IDS=$(aws route53 list-hosted-zones --query "HostedZones[?contains(Name, '$BASENAME')].[Id]" --output text | tr -d ' ')
    for ZONE_ID in $ZONE_IDS; do
        RECORD_SETS=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?contains(Name, '$BASENAME')].[Name]" --output text)
        for RECORD in $RECORD_SETS; do
            aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{"Changes":[{"Action":"DELETE","ResourceRecordSet":{"Name":"'"$RECORD"'","Type":"A"}}]}'
        done
        aws route53 delete-hosted-zone --id $ZONE_ID
    done

    ###
    # Delete Secrets Manager Secrets
    ###
    echo "Deleting Secrets Manager Secrets:"
    SECRET_NAMES=$(aws secretsmanager list-secrets --query "SecretList[?contains(Name, '$BASENAME')].[Name]" --output text)
    for SECRET_NAME in $SECRET_NAMES; do
        aws secretsmanager delete-secret --secret-id $SECRET_NAME --force-delete-without-recovery
    done

    ###
    # Delete SSM Parameter Store Entries
    ###
    echo "Deleting SSM Parameter Store Entries:"
    PARAMETER_NAMES=$(aws ssm describe-parameters --query "Parameters[?contains(Name, '$BASENAME')].[Name]" --output text)
    for PARAMETER_NAME in $PARAMETER_NAMES; do
        aws ssm delete-parameter --name $PARAMETER_NAME
    done
}

if [ "$ACTION" == "list" ]; then
    list_resources
elif [ "$ACTION" == "delete" ]; then
    delete_resources
else
    usage
fi
