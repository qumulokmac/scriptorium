 $remoteComputers = 'fsi-0', 'fsi-1', 'fsi-2', 'fsi-3'


foreach (${computer} in $remoteComputers) {
    try {
        $processes = Invoke-Command -ComputerName ${computer} -ScriptBlock {
            Get-Process -Name 'diskspd' -ErrorAction SilentlyContinue
        }

        if ($processes) {
            Write-Host "$(Get-Date) - Killing 'diskspd' processes on ${computer}"
            Invoke-Command -ComputerName ${compute}r -ScriptBlock {
                Get-Process -Name 'diskspd' | Stop-Process -Force
            }
        } else {
            Write-Host "$(Get-Date) - No 'diskspd' processes found on ${computer}"
        }
    } catch {
        Write-Host "$(Get-Date) - Error connecting to ${computer}: $_"
    }
}
 

