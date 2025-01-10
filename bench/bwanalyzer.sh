#!/bin/bash
################################################################################
# Script:  bwanalyzer.sh
# Purpose: Sets up, executes, and summarizes multiple iperf3 server and client
#          sessions for network performance testing.
#
# Author: KMac | kmac@qumulo.com
# Date:   November 21, 2024
#
# Usage:
#   - Run as a server or client using the appropriate options.
#   - Use `--summarize` to summarize sender and receiver data from logs.
#
# Options:
#   -s, --server <server_ip>     IP address of the iperf3 server (required for clients)
#   -l, --log-dir <log_dir>      Directory to store logs (default: /tmp/iperf3_logs)
#   -p, --ports <ports>          Comma-separated list of ports (default: 5101,5102,5103,5104)
#   -m, --mode <mode>            Mode to run: 'server' or 'client' (required)
#   --summarize                  Summarize sender and receiver data from logs
#
# Example:
#   To start as a client:
#     ./bwanalyzer.sh -m client -s 10.10.60.11 -l /root/logs -p "5201,5202,5203,5204"
#
#   To start as a server:
#     ./bwanalyzer.sh -m server -p '5201,5202,5203,5204'
#
#   To summarize logs:
#     ./bwanalyzer.sh --summarize -l /root/logs
#
################################################################################

IPERF3_SERVER=""
LOG_DIR="bwanalyzer_logs"
PORTS=(5101 5102 5103 5104)
DTS=$(date +"%Y%m%d_%H%M%S")
SUM=false

Usage() {
    echo "Usage: $0 -m [server|client] [-s <server_ip>] [-l <log_dir>] [-p <ports> | --summarize]"
    echo "    Example usage:"
    echo "    To start the iperf3 servers, run: \"$0 -m server \" on the designated server machine"
    echo "    To start the iperf3 clients, run: \"$0 -m client -s IP_ADDRESS\" on the designated client"
    echo "    To summarize the results, run:    \"$0 --summarize\" on the client machine where logs are stored"
    echo ""
}

summarize_logs() {
    if [[ ! -d "$LOG_DIR" ]]; then
        echo "Error: Log directory $LOG_DIR does not exist."
        exit 1
    fi

    local total_sender=0
    local total_receiver=0

    echo "Summarizing logs in $LOG_DIR..."
    for log_file in "$LOG_DIR"/*.out; do
        if [[ -f "$log_file" ]]; then
            sender=$(grep -Eo '([0-9.]+) GBytes.*sender' "$log_file" | awk '{total+=$1} END {print total}')
            receiver=$(grep -Eo '([0-9.]+) GBytes.*receiver' "$log_file" | awk '{total+=$1} END {print total}')

            total_sender=$(echo "$total_sender + $sender" | bc)
            total_receiver=$(echo "$total_receiver + $receiver" | bc)

            echo "File: $log_file | Sender: ${sender:-0} GBytes | Receiver: ${receiver:-0} GBytes"
        fi
    done

    echo "============================================================"
    echo "Total Sender Data  : $total_sender GBytes"
    echo "Total Receiver Data: $total_receiver GBytes"
    echo "============================================================"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--server)
            IPERF3_SERVER="$2"
            shift 2
            ;;
        -l|--log-dir)
            LOG_DIR="$2"
            mkdir -p $LOG_DIR
            shift 2
            ;;
        -p|--ports)
            IFS=',' read -r -a PORTS <<< "$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        --summarize)
            SUM=true
            shift
            ;;
        -h|--help)
            Usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            Usage
            exit 1
            ;;
    esac
done

if [[ "$SUM" == "true" ]]; then
    summarize_logs
    exit 0
fi

if [[ -z "$MODE" ]]; then
    Usage
    exit 1
fi

print_config() {
    echo ""
    echo "============================================================"
    echo "iperf3 Configuration"
    echo "============================================================"
    echo "Mode          : $MODE"
    [[ "$MODE" == "client" ]] && echo "Server IP     : $IPERF3_SERVER"
    echo "Log Directory : $LOG_DIR"
    echo "Ports         : ${PORTS[*]}"
    echo "============================================================"
    echo ""
}

start_server() {
    echo "Starting iperf3 servers on ports ${PORTS[*]}..."
    for port in "${PORTS[@]}"; do
        if ! pgrep -f "iperf3 -s -p $port" > /dev/null; then
            iperf3 -s -p "$port" > "${LOG_DIR}/iperf-server-${port}-${DTS}.out" 2>&1 &
            echo "Started iperf3 server on port $port"
        else
            echo "iperf3 server on port $port is already running."
        fi
    done
}

start_client() {
    if [[ -z "$IPERF3_SERVER" ]]; then
        echo "Error: Server IP (-s or --server) is required in client mode."
        exit 1
    fi

    echo "Starting iperf3 clients connecting to $IPERF3_SERVER..."
    for i in "${!PORTS[@]}"; do
        log_file="${LOG_DIR}/iperf3_$(hostname)_client_${PORTS[$i]}_${DTS}.out"
        echo "Running: iperf3 -c $IPERF3_SERVER -p ${PORTS[$i]}"
        iperf3 -c "$IPERF3_SERVER" -p "${PORTS[$i]}" > "$log_file" 2>&1 &
        echo "Started iperf3 client for port ${PORTS[$i]}, logging to $log_file"
    done
    echo ""
}

case "$MODE" in
    server)
        start_server
        ;;
    client)
        start_client
        ;;
    *)
        echo "Error: Invalid mode. Use -m or --mode <server|client>."
        exit 1
        ;;
esac