#!/bin/bash
################################################################################
# Script: vmss_manager.sh
# Purpose: Manage Azure VM Scale Sets (VMSS) by starting, stopping, listing
#          private IPs, or checking the status of VMs in the scale set.
# Usage: ./vmss_manager.sh --start | --stop | --list | --status
# Author: KMac | kmac@qumulo.com
# Date:   November 30, 2024
#
################################################################################

RESOURCE_GROUP="qumulo-southeastasia-rg"
VMSS_NAME="alg-worker-vmss"

function start_vms {
  echo "Starting all VMs in the VMSS: $VMSS_NAME..."
  az vmss start \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VMSS_NAME" \
    --no-wait
  echo "All VMs in the VMSS have been started."
}

function stop_vms {
  echo "Stopping and deallocating all VMs in the VMSS: $VMSS_NAME..."
  az vmss deallocate \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VMSS_NAME" \
    --no-wait
  echo "All VMs in the VMSS have been stopped and deallocated."
}

function list_vm_ips {
  echo "Fetching private IPs of VMs in the VMSS: $VMSS_NAME..."
  az vmss nic list \
    --resource-group "$RESOURCE_GROUP" \
    --vmss-name "$VMSS_NAME" \
    --query "[].ipConfigurations[0].privateIPAddress" \
    --output tsv
}

function check_status {
  echo "Checking the status of VMs in the VMSS: $VMSS_NAME..."
  az vmss list-instances \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VMSS_NAME" \
    --expand instanceView \
    --query "[].{InstanceId:instanceId, State:instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus | [0]}" \
    --output tsv | while read -r instance_id state; do
      if [[ -z $state || $state == "None" ]]; then
        echo "$instance_id: Status unavailable"
      elif [[ $state == "VM running" ]]; then
        echo "$instance_id: Running"
      elif [[ $state == "VM deallocated" ]]; then
        echo "$instance_id: Stopped"
      else
        echo "$instance_id: Unknown State ($state)"
      fi
    done
}

function print_usage {
  echo "Usage: $0 --start | --stop | --list | --status"
  echo "Options:"
  echo "  --start    Start all VMs in the VMSS."
  echo "  --stop     Stop and deallocate all VMs in the VMSS."
  echo "  --list     List the private IPs of VMs in the VMSS."
  echo "  --status   Check the status of VMs in the VMSS."
  exit 1
}

if [[ $# -eq 0 ]]; then
  print_usage
fi

case "$1" in
  start)
    set -- "--start"
    ;;
  stop)
    set -- "--stop"
    ;;
  list)
    set -- "--list"
    ;;
  status)
    set -- "--status"
    ;;
esac

ARGS=$(getopt -o '' --long start,stop,list,status -- "$@")
if [[ $? -ne 0 ]]; then
  print_usage
fi

eval set -- "$ARGS"

while true; do
  case "$1" in
    --start)
      start_vms
      shift
      ;;
    --stop)
      stop_vms
      shift
      ;;
    --list)
      list_vm_ips
      shift
      ;;
    --status)
      check_status
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option: $1"
      print_usage
      ;;
  esac
done
