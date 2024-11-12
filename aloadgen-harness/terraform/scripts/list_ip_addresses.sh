aws ec2 describe-instances --filters "Name=tag:Name,Values=*node*" --query "Reservations[].Instances[].PrivateIpAddress" --output text
