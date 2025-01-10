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

echo "Running a parallel umount on all workers to unmount all NFS exports..."
parallel-ssh -h "$WORKERS_CONF" -i "sudo umount -a -t nfs,nfs4" 2>&1 | grep -v "[FAILURE]"

echo "Verifying NFS mounts on all clients..."
for host in $(cat "$WORKERS_CONF"); do
    NUMMNTS_BEFORE=$(ssh "$host" 'mount | grep -E "type nfs|type nfs4" | wc -l')

    if [ "$NUMMNTS_BEFORE" -eq 0 ]; then
        echo "No NFS mounts found on $host."
        continue
    fi

    echo "$NUMMNTS_BEFORE mounts stuck on $host. Attempting to kill any remnant fio or coordinating processes..."
    
    ssh "$host" "sudo pkill -f '(fio|adapt)'" && echo "Processes killed on $host." || echo "Warning: Failed to kill processes on $host."

    ssh "$host" "sudo umount -a -t nfs,nfs4" && echo "Unmount attempted on $host." || echo "Warning: Failed to unmount on $host."
    
    NUMMNTS_AFTER=$(ssh "$host" 'mount | grep -E "type nfs|type nfs4" | wc -l')

    echo "There are now $NUMMNTS_AFTER NFS exports on $host."

done
