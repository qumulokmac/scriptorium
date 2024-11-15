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

echo "Checking fio processes on all clients..."
for host in $(cat "$WORKERS_CONF"); do
    echo -n "Number of fio processes running on ${host}: "
    if ! ssh "$host" 'ps -ef | grep fio | grep -v grep | wc -l'; then
        echo "Error: Failed to check fio processes on $host." >&2
    fi
done
