#!/bin/bash
################################################################################
# swizzle_mounts.sh
#
# kmac@qumulo.com
#
# Feb 16th, 2024
#
################################################################################
WORKERHOSTS="workers.conf"
NODEHOSTS="nodes.conf"
NFSEXPORT="specgenes"
TMPFILE="/tmp/._$$-${RANDOM}_`uuidgen`-swizzled.tmp"
readarray -t HOSTS < $WORKERHOSTS
readarray -t NODES < $NODEHOSTS

MAXHOSTS=${#HOSTS[@]}
MAXNODES=${#NODES[@]}
MNMO=$((MAXNODES -1 ))
###
# Pointer used to mark the starting node
###
declare -i  CURSTART=0
declare -i  HIGHWATERMARK=0
declare -i  THEHOST=0
declare -i  THENODE=0
declare -i  NEWSTART=0

for host in `seq 0 $MAXHOSTS`
do
  for (( count=0; count<${#NODES[@]}; count++ ))
	do
    if [[ $CURSTART == ${MAXNODES} ]]
    then
      CURSTART=0
    fi
    if [[ $THENODE == ${MNMO} ]]
    then
      # printf "\tTripped MNMO\n"
      HIGHWATERMARK=1
      THENODE=0
      NEWSTART=0
    fi

    if [[ $HIGHWATERMARK == 1 ]]
    then
      THENODE=$((NEWSTART))
      NEWSTART=$((NEWSTART + 1))
      # printf "\tHWM: Host $THEHOST| Node $THENODE\n"
    else
      THENODE=$((count + CURSTART))
      # printf "\tNRM: Host $THEHOST| Node $THENODE\n"
    fi
    printf "spec-$THEHOST /mnt/${NFSEXPORT}-node${THENODE}\n"
    THEHOST=$((THEHOST + 1))
	done
  # Next host coming up
  THENODE=0
  THEHOST=0
  NEWSTART=0
  HIGHWATERMARK=0
  CURSTART=$((CURSTART+1))
 # echo "------"
done
