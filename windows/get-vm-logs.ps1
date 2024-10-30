Get-EventLog -LogName Application -Newest 1000 | Export-Csv -Path C:\eventlogs.csv -NoTypeInformation

