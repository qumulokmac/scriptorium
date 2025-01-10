#!/usr/bin/bash
##########################################################################################################
#
# Script:		start-all.sh
# Purpose:		Starts fio processes on worker hosts from the configuration file.
#               Uses a governor to limit the number of workers to a specified value. If not specified,
#               all IP addresses in the workers.conf file are used by default.
# Usage:		./start-all.sh [-w <num_workers>] [--num-workers <num_workers>]
#               -w, --num-workers: Specifies the number of workers to use (default is all IPs found).
# Author:		KMac | kmac@qumulo.com
# Date:  		November 15, 2024
#
#########################################################################################################

WORKERS_CONF="/home/qumulo/workers.conf"

# Default behavior: use all IPs from the configuration file
GOVERNOR=$(wc -l < "$WORKERS_CONF")

# Parse command-line options
while getopts ":w:-:" opt; do
    case $opt in
        w)
            GOVERNOR=$OPTARG
            ;;
        -)
            case $OPTARG in
                num-workers)
                    GOVERNOR="${!OPTIND}"; OPTIND=$((OPTIND + 1))
                    ;;
                *)
                    echo "Invalid option: --$OPTARG" >&2
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Check if the governor value is a valid number
if ! [[ "$GOVERNOR" =~ ^[0-9]+$ ]] || [ "$GOVERNOR" -le 0 ]; then
    echo "Error: The number of workers must be a positive integer." >&2
    exit 1
fi

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists parallel-ssh || ! command_exists ssh; then
    echo "Error: parallel-ssh and/or ssh command not found." >&2
    exit 1
fi

if [ ! -f "$WORKERS_CONF" ]; then
    echo "Error: Configuration file $WORKERS_CONF not found." >&2
    exit 1
fi

# Limit the number of hosts read from the file based on the governor
hosts=($(head -n "$GOVERNOR" "$WORKERS_CONF"))

echo "Using the following hosts (limited by governor $GOVERNOR):"
for host in "${hosts[@]}"; do
    echo "$host"
done

FOUNDFIO=0
echo "Checking if any fio jobs are running on the selected hosts..."
for host in "${hosts[@]}"; do
    fio_running=$(ssh "$host" 'ps -ef | grep fio | grep -v grep | wc -l')
    echo "Number of fio processes running on ${host}: $fio_running"
    if [ "$fio_running" -ne 0 ]; then
        FOUNDFIO=1
    fi
done

#if [ "$FOUNDFIO" -eq 0 ]; then
#    echo "No fio jobs running on any clients. Nothing to stop."
#else
#    echo "Attempting to stop adaptive_load_generator.sh..."
#    if ! parallel-ssh -H "${hosts[*]}" -i "sudo pkill -9 -f 'adapt|fio'" 2>&1 | grep -v "[FAILURE]"; then
#        echo "Failed to stop adaptive_load_generator.sh on some clients. (FIO not running?)" >&2
#    fi
#    echo "SLEEP 3"
#    sleep 3
#fi

echo "Starting fio processes on selected Ubuntu clients..."
for host in "${hosts[@]}"; do
    ssh "${host}" "/home/qumulo/start_load.sh" &
done

echo "SLEEP 3"
sleep 3

echo "Checking fio processes on all selected clients..."
for host in "${hosts[@]}"; do
    echo -n "Number of fio processes running on ${host}: "
    if ! ssh "$host" 'ps -ef | grep fio | grep -v grep | wc -l'; then
        echo "Error: Failed to check fio processes on $host." >&2
    fi
done
