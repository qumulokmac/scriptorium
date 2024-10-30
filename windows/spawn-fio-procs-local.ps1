 
$batchScripts = @(
        "C:\FIO\runfio-172.16.1.18-20231216091226-0.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-1.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-2.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-3.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-4.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-5.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-6.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-7.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-8.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-9.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-10.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-11.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-12.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-13.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-14.bat",
        "C:\FIO\runfio-172.16.1.18-20231216091226-15.bat"
)

$jobs = @()
foreach ($scriptPath in $batchScripts) {
    $job = Start-Job -ScriptBlock {
        param($scriptPath)
        & $scriptPath
    } -ArgumentList $scriptPath
    $jobs += $job
}

Wait-Job -Job $jobs
 
$results = Receive-Job -Job $jobs

foreach ($result in $results) {
    Write-Output "Job Result: $result"
}

Remove-Job -Job $jobs 
