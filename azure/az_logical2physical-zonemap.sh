#!/bin/bash 

PRODUCTSUB=2f0fe240-4ebb-45eb-8307-9f54ae213157
STAGINGSUB=7418a6db-97af-4ae5-8633-c2549a0fdd3f
SASTUB=03a3547d-beb4-45f7-96ea-e6559202f2d2

location=eastasia

PeerSubscriptionId=$STAGINGSUB

payload="{ \"location\": \"$location\", \"subscriptionIds\": [\"subscriptions/$STAGINGSUB\"] }"

echo ""
echo "Payload is: $payload"
echo ""

az rest --method post  --uri "https://management.azure.com/subscriptions/${PRODUCTSUB}/providers/Microsoft.Resources/checkZonePeers/?api-version=2022-12-01" --body "${payload}" 


exit 
echo ""
echo "Response code: $?"
echo ""
