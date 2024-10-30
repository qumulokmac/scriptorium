#!/bin/bash -x 

# Variables
RESOURCE_GROUP="product-eastasia-rg"

# Log in to Azure

# Find all VM names with "smbbench" in their name within the specified resource group
VM_NAMES=$(az vm list -g $RESOURCE_GROUP --query "[?contains(name, 'smbbench')].name" -o tsv)

if [ -z "$VM_NAMES" ]; then
    echo "No VMs found with 'smbbench' in their name in resource group $RESOURCE_GROUP."
    exit 1
else
    echo "Found VMs: $VM_NAMES in resource group $RESOURCE_GROUP."
fi

# Loop through each VM and perform the operations
for VM_NAME in $VM_NAMES; do
    echo "Processing VM: $VM_NAME"

    # List the data disks attached to the VM
    echo "Listing disks attached to VM $VM_NAME..."
    az vm show -g $RESOURCE_GROUP -n $VM_NAME --query "storageProfile.dataDisks[].{name:name, lun:lun}" -o table

    # Identify the OS disk
    OS_DISK_ID=$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query "storageProfile.osDisk.managedDisk.id" -o tsv)

    # List all attached disks excluding the OS disk
    DISK_IDS=$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query "storageProfile.dataDisks[?id!='$OS_DISK_ID'].id" -o tsv)

    if [ -z "$DISK_IDS" ]; then
        echo "No data disks found attached to VM $VM_NAME."
        continue
    fi

    # Loop through each disk to check if it's mounted as E:
    for DISK_ID in $DISK_IDS; do
        DISK_NAME=$(az disk show --ids $DISK_ID --query "name" -o tsv)
        echo "Checking disk $DISK_NAME (ID: $DISK_ID) on VM $VM_NAME..."

        # Run a PowerShell script to check if the disk is mounted as E: and detach it
        az vm run-command invoke -g $RESOURCE_GROUP -n $VM_NAME --command-id RunPowerShellScript --scripts @"
            \$driveLetter = "E:"
            \$volumes = Get-WmiObject -Query "SELECT * FROM Win32_Volume WHERE DriveLetter = '\$driveLetter'"
            if (\$volumes) {
                Write-Output "Drive found mounted as \$driveLetter. Detaching disk."
                \$volumes.Dismount(\$false, \$false)
            } else {
                Write-Output "No drive found mounted as \$driveLetter."
            }
"@

        # Check if the drive was detached
        DETACHED=$(az vm run-command invoke -g $RESOURCE_GROUP -n $VM_NAME --command-id RunPowerShellScript --scripts @"
            \$driveLetter = "E:"
            \$volumes = Get-WmiObject -Query "SELECT * FROM Win32_Volume WHERE DriveLetter = '\$driveLetter'"
            if (\$volumes) {
                Write-Output "Drive still mounted as \$driveLetter."
            } else {
                Write-Output "Drive successfully detached."
            }
"@ --query "value[].message" -o tsv)

        if [[ $DETACHED == *"Drive successfully detached"* ]]; then
            echo "Detaching disk $DISK_NAME from VM $VM_NAME..."
            az vm disk detach --resource-group $RESOURCE_GROUP --vm-name $VM_NAME --name $DISK_NAME

            echo "Deleting disk $DISK_NAME with ID $DISK_ID..."
            az disk delete --ids $DISK_ID --yes
            echo "Disk $DISK_NAME deleted successfully from VM $VM_NAME."
            break
        else
            echo "No drive found mounted as E: on VM $VM_NAME."
        fi
    done

    echo "Completed processing VM: $VM_NAME"
done

