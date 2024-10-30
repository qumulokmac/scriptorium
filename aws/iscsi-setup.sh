#!/bin/bash
################################################################################
#
# Author:  tjm@ 
# Date:    10/31/2022
################################################################################

sudo yum install zip jq sshpass -y

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install
export num_sessions=4
export REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
export SVM="svm0"
export IGROUP="block"
export IN=$(cat /etc/iscsi/initiatorname.iscsi | awk -F "=" '{print $2}')
export PW=$(/usr/local/bin/aws --region=${REGION} secretsmanager get-secret-value --secret-id "fsxAdminPW" --output text --query SecretString)

# iSCSI packages
sudo yum install -y device-mapper-multipath iscsi-initiator-utils
#
sudo systemctl start iscsid
#
sudo systemctl enable iscsid.service
sudo mpathconf --enable --with_multipathd y


# Build LUNS first
for MGMT in $(/usr/local/bin/aws fsx describe-file-systems | jq -r .FileSystems[].OntapConfiguration.Endpoints.Management.IpAddresses[])
     do
          for LUN in {1..8}
              do
              sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "lun create -vserver ${SVM} -path /vol/vol${LUN}/LUN${LUN} -size 500GB -ostype linux -space-allocation enabled"
              done
     done


# Configure Netapp

for MGMT in $(/usr/local/bin/aws fsx describe-file-systems | jq -r .FileSystems[].OntapConfiguration.Endpoints.Management.IpAddresses[])
        do
        sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "lun igroup create -vserver $SVM -igroup $IGROUP -initiator $IN -protocol iscsi -ostype linux"
                for LUN in {1..8}
                do
                #echo sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "lun mapping create -vserver $SVM -path /vol/vol${LUN}/LUN${LUN} -igroup $IGROUP -lun-id ${LUN}"
                sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "lun map -path /vol/vol${LUN}/LUN${LUN} -igroup $IGROUP -lun-id ${LUN} -vserver ${SVM}"
                done
        sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "set -confirmations off ; set adv ; vol show -volume vol* -fields min-readahead,caching-policy"
        sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "set -confirmations off ; set adv ; volume modify -volume vol* -min-readahead true ; lun modify -path /vol/vol*/LUN* -caching-policy all ; volume modify -volume vol* -caching-policy all"
        sshpass -p $PW ssh -o StrictHostKeyChecking=no -q  fsxadmin@${MGMT} "set -confirmations off ; set adv ; vol show -volume vol* -fields min-readahead,caching-policy"
        done

# Client side setup

for IP in $(/usr/local/bin/aws fsx describe-storage-virtual-machines | jq -r .StorageVirtualMachines[].Endpoints.Iscsi.IpAddresses[0])
do
        target=$(iscsiadm --mode discovery --op update --type sendtargets --portal $IP | head -1 | awk '{print $2}')
        iscsiadm --mode node -T $target
        iscsiadm --mode node -T $target --op update -n node.session.nr_sessions -v $num_sessions
        iscsiadm --mode node -T $target --op update -n node.session.queue_depth -v 32
        iscsiadm --mode node -T $target --login
done

# Use Receive Packet Steering
# change to ttl number of slots
for rsp in $(grep cores /proc/cpuinfo  | wc -l | awk '{print ($1-1)}')
do
        echo "00000000,00000000,ffffffff" > /sys/class/net/eth0/queues/rx-${rsp}/rps_cpus
done

# Set device settings

lsscsi | grep NETAPP | awk '{print $NF}' | awk -F"/" '{print $NF}' | grep -v "-" | while read LUN;  do echo 512 > /sys/block/${LUN}/queue/max_sectors_kb; done
lsscsi | grep NETAPP | awk '{print $NF}' | awk -F"/" '{print $NF}' | grep -v "-" | while read LUN;  do echo none > /sys/block/${LUN}/queue/scheduler; done

