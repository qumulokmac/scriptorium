Start-Transcript -Path "C:\custom_data_log.txt" -Append
netsh advfirewall set allprofiles state off
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -PropertyType DWORD -Value 1 -Force
Stop-Transcript
