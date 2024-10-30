#!/usr/bin/bash
##########################################################################################
# Script to clone and transfer a KVM virtual machine to remote KVM servers.
#
# Script Name:  copy_kvm_vm.sh
# Date:         October 26, 2024
# Author:       Kevin McDonald (kmac@qumulo.com)
#
# Script is ran on sut6621 (Physical KVM Server) 
# If ran on another server be sure to run "apt install libguestfs-tools -y"
##########################################################################################

THIS_PHYSICAL_KVM_SERVER="sut6621"
TARGET_PHYSICAL_KVM_SERVER="sut6625"
IMAGE_DIR="/var/lib/libvirt/images"
SOURCE_VM_NAME="${THIS_PHYSICAL_KVM_SERVER}-vm2"
NEW_VM_NAME="${TARGET_PHYSICAL_KVM_SERVER}-vm2"
LOG_FILE="/var/log/copy_kvm_vm.log"

log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "Error: $1"
    exit 1
}

if virsh domstate ${SOURCE_VM_NAME} | grep -q "running"; then
    virsh shutdown ${SOURCE_VM_NAME} || error_exit "Failed to shutdown source VM ${SOURCE_VM_NAME}"
    log "Waiting for ${SOURCE_VM_NAME} to power off..."
    until virsh domstate ${SOURCE_VM_NAME} | grep -q "shut off"; do
        sleep 2
    done
    log "${SOURCE_VM_NAME} is powered off."
else
    log "${SOURCE_VM_NAME} is already powered off."
fi

DISK_IMAGE_PATH=$(virsh domblklist ${SOURCE_VM_NAME} | grep ${IMAGE_DIR} | awk '{print $2}')
[ -z "$DISK_IMAGE_PATH" ] && error_exit "Failed to locate disk image for ${SOURCE_VM_NAME}"

log "Disk image path: ${DISK_IMAGE_PATH}"

log "Dumping ${SOURCE_VM_NAME}.xml --> ${NEW_VM_NAME}.xml"
virsh dumpxml ${SOURCE_VM_NAME} > ${NEW_VM_NAME}.xml || error_exit "Failed to create XML configuration for ${SOURCE_VM_NAME}"

log "Modifying ${NEW_VM_NAME}.xml..."
sed -i -e "s/${SOURCE_VM_NAME}/${NEW_VM_NAME}/g" -e '/<uuid>/d' -e '/<mac address=/d' ${NEW_VM_NAME}.xml || error_exit "Failed to update the XML file for ${NEW_VM_NAME}"

log "Cloning disk image for ${NEW_VM_NAME}..."
qemu-img convert -O qcow2 ${DISK_IMAGE_PATH} ${IMAGE_DIR}/${NEW_VM_NAME}.qcow2 || error_exit "Failed to fully clone the disk image for ${SOURCE_VM_NAME}"

virsh define ${NEW_VM_NAME}.xml || error_exit "Failed to define the new VM ${NEW_VM_NAME}"

virt-sysprep -a ${IMAGE_DIR}/${NEW_VM_NAME}.qcow2 || error_exit "Failed to run virt-sysprep on ${NEW_VM_NAME}"

log "Copying the VM disk image \"${IMAGE_DIR}/${NEW_VM_NAME}.qcow2\" to \"${TARGET_PHYSICAL_KVM_SERVER}:${IMAGE_DIR}\"..."
scp ${IMAGE_DIR}/${NEW_VM_NAME}.qcow2 ${TARGET_PHYSICAL_KVM_SERVER}:${IMAGE_DIR}/ || error_exit "Failed to copy disk image to ${TARGET_PHYSICAL_KVM_SERVER}"

log "Copying \"${NEW_VM_NAME}.xml\" to \"${TARGET_PHYSICAL_KVM_SERVER}:/root/kvm/...\""
scp ${NEW_VM_NAME}.xml ${TARGET_PHYSICAL_KVM_SERVER}:/root/kvm/ || error_exit "Failed to copy XML file to ${TARGET_PHYSICAL_KVM_SERVER}"

log "Importing ${NEW_VM_NAME}.xml on ${TARGET_PHYSICAL_KVM_SERVER}..."
ssh ${TARGET_PHYSICAL_KVM_SERVER} "virsh define /root/kvm/${NEW_VM_NAME}.xml" || error_exit "Failed to define ${NEW_VM_NAME} on ${TARGET_PHYSICAL_KVM_SERVER}"

log "Checking VM import status on ${TARGET_PHYSICAL_KVM_SERVER}..."
ssh ${TARGET_PHYSICAL_KVM_SERVER} "virsh list --all | grep ${NEW_VM_NAME}" || error_exit "VM import check failed on ${TARGET_PHYSICAL_KVM_SERVER}"

