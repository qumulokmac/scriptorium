#!/bin/bash 
################################################################################
#
################################################################################


usage() { echo "Usage: $0 [-r resource-group -n name_to_parse ]" 1>&2; exit 1; }

while getopts ":n:r:" o; do
    case "${o}" in
        r)
            r=${OPTARG}
            ;;
        n)
            n=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [ -z "${r}" ] || [ -z "${n}" ] ; then
    usage
fi

RESOURCE_GROUP=${r}
NAMETOPARSE=${n}

echo "Deleting NIC's in RG $RESOURCE_GROUP with $NAMETOPARSE in the name" 
for nic in `az network nic list | grep ${NAMETOPARSE} | grep -v maestro | awk '{print $6}'`
do 
	echo "NIC is $nic" 
	az network nic delete --resource-group ${RESOURCE_GROUP} --name $nic
done


echo "Deleting Disks in RG $RESOURCE_GROUP with $NAMETOPARSE in the name" 
for disk in `az disk list --resource-group $RESOURCE_GROUP | grep ${NAMETOPARSE} | grep -v maestro | awk '{print $6}'`
do 
	echo "Disk is $disk" 
	az disk delete --resource-group $RESOURCE_GROUP -n $disk --yes --no-wait
done

