#!/bin/bash
################################################################################
#
# mysar
#
# kmac@qumulo.com
#
# A quickie to pull OS stats
#
################################################################################

while true
do
  printf '#%.0s' {1..42}
  printf "\n CPU Usage \n"
  printf '#%.0s' {1..42}
  echo ""

  sar -u 1 8

  printf '#%.0s' {1..42}
  printf "\n Run Queue \n"
  printf '#%.0s' {1..42}
  echo ""
  sar -q 1 8

  printf '#%.0s' {1..42}
  printf "\n Process, Kernel Thread, I-node \n"
  printf '#%.0s' {1..42}
  echo ""
  sar -v 1 8

  printf '#%.0s' {1..42}
  printf "\nCPU proc/s and context switching \n"
  printf '#%.0s' {1..42}
  echo ""
  sar -w 1 8

  printf '#%.0s' {1..42}
  printf "\n Memory Usage:\n"
  printf '#%.0s' {1..42}
  echo ""
  sar -r 1 4

  printf '#%.0s' {1..42}
  printf "\nIO Activity:\n"
  printf '#%.0s' {1..42}
  echo ""
  sar -b 1 8

  printf '#%.0s' {1..42}
  printf "\nNFS Stats:\n"
  printf '#%.0s' {1..42}
  echo ""
  nfsstat 1 8 -v -3 /mnt/gattaca/

  printf '#%.0s' {1..42}
  printf "\n60s Sleep at `date`\n"
  printf '#%.0s' {1..42}
  sleep 60
done