log "Cleaning up local VM definition and image for ${NEW_VM_NAME}..."
virsh undefine ${NEW_VM_NAME}
rm -f ${IMAGE_DIR}/${NEW_VM_NAME}.qcow2

log "All done!"
exit 0


##
exit
##

THIS_PHYSICAL_KVM_SERVER="sut6621"
TARGET_PHYSICAL_KVM_SERVER="sut6623"
IMAGE_DIR="/var/lib/libvirt/images"
SOURCE_VM_NAME="${THIS_PHYSICAL_KVM_SERVER}-vm2"
NEW_VM_NAME="${TARGET_PHYSICAL_KVM_SERVER}-vm2"
LOG_FILE="/var/log/copy_kvm_vm.log"


echo "Changing the \"127.0.1.1 ${SOURCE_VM_NAME}\" record to \"127.0.1.1 ${NEW_VM_NAME}\" in /etc/hosts"

cp -p /etc/hosts /etc/hosts.bak
sed -i "s/127.0.1.1 ${SOURCE_VM_NAME}/127.0.1.1 ${NEW_VM_NAME}/" /etc/hosts

echo "Resolving ${SOURCE_VM_NAME}'s IP address..." 
IP_ADDRESS=$(getent hosts ${SOURCE_VM_NAME} | awk '{print $1}')

if [ -z "$IP_ADDRESS" ]; then
    echo "Error: Could not resolve IP address for ${SOURCE_VM_NAME}. Exiting."
    exit 1
fi

echo "Uncommenting the static IP address record for ${SOURCE_VM_NAME}"
sed -i "/${IP_ADDRESS} ${SOURCE_VM_NAME}/s/^#//" /etc/hosts


            ### THIS ONE IS BROKE KMAC. 
            echo "Commenting out the static IP address record for ${NEW_VM_NAME}"
            sed -i "/${NEW_VM_NAME}/s/^/#/" /etc/hosts


# AUTOMATE BELOW HERE

# Change the hostname to the new VM name permanently
NEW_HOSTNAME="sut6623-vm2"
hostnamectl set-hostname $NEW_HOSTNAME
echo "$NEW_HOSTNAME" > /etc/hostname
log "Hostname changed to $NEW_HOSTNAME"

# Backup and update SSH authorized_keys for sut6623-vm2 with existing keys
log "Backing up and updating SSH keys for ${NEW_VM_NAME}"
scp sut6621-vm1:/root/.ssh/authorized_keys ~/.ssh/authorized_keys_sut6621-vm1 || error_exit "Failed to fetch authorized_keys from sut6621-vm1"
cp -p ~/.ssh/authorized_keys ~/.ssh/authorized_keys_$NEW_HOSTNAME
cat ~/.ssh/authorized_keys_sut6621-vm* >> ~/.ssh/authorized_keys

# Add SSH keys of all VMs in the sequence if they respond to ping
for i in $(seq 1 6); do
    VM_NAME="sut662${i}-vm2"
    if ping -c 1 -W 1 $VM_NAME &> /dev/null; then
        echo "Adding SSH key for $VM_NAME..."
        ssh-keyscan $VM_NAME >> ~/.ssh/authorized_keys
    else
        log "$VM_NAME is not reachable. Skipping."
    fi
done

# Ensure the new VM's SSH key is authorized on the source server (sut6621)
ssh-copy-id -i ~/.ssh/id_rsa.pub sut6621-vm1 || error_exit "Failed to add the new VM's SSH key to sut6621-vm1's authorized_keys"

# Run the userdata script to finalize configuration
log "Running ~/userdata4physicals.sh script on $THIS_PHYSICAL_KVM_SERVER"
ssh $THIS_PHYSICAL_KVM_SERVER "~/userdata4physicals.sh" || error_exit "Failed to run userdata4physicals.sh on $THIS_PHYSICAL_KVM_SERVER"

log "Final automation steps complete!"



##
exit
##

# AUTOMATE BELOW HERE 
hostnamectl set-hostname sut6623-vm2
echo "sut6623-vm2" > /etc/hostname


scp sut6621-vm1:/root/.ssh/authorized_keys ~/.ssh/authorized_keys_sut6621-vm1
cp  -p ~/.ssh/authorized_keys  ~/.ssh/authorized_keys_sut6623-vm2
cat ~/.ssh/authorized_keys_sut6621-vm* >>  ~/.ssh/authorized_keys


for i in $(seq 1 6)
do
    if ping -c 1 -W 1 sut662${i}-vm2 &> /dev/null; then
        echo "Adding SSH key for sut662${i}-vm2..."
        ssh-keyscan sut662${i}-vm2 >> ~/.ssh/authorized_keys
    else
        echo "sut662${i}-vm2 is not reachable. Skipping."
    fi
done

# I need to add the new vm's key to the authorized_keys on source server first 

Run ~/userdata4physicals.sh script 




