aws ec2 describe-availability-zones --region us-east-1 --query "AvailabilityZones[*].[ZoneId, ZoneName]" --output text
