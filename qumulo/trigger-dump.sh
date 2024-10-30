#!/bin/bash
################################################################################
#
# Copyright (c) 2024 Qumulo, Inc. All rights reserved.
#
# NOTICE: All information and intellectual property contained herein is the
# confidential property of Qumulo, Inc. Reproduction or dissemination of the
# information or intellectual property contained herein is strictly forbidden,
# unless separate prior written permission has been obtained from Qumulo, Inc.
#
# Name:     capture_trigger.sh
# Date:     2024-07-20
# Author:   kmac@qumulo.com
#
# Notes:
# - This script runs trigger.py for a specified duration and number of captures,
#   with a sleep interval between each capture.
# - The duration of each capture, the sleep interval, and the number of captures
#   are configurable via script variables.
#
################################################################################

CAPTURE_DURATION_SECS=30
SLEEP_INTERVAL_SECONDS=1800
NUMBER_OF_CAPTURES=12

for i in `seq 1 ${NUMBER_OF_CAPTURES}`
do
    echo "Starting trigger.py iteration $i @`date`"
    sudo /opt/qumulo/qinternal/monitor/trigger.py -n --duration ${CAPTURE_DURATION_SECS}
    echo "Sleeping for ${SLEEP_INTERVAL_SECONDS} seconds @`date`"
    
    for j in $(seq 1 ${SLEEP_INTERVAL_SECONDS})
    do
        echo -n "."
        sleep 1
    done
    
    echo 
done