#!/usr/bin/bash

GRAVY_URL_BASE="https://gravyweb.eng.qumulo.com/release"
DEBNAME="qumulo-core.deb"

usage() {
    echo "Usage: $0 --version VERSION"
    exit 1
}

while getopts ":v:-:" opt; do
    case $opt in
        v)
            VERSION=$OPTARG
            ;;
        -)
            case "${OPTARG}" in
                version)
                    VERSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                *)
                    echo "Unknown option --${OPTARG}"
                    usage
                    ;;
            esac
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    usage
fi

GRAVY_URL="${GRAVY_URL_BASE}/${VERSION}/src/build/release/install/${DEBNAME}"

resolve_gravy_ip() {
    DIG_OUTPUT=$(dig +short gravyweb.eng.qumulo.com)
    
    if [[ $DIG_OUTPUT =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        GRAVY_IP_ADDRESS=$DIG_OUTPUT
    else
        for line in $DIG_OUTPUT; do
            if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                GRAVY_IP_ADDRESS=$line
                echo "gravyweb.eng.qumulo.com resolves to ${GRAVY_IP_ADDRESS}"
                break
            fi
        done
    fi

    if [ -z "$GRAVY_IP_ADDRESS" ]; then
        GRAVY_IP_ADDRESS="notfound"
        sft login
        sudo tailscale up --advertise-routes="" --accept-routes
    fi
}

backup_existing_file() {
    if [ -f "$DEBNAME" ]; then
        DATE_STAMP=$(date +"%y%m%d")
        mv "$DEBNAME" "${DEBNAME%.*}.$DATE_STAMP.${DEBNAME##*.}"
    fi
}

download_deb() {
    wget "${GRAVY_URL}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download the file from ${GRAVY_URL}"
        exit 1
    fi
}

upload_to_s3() {
    aws s3 cp "${DEBNAME}" s3://cnqdemo/bits/qumulo-core-install/${VERSION}/${DEBNAME}
}

resolve_gravy_ip
backup_existing_file
download_deb
sudo tailscale down
upload_to_s3
