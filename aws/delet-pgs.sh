#!/bin/bash

# Set AWS region (modify as needed)
REGION="us-east-2"

# List all placement groups
PLACEMENT_GROUPS=$(aws ec2 describe-placement-groups --query 'PlacementGroups[*].GroupName' --output text --region $REGION)

# Check if there are any placement groups
if [ -z "$PLACEMENT_GROUPS" ]; then
  echo "No placement groups found in region $REGION."
  exit 0
fi

# Delete each placement group
for PG in $PLACEMENT_GROUPS; do
  echo "Deleting placement group: $PG"
  aws ec2 delete-placement-group --group-name $PG --region $REGION
  if [ $? -eq 0 ]; then
    echo "Successfully deleted placement group: $PG"
  else
    echo "Failed to delete placement group: $PG"
  fi
done

echo "All placement groups have been processed."
