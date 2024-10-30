#!/usr/bin/bash
################################################################################
#
# Name:    create-mountpoints-file.sh
# Author:  kmac@qumulo.com
# Date:    March 27th, 2024
#
################################################################################

usage() { echo "Usage: $0 -n sharename -s shift-factor" 1>&2; exit 1; }

while getopts ":n:s:" o; do
    case "${o}" in
        n)
            n=${OPTARG}
            ;;
        s)
            s=${OPTARG}
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
if [[ -z $s ]]
then
  usage; exit 1
fi

NFS_EXPORT_NAME="${n}"

WORKERS_CONF="/home/qumulo/tools/workers.conf"
NODES_CONF="/home/qumulo/tools/nodes.conf"
NFS_EXPORT_BASE="/mnt/${NFS_EXPORT_NAME}-node"

declare -g WORKER_IP_ADDRESS
declare -g NFS_MOUNT_POINT
declare -ig NUM_NODES
declare -ig NUM_WORKERS
declare -ig NUM_SHIFT=${s}

###
# Setup:  Using nodes.conf and workers.conf, determine the geometry of the harness and create an indexed array.
###
function Setup
{
    declare -i n
    declare -i i

    readarray -t WORKER_IP_ADDRESS < $WORKERS_CONF
    readarray -t NODE_IPS < $NODES_CONF

    NUM_NODES=${#NODE_IPS[@]}
    NUM_WORKERS=${#WORKER_IP_ADDRESS[@]}

    for (( n=0; n<$NUM_NODES; n++ ))
    do
      NFS_MOUNT_POINT["${n}"]=${NFS_EXPORT_BASE}${n}
    done
}

function DumpWorkingSet
{
    declare -i n

    for ((n=0; n<$NUM_NODES; n++))
    do
        if [[ $n -ge ${NUM_WORKERS} ]]; then
          if [[ $n -ge $((NUM_WORKERS * 2)) ]] ; then
            i=$((n - NUM_WORKERS * 2))
          else
            i=$((n - NUM_WORKERS ))
          fi
          echo "${WORKER_IP_ADDRESS[$i]} ${NFS_MOUNT_POINT[$n]}"
        else
          echo "${WORKER_IP_ADDRESS[$n]} ${NFS_MOUNT_POINT[$n]}"
        fi
    done
}

function ShiftIndex {
    declare -i n
    declare -i NEWINDEX

    ROLLOVER_POINT=$((NUM_NODES - NUM_SHIFT))

    for ((n=0; n<$NUM_NODES; n++))
    do
        if [[ $n -ge $ROLLOVER_POINT ]]; then
            NEWINDEX=$((n - ROLLOVER_POINT))
        else
            NEWINDEX=$((n + NUM_SHIFT))
        fi
        NEW_NFS_MOUNT_POINT[$n]=${NFS_MOUNT_POINT[$NEWINDEX]}
    done

    for ((n=0; n<$NUM_NODES; n++))
    do
        NFS_MOUNT_POINT[$n]=${NEW_NFS_MOUNT_POINT[$n]}
    done
}


Setup

NUM_ITERATIONS=$((NUM_NODES / NUM_SHIFT))

DumpWorkingSet

for ((n=0; n<$NUM_ITERATIONS; n++))
do
    ShiftIndex
    DumpWorkingSet
done

