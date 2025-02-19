#!/bin/bash
################################################################################
# Script: mp4_to_iso.sh
# Purpose: Converts an MP4 file into an ISO image using a DMG intermediary.
# Usage: ./mp4_to_iso.sh <source_mp4_file> <output_iso_file>
# Author: KMac | kmac@qumulo.com
# Date:   February 19, 2025
################################################################################

# Ensure script is executed with correct arguments
if [[ $# -ne 2 ]]; then
    echo -e "\nUsage: $0 <source_mp4_file> <output_iso_file>"
    echo -e "Example: $0 ~/Downloads/AXIII.1GB.mp4 ~/Downloads/AXIII.iso\n"
    exit 1
fi

# Variables
SOURCE_MP4_FILE="$1"
OUTPUT_ISO_FILE="$2"
DMG_FILE="${OUTPUT_ISO_FILE%.iso}.dmg"

FILENAME=$(basename "$SOURCE_MP4_FILE")
VOLUME_NAME=$(echo "$FILENAME" | grep -oE '^[[:alnum:]]+')

if [[ -z "$VOLUME_NAME" ]]; then
    echo -e "\033[1;31mError:\033[0m Unable to determine volume name from $FILENAME\n"
    exit 1
fi

print_step() {
    echo -e "\n\033[1;34m[STEP $1]\033[0m $2\n"
}

if [[ ! -f "$SOURCE_MP4_FILE" ]]; then
    echo -e "\033[1;31mError:\033[0m Source MP4 file not found: $SOURCE_MP4_FILE\n"
    exit 1
fi

print_step 1 "Creating a Disk Image (DMG) of size 2GB..."
hdiutil create -size 2g -fs HFS+ -volname "$VOLUME_NAME" "$DMG_FILE" || { echo "Failed to create DMG"; exit 1; }

print_step 2 "Mounting the Disk Image..."
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" | grep "Volumes" | awk '{print $3}')
if [[ -z "$MOUNT_POINT" ]]; then
    echo -e "\033[1;31mError:\033[0m Failed to mount DMG\n"
    exit 1
fi

print_step 3 "Copying the MP4 file into the mounted disk..."
cp "$SOURCE_MP4_FILE" "$MOUNT_POINT/" || { echo "Failed to copy MP4 file"; exit 1; }

print_step 4 "Detaching the Disk Image..."
hdiutil detach "$MOUNT_POINT" || { echo "Failed to detach DMG"; exit 1; }

print_step 5 "Converting the DMG to an ISO file..."
hdiutil convert "$DMG_FILE" -format UDTO -o "$OUTPUT_ISO_FILE" || { echo "Failed to convert DMG to ISO"; exit 1; }

print_step 6 "Renaming the ISO file..."
mv "${OUTPUT_ISO_FILE}.cdr" "$OUTPUT_ISO_FILE" || { echo "Failed to rename ISO"; exit 1; }

echo -e "\n\033[1;32mConversion successful!\033[0m"
echo -e "ISO File Created: \033[1;36m$OUTPUT_ISO_FILE\033[0m\n"

exit 0