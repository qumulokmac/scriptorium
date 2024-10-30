#!/usr/bin/bash
################################################################################
#
# Script: monclient.sh
# Author: kmac@qumulo.com
# Date:   May 5th, 2024
#
################################################################################

SLEEP_INTERVAL=300

while true
do
  ~/tools/monclient-logger.sh
  sleep $SLEEP_INTERVAL
done
