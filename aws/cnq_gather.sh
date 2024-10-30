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
# Name:     cnq_gather
# Date:     2024-07-20
# Author:   kmac@qumulo.com
#
# Notes:
# - This script gathers logs from cluster nodes and worker nodes.
# - It creates a directory structure to store logs, gathers qfsd-journal logs
#   and syslogs from cluster nodes, and gathers netmist logs and varlogs from worker nodes.
# - Finally, it consolidates the logs into a tarball and uploads it to an S3 bucket.
#
# Example:
# ./cnq_gather -h specai -s s3://cnq-log-archive -l /home/user/cnq_gather.log -u qumulo
#
################################################################################

###
# Variables
###

HARNESS_BASE_NAME=""
S3_BUCKET=""
LOG_FILE=""
SSH_USER="qumulo"

NODES_CONF_FILE=~/tools/nodes.conf
WORKERS_CONF_FILE=~/tools/workers.conf

SSH_PRIVATE_KEY='~/.harness-key.pem'

usage() {
    echo "Usage: $0 -h <harness_base_name> -s <s3_bucket> [-u <ssh_user>] [--help]"
    echo
    echo "Options:"
    echo "  -h <harness_base_name>  Set the harness base name"
    echo "  -s <s3_bucket>          Set the S3 bucket name"
    echo "  -u <ssh_user>           Set the SSH username (default: qumulo)"
    echo "  --help                  Show this help message and exit"
    echo
    echo "Example:"
    echo "  $0 -h specai -s s3://cnq-log-archive -u qumulo"
    exit 1
}

while getopts ":h:s:u:-:" opt; do
    case ${opt} in
        h )
            HARNESS_BASE_NAME=$OPTARG
            ;;
        s )
            S3_BUCKET=$OPTARG
            ;;
        u )
            SSH_USER=$OPTARG
            ;;
        - )
            case "${OPTARG}" in
                help)
                    usage
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" 1>&2
                    usage
                    ;;
            esac
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            usage
            ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$HARNESS_BASE_NAME" ] || [ -z "$S3_BUCKET" ]; then
    usage
fi


###
# Load nodes and workers into arrays
###
IFS=$'\r\n' GLOBIGNORE='*' command eval 'NODES=($(cat $NODES_CONF_FILE))'
IFS=$'\r\n' GLOBIGNORE='*' command eval 'WORKERS=($(cat $WORKERS_CONF_FILE))'

