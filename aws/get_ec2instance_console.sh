
INSTANCE_ID="i-03276f07a8910e862"
aws ec2 get-console-output --instance-id $INSTANCE_ID --output text

# Retrieve the Log After Instance Shutdown or Reboot:

aws ec2 get-console-output --instance-id $INSTANCE_ID --latest --output text


# Enable Detailed Monitoring (if needed):
aws ec2 monitor-instances --instance-ids $INSTANCE_ID

