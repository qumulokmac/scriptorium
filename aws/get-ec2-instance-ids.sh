#!/bin/bash
#
# Specify the profile 
# Note: This is so you dont have to figure out the jq again... 

aws ec2 describe-instances --profile sandbox | jq -r '.Reservations[].Instances[].InstanceId'
