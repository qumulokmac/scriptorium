#!/usr/bin/bash
################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# Name:     single-trigger-dump.sh 
# Date:     2024-07-22
# Author:   kmac@qumulo.com
#
# Notes:
# - This script starts a trigger dump on the first qumulo node in nodes.conf
#
################################################################################

HARNESS_BASE_NAME="specai"
SSH_USER="qumulo"

NODES_CONF_FILE=~/tools/nodes.conf
SSH_PRIVATE_KEY="${HOME}/.harness-key.pem"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

LOG_DIR_BASE="/home/qumulo/logs/${HARNESS_BASE_NAME}"
TRIGGER_LOGS_BASE="${LOG_DIR_BASE}/triggers"
TRIGGER_LOG_FILE="${TRIGGER_LOGS_BASE}/trigger-dump.${TIMESTAMP}.log"

validate_environment() {
    if [ ! -r ${NODES_CONF_FILE} ]; then
        echo "Nodes configuration file ${NODES_CONF_FILE} does not exist or is not readable."
        exit 1
    fi

    mkdir -p ${TRIGGER_LOGS_BASE}
    if [ $? -ne 0 ]; then
        echo "Failed to create the log base directory: $?"
        exit 1
    fi

    QNODE=$(head -n1 ${NODES_CONF_FILE})

    if [ -z "$QNODE" ]; then
        echo "No node found in ${NODES_CONF_FILE}."
        exit 1
    fi

    nc -z -w5 ${QNODE} 22
    if [ $? -ne 0 ]; then
        echo "Node ${QNODE} is not reachable on port 22."
        exit 1
    fi
}

validate_environment

echo "Starting $0 at $(date)"
QNODE=$(head -n1 ${NODES_CONF_FILE})

ssh ubuntu@${QNODE} -i ${SSH_PRIVATE_KEY} "bash -c 'sudo machinectl shell root@qcore /opt/qumulo/qinternal/monitor/trigger.py -n --qtrace-duration 20'" > ${TRIGGER_LOG_FILE}
if [ $? -ne 0 ]; then
    echo "Failed to take trigger dump on ${QNODE}: $?"
    exit 1
fi




