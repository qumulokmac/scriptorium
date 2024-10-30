#!/bin/bash 


for nic in `az network nic list | grep genome | grep -v maestro | awk '{print $6}'`
do 
	echo "NIC is $nic" 
	az network nic delete --resource-group product-eastus2-rg --name $nic
done

exit 
