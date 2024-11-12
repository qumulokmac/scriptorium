#!/usr/bin/bash
##########################################################################################################
#
# Script:		start-all.sh
#
#########################################################################################################

WORKERS_CONF="/home/qumulo/workers.conf"
KEY_PATH="~/keys/grumpquat"

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

FOUNDFIO=0
echo "Checking if any fio jobs are running on the hosts..."
for host in $(cat "$WORKERS_CONF"); do
    fio_running=$(ssh -i "$KEY_PATH" "$host" 'ps -ef | grep fio | grep -v grep | wc -l')
    echo "Number of fio processes running on ${host}: $fio_running"
    if [ "$fio_running" -ne 0 ]; then
        FOUNDFIO=1
    fi
done

if [ "$FOUNDFIO" -eq 0 ]; then
    echo "No fio jobs running on any clients. Nothing to stop."
else
    echo "Attempting to stop adaptive_load_generator.sh..."
    if ! parallel-ssh -h "$WORKERS_CONF" -x "-i $KEY_PATH" -i "sudo pkill -9 -f 'adapt|fio'" 2>&1 | grep -v "[FAILURE]"; then
        echo "Failed to stop adaptive_load_generator.sh on some clients. (FIO not running?)" >&2
    fi
    echo "SLEEP 3"
    sleep 3
fi

echo "Starting fio processes on Ubuntu clients..."
for host in $(cat ~/workers.conf); do
    ssh -i "${KEY_PATH}" "${host}" "/home/qumulo/start_load.sh" & 
done

echo "SLEEP 3"
sleep 3

echo "Checking fio processes on all clients..."
for host in $(cat "$WORKERS_CONF"); do
    echo -n "Number of fio processes running on ${host}: "
    if ! ssh -i "$KEY_PATH" "$host" 'ps -ef | grep fio | grep -v grep | wc -l'; then
        echo "Error: Failed to check fio processes on $host." >&2
    fi
done
