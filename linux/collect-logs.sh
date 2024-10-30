#!/usr/bin/bash
################################################################################
#
# Script: collect-logs.sh
# Author: kmac@qumulo.com
# Date:   May 5th, 2024
#
################################################################################

usage() { echo "Usage: $0 -n sharename " 1>&2; exit 1; }

while getopts ":n:" o; do
    case "${o}" in
        n)
            n=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [[ -z $n ]]
then
  usage; exit 1
fi

SUFFIX="${n}"

DTS=`date +"%Y_%m_%d_%H:%M"`
HOST=`hostname`

NETMIST_DIR="netmist-${SUFFIX}-${DTS}"
MONCLT_WRKR_DIR="monclient-worker-${SUFFIX}-${DTS}"

echo "Making directories..."
mkdir -p /home/qumulo/logs/${NETMIST_DIR}
mkdir -p /mnt/${SUFFIX}-node0/${NETMIST_DIR}
mkdir -p /home/qumulo/logs/${MONCLT_WRKR_DIR}
mkdir -p /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR}
mkdir -p /home/qumulo/logs/syslogs/syslogs-$DTS
mkdir -p /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-`cat /proc/sys/kernel/hostname`

echo "Consolidating netmist logs to /mnt/${SUFFIX}-node0/${NETMIST_DIR}"
parallel-ssh -v -h ~/tools/workers.conf -i "cp /tmp/netmist*.log /mnt/${SUFFIX}-node0/${NETMIST_DIR}"

echo "Consolidating monclient logs to /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR}/HOSTNAME "
parallel-ssh -v -h ~/tools/workers.conf -i "mkdir -p /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR}/\`cat /proc/sys/kernel/hostname\` "
parallel-ssh -v -h ~/tools/workers.conf -i "cp /home/qumulo/logs/monclient/*  /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR}/\`cat /proc/sys/kernel/hostname\` "

echo "Copying netmist logs locally, from /mnt/${SUFFIX}-node0/${NETMIST_DIR} to /home/qumulo/logs/${NETMIST_DIR}"
cp /mnt/${SUFFIX}-node0/${NETMIST_DIR}/* /home/qumulo/logs/${NETMIST_DIR}

echo "Copying monclient logs locally, from /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR} to /home/qumulo/logs/${MONCLT_WRKR_DIR}"
cp -rp /mnt/${SUFFIX}-node0/${MONCLT_WRKR_DIR}/* /home/qumulo/logs/${MONCLT_WRKR_DIR}

echo "Consolidating syslogs to /mnt/${SUFFIX}-node0/syslogs-$DTS"

parallel-ssh -v -h ~/tools/workers.conf -i "mkdir -p /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-\`cat /proc/sys/kernel/hostname\` "
parallel-ssh -v -h ~/tools/workers.conf -i "sudo cp /var/log/syslog* /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-\`cat /proc/sys/kernel/hostname\` "
sudo cp  /var/log/syslog* /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-`cat /proc/sys/kernel/hostname`
sudo cp /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-`cat /proc/sys/kernel/hostname`/* /home/qumulo/logs/syslogs
sudo chown -R qumulo:qumulo  /mnt/${SUFFIX}-node0/syslogs-$DTS/syslog-`cat /proc/sys/kernel/hostname`

echo "complete"
echo ""