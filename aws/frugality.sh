#!/bin/bash
################################################################################
# Name:     frugality.sh 
# Purpose:  The intent of this script is to shutdown ALL of yourEC2 instances
#           before you start the weekend or go on holiday. Lets save some power. 
#           Simply put, this script will dynamically walk your EC2 instances in
#           all regions and shut down any instance it finds. 
#           There are many like this, but this one is mine. 
#           Future versions will check EBS snapshots and perhaps clean them up.
# Author:   mcaws 
# Date:     March 6th, 2022
#
################################################################################
# Prereqs:  Be sure to have the AWS CLI installed and configured 
################################################################################

source ~/.bash_profile 
###
# Parse options:  -action [start|stop|list] -r [region] -quiet
###

while getopts 'a:r:qh' opt; do
  case "$opt" in
    a)
      ACTION="$OPTARG"
      echo "Action is '${OPTARG}'"
      ;;

    r)
      REGION="$OPTARG"
      echo "Region is '${OPTARG}'"
      ;;

    q)
      QUIET=1
      echo "Going into stealth mode '${OPTARG}'"
      ;;

    *|h)
      echo "Usage: $(basename $0) -a [start|stop|list] -r [region|all] -quiet "
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"


function get-ec2-instances() {
  # REGIONS=`aws ec2 describe-regions --region us-east-1 --output text --query Regions[*].[RegionName]`
  REGIONS="us-east-1 us-east-2"
  for REGION in $REGIONS
  do
    echo -e "\nInstances in '$REGION'..";
    IFS=$'\n'
    read -r -d '' -a OUTPUT < <(aws ec2 describe-instances --region $REGION | jq '.Reservations[].Instances[] |
    "\(.InstanceId):\(.State.Name)" ' | sed -e 's/\"//g')
      if [[ "${OUTPUT}" == "" ]]
      then
        echo "No EC2 instances found in region: $REGION"
      else
          for i in ${!OUTPUT[@]}
          do
             NAME=$(echo ${OUTPUT[$i]} | cut -d':' -f1)
             STATE=$(echo ${OUTPUT[$i]} | cut -d':' -f2)
             echo "EC2 Instance $NAME in $REGION is ${STATE}"
             if [[ "${STATE}" == "running" ]]
             then
                echo "Stopping Instance $NAME in $REGION..."
             fi
          done
      fi
  done
}

################################################################################
# Main 
################################################################################
# This is a hacvk for now until you finish the above  - 

# get-ec2-instances

for reg in us-east-1 us-east-2 us-west-1 us-west-2 
do
    ~/.bash-my-aws/bin/bma region $reg
    echo "Instances in regions $reg:" 
    ~/.bash-my-aws/bin/bma instances
    echo "Stopping Instances in regions $reg:" 
    ~/.bash-my-aws/bin/bma instances | grep -v stopped | awk '{ print $1 }' | ~/.bash-my-aws/bin/bma instance-stop
done
