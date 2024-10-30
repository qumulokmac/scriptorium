

az network nic list  | awk '{ print $7 "  " $8 }'



for nic in `cat /tmp/nics`
do
	az network nic delete --resource-group crucible --name nics
done
