#!/bin/bash
##################################################################################################
# 
# Script:   adaptive_load_generator userdata script
#
# Date:     November 5th, 2024
# Author:   KMac kmac@qumulo.com
# Version:  110824.0920
#
##################################################################################################

LOG_FILE="/var/log/alg-ubuntu-userdata.log"
ADMIN_USER="qumulo"

log_message() {
    local MESSAGE="$1"
    echo "#############################" | tee -a "$LOG_FILE"
    echo "#  $(date '+%Y-%m-%d %H:%M:%S') - $MESSAGE" | tee -a "$LOG_FILE"
    echo "#############################" | tee -a "$LOG_FILE"
}

run_command() {
    local CMD="$1"
    log_message "Executing: $CMD"
    eval "$CMD" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log_message "Error: Command failed - $CMD"
        exit 1
    fi
}

stop_service_if_running() {
    local SERVICE="$1"
    if systemctl list-units --type=service --all | grep -q "$SERVICE"; then
        if systemctl is-active --quiet "$SERVICE"; then
            log_message "Stopping $SERVICE service..."
            run_command "systemctl stop $SERVICE"
            log_message "$SERVICE service stopped successfully."
        else
            log_message "$SERVICE service is not running."
        fi
    else
        log_message "$SERVICE service not found."
    fi
}

remove_package_if_installed() {
    local PKG="$1"
    if dpkg -l | grep -q "^ii.*$PKG"; then
        log_message "Removing $PKG..."
        stop_service_if_running "$PKG"
        run_command "apt-get remove --purge -y $PKG"
        log_message "$PKG removed successfully."
    else
        log_message "$PKG is not installed."
    fi
}

update_limits_conf() {
    log_message "Updating /etc/security/limits.conf and PAM settings"
    grep -q "soft nofile 65535" /etc/security/limits.conf || echo "* soft nofile 65535" >> /etc/security/limits.conf
    grep -q "hard nofile 65535" /etc/security/limits.conf || echo "* hard nofile 65535" >> /etc/security/limits.conf
    grep -q "session required pam_limits.so" /etc/pam.d/common-session || echo "session required pam_limits.so" >> /etc/pam.d/common-session
    grep -q "session required pam_limits.so" /etc/pam.d/common-session-noninteractive || echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
    run_command "sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' /etc/systemd/system.conf"
    run_command "sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' /etc/systemd/user.conf"
}

disable_selinux() {
    log_message "Disabling SELinux"
    if [ -f /etc/selinux/config ]; then
        run_command "sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config"
        run_command "setenforce 0"
    fi
}

remove_security_tools() {
    log_message "Removing security tools"
    for tool in ufw iptables firewalld; do
        remove_package_if_installed "$tool"
    done
    run_command "apt-get autoremove -y"
    run_command "apt-get clean"
}

disable_ipv6() {
    log_message "Disabling IPv6"
    cat <<EOF > /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    run_command "sysctl --system"
    run_command "sed -i 's/GRUB_CMDLINE_LINUX=\"[^\"]*/& ipv6.disable=1/' /etc/default/grub"
    run_command "update-grub"
}

configure_ntp() {
    log_message "Configuring NTP with Chrony"
    run_command "apt-get install -y chrony"
    echo "server 169.254.169.123 prefer iburst" > /etc/chrony/chrony.conf
    run_command "systemctl restart chrony"
}

create_admin_user() {
    log_message "Creating admin user $ADMIN_USER"
    run_command "useradd -m -s /bin/bash $ADMIN_USER"
    echo 'PS1="\u@$(hostname -f):\w\$ "' >> "/home/$ADMIN_USER/.bashrc"
    run_command "mkdir -p /home/$ADMIN_USER/.ssh"
    run_command "cp /home/ubuntu/.ssh/authorized_keys /home/$ADMIN_USER/.ssh/authorized_keys"
    run_command "chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh"
    run_command "chmod 700 /home/$ADMIN_USER/.ssh"
    run_command "chmod 600 /home/$ADMIN_USER/.ssh/authorized_keys"
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$ADMIN_USER"
}

update_and_install_packages() {
    log_message "Updating and installing packages"
    run_command "apt -y update"
    run_command "apt -y upgrade"
    run_command "apt -y install fio make gcc automake autoconf libtool m4 selinux-utils gpg manpages-dev binutils coreutils curl jq wget git gzip lsof nfs-common pssh screen strace tcpdump unzip util-linux vim build-essential libssl-dev libffi-dev software-properties-common net-tools python3-apt iperf3"
    run_command "apt -y autoremove"
}

update_sysctl_settings() {
    log_message "Updating sysctl settings"
    cat << _EOF_ >> /etc/sysctl.conf
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
net.ipv4.tcp_rmem = 1048576 8388608 16777216
net.ipv4.tcp_wmem = 1048576 8388608 16777216
net.core.optmem_max = 2048000
net.core.somaxconn = 65535
net.ipv4.tcp_mem = 4096 89600 4194304
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max = 2097152
_EOF_
    log_message "Sysctl settings updated"
}

