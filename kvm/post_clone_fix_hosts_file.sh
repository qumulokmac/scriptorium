#!/bin/bash
###################################################################################################
# Backup the /etc/hosts file with a date-time-stamp
#
#	change vm1's to vm3's  
#	change the localhost entry to match the new hostname:  127.0.1.1 sut6621-vm3
#	uncomment the line: 	10.10.66.161   sut6621-vm2
#	comment out the line: # 10.10.66.151   sut6621-vm3
#	
#
#
NEW_KVM_HOST="sut6622"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
cp /etc/hosts /etc/hosts.bak.$TIMESTAMP
echo "Backup created: /etc/hosts.bak.$TIMESTAMP"

# Step 1: Change the string "vm1" to "vm3" throughout the file
sed -i "s/vm1/vm3/g" /etc/hosts
echo "Replaced 'vm1' with 'vm3'"

# Step 2: Replace the line containing "127.0.1.1 sut66*" with "127.0.1.1 ${NEW_KVM_HOST}-vm3"
sed -i "s/^127\.0\.1\.1 sut66.*/127.0.1.1 ${NEW_KVM_HOST}-vm3/" /etc/hosts
echo "Updated 127.0.1.1 line for ${NEW_KVM_HOST}-vm3"

# Step 3: Uncomment the line "10.10.66.161   sut6621-vm2"
sed -i "/^10\.10\.66\.161[[:space:]]\+sut6621-vm2/s/^#//" /etc/hosts
echo "Uncommented '10.10.66.161 sut6621-vm2' line"

# Step 4: Comment out the line containing "10.10.66.*   ${NEW_KVM_HOST}-vm3"
sed -i "/^10\.10\.66\..*[[:space:]]\+${NEW_KVM_HOST}-vm3/s/^/#/" /etc/hosts
echo "Commented out line for '10.10.66.* ${NEW_KVM_HOST}-vm3'"

echo "All updates applied to /etc/hosts"
