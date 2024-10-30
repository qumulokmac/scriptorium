#!/bin/bash 


# az vm list --resource-group mrcoop-vms-rg --output tsv  | awk '{print $16}' > /tmp/vm.list

# for vm in `cat  /tmp/vm.list`
for vm in mrcoop-vms-0
do
	command="az network nic list --resource-group mrcoop-vms-rg"
	`${command} > /tmp/nics.list`
	`grep $vm /tmp/nics.list`

	echo "VM: ${vm} NIC: ${NIC} "

	exit

	az vm deallocate --resource-group mrcoop-vms-rg --name $vm
	az network nic update --vm-name $vm --name ${NIC} --resource-group mrcoop-vms-rg --accelerated-networking true
	# az vm start --resource-group mrcoop-vms-rg --name $vm
done


