#!/bin/bash

# Script that will disable the metadata for the given instance.

for instanceID in `./get-ec2-instance-ids.sh`
do
    if [[ -n $instanceID ]];
    then
        aws ec2 modify-instance-metadata-options \
         --instance-id ${instanceID} --profile sandbox \
         --http-endpoint disabled
    else
        echo "The instanceID is blank. Please try passing in the ID when running the script"
        exit
    fi
done
