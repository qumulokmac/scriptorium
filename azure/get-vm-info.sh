#!/bin/bash
###################################################################################################
#
# Name:             get-vm-info.sh
# Author:           kmac@qumulo.com
# Date:             May 2nd  2024
# Description:      This script will report VM specific information using dmicode (from BIOS)
###################################################################################################

HOST=$(hostname)
VMID=$(sudo dmidecode -s system-uuid)
SYSTEM_SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number)
BASEBOARD_SERIAL_NUMBER=$(sudo dmidecode -s baseboard-serial-number)
CHASSIS_SERIAL_NUMBER=$(sudo dmidecode -s chassis-serial-number)
CHASSIS_ASSET_TAG=$(sudo dmidecode -s chassis-asset-tag)
CHASSIS_SERIAL_NUMBER=$(sudo dmidecode -s chassis-serial-number)

print_variables_text() {
    for var in "$@"; do
        printf "%-30s: %s\n" "$var" "${!var}"
    done
}

print_variables_csv() {
    local delimiter=","
    printf "HOST,VMID,SYSTEM_SERIAL_NUMBER,BASEBOARD_SERIAL_NUMBER,CHASSIS_SERIAL_NUMBER,CHASSIS_ASSET_TAG\n"
    printf "%s$delimiter%s$delimiter%s$delimiter%s$delimiter%s$delimiter%s\n" "$HOST" "$VMID" "$SYSTEM_SERIAL_NUMBER" "$BASEBOARD_SERIAL_NUMBER" "$CHASSIS_SERIAL_NUMBER" "$CHASSIS_ASSET_TAG" | sed 's/,\s*$//'
}

print_variables_json() {
    printf "{\n"
    printf "\"HOST\": \"%s\",\n" "$HOST"
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

print_variables_xml() {
    printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    printf "<vm_info>\n"
    printf "\t<host>%s</host>\n" "$HOST"
    printf "\t<vmid>%s</vmid>\n" "$VMID"
    printf "\t<system_serial_number>%s</system_serial_number>\n" "$SYSTEM_SERIAL_NUMBER"
    printf "\t<baseboard_serial_number>%s</baseboard_serial_number>\n" "$BASEBOARD_SERIAL_NUMBER"
    printf "\t<chassis_serial_number>%s</chassis_serial_number>\n" "$CHASSIS_SERIAL_NUMBER"
    printf "\t<chassis_asset_tag>%s</chassis_asset_tag>\n" "$CHASSIS_ASSET_TAG"
    printf "</vm_info>\n"
}

print_variables_yaml() {
    printf "host: %s\n" "$HOST"
    printf "vmid: %s\n" "$VMID"
    printf "system_serial_number: %s\n" "$SYSTEM_SERIAL_NUMBER"
    printf "baseboard_serial_number: %s\n" "$BASEBOARD_SERIAL_NUMBER"
    printf "chassis_serial_number: %s\n" "$CHASSIS_SERIAL_NUMBER"
    printf "chassis_asset_tag: %s\n" "$CHASSIS_ASSET_TAG"
}

print_variables_markdown() {
    printf "| %-30s | %s |\n" "Variable" "Value"
    printf "| %'-'31s | %'-'40s |\n" "" ""
    for var in "$@"; do
        printf "| %-30s | %s |\n" "${var}" "${!var}"
    done
}

usage() {
    echo "Usage: $0 [-c] [-j] [-t] [-x] [-y] [-m]"
    echo "Options:"
    echo "  -c  Output in CSV format"
    echo "  -j  Output in JSON format"
    echo "  -t  Output in TEXT format"
    echo "  -x  Output in XML format"
    echo "  -y  Output in YAML format"
    echo "  -m  Output in Markdown format"
    exit 1
}


while getopts ":tcjxym" opt; do
  case $opt in
    c) CSV=true ;;
    j) JSON=true ;;
    t) TEXT=true ;;
    x) XML=true ;;
    y) YAML=true ;;
    m) MARKDOWN=true ;;
    *) usage ;;
  esac
done

if [ "$CSV" = true ]; then
    print_variables_csv
elif [ "$JSON" = true ]; then
    print_variables_json "HOST" "VMID" "SYSTEM_SERIAL_NUMBER" "BASEBOARD_SERIAL_NUMBER" "CHASSIS_SERIAL_NUMBER" "CHASSIS_ASSET_TAG"
elif [ "$XML" = true ]; then
    print_variables_xml
elif [ "$YAML" = true ]; then
    print_variables_yaml
elif [ "$MARKDOWN" = true ]; then
    print_variables_markdown "HOST" "VMID" "SYSTEM_SERIAL_NUMBER" "BASEBOARD_SERIAL_NUMBER" "CHASSIS_SERIAL_NUMBER" "CHASSIS_ASSET_TAG"
elif [ "$TEXT" = true ]; then
    print_variables_text "HOST" "VMID" "SYSTEM_SERIAL_NUMBER" "BASEBOARD_SERIAL_NUMBER" "CHASSIS_SERIAL_NUMBER" "CHASSIS_ASSET_TAG"
else
    usage
fi
