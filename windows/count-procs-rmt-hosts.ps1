 
$remoteComputers = 'fsi-0', 'fsi-1', 'fsi-2', 'fsi-3'

while ( $true )
{
    foreach ($computer in $remoteComputers) {
        try {
            $processCount = Invoke-Command -ComputerName $computer -ScriptBlock {
                Get-Process -Name 'diskspd' -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
            }
            Write-Host "Number of 'diskspd' processes on ${computer}: $processCount"
        } catch {
            Write-Host "Error connecting to ${computer}: $_"
        }
    }
    Start-Sleep 30 
} 

