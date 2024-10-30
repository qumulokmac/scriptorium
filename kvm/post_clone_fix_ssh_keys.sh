
#!/bin/bash
###################################################################################################
# Re-configure the ssh keys and such 
#
#	rm -f /etc/ssh/ssh_host_*
#	dpkg-reconfigure openssh-server
#	ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
#	ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
#	ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
#	ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa
#	
#	scp -p sut6621-vm1:/root/.ssh/authorized_keys /root/.ssh/authorized_keys
#	scp -p sut6621-vm1:/root/.ssh/known_hosts /root/.ssh/known_hosts
#	
#	ssh-copy-id root@sut6621-vm1
#	
###################################################################################################
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/etc/ssh/backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR" || { echo "Error creating backup directory."; exit 1; }

echo "Backing up existing SSH host keys to $BACKUP_DIR"
cp /etc/ssh/ssh_host_* "$BACKUP_DIR" || { echo "Error backing up SSH host keys."; exit 1; }

# Remove old SSH host keys
echo "Removing old SSH host keys..."
rm -f /etc/ssh/ssh_host_* || { echo "Error removing old SSH host keys."; exit 1; }

# Reconfigure openssh-server to generate new host keys
echo "Regenerating SSH host keys..."
dpkg-reconfigure openssh-server || { echo "Error reconfiguring openssh-server."; exit 1; }

# Generate new SSH host keys manually for specific key types
echo "Generating new SSH host keys..."
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' || { echo "Error generating RSA SSH host key."; exit 1; }
ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' || { echo "Error generating ECDSA SSH host key."; exit 1; }
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' || { echo "Error generating ED25519 SSH host key."; exit 1; }

# Generate a new user SSH key for root
echo "Generating a new SSH key pair for root..."
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N '' || { echo "Error generating new SSH key for root."; exit 1; }

# Sync authorized_keys and known_hosts from a source machine
SOURCE_VM="sut6621-vm1"

echo "Copying authorized_keys and known_hosts from ${SOURCE_VM}..."
scp -p "${SOURCE_VM}:/root/.ssh/authorized_keys" /root/.ssh/authorized_keys || { echo "Error copying authorized_keys."; exit 1; }
scp -p "${SOURCE_VM}:/root/.ssh/known_hosts" /root/.ssh/known_hosts || { echo "Error copying known_hosts."; exit 1; }

# Add the SSH key to the source VM for root login
echo "Adding SSH key to ${SOURCE_VM} for root login..."
ssh-copy-id root@"${SOURCE_VM}" || { echo "Error adding SSH key to ${SOURCE_VM}."; exit 1; }

echo "SSH key regeneration and configuration complete."