#!/bin/bash
################################################################################
#
# KMac 11/23/2023
#
# Creates workers for performance testing using SPOT instances
#
# Change the seq values to match the curent testing set range
# Check that the correct image is being referenced 
# etc...
#
################################################################################

for i in `seq -f %02g 1 16`
do
	az vm create --no-wait --name mrc-wrkr${i} --resource-group crucible --image maestro-image-20231204 --location eastus --accept-term --size Standard_F16s_v2 --ssh-key-name crucible --zone 1 --admin-username qumulo --nsg oilnet-nsg --subnet oilnet --subnet-address-prefix 10.0.16.0/20 --vnet-name oilnet --public-ip-address "" --priority Spot --max-price -1 --eviction-policy Delete
done
