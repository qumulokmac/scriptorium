#!/opt/homebrew/bin/bash

aws ec2 describe-instances --filters "Name=instance-lifecycle,Values=spot" --query "Reservations[].Instances[].{InstanceID:InstanceId,Name:Tags[?Key=='Name']|[0].Value,Description:State.Name}" --output text

