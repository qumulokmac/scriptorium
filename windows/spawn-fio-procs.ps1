#################################################################################################
# Spawn FIO Processes Powershell Script
#################################################################################################

# Intended to be run on Maestro 

$remoteComputer = "172.16.1.18"

$batchScripts = @(

    "runfio-172.16.1.18-20231216081215-0.bat",
    "runfio-172.16.1.18-20231216081215-1.bat",
    "runfio-172.16.1.18-20231216081215-2.bat",
    "runfio-172.16.1.18-20231216081215-3.bat",
    "runfio-172.16.1.18-20231216081215-4.bat",
    "runfio-172.16.1.18-20231216081215-5.bat",
    "runfio-172.16.1.18-20231216081215-6.bat",
    "runfio-172.16.1.18-20231216081215-7.bat",
    "runfio-172.16.1.18-20231216081215-8.bat",
    "runfio-172.16.1.18-20231216081215-9.bat",
    "runfio-172.16.1.18-20231216081215-10.bat",
    "runfio-172.16.1.18-20231216081215-11.bat",
    "runfio-172.16.1.18-20231216081215-12.bat",
    "runfio-172.16.1.18-20231216081215-13.bat",
    "runfio-172.16.1.18-20231216081215-14.bat",
    "runfio-172.16.1.18-20231216081215-15.bat"
)

$session = New-PSSession -ComputerName $remoteComputer

foreach ($scriptPath in $batchScripts) {
    Copy-Item -Path $scriptPath -Destination "\\$remoteComputer\C$\FIO\" -ToSession $session
}

$jobs = @()
foreach ($scriptPath in $batchScripts) {
    $remoteScriptPath = "\\$remoteComputer\C$\FIO\" + (Get-Item $scriptPath).Name
    $job = Invoke-Command -ScriptBlock {
        param($scriptPath)
        & $scriptPath
    } -ArgumentList $remoteScriptPath -Session $session
    $jobs += $job
}

# Wait for all jobs to complete
Wait-Job -Job $jobs

# Receive job results (optional, you can remove this if you don't need the results)
$results = Receive-Job -Job $jobs

# Display job results (optional)
foreach ($result in $results) {
    Write-Output "Job Result: $result"
}

# Clean up jobs and remove the remote session
Remove-Job -Job $jobs
Remove-PSSession -Session $session






















