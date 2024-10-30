################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# Name:     apply_tunables.sh
# Date:     2024-07-22
# Author:   kmac@qumulo.com
#
# Notes:
# - This script reads key-value pairs from a configuration file and applies
#   them to a Qumulo cluster.
#
################################################################################

################################################################################
# Example tunables.conf configuration script for setting qumulo tunables
################################################################################
#
# vm_disk_throughput_model_megabytes_per_second|534
# vm_network_saturation_model_threshold_megabytes_per_second|2812
#
################################################################################
# End of configuration script
################################################################################

HARNESS_BASE_NAME="specai"
SSH_USER="qumulo"

NODES_CONF_FILE=~/tools/nodes.conf
SSH_PRIVATE_KEY="${HOME}/.harness-key.pem"
TUNABLES_CONF_FILE=~/tools/tunables.conf

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

LOG_DIR_BASE="/home/qumulo/logs/${HARNESS_BASE_NAME}"
TUNABLES_LOGS_BASE="${LOG_DIR_BASE}/tunables"
TUNABLES_LOG_FILE="${TUNABLES_LOGS_BASE}/apply_tunables_output.${TIMESTAMP}.log"

validate_environment() {
    if [ ! -r ${NODES_CONF_FILE} ]; then
        echo "Nodes configuration file ${NODES_CONF_FILE} does not exist or is not readable."
        exit 1
    fi

    if [ ! -r ${TUNABLES_CONF_FILE} ]; then
        echo "Tunables configuration file ${TUNABLES_CONF_FILE} does not exist or is not readable."
        exit 1
    fi

    mkdir -p ${TUNABLES_LOGS_BASE}
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

apply_tunables() {
    while IFS='|' read -r KEY VALUE; do
        if [[ -z "$KEY" || -z "$VALUE" ]]; then
            continue
        fi

        echo "Applying tunable ${KEY}=${VALUE} to ${QNODE}"

        echo "Tunables setting before change:" >> ${TUNABLES_LOG_FILE} 2>&1

        ssh ubuntu@${QNODE} -i ${SSH_PRIVATE_KEY} "bash -c \"sudo machinectl shell root@qcore /opt/qumulo/qinternal/qq_internal tunables_get ${KEY}\"" >> ${TUNABLES_LOG_FILE} 2>&1
        if [ $? -ne 0 ]; then
            echo "Failed to get tunable ${KEY}=${VALUE} on ${QNODE}: $?"
            exit 1
        fi

        ssh ubuntu@${QNODE} -i ${SSH_PRIVATE_KEY} "bash -c \"sudo machinectl shell root@qcore /opt/qumulo/qinternal/qq_internal tunables_set ${KEY} ${VALUE}\"" >> ${TUNABLES_LOG_FILE} 2>&1
        if [ $? -ne 0 ]; then
            echo "Failed to set tunable ${KEY}=${VALUE} on ${QNODE}: $?"
            exit 1
        fi

        echo "Tunables setting after change:" >> ${TUNABLES_LOG_FILE} 2>&1

        ssh ubuntu@${QNODE} -i ${SSH_PRIVATE_KEY} "bash -c \"sudo machinectl shell root@qcore /opt/qumulo/qinternal/qq_internal tunables_get ${KEY}\"" >> ${TUNABLES_LOG_FILE} 2>&1
        if [ $? -ne 0 ]; then
            echo "Failed to get tunable ${KEY}=${VALUE} on ${QNODE}: $?"
            exit 1
        fi

    done < ${TUNABLES_CONF_FILE}
}

validate_environment

echo "Starting $0 at $(date)"
apply_tunables

echo "Completed $0 at $(date)"

exit 0