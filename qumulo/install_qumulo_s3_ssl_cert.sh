#!/bin/bash
################################################################################
# Script: update_certificate.sh
# Purpose: Verifies, combines, and installs SSL certificates on a Qumulo cluster.
# Usage: ./update_certificate.sh
# Author: KMac | kmac@qumulo.com
# Date:   February 14, 2025
################################################################################

set -euo pipefail

CERT_FILE="/path/to/your/cert.pem"
INTERMEDIATE_FILE="/path/to/your/intermediate-r10.pem"
ROOT_CERT_FILE="/path/to/your/isrgrootX1.pem"
PRIVATE_KEY_FILE="/path/to/your/privkey.pem"
COMBINED_CERT_FILE="/path/to/your/fullchain_combined.pem"

verify_certificate() {
    if [[ ! -f "$1" ]]; then
        echo "Error: Certificate file $1 not found." >&2
        exit 1
    fi
    openssl x509 -in "$1" -text -noout || { echo "Error: Failed to verify $1." >&2; exit 1; }
}

verify_private_key() {
    if [[ ! -f "$1" ]]; then
        echo "Error: Private key file $1 not found." >&2
        exit 1
    fi
    openssl rsa -in "$1" -check || { echo "Error: Failed to verify private key $1." >&2; exit 1; }
}

echo "--- 1. Verifying certificate files ---"
verify_certificate "$CERT_FILE"
verify_certificate "$INTERMEDIATE_FILE"
verify_certificate "$ROOT_CERT_FILE"
verify_private_key "$PRIVATE_KEY_FILE"

echo "--- 2. Combining certificates (Your Cert, Intermediate, Root) ---"
cat "$CERT_FILE" "$INTERMEDIATE_FILE" "$ROOT_CERT_FILE" > "$COMBINED_CERT_FILE" || { echo "Error: Failed to create combined certificate." >&2; exit 1; }
echo "Combined certificate written to $COMBINED_CERT_FILE"

echo "--- 3. Setting file permissions ---"
chmod 644 "$COMBINED_CERT_FILE" || { echo "Error: Failed to set permissions on $COMBINED_CERT_FILE." >&2; exit 1; }
chmod 600 "$PRIVATE_KEY_FILE" || { echo "Error: Failed to set permissions on $PRIVATE_KEY_FILE." >&2; exit 1; }
echo "Permissions set."

echo "--- 4. Installing certificate on Qumulo (using qq command) ---"
if ! qq ssl_modify_certificate -c "$COMBINED_CERT_FILE" -k "$PRIVATE_KEY_FILE"; then
    echo "Error: Failed to install certificate on Qumulo." >&2
    exit 1
fi
echo "Certificate installation command executed."

echo "--- 5. Verification (Manual - Use S3 clients, openssl s_client, etc.) ---"
echo "Remember to validate the SSL certificate using an S3 client or openssl s_client."
echo "Also, check the Qumulo logs for any related messages."
