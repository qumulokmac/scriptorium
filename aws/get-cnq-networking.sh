aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*cnq*" --query "Vpcs[*].{VPCID:VpcId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

aws ec2 describe-subnets --filters "Name=tag:Name,Values=*cnq*" --query "Subnets[*].{SubnetID:SubnetId,Name:Tags[?Key=='Name'].Value | [0]}" --output table

aws ec2 describe-security-groups --filters "Name=tag:Name,Values=*cnq*" --query "SecurityGroups[*].{GroupID:GroupId,GroupName:GroupName}" --output table