NUM_NODES=${#NODES[@]}
NUM_WORKERS=${#WORKERS[@]}

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR_BASE="/home/qumulo/logs/${HARNESS_BASE_NAME}-${TIMESTAMP}"
LOG_FILE="${LOG_DIR_BASE}/cnq_gather-${TIMESTAMP}.log"
CLUSTER_LOGS_BASE="${LOG_DIR_BASE}/cluster"
WORKER_LOGS_BASE="${LOG_DIR_BASE}/workers"
SPEC_LOG_BASE="${LOG_DIR_BASE}/${HARNESS_BASE_NAME}"
NFS_ADMIN_MNT="/mnt/${HARNESS_BASE_NAME}-node0"

mkdir -p "${LOG_DIR_BASE}"

echo "Gathering logs from $NUM_NODES nodes and $NUM_WORKERS workers"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") : $1" | tee -a "${LOG_FILE}"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

check_dependencies() {
    command -v ssh >/dev/null 2>&1 || error_exit "ssh is not installed."
    command -v scp >/dev/null 2>&1 || error_exit "scp is not installed."
    command -v aws >/dev/null 2>&1 || error_exit "aws CLI is not installed."
}

create_directory_structure() {
    log "Creating gather directory structure..."
    mkdir -p "${CLUSTER_LOGS_BASE}/qfsd-journals" \
             "${CLUSTER_LOGS_BASE}/syslogs" \
             "${WORKER_LOGS_BASE}/netmist" \
             "${WORKER_LOGS_BASE}/varlogs" \
             "${NFS_ADMIN_MNT}/netmist-logs-${TIMESTAMP}" \
             "${NFS_ADMIN_MNT}/worker-varlogs-${TIMESTAMP}" \
             "${SPEC_LOG_BASE}/stdout"
    if [ $? -ne 0 ]; then
        error_exit "Failed to create directory structure"
    fi
}

# gather_cluster_logs() {
#     log "Gathering cluster logs..."
#     for host in "${NODES[@]}"; do
#         this_hostname=$(ssh -i ${SSH_PRIVATE_KEY} -o 'StrictHostKeyChecking=no' ubuntu@${host} hostname)
#         if [ $? -ne 0 ]; then
#             log "Failed to get hostname for ${host}"
#             continue
#         fi
# 
#         log "Gathering the qfsd-journal.log from ${this_hostname}..."
#         ssh ubuntu@${host} -i ${SSH_PRIVATE_KEY} "bash -c 'sudo machinectl shell root@qcore /usr/bin/journalctl --no-pager -b -u qumulo-qfsd.service 2>/dev/null'" > "${CLUSTER_LOGS_BASE}/qfsd-journals/qfsd-journal-${this_hostname}.log"
#         if [ $? -ne 0 ]; then
#             log "Failed to gather qfsd-journal.log from ${this_hostname}"
#             continue
#         fi
# 
#         log "Gathering the syslog from ${this_hostname}..."
#         scp -i ${SSH_PRIVATE_KEY} ubuntu@${host}:/var/log/syslog "${CLUSTER_LOGS_BASE}/syslogs/${this_hostname}.syslog"
#         if [ $? -ne 0 ]; then
#             log "Failed to gather syslog from ${this_hostname}"
#             continue
#         fi
#     done
# }


gather_cluster_logs() {
    log "Gathering cluster logs..."
    for host in "${NODES[@]}"; do
        this_hostname=$(ssh -i ${SSH_PRIVATE_KEY} -o 'StrictHostKeyChecking=no' ubuntu@${host} hostname)
        if [ $? -ne 0 ]; then
            log "Failed to get hostname for ${host}"
            continue
        fi

        log "Gathering the qfsd-journal.log from ${this_hostname}..."
        ssh ubuntu@${host} -i ${SSH_PRIVATE_KEY} "bash -c 'sudo machinectl shell root@qcore /usr/bin/journalctl --no-pager -b -u qumulo-qfsd.service 2>/dev/null'" > "${CLUSTER_LOGS_BASE}/qfsd-journals/qfsd-journal-${this_hostname}.log"
        if [ $? -ne 0 ]; then
            log "Failed to gather qfsd-journal.log from ${this_hostname}"
            continue
        fi

        log "Gathering the syslog from ${this_hostname}..."
        scp -i ${SSH_PRIVATE_KEY} ubuntu@${host}:/var/log/syslog "${CLUSTER_LOGS_BASE}/syslogs/${this_hostname}.syslog"
        if [ $? -ne 0 ]; then
            log "Failed to gather syslog from ${this_hostname}"
            continue
        fi

        log "Creating tarball of /var/log and /var/crash from qcore on ${this_hostname}..."
        ssh ubuntu@${host} -i ${SSH_PRIVATE_KEY} "bash -c 'sudo machinectl shell root@qcore tar czf /tmp/${this_hostname}_logs.tar.gz /var/log /var/crash'" 2>&1 >> ${CLUSTER_LOGS_BASE}/config/tarvarlogcrash-out.log
        if [ $? -ne 0 ]; then
            log "Failed to create tarball of /var/log and /var/crash from ${this_hostname}"
            continue
        fi

        log "Copying tarball from ${this_hostname}..."
        scp -i ${SSH_PRIVATE_KEY} ubuntu@${host}:/tmp/${this_hostname}_logs.tar.gz "${CLUSTER_LOGS_BASE}/logs/${this_hostname}_logs.tar.gz" 2>&1 >> ${CLUSTER_LOGS_BASE}/config/tarvarlogcrash-out.log
        if [ $? -ne 0 ]; then
            log "Failed to copy tarball from ${this_hostname}"
            continue
        fi
    done

    log "Creating config directory and gathering cluster configuration tunables..."

    mkdir -p "${CLUSTER_LOGS_BASE}/config"
    
    ssh ubuntu@${host} -i ${SSH_PRIVATE_KEY} "bash -c 'sudo machinectl shell root@qcore cat /config/tunables.json | jq .'" > "${CLUSTER_LOGS_BASE}/config/cluster_config_tunables-${TIMESTAMP}.json"
    if [ $? -ne 0 ]; then
        log "Failed to gather cluster configuration tunables."
    fi
}

gather_spec_logs() {
    log "Gathering spec logs..."
    for host in "${WORKERS[@]}"; do
        ssh_output=$(ssh ${SSH_USER}@${host} -i ${SSH_PRIVATE_KEY} "cp /tmp/netmist_*.log ${NFS_ADMIN_MNT}/netmist-logs-${TIMESTAMP}" 2>&1)
        if [ $? -ne 0 ]; then
            log "Failed to gather netmist logs from ${host}. Check permissions and paths."
            log "SSH output: ${ssh_output}"
            continue
        fi
    done

    cp -rp "${NFS_ADMIN_MNT}/netmist-logs-${TIMESTAMP}" "${SPEC_LOG_BASE}"
    if [ $? -ne 0 ]; then
        error_exit "Failed to copy netmist logs"
    fi
    if ls ~/logs/*_STDOUT.log 1> /dev/null 2>&1; then
        cp ~/logs/*_STDOUT.log "${SPEC_LOG_BASE}/stdout"
        if [ $? -ne 0 ]; then
            error_exit "Failed to copy stdout logs"
        fi
    else
        log "No *_STDOUT.log files found to copy"
    fi

    tar czf "${SPEC_LOG_BASE}/spec-config-${TIMESTAMP}.tgz" ~/spec 2>/dev/null
    if [ $? -ne 0 ]; then
        error_exit "Failed to create spec-config tarball"
    fi
}

gather_worker_logs() {
    log "Gathering worker logs..."
    for host in "${WORKERS[@]}"; do
        this_hostname=$(ssh -i ${SSH_PRIVATE_KEY} -o 'StrictHostKeyChecking=no' ${SSH_USER}@${host} hostname)
        if [ $? -ne 0 ]; then
            log "Failed to get hostname for ${host}"
            continue
        fi

        log "Gathering /var/logs from ${this_hostname}..."
        ssh_output=$(ssh ${SSH_USER}@${host} -i ${SSH_PRIVATE_KEY} "sudo tar czf ${NFS_ADMIN_MNT}/worker-varlogs-${TIMESTAMP}/${this_hostname}-varlog.tgz --exclude=/var/log/journal /var/log" 2>&1)
        if [ $? -ne 0 ]; then
            log "Failed to gather varlogs from ${this_hostname}. Check permissions and paths."
            log "SSH output: ${ssh_output}"
            continue
        fi

        ssh_output=$(ssh ${SSH_USER}@${host} -i ${SSH_PRIVATE_KEY} "sudo chown ${SSH_USER}:${SSH_USER} ${NFS_ADMIN_MNT}/worker-varlogs-${TIMESTAMP}/${this_hostname}-varlog.tgz" 2>&1)
        if [ $? -ne 0 ]; then
            log "Failed to change ownership of varlogs tarball for ${this_hostname}. Check permissions."
            log "SSH output: ${ssh_output}"
            continue
        fi
    done
    cp -rp "${NFS_ADMIN_MNT}/worker-varlogs-${TIMESTAMP}" "${WORKER_LOGS_BASE}/varlogs"
    if [ $? -ne 0 ]; then
        error_exit "Failed to copy worker varlogs"
    fi
}

consolidate_and_upload_logs() {
    log "Consolidating archive..."
    cd "${LOG_DIR_BASE}" || error_exit "Failed to change directory to ${LOG_DIR_BASE}"
    tar cvzf "${NFS_ADMIN_MNT}/cnq_gather-${TIMESTAMP}.tgz" .
    if [ $? -ne 0 ]; then
        error_exit "Failed to create final tarball"
    fi

    log "Copying archive to $S3_BUCKET/${TIMESTAMP}/cnq_gather-${TIMESTAMP}.tgz"
    aws s3 cp "${NFS_ADMIN_MNT}/cnq_gather-${TIMESTAMP}.tgz" "$S3_BUCKET/${TIMESTAMP}/cnq_gather-${TIMESTAMP}.tgz"
    if [ $? -ne 0 ]; then
        error_exit "Failed to upload tarball to S3"
    fi
}

main() {
    check_dependencies
    create_directory_structure
    gather_cluster_logs
    gather_spec_logs
    gather_worker_logs
    consolidate_and_upload_logs
    log "Log gathering and upload completed successfully."
}

main
