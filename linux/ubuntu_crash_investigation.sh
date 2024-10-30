#!/usr/bin/bash
###################################################################################################
# System Crash Investigation Script
#
# Description:
# This script systematically checks system logs and outputs relevant findings to help diagnose
# potential causes of system crashes, including memory issues, hardware errors, kernel panics, 
# and power events.
#
# Usage:
# Run this script with root privileges to ensure access to system logs:
#   sudo ./ubuntu_crash_investigation.sh
#
# Requirements:
# - Bash shell
# - Root access for viewing certain logs
#
# Author: 	KMac
# Date: 	October 31st, 2024
#
###################################################################################################

run_check() {
    echo "###################################################################################################"
    echo "# Running check: $1"
    echo "# Command: $2"
    echo "###################################################################################################"
    echo ""
    eval "$2" | tee /dev/stderr | grep -q . || echo "No findings in this section."
    echo ""
}

echo "==================== System Crash Investigation Script ===================="
run_check "dmesg Errors and Warnings" "dmesg | grep -iE 'error|warn|fail|fatal'"
run_check "Out of Memory (OOM) Events" "dmesg | grep -i 'oom'"
run_check "Hardware Errors" "dmesg | grep -iE 'hardware|cpu|disk|thermal|temperature'"
run_check "Kernel Panics and Stack Traces" "dmesg | grep -i 'panic'"
run_check "Critical Events in syslog" "sudo grep -iE 'error|critical|segfault|panic|fail' /var/log/syslog"
run_check "Recent syslog Entries (last 1000 lines)" "sudo tail -n 1000 /var/log/syslog"
run_check "Kernel Messages from journalctl" "sudo journalctl -k | grep -iE 'fail|error|warn'"
run_check "File System and Disk Errors" "dmesg | grep -iE 'ext4|xfs|btrfs|filesystem|disk'"
run_check "Power or Reboot Events in syslog" "grep -iE 'power|shutdown|reboot' /var/log/syslog"
echo "==================== Investigation Complete ===================="