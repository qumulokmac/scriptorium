#!/bin/bash
################################################################################
# Script: sync_workers.sh
# Author: KMac | kmac@qumulo.com
# Date:   2024-11-23
################################################################################

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[1;34m"
NC="\033[0m"

RESOURCE_GROUP="qumulo-centralindia-rg"
VMSS_NAME="alg-worker-vmss"

handle_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  exit 1
}

WORKERS_CONF="${HOME}/conf/workers.conf"
ADAPTIVE_SCRIPT="/home/qumulo/adaptive_load_generator.sh"
START_SCRIPT="/home/qumulo/start_load.sh"
TOOLS_DIR="/home/qumulo/tools"

# echo -e "${BLUE}[INFO] Fetching private IP addresses for VMSS: ${VMSS_NAME}...${NC}"
# PRIVATE_IPS=$(az vmss nic list \
#  --resource-group "$RESOURCE_GROUP" \
#  --vmss-name "$VMSS_NAME" \
#  --query "[].ipConfigurations[0].privateIPAddress" \
#  --output tsv 2>/dev/null) || handle_error "Failed to fetch private IP addresses. Check your Azure CLI setup and resource details."

PRIVATE_IPS=$(cat $WORKERS_CONF)

if [[ -z "$PRIVATE_IPS" ]]; then
  handle_error "No private IP addresses found. Ensure the VMSS is running and has network interfaces."
fi

echo -e "${GREEN}[SUCCESS] Private IPs fetched:${NC}"
for ip in $PRIVATE_IPS; do
  echo -e "${YELLOW}- $ip${NC}"
done


if [[ ! -f "$WORKERS_CONF" ]]; then
  handle_error "Workers configuration file not found at $WORKERS_CONF."
fi

echo -e "${BLUE}[INFO] Syncing scripts and tools to workers...${NC}"
parallel-scp -h "$WORKERS_CONF" "$ADAPTIVE_SCRIPT" "$ADAPTIVE_SCRIPT" || handle_error "Failed to sync adaptive_load_generator.sh."
parallel-scp -h "$WORKERS_CONF" "$START_SCRIPT" "$START_SCRIPT" || handle_error "Failed to sync start_load.sh."

echo -e "${BLUE}[INFO] Creating tools directory on workers...${NC}"
parallel-ssh -h "$WORKERS_CONF" "mkdir -p $TOOLS_DIR"

echo -e "${BLUE}[INFO] Syncing tools directory to workers...${NC}"
#echo "parallel-scp -h $WORKERS_CONF ${TOOLS_DIR}/* $TOOLS_DIR"
# parallel-scp -h "$WORKERS_CONF" "${TOOLS_DIR}/*" "$TOOLS_DIR" 

parallel-scp -h "$WORKERS_CONF" ${TOOLS_DIR}/* "$TOOLS_DIR"
