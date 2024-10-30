#!/usr/bin/bash

declare -g DEBUG="off"

NFS_EXPORT_NAME="AI_IMAGE"

WORKERS_CONF="/home/qumulo/tools/workers.conf"
NODES_CONF="/home/qumulo/tools/nodes.conf"
NFS_EXPORT_BASE="/mnt/${NFS_EXPORT_NAME}-node"
MOUNTPOINT_BASE="/mnt/AI_IMAGE-node"

declare -g WORKER_IP_ADDRESS
declare -g NFS_MOUNT_POINT
declare -ig NUM_NODES
declare -ig NUM_WORKERS
declare -ig AGG_CMP

readarray -t WORKERS < $WORKERS_CONF
readarray -t NODES < $NODES_CONF

NUM_NODES=${#NODE_IPS[@]}
NUM_WORKERS=${#WORKER_IP_ADDRESS[@]}
NODE_SET_SIZE=16

NODE_SET_A=("${NODES[@]:0:16}")
NODE_SET_B=("${NODES[@]:16:16}") 
NODE_SET_C=("${NODES[@]:32:16}") 

WORKER_SET_A=("${WORKERS[@]:0:10}")
WORKER_SET_B=("${WORKERS[@]:10:12}")
WORKER_SET_C=("${WORKERS[@]:22:10}")

for ((SHIFT_IDX=0; SHIFT_IDX<${NODE_SET_SIZE}; SHIFT_IDX++))
do
     # echo "SHIFT_IDX: $SHIFT_IDX "

 for ((COMBO_IDX_A=0; COMBO_IDX_A<$NODE_SET_SIZE; COMBO_IDX_A++)); do
 
     WORKER_A_IDX=$(( (COMBO_IDX_A + $SHIFT_IDX) % ${#WORKER_SET_A[@]} ))
	 if [[ "$DEBUG" == "on" ]]; then
     	echo -n "A: "
     fi
     echo "${WORKER_SET_A[$WORKER_A_IDX]} $MOUNTPOINT_BASE$COMBO_IDX_A"

 done

 for ((COMBO_IDX_B=0; COMBO_IDX_B<$NODE_SET_SIZE; COMBO_IDX_B++)); do
 
     WORKER_B_IDX=$(( COMBO_IDX_B + $SHIFT_IDX ))
     if [[ $COMBO_IDX_B -ge ${#WORKER_SET_B[@]} || $WORKER_B_IDX -ge ${#WORKER_SET_B[@]} ]]
     then
     	WORKER_B_IDX=$(( WORKER_B_IDX - ${#WORKER_SET_B[@]} ))
	     if [[ $WORKER_B_IDX -ge ${#WORKER_SET_B[@]} ]]
	     then
	     	WORKER_B_IDX=$(( WORKER_B_IDX - ${#WORKER_SET_B[@]} - ${#WORKER_SET_B[@]} ))
	     	# echo "WORKER_B_IDX is now $WORKER_B_IDX"
	     fi
     	# echo "WORKER_B_IDX is now $WORKER_B_IDX"
     fi
	 if [[ "$DEBUG" == "on" ]]; then
     	echo -n "B: "
     fi
     NODEIDX=$((COMBO_IDX_B + ${#NODE_SET_A[@]}))
     echo "${WORKER_SET_B[$WORKER_B_IDX]} $MOUNTPOINT_BASE$NODEIDX"

 done

 for ((COMBO_IDX_C=0; COMBO_IDX_C<$NODE_SET_SIZE; COMBO_IDX_C++)); do
     WORKER_C_IDX=$(( COMBO_IDX_C + $SHIFT_IDX ))
     if [[ $COMBO_IDX_C -ge ${#WORKER_SET_C[@]} || $WORKER_C_IDX -ge ${#WORKER_SET_C[@]} ]]
     then
        WORKER_C_IDX=$(( WORKER_C_IDX - ${#WORKER_SET_C[@]} ))
	     if [[ $WORKER_C_IDX -ge ${#WORKER_SET_C[@]} ]]
	     then
	     	WORKER_C_IDX=$(( WORKER_C_IDX - ${#WORKER_SET_C[@]} - ${#WORKER_SET_C[@]} ))
	     	# echo "WORKER_B_IDX is now $WORKER_B_IDX"
	     fi
     fi
	 if [[ "$DEBUG" == "on" ]]; then
     	echo -n "C: "
     fi
     NODEIDX=$((COMBO_IDX_C + ${#NODE_SET_A[@]} + ${#NODE_SET_B[@]} ))

     echo "${WORKER_SET_C[$WORKER_C_IDX]} ${MOUNTPOINT_BASE}$NODEIDX"
 done

done

