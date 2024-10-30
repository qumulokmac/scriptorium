# remove_dvd_drive.ps1

# Load PnPDevice module if available
Import-Module PnPDevice -ErrorAction SilentlyContinue

# Function to remove CD-ROM using PnPDevice
function Remove-CDROM {
    param (
        [string]$DriveLetter
    )
    # Get the CD-ROM drive that is mounted as E:
    $cdrom = Get-WmiObject -Query "SELECT * FROM Win32_CDROMDrive WHERE Drive = '$DriveLetter'"
    if ($cdrom) {
        Write-Output "Found CD-ROM drive at ${DriveLetter}: $($cdrom.Description)"
        $device = Get-PnpDevice -InstanceId $cdrom.PNPDeviceID
        if ($device) {
            Write-Output "Uninstalling device: $($device.Name)"
            Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
            Remove-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
        } else {
            Write-Output "Device not found in PnPDevice list."
        }
    } else {
        Write-Output "No CD-ROM drive found at $DriveLetter"
    }
}

# Remove the CD-ROM drive mounted at E:
Remove-CDROM -DriveLetter "E:"
