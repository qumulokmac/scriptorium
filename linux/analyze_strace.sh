#!/bin/bash
################################################################################
# Script: analyze_strace.sh
# Purpose: Analyzes an strace log file for common issues in MPI operations.
# Usage: ./analyze_strace.sh -f <strace_log_file> -o <output_log_file>
# Author: KMac kmac@qumulo.com
# Date:   October 26, 2024
#
################################################################################

# Function to display usage
usage() {
    echo "Usage: $0 -f <strace_log_file> -o <output_log_file>"
    exit 1
}

# Parse command-line arguments
while getopts ":f:o:" opt; do
  case $opt in
    f) STRACE_FILE="$OPTARG" ;;
    o) LOGFILE="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check for required STRACE_FILE argument
if [ -z "$STRACE_FILE" ]; then
    echo "Error: strace log file is required."
    usage
fi

# Set default log file if not provided
DTS=$(date +"%Y%m%d_%H%M%S")
LOGFILE=${LOGFILE:-"antrc_$DTS.log"}

# Begin logging
echo "Analyzing strace log: $STRACE_FILE" > "$LOGFILE"

# Analysis 1: Overview with strace in summary mode
echo -e "\n--- Summary Analysis ---" | tee -a "$LOGFILE"
echo "Running strace in summary mode for a general overview of system calls." | tee -a "$LOGFILE"
strace -c -o summary.strace ./hrt-io500.sh >> "$LOGFILE"

# Analysis 2: Specific error codes
echo -e "\n--- Searching for Specific Error Codes ---" | tee -a "$LOGFILE"
echo "Checking for common error codes like EIO, EBADF, EEXIST, EINVAL, ENOSPC, ENOMEM, and MPI_Abort." | tee -a "$LOGFILE"
grep -E "EIO|EBADF|EEXIST|EINVAL|ENOSPC|ENOMEM|MPI_Abort" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 3: System calls longer than 0.1 seconds
echo -e "\n--- Finding High-Latency Calls ---" | tee -a "$LOGFILE"
echo "Identifying calls that took more than 0.1 seconds." | tee -a "$LOGFILE"
awk '{if ($NF > 0.1) print $0}' "$STRACE_FILE" >> "$LOGFILE"

# Analysis 4: Failed system calls
echo -e "\n--- Listing Failed System Calls ---" | tee -a "$LOGFILE"
echo "Displaying system calls that returned errors." | tee -a "$LOGFILE"
grep " = -1 " "$STRACE_FILE" >> "$LOGFILE"

# Analysis 5: Count of each error type
echo -e "\n--- Counting Each Error Type ---" | tee -a "$LOGFILE"
echo "Counting occurrences of each error type." | tee -a "$LOGFILE"
grep -o "E[A-Z]*" "$STRACE_FILE" | sort | uniq -c | sort -nr >> "$LOGFILE"

# Analysis 6: Open calls
echo -e "\n--- Viewing File Access Calls ---" | tee -a "$LOGFILE"
echo "Displaying 'open' calls to check file access." | tee -a "$LOGFILE"
grep "open(" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 7: Files with open errors
echo -e "\n--- Listing Files Accessed with Errors ---" | tee -a "$LOGFILE"
echo "Listing files that encountered errors during access." | tee -a "$LOGFILE"
grep "open.* = -1" "$STRACE_FILE" | awk '{print $3}' >> "$LOGFILE"

# Analysis 8: Memory allocation calls
echo -e "\n--- Memory Allocation Calls ---" | tee -a "$LOGFILE"
echo "Listing memory-related calls such as mmap, munmap, brk, and mremap." | tee -a "$LOGFILE"
grep -E "mmap|munmap|brk|mremap" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 9: Read and write errors
echo -e "\n--- Read and Write Errors ---" | tee -a "$LOGFILE"
echo "Displaying read and write calls that returned errors." | tee -a "$LOGFILE"
grep -E "read.* = -1|write.* = -1" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 10: Socket calls
echo -e "\n--- Socket-Related Calls ---" | tee -a "$LOGFILE"
echo "Displaying socket-related calls to investigate network issues." | tee -a "$LOGFILE"
grep -E "socket|connect|bind|listen|accept" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 11: Timestamps
echo -e "\n--- Adding Timestamps ---" | tee -a "$LOGFILE"
echo "Highlighting lines with timestamps for quick navigation." | tee -a "$LOGFILE"
grep -E "^[0-9]{2}:[0-9]{2}:[0-9]{2}" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 12: MPI_Abort context
echo -e "\n--- MPI_Abort Context ---" | tee -a "$LOGFILE"
echo "Displaying lines around MPI_Abort to understand context." | tee -a "$LOGFILE"
grep -C 20 "MPI_Abort" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 13: High-latency calls (last 50)
echo -e "\n--- High-Latency Calls (Last 50) ---" | tee -a "$LOGFILE"
echo "Showing the last 50 calls with high latency for recent performance issues." | tee -a "$LOGFILE"
awk '{if ($NF > 0.1) print $0}' "$STRACE_FILE" | tail -n 50 >> "$LOGFILE"

# Analysis 14: Fatal terminations
echo -e "\n--- Fatal Terminations ---" | tee -a "$LOGFILE"
echo "Filtering for fatal or abnormal terminations like exit or SIGKILL." | tee -a "$LOGFILE"
grep -E "exit|killed by SIG|SIGKILL|assert" "$STRACE_FILE" >> "$LOGFILE"

# Analysis 15: Last 500 lines around MPI or SIG events
echo -e "\n--- MPI and SIG Events (Last 500 Lines) ---" | tee -a "$LOGFILE"
echo "Displaying last 500 lines around MPI or SIG events for debugging." | tee -a "$LOGFILE"
grep -E "MPI|SIG" "$STRACE_FILE" | tail -n 500 >> "$LOGFILE"

# Completion message
echo "Analysis complete. Output saved to $LOGFILE."