
###
# Deallocate the existing VM
###

az vm deallocate --resource-group hasbro --name hasbro-server03

# az vm deallocate --resource-group hasbro --name hasbro-server04

###
# Create New NIC's
###
az network nic create --resource-group hasbro --name hasbro03NIC1 --vnet-name vnet-hasbro --subnet hasbro-private --network-security-group hasbro-private-sg

az network nic create --resource-group hasbro --name hasbro03NIC2 --vnet-name vnet-hasbro --subnet hasbro-private --network-security-group hasbro-private-sg

az network nic create --resource-group hasbro --name hasbro03NIC3 --vnet-name vnet-hasbro --subnet hasbro-private --network-security-group hasbro-private-sg

###
# Add the New NIC's
###
az vm nic add --resource-group hasbro --vm-name hasbro-server03 --nics hasbro03NIC1 hasbro03NIC2 hasbro03NIC3

###
# Start the VM 
###

az vm start --resource-group hasbro --name hasbro-server03

###
# View the VM
###

az vm show --resource-group hasbro --name hasbro-server03


qumulo@hasbro-server03:~$ ip address | grep 172.16
    inet 172.16.16.7/20 brd 172.16.31.255 scope global eth0
    inet 172.16.16.10/20 brd 172.16.31.255 scope global eth1
    inet 172.16.16.11/20 brd 172.16.31.255 scope global eth2
    inet 172.16.16.12/20 brd 172.16.31.255 scope global eth3

sudo cat /etc/sysconfig/network-scripts/rule-eth1

###############
You left off with 4 NIC's on the VM but they all have seperate IP addresses
