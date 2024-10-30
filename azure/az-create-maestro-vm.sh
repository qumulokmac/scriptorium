#!/bin/bash

az vm create --name maestro --resource-group crucible --image maestro-image-20231204 --location eastus --accept-term --size Standard_D2s_v3 --ssh-key-name 'crucible' --zone 1 --admin-username qumulo --nsg oilnet-nsg --subnet oilnet --subnet-address-prefix 10.0.16.0/20 --vnet-name oilnet 
