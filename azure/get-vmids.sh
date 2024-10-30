#!/bin/bash
###################################################################################################
#
# Name:             get-vm-info.sh
# Author:           kmac@qumulo.com
# Date:             May 2nd  2024
# Description:      This script will report VM specific information using dmicode (from BIOS)
###################################################################################################

print_variables() {
    for var in "$@"; do
        printf "%-30s: %s\n" "$var" "${!var}"
    done
}

print_variables_csv() {
    local delimiter=","
    local last_var=${!#}
    for var in "$@"; do
        printf "%s$delimiter" "${!var}"
        [[ "$var" == "$last_var" ]] && delimiter=""
    done
    printf "\n"
}

print_variables_json() {
    printf "{\n"
    local last_var=${!#}
    for var in "$@"; do
        value="${!var}"
        # Quote the value if it's a string
        if [[ "$value" =~ [^0-9] ]]; then
            value="\"$value\""
        fi
        printf "\"%s\": %s" "$var" "$value"
        if [[ "$var" != "$last_var" ]]; then
            printf ",\n"
        else
            printf "\n"
        fi
    done
    printf "}\n"
}


# Set default output format
output_format="text"

# Parse command line options
while getopts ":ctjh" opt; do
  case $opt in
    c) output_format="csv" ;;
    j) output_format="json" ;;
    t) output_format="text" ;;
    h) echo "Usage: $0 [-c] [-j] [-t]"; exit ;;
    \?) echo "Invalid option: -$OPTARG" >&2 ;;
  esac
done

shift $((OPTIND -1))

# parallel-ssh -v -h ~/tools/workers.conf -i "~/tools/get-vm-info.sh"

HOST=$(hostname)
VMID=$(sudo dmidecode -s system-uuid)
SYSTEM_SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number)
BASEBOARD_SERIAL_NUMBER=$(sudo dmidecode -s baseboard-serial-number)
CHASSIS_SERIAL_NUMBER=$(sudo dmidecode -s chassis-serial-number)
CHASSIS_ASSET_TAG=$(sudo dmidecode -s chassis-asset-tag)
SYSTEM_SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number)

printf '#%.0s' {1..80}
echo ""
echo "# VM info for host $HOST"
printf '#%.0s' {1..80}
echo ""

case $output_format in
  "text") print_variables VMID SYSTEM_SERIAL_NUMBER BASEBOARD_SERIAL_NUMBER CHASSIS_SERIAL_NUMBER CHASSIS_ASSET_TAG SYSTEM_SERIAL_NUMBER ;;
  "csv") print_variables_csv VMID SYSTEM_SERIAL_NUMBER BASEBOARD_SERIAL_NUMBER CHASSIS_SERIAL_NUMBER CHASSIS_ASSET_TAG SYSTEM_SERIAL_NUMBER ;;
  "json") print_variables_json VMID SYSTEM_SERIAL_NUMBER BASEBOARD_SERIAL_NUMBER CHASSIS_SERIAL_NUMBER CHASSIS_ASSET_TAG SYSTEM_SERIAL_NUMBER ;;
esac

printf '#%.0s' {1..80}
echo ""

# Example usage:

# $ ./get-vm-info.sh -c
# $ ./get-vm-info.sh -j
# $ ./get-vm-info.sh -t
# $ ./get-vm-info.sh -h
# $ ./get-vm-info.sh