install_aws_cli() {
    log_message "Installing AWS CLI"
    cd /tmp
    run_command "curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
    run_command "apt-get install -y unzip"
    run_command "unzip -q awscliv2.zip"
    run_command "./aws/install"
    export PATH=$PATH:/usr/local/bin
    echo 'export PATH=$PATH:/usr/local/bin' >> /etc/profile
    run_command "aws --version"
    cd -
}

reboot_system() {
    log_message "Rebooting system"
    run_command "reboot"
}

enable_jumbo_frames() {
    log_message "Starting enable_jumbo_frames"
    INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
    if [ -n "$INTERFACE" ]; then
        ip link set dev $INTERFACE mtu 9000 || true
    else
        log_message "No default interface found, unable to set MTU"
    fi
    log_message "Completed enable_jumbo_frames"
}

copy_tools() {
    log_message "Copying tools from S3. Be sure to have updated the pre-signed URL"
    run_command "curl -o /home/${ADMIN_USER}/alg_suite.tgz 'https://bucket-of-bytes.s3.us-east-1.amazonaws.com/scripts/alg_suite.tgz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAU2VJCYGYN7NUXMXI%2F20241108%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241108T152103Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=6ebdad9ab39af76b7200a158862215c89a36631d325937fe51b21fafef88f2c4'"
    run_command "tar --exclude='.ssh' --no-xattrs -xf /home/${ADMIN_USER}/alg_suite.tgz -C /home/qumulo"
}

configure_workers() {
    log_message "Configuring workers.conf"
    /usr/local/bin/aws ec2 describe-instances --filters "Name=tag:Name,Values=*ubuntu*" --query "Reservations[].Instances[].PrivateIpAddress" --output text | tr '\t' '\n' > /home/qumulo/workers.conf
    # The nodes.conf will only be populated if CNQ has already been deployed. 
    /usr/local/bin/aws ec2 describe-instances --filters "Name=tag:Name,Values=*node*" --query "Reservations[].Instances[].PrivateIpAddress" --output text | tr '\t' '\n' > /home/qumulo/nodes.conf
    # head -1 /home/qumulo/workers.conf > /home/qumulo/workers-1.conf
    # head -4 /home/qumulo/workers.conf > /home/qumulo/workers-4.conf
    chown -R qumulo:qumulo /home/qumulo

    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
    REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
    NAME_TAG=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=Name" --region ${REGION} --query "Tags[0].Value" --output text)

    log_message "INSTANCE_ID is $INSTANCE_ID, REGION is $REGION, NAME_TAG is $NAME_TAG"
    echo "export NAME_TAG=\"${NAME_TAG}\"" >> "/home/$ADMIN_USER/.bashrc"
    echo "export PS1='[\u@\W] \${NAME_TAG} \$ '" >> "/home/$ADMIN_USER/.bashrc"
    echo 'PATH=$PATH:/home/qumulo/tools:.' >> "/home/$ADMIN_USER/.bashrc"
    chmod 0600 "/home/$ADMIN_USER/.bashrc"
    chown ${ADMIN_USER}:${ADMIN_USER} "/home/$ADMIN_USER/.bashrc"

    for host in $(cat /home/qumulo/workers.conf); do
        ssh-keyscan $host >> "/home/$ADMIN_USER/.ssh/known_hosts" 2>/dev/null
    done
    chmod 0600 "/home/$ADMIN_USER/.bashrc" "/home/$ADMIN_USER/.ssh/known_hosts" 
    chown -R qumulo:qumulo "/home/$ADMIN_USER/"

    log_message "Removing apparmor..."

    systemctl stop apparmor.service 
    systemctl disable apparmor.service 
    apt -y remove apparmor

}

set_sshdconfig() {
    log_message "Starting set_sshdconfig"
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    log_message "Completed set_sshdconfig"
}

configure_ena_express() {
    log_message "Starting configure_ena_express"

    INTERFACE=$(basename `ls -1d /sys/class/net/e*`)
    echo "NIC set to $INTERFACE"

    echo "Setting MTU to 8900"
    ip link set $INTERFACE mtu 8900

    echo "Setting the RX size to 8192"
    /usr/sbin/ethtool -G $INTERFACE rx 8192

    echo "Setting the TX Queue size to max on all queues"
    for txq in `ls -1d /sys/class/net/$INTERFACE/queues/tx-*`
    do
        echo max > $txq/byte_queue_limits/limit_min
    done

    echo "Loading the ENA module"
    /usr/sbin/modprobe ena
    echo 'ena' >> /etc/modules

    echo "Updating Grub"
    echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' >> /etc/default/grub
    /usr/sbin/update-grub

    cat << EOF > /etc/sysctl.d/99-ena-tcp-tuning.conf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_moderate_rcvbuf = 1

EOF

}

main() {
    log_message "Starting main script"
    disable_selinux
    remove_security_tools
    enable_jumbo_frames
    configure_ena_express
    disable_ipv6
    configure_ntp
    create_admin_user
    update_and_install_packages
    install_aws_cli
    update_sysctl_settings
    update_limits_conf
    copy_tools
    configure_workers
    reboot_system
}

main
