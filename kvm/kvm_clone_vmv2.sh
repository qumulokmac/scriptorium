#!/usr/bin/bash
########################################################################################################
# clonev2.sh V2
# Building the vm-3's
#
# VMs: 
# sut6621-vm3, sut6622-vm3, sut6623-vm3, sut6624-vm3, sut6625-vm3, sut6626-vm3
#
# 1. Wait for the current benchmark to finish
# 2. Clone a new image from the current VM
########################################################################################################

SOURCE_VM="sut6621-vm2"
TARGET_VM="sut662clone-vm3"

MOUNT_POINT="/mnt/qumulo"
NFS_EXPORT="10.10.60.11:/data"
CLONE_OUTBOUND_TMPDIR="${MOUNT_POINT}/clone_outbound"
DTS=$(date +%Y%m%d-%H%M%S)
KVM_HOST=$(echo "$SOURCE_VM" | sed 's/-vm[0-9]*//')

mkdir -p "$CLONE_OUTBOUND_TMPDIR"

if ! mount | grep -q "$NFS_EXPORT on $MOUNT_POINT"; then
    echo "NFS export not mounted. Mounting now..."
    mount -t nfs -o vers=3,tcp,nconnect=16 "$NFS_EXPORT" "$MOUNT_POINT"
else
    echo "NFS export is already mounted on $MOUNT_POINT."
fi

echo "Saving XML configuration of ${SOURCE_VM} to ${CLONE_OUTBOUND_TMPDIR}/${SOURCE_VM}-${DTS}.xml..."
virsh dumpxml "$SOURCE_VM" > "${CLONE_OUTBOUND_TMPDIR}/${SOURCE_VM}-${DTS}.xml"
virsh dumpxml "$SOURCE_VM" > "${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.xml"

echo "Continue to copy ${SOURCE_VM}.qcow2 to ${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2? [Y/N]"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    cp "/var/lib/libvirt/images/${SOURCE_VM}.qcow2" "${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2"
else
    echo "Copy canceled."
fi

echo "Copying backup files to ${KVM_HOST}:/var/lib/libvirt/images..."
scp "${CLONE_OUTBOUND_TMPDIR}"/* "${KVM_HOST}:/var/lib/libvirt/images"

echo "Remove the cloned image ${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2 from ${CLONE_OUTBOUND_TMPDIR}? [Y/N]"
read -r ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -i "${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2"
    rm -f "${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}"*
else
    echo "${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2 not removed."
    echo -n "Image size: "
    du -sh ${CLONE_OUTBOUND_TMPDIR}/${TARGET_VM}.qcow2 
fi

echo "Switch to the TARGET KVM HOST and run the post fix scripts..."

exit
