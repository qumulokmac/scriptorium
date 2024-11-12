#!/usr/bin/bash

WORKERS_CONF="/home/qumulo/workers.conf"

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

echo "Attempting to stop adaptive_load_generator on ALL Ubuntu client..."
parallel-ssh -h "$WORKERS_CONF" -x '-i ~/keys/grumpquat' -i "sudo pkill -9 -f 'adapt|fio' " 2>&1 | grep -v "[FAILURE]"

echo "Checking fio processes on all clients..."
for host in $(cat "$WORKERS_CONF"); do
    echo -n "$host number of fio processes: "
    if ! ssh -i ~/keys/grumpquat "$host" 'ps -ef | grep fio | grep -v grep | wc -l'; then
        echo "Error: Failed to check fio processes on $host." >&2
    fi
done
