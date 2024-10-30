#!/bin/bash

CAPTURE_DURATION_SECS=60
SLEEP_INTERVAL_SECONDS=120
NUMBER_OF_CAPTURES=10

echo "Waiting 900 seconds for AI_IMAGE jobs to warm up @`date`"
sleep 900

for i in `seq 1 ${NUMBER_OF_CAPTURES}`
do
        echo "Starting trigger.py iteration $i @`date`"
        sudo qsh -c /opt/qumulo/qinternal/monitor/trigger.py -n --duration ${CAPTURE_DURATION_SECS}
        echo "Sleeping for ${SLEEP_INTERVAL_SECONDS} seconds @`date`"
        sleep ${SLEEP_INTERVAL_SECONDS}
done