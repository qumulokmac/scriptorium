


# aws ec2 describe-vpc-endpoints --filters Name=service-name,Values=com.amazonaws.us-west-2.s3 --query 'VpcEndpoints[*].VpcId' --output table


aws ec2 describe-vpc-endpoints --filters "Name=service-name,Values=com.amazonaws.us-west-2.s3" "Name=vpc-id,Values=vpc-0f412bd3213285151" --output table
