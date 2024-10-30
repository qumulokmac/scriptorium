#!/bin/bash
########################################################################################################
WORKERS_FILE="workers.conf"
BACKUP_DIR="/mnt/qumulo/vm-backups"

mkdir -p ${BACKUP_DIR}

DATE=$(date +%Y%m%d-%H%M%S)

if [ ! -f "$WORKERS_FILE" ]; then
    echo "Error: workers.conf file not found."
    exit 1
fi

for WORKER in `cat workers.conf`
do
    echo "Starting ${WORKER}"
    echo ""
    TAR_FILE="${WORKER}-root-backup-${DATE}.tar.gz"
    DESTINATION_PATH="${BACKUP_DIR}/${WORKER}"

    mkdir -p "$DESTINATION_PATH"

    echo "Backing up /root on ${WORKER}..."

    if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$WORKER" exit; then
        echo "Connection to ${WORKER} successful."

        echo "Backing up /root to ${TAR_FILE}..."
        ssh "$WORKER" "sudo tar -czf ${DESTINATION_PATH}/${TAR_FILE} /root"

        # echo "Copying $WORKER:/tmp/${TAR_FILE} --> ${DESTINATION_PATH}/"
        # scp "$WORKER:/tmp/${TAR_FILE}" "${DESTINATION_PATH}/"

        # ssh "$WORKER" "Removing local ${TAR_FILE}"
        # ssh "$WORKER" "rm -f /tmp/${TAR_FILE}"

        if [ $? -eq 0 ]; then
            echo "Backup completed for ${WORKER} and saved to ${DESTINATION_PATH}/${TAR_FILE}"
        else
            echo "Error: Backup failed for ${WORKER}"
        fi
    else
        echo "Error: Unable to connect to ${WORKER}. Skipping backup for this server."
    fi

    echo ""

done < "$WORKERS_FILE"

echo "Done."

exit
