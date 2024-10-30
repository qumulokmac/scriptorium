#!/bin/bash
# Script to clear logs for a clean reboot

echo "Clearing system logs..."

# Clear journal logs (if systemd is used)
echo "Clearing journal logs..."
journalctl --rotate
journalctl --vacuum-time=1s

# Clear syslog and other logs in /var/log
echo "Clearing logs in /var/log..."
find /var/log -type f -exec truncate -s 0 {} \;

# Clear D-Bus logs (if applicable)
if [ -d /var/log/dbus ]; then
    echo "Clearing D-Bus logs..."
    find /var/log/dbus -type f -exec truncate -s 0 {} \;
fi

# Clear wtmp, btmp, and lastlog files (login history)
echo "Clearing login history logs..."
truncate -s 0 /var/log/wtmp
truncate -s 0 /var/log/btmp
truncate -s 0 /var/log/lastlog

# Reboot the system
echo "Rebooting the system for a clean start..."
reboot