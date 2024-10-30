
# POST FIX Scripts below for now: 

# Be sure you are running on a KVM HOST FIRST, not a -vm 


SOURCE_VM="sut6621-vm2"
TARGET_VM="sut6622-vm3"

MOUNT_POINT="/mnt/qumulo"
NFS_EXPORT="10.10.60.11:/data"
CLONE_OUTBOUND_TMPDIR="${MOUNT_POINT}/clone_outbound"
DTS=$(date +%Y%m%d-%H%M%S)
NEW_KVM_HOST=$(echo "$TARGET_VM" | sed 's/-vm[0-9]*//')
HOST_INDEX="${NEW_KVM_HOST:6:1}"

sed -i '/uuid/d;/mac address/d;s/vm2/vm3/g'  /var/lib/libvirt/images/${NEW_KVM_HOST}-vm3.xml 
sed -i "s/sut6621/${NEW_KVM_HOST}/g"  /var/lib/libvirt/images/${NEW_KVM_HOST}-vm3.xml 

virsh define /var/lib/libvirt/images/${NEW_KVM_HOST}-vm3.xml ; virsh list --all

virsh start $TARGET_VM

echo "Now switch to the Guest VM CONSOLE and run:"
cat <<EOF
    sed -i "s/10\.10\.66\.161/10.10.66.15${HOST_INDEX}/g" /etc/netplan/50-cloud-init.yaml
    netplan apply
    hostnamectl set-hostname "${NEW_KVM_HOST}-vm3"

    scp 10.10.66.161:/root/post_clone* /root
    
    /root/kvm/post_clone_fix_hosts_file.sh
    
    /root/kvm/post_clone_fix_ssh_keys.sh
        
    reboot 
EOF