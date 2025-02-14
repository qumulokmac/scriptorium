#!/bin/bash
##################################################################################################
# 
# Script:   adaptive_load_generator userdata script
#
# Date:     November 14th, 2024
# Author:   KMac kmac@qumulo.com
# Version:  111524.0903
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

set_admin_user() {
    log_message "Setting admin user $ADMIN_USER"
    echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$ADMIN_USER"
}

update_and_install_packages() {
    log_message "Updating and installing packages"
    run_command "apt -y update"
    run_command "apt -y upgrade"
    run_command "apt -y install fio make gcc automake autoconf libtool m4 selinux-utils gpg manpages-dev binutils coreutils curl jq wget git gzip lsof nfs-common pssh screen strace tcpdump unzip util-linux vim build-essential libssl-dev libffi-dev software-properties-common net-tools python3-apt iperf3"
    run_command "apt -y autoremove"
    run_command "apt -y remove walinuxagent" 
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

install_azure_cli() {
    log_message "Installing Azure CLI"
    run_command "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    export PATH=$PATH:/usr/bin
    echo 'export PATH=$PATH:/usr/bin' >> /etc/profile
}

reboot_system() {
    log_message "Rebooting system"
    run_command "reboot"
}

copy_tools() {
    log_message "Copying tools from S3. Be sure to have updated the pre-signed URL"
    run_command "curl -o /home/${ADMIN_USER}/azure_alg_suite.tgz 'https://bucket-of-bytes.s3.us-east-1.amazonaws.com/scripts/azure_alg_suite.tgz?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=YOUR_AWS_ACCESS_KEY_ID%2F20241118%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241118T022350Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=88168a37561dcb1175f8e5ded57e373b9ef0d37cee7b228915d47837bab6ac82'"
    run_command "tar --warning=no-unknown-keyword -xvf /home/${ADMIN_USER}/azure_alg_suite.tgz -C /home/qumulo ./adaptive_load_generator.sh ./start_load.sh ./tools"
    run_command "chown -R ${ADMIN_USER} /home/${ADMIN_USER}"
}

set_sshdconfig() {
    log_message "Starting set_sshdconfig"
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/#PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
    log_message "Completed set_sshdconfig"
}

main() {
    log_message "Starting main script"
    disable_selinux
    remove_security_tools
    disable_ipv6
    configure_ntp
    set_admin_user
    update_and_install_packages
    install_azure_cli
    update_sysctl_settings
    update_limits_conf
    copy_tools
    reboot_system
}

main
