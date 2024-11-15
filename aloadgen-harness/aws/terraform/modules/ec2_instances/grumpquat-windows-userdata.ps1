<powershell>
param(
    [string]$AdminPassword
)

$logDirectory = "C:\userdata"
$desktopPath = "C:\Users\Administrator\Desktop"
$chromeHomePageValue = "www.google.com"
$chromeHomePageRegPath = "HKCU:\Software\Policies\Google\Chrome"
$chromePolicyPath = "HKLM:\Software\Policies\Google\Chrome"
$resourceBucketName = "bucket-of-bytes"

New-Item -ItemType Directory -Path $logDirectory -Force
Start-Transcript -Path "$logDirectory\userdata_mainlog.txt" -Append
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

function Log-Output {
    param (
        [string]$message,
        [string]$logFile
    )
    $message | Out-File -FilePath $logFile -Append
}

function Set-AdminPassword {
    $logFile = "$logDirectory\userdata_password_log.txt"
    $adminUser = [ADSI]("WinNT://$env:COMPUTERNAME/Administrator, user")
    try {
        $adminUser.psbase.Invoke("SetPassword", "${AdminPassword}")
        $adminUser.SetInfo()
        Log-Output "Password set successfully" $logFile
    } catch {
        Log-Output "Failed to set password: $_" $logFile
    }
}

function Disable-SecurityFeatures {
    $logFile = "$logDirectory\security_features_log.txt"
    Write-Host "Disabling Windows Firewall..."
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
    netsh advfirewall set allprofiles state off
    Log-Output "Firewall disabled successfully" $logFile

    Write-Host "Disabling Windows Defender SmartScreen..."
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off"
    Log-Output "SmartScreen disabled successfully" $logFile
}

function Disable-ServerManager {
    $logFile = "$logDirectory\server_manager_log.txt"
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -PropertyType DWORD -Value 1 -Force
    Log-Output "Server Manager Dashboard disabled successfully" $logFile
}

function Configure-Chrome {
    $logFile = "$logDirectory\chrome_config_log.txt"
    if (-not (Test-Path -Path $chromeHomePageRegPath)) {
        New-Item -Path $chromeHomePageRegPath -Force
    }
    Set-ItemProperty -Path $chromeHomePageRegPath -Name "HomepageLocation" -Value $chromeHomePageValue

    if (-not (Test-Path -Path $chromePolicyPath)) {
        New-Item -Path $chromePolicyPath -Force
    }
    Set-ItemProperty -Path $chromePolicyPath -Name "HomepageLocation" -Value $chromeHomePageValue
    Set-ItemProperty -Path $chromePolicyPath -Name "DefaultBrowserSettingEnabled" -Value 0
    Log-Output "Chrome configured successfully" $logFile
}

function Disable-PrintSpooler {
    $logFile = "$logDirectory\print_spooler_log.txt"
    Stop-Service -Name "Spooler" -Force
    Set-Service -Name "Spooler" -StartupType Disabled
    Log-Output "Print Spooler disabled successfully" $logFile
}

function Download-HeroMaker {
    $logFile = "$logDirectory\heromaker_download_log.txt"
    $key = "scripts/heromaker.ps1"
    $destinationPath = "C:\Users\Administrator\Desktop\heromaker.ps1"

    try {
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Verbose
		Install-Module -Name AWSPowerShell.NetCore -Force -AllowClobber
		Import-Module AWSPowerShell.NetCore

        Read-S3Object -BucketName "$${resourceBucketName}" -Key "$${key}" -File "$${destinationPath}"

        if (Test-Path $destinationPath) {
            Write-Output "heromaker.ps1 downloaded successfully to $destinationPath" | Out-File -FilePath $logFile -Append
        } else {
            Write-Output "Download failed, file not found: $destinationPath" | Out-File -FilePath $logFile -Append
        }
    } catch {
        Write-Output "Failed to download heromaker.ps1: $_" | Out-File -FilePath $logFile -Append
    }
}

function Handle-Reboot {
    $logFile = "$logDirectory\reboot_log.txt"
    $markerFile = "$logDirectory\rebooted_once.marker"
    if (Test-Path $markerFile) {
        Log-Output "Reboot has already occurred, skipping reboot." $logFile
    } else {
        Log-Output "First run, creating marker file and rebooting..." $logFile
        New-Item -ItemType File -Path $markerFile -Force
        Restart-Computer -Force
    }
}

function Download-And-Install {
    param (
        [string]$s3Key,
        [string]$destinationPath,
        [string]$installArguments = ""
    )
    Write-Host "Starting download of $${resourceBucketName}/$${s3Key} to $${destinationPath}..."
    Read-S3Object -BucketName $${resourceBucketName} -Key $${s3Key} -File $${destinationPath}
    Write-Host "Download completed. File saved to $${destinationPath}"

    if ($destinationPath -like "*.msi") {
        Write-Host "Starting MSI installation from $${destinationPath}..."
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$destinationPath`" $installArguments" -Wait
    }
    elseif ($destinationPath -like "*.exe") {
        Write-Host "Starting EXE installation from $${destinationPath}..."
        Start-Process -FilePath $${destinationPath} -ArgumentList $${installArguments} -Wait
    }
    Write-Host "Installation completed for $${destinationPath}"
}


Set-AdminPassword
Disable-SecurityFeatures
Disable-ServerManager
Disable-PrintSpooler
Download-HeroMaker

Start-Sleep -Seconds 30 

Download-And-Install -s3Key "downloads/7z1900-x64.msi" `
                     -destinationPath "$logDirectory\7z1900-x64.msi" `
                     -installArguments "/quiet /norestart"

Download-And-Install -s3Key "downloads/fio-3.37-x64.msi" `
                     -destinationPath "$logDirectory\fio-3.37-x64.msi" `
                     -installArguments "/quiet /norestart"

Download-And-Install -s3Key "downloads/powershell7.msi" `
                     -destinationPath "$logDirectory\powershell7.msi" `
                     -installArguments "/quiet"

Download-And-Install -s3Key "downloads/npp_installer.exe" `
                     -destinationPath "$logDirectory\npp_installer.exe" `
                     -installArguments "/S"

Download-And-Install -s3Key "downloads/SysinternalsSuite.zip" `
                     -destinationPath "$logDirectory\SysinternalsSuite.zip"
Expand-Archive -LiteralPath "$logDirectory\SysinternalsSuite.zip" -DestinationPath "C:\SysinternalsSuite" -Force

Download-And-Install -s3Key "downloads/chrome_installer.exe" `
                     -destinationPath "$logDirectory\chrome_installer.exe" `
                     -installArguments "/silent /install" 
Configure-Chrome

Handle-Reboot

Stop-Transcript

</powershell>
<persist>true</persist>
