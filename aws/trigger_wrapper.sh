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
# Name:     trigger_wrapper.sh
# Date:     2024-07-22
# Author:   kmac@qumulo.com
#
# Notes:
# - This script tails the SPECLOG and runs the TRIGGER_SCRIPT when TRIGGER_STRING is detected
#
################################################################################

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

SPECLOG="/home/qumulo/spec/SPECExecutable/results/sfslog_AI_IMAGE.log"
TRIGGER_STRING="Starting RUN phase"
TRIGGER_SCRIPT="/home/qumulo/tools/single-trigger-dump.sh"
LOGFILE="/home/qumulo/logs/trigger_wrapper-${TIMESTAMP}.log"

log_message() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> ${LOGFILE}
}

if [ ! -r ${SPECLOG} ]; then
    log_message "SPECLOG file ${SPECLOG} does not exist or is not readable."
    exit 1
fi

if [ ! -x ${TRIGGER_SCRIPT} ]; then
    log_message "TRIGGER_SCRIPT ${TRIGGER_SCRIPT} is not executable."
    exit 1
fi

log_message "Starting to tail ${SPECLOG} for trigger string '${TRIGGER_STRING}'."
tail -F ${SPECLOG} | while read LINE; do
    echo "$LINE" | grep --quiet "${TRIGGER_STRING}"
    if [ $? -eq 0 ]; then
        log_message "Starting RUN phase, starting trigger script."
        ${TRIGGER_SCRIPT} >> ${LOGFILE} 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error running trigger script."
        else
            log_message "Trigger script executed successfully."
        fi
    fi
done


