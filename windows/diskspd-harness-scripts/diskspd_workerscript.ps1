 ####################################################################################################
# diskspd_workerscript.ps1
#
# Author: kmac@qumulo.com
#
# Date: 20231229
#
####################################################################################################
param($Cred,$myhost,$sharename,$runname,$NUMBER_INVOCATIONS_PER_HOST)

$index = 5
$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$maxnodes=(Get-Content $nodeconf | Measure-Object –Line).Count
$nodes = [string[]](Get-Content $nodeconf)
$jobArray = New-Object -TypeName System.Collections.ArrayList

####################################################################################################
      
foreach ($node in Get-Content $nodeconf) 
{
    $SMBServer = $nodes[$maxnodes--]
    $myunc = "\\${SMBServer}\${sharename}"
    $driveletter = [char](65+$index++)

    New-PSDrive -Name $driveletter -Root $myunc -Persist -PSProvider "FileSystem" -Credential $Cred | Out-Null
}

Write-Host "`n${myhost}: Mapped drives...`n" -ForegroundColor yellow

####################################################################################################

for ( $counter = 0; $counter -lt $NUMBER_INVOCATIONS_PER_HOST ; $counter++ ) 
{ 
    Write-Host "`nLaunching Diskspd on host $myhost with ${NUMBER_INVOCATIONS_PER_HOST} invocation(s) `n" -ForegroundColor Yellow
    $DTS = Get-Date -UFormat "%Y-%m-%d-%H%M"
    $UUID = [guid]::NewGuid() 
    New-Item -ItemType Directory -Force -Path "F:\datadisks\${myhost}\node-1"
    New-Item -ItemType Directory -Force -Path "G:\datadisks\${myhost}\node-2"
    New-Item -ItemType Directory -Force -Path "H:\datadisks\${myhost}\node-3"
    New-Item -ItemType Directory -Force -Path "I:\datadisks\${myhost}\node-4"

    $diskspdcommand =  "C:\FIO\diskspd.exe -c1g -d300 -r -w40 -o32 -b64k -Sh -L F:\datadisks\\${myhost}\node-1\${myhost}-${UUID}-disk1.dat G:\datadisks\\${myhost}\node2\${myhost}-${UUID}-disk2.dat H:\datadisks\\${myhost}\node3\${myhost}-${UUID}-disk3.dat I:\datadisks\\${myhost}\node4\${myhost}-${UUID}-disk4.dat > F:\output\${myhost}-${DTS}-${UUID}_${runname}_${NUMBER_INVOCATIONS_PER_HOST}_results.txt" 

    $job = start-job -ScriptBlock { Param($InnerCmd)
        Invoke-Expression $InnerCmd  } -ArgumentList $diskspdcommand

    $jobArray.Add($job.Id) | Out-Null
}


 Wait-Job  $jobArray | Receive-Job 
 
