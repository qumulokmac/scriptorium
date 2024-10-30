

###
#
###
aws ec2 describe-spot-instance-requests --filters "Name=state,Values=open,active" --query 'SpotInstanceRequests[*].{ID:SpotInstanceRequestId,State:State,Instance:InstanceId}' --output table

###
# 1. Describe Spot Instance Requests with Detailed Information
###

aws ec2 describe-spot-instance-requests --spot-instance-request-ids sir-8s1pwr3h sir-wt6yx9qk sir-58fpzzgk sir-wyb6zfwg sir-3m4pwzik sir-wiqyxnjk sir-irfyyn2h sir-14t6w31k sir-1n6yx5rk --output table

###
# aws ec2 describe-instances --instance-ids i-0a735b10fb00a66d7 i-09d34f068978be2a5 i-0874fa87217e7e13e i-00ed648be0a208184 i-038b85ec84356e108 i-0a5b7655ab105030f i-0e9422ec44e3c1f45 i-0d4a84e5f6be24317 i-0fc0d195f7f5c8b4a --output table
###

###
# Check the tags
###

aws ec2 describe-instances --instance-ids i-0a735b10fb00a66d7 i-09d34f068978be2a5 i-0874fa87217e7e13e i-00ed648be0a208184 i-038b85ec84356e108 i-0a5b7655ab105030f i-0e9422ec44e3c1f45 i-0d4a84e5f6be24317 i-0fc0d195f7f5c8b4a --query 'Reservations[*].Instances[*].Tags' --output table


###
# Filter by Launch Time
###
aws ec2 describe-instances --instance-ids i-0a735b10fb00a66d7 i-09d34f068978be2a5 i-0874fa87217e7e13e i-00ed648be0a208184 i-038b85ec84356e108 i-0a5b7655ab105030f i-0e9422ec44e3c1f45 i-0d4a84e5f6be24317 i-0fc0d195f7f5c8b4a --query 'Reservations[*].Instances[*].{ID:InstanceId,LaunchTime:LaunchTime}' --output table


###
# Use the following command to cancel the Spot Instance requests and terminate the instances
###
aws ec2 cancel-spot-instance-requests --spot-instance-request-ids sir-8s1pwr3h sir-wt6yx9qk sir-58fpzzgk sir-wyb6zfwg sir-3m4pwzik sir-wiqyxnjk sir-irfyyn2h sir-14t6w31k sir-1n6yx5rk

aws ec2 terminate-instances --instance-ids i-0a735b10fb00a66d7 i-09d34f068978be2a5 i-0874fa87217e7e13e i-00ed648be0a208184 i-038b85ec84356e108 i-0a5b7655ab105030f i-0e9422ec44e3c1f45 i-0d4a84e5f6be24317 i-0fc0d195f7f5c8b4a

###
# Script to list Spot instances that do not have a Name tag
###
# Define the tag keys you're interested in
$tagKeys = @("Name", "Description")

# Get all active Spot Instance requests
$spotInstanceRequests = aws ec2 describe-spot-instance-requests --query 'SpotInstanceRequests[*].{ID:SpotInstanceRequestId,Instance:InstanceId}' --output json | ConvertFrom-Json

# Loop through each Spot Instance request
foreach ($request in $spotInstanceRequests) {
    # Get tags associated with the instance
    $instanceId = $request.Instance
    $tags = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[*].Instances[*].Tags' --output json | ConvertFrom-Json

    # Check if the required tags are missing
    $missingTags = $true
    foreach ($tagKey in $tagKeys) {
        if ($tags | Where-Object { $_.Key -eq $tagKey }) {
            $missingTags = $false
        }
    }

    # If any of the required tags are missing, output the Spot Instance request ID and Instance ID
    if ($missingTags) {
        Write-Host "Spot Instance Request ID: $($request.ID) is missing one or more of the following tags: $($tagKeys -join ', ')"
        Write-Host "Associated Instance ID: $instanceId"
        Write-Host "-------------------------------------------------------------"
    }
}



for i in `aws ec2 describe-spot-instance-requests --filters "Name=state,Values=open,active" --query 'SpotInstanceRequests[*].{ID:SpotInstanceRequestId,State:State,Instance:InstanceId}' --output json | jq -r '.[].ID'`
> do
> aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $i
> done


