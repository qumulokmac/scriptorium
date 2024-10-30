#!/bin/bash
#
# Script:  s3_remove_deletemarkers.sh 
# Date:     20210830
# Author:   KJM
#
# Script to remove ALL delete markers. 
# Change the BUCKET_NAME and PREFIX_NAME variables to match your bucket name and prefix.  
# This script requires the AWS s3api CLI to be installed and configured.
# YMWV - be sure to put in error checking situations based on the unique characteristics of your data and namespace.  
###
export BUCKET_NAME=‘mybucketname’
export PREFIX_NAME=‘myprefixname’
 
aws s3api list-object-versions --bucket ${BUCKET_NAME } --prefix ${PREFIX_NAME} --output text | 
grep "DELETEMARKERS" | while read obj
do
    KEY=$( echo $obj| awk '{print $3}')
    VERSION_ID=$( echo $obj | awk '{print $5}')
    echo "Deleting ${KEY} from ${BUCKET_NAME}/${PREFIX_NAME} with versionid ${VERSION_ID}"
    aws s3api delete-object --bucket ${BUCKET_NAME} --key ${KEY} --version-id ${VERSION_ID}
done


