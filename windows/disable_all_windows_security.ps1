###
# disable_all_windows_security.ps1
###

# Disable Windows Defender Antivirus
Write-Host "Disabling Windows Defender Antivirus..."
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableScriptScanning $true
Stop-Service -Name "WinDefend" -Force
Set-Service -Name "WinDefend" -StartupType Disabled
Write-Host "Windows Defender Antivirus disabled."

# Disable Windows Firewall
Write-Host "Disabling Windows Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
Stop-Service -Name "MpsSvc" -Force
Set-Service -Name "MpsSvc" -StartupType Disabled
Write-Host "Windows Firewall disabled."

# Uninstall Windows Defender Features
Write-Host "Uninstalling Windows Defender features..."
Remove-WindowsFeature -Name Windows-Defender-Features
Write-Host "Windows Defender features uninstalled."

# Disable Windows Security Center
Write-Host "Disabling Windows Security Center..."
Stop-Service -Name "wscsvc" -Force
Set-Service -Name "wscsvc" -StartupType Disabled
Write-Host "Windows Security Center disabled."

# Disable and Uninstall Windows Defender SmartScreen
Write-Host "Disabling and Uninstalling Windows Defender SmartScreen..."
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "EnableSmartScreen" -Value 0
Write-Host "Windows Defender SmartScreen disabled."

# Disable Windows Defender Antivirus Scheduled Tasks
Write-Host "Disabling Windows Defender Antivirus Scheduled Tasks..."

$tasks = Get-ScheduledTask | Where-Object {$_.TaskName -like "Windows Defender*" }
foreach ($task in $tasks) {
    Disable-ScheduledTask -TaskName $task.TaskName
}
Write-Host "Windows Defender Antivirus Scheduled Tasks disabled."

# Disable Microsoft Defender Application Guard (if applicable)
Write-Host "Disabling Microsoft Defender Application Guard..."
Remove-WindowsFeature -Name Windows-Defender-ApplicationGuard
Write-Host "Microsoft Defender Application Guard disabled."

# Disable and Uninstall Windows Defender Exploit Guard (if applicable)
Write-Host "Disabling and Uninstalling Windows Defender Exploit Guard..."
Remove-WindowsFeature -Name Windows-Defender-ExploitGuard
Write-Host "Windows Defender Exploit Guard disabled."

# Disable Windows Defender SmartScreen in Registry (for older versions)
Write-Host "Disabling Windows Defender SmartScreen in Registry..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -Value "Off"
Write-Host "Windows Defender SmartScreen disabled in Registry."


Uninstall-WindowsCapability -Online -Name 'Microsoft-Windows-Defender'" 

