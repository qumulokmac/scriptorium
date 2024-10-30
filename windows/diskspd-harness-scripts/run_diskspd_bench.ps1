 ####################################################################################################
# SMB Diskspd wrapper script - run_diskspd_bench.ps1
#
# Author: kmac@qumulo.com
#
# Date: 20240118
##
####################################################################################################

$jsonString = Get-Content 'C:\cygwin64\home\localadmin\ini\smbbench_config.json' -Raw
$jsonObject = $jsonString | ConvertFrom-Json
$jsonObject.smbbench_settings | Where-Object { $_.type -eq "powershell" -or $_.type -eq "global" } | ForEach-Object {
    $envVarName = $_.name
    $envVarValue = $_.value
    Set-Variable -Name $_.name -Value $_.value
}

$nodeconf = 'C:\FIO\nodes.conf'
$wrkrconf = 'C:\FIO\workers.conf'
$LOCALADMIN_PASSWORD = ConvertTo-SecureString $LOCALADMIN_PASSWORD -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($LOCALADMIN_USERNAME, $LOCALADMIN_PASSWORD)
$nodes = [string[]](Get-Content $nodeconf)
$jobArray = New-Object -TypeName System.Collections.ArrayList
$maxnodes=(Get-Content $nodeconf | Measure-Object Line).Count
$wrkArray=(0,0,0,0,0,0,0,0)
$wrkArray.length = (Get-Content $wrkrconf | Measure-Object Line).Count

Clear-Host
$index=0
foreach($myhost in Get-Content $wrkrconf) 
{
  Write-Host "Unmounting all mapped drives on: "${myhost} -ForegroundColor Green 
  Invoke-Command -Computer $myhost -scriptblock { Get-SmbMapping | Remove-SmbMapping -UpdateProfile -Force 2>$null  }
  $wrkArray[${index}++] = ${myhost}
}

####################################################################################################
# Main worker host loop
####################################################################################################

for ( $NUM_INVOCATIONS = 15 ; $NUM_INVOCATIONS -lt 48 ; $NUM_INVOCATIONS++)
{
    Write-Host "Entering the ${NUM_INVOCATIONS} invocation run" -ForegroundColor Yellow

    $NUMBER_INVOCATIONS_PER_HOST = [math]::ceiling($NUM_INVOCATIONS/4)
    $LEFTOVERS = ${NUM_INVOCATIONS} % 4

        foreach($myhost in Get-Content $wrkrconf) 
        { 

          $SMBServer = $nodes[0]
          $myunc = -join("\\", $SMBServer, "\", $SMB_SHARE_NAME)
          $driveletter = "A"

          $session = New-PSSession -ComputerName $myhost

          $RRun = { 
              param($Cred, $myunc, $driveletter, $myhost)
              New-PSDrive -Name $driveletter -Root $myunc -Persist -PSProvider "FileSystem" -Credential $Cred | out-null
              Copy-Item "A:\config\*" -Destination C:\FIO

          }
          Invoke-Command -ComputerName $myhost -ScriptBlock $RRun -ArgumentList $Cred,$myunc,$driveletter,$myhost -Credential $Cred
 
          $scriptContent = Get-Content -Path 'C:\FIO\diskspd_workerscript.ps1' -Raw
          $workerScript = [ScriptBlock]::Create($scriptContent)

          Write-Host "`tStarting Diskspd on " -NoNewline -ForegroundColor Green 

          Write-Host ${myhost} -ForegroundColor Cyan

          $job = Invoke-Command -ComputerName $myhost -ScriptBlock $workerScript -ArgumentList $Cred,$myhost,$SMB_SHARE_NAME,$UNIQUE_RUN_IDENTIFIER,$NUMBER_INVOCATIONS_PER_HOST -Credential $Cred -AsJob -JobName "${myhost}_${UNIQUE_RUN_IDENTIFIER}"
          $jobArray.Add($job.Id) | Out-Null
          $job | Format-List | Out-File -Width 2000 -FilePath "A:\stderr\${myhost}_${UNIQUE_RUN_IDENTIFIER}_workerscript.out" 

        }

        ###
        # Handle the fractional diskspd leftovers...  
        ###

        for ( $PTR = $LEFTOVERS ; $PTR -lt 4 ; $PTR++)
        {
          $myhost = $wrkArray[${PTR}]

          Write-Host "Setting Myhost to ${myhost} using ${PTR} with leftovers ${LEFTOVERS}" -ForegroundColor Cyan

          $job = Invoke-Command -ComputerName $myhost -ScriptBlock $workerScript -ArgumentList $Cred,$myhost,$SMB_SHARE_NAME,$UNIQUE_RUN_IDENTIFIER,$NUMBER_INVOCATIONS_PER_HOST -Credential $Cred -AsJob -JobName "${myhost}_${UNIQUE_RUN_IDENTIFIER}"
          $jobArray.Add($job.Id) | Out-Null
          $job | Format-List | Out-File -Width 2000 -FilePath "A:\stderr\${myhost}_${UNIQUE_RUN_IDENTIFIER}_workerscript.out" 

        }

        Write-Host -NoNewline "`tWaiting for ALL diskspd jobs " -ForegroundColor Green
        Write-Host -NoNewline "[${jobArray}]"  -ForegroundColor Magenta
        Write-Host " to complete`n`n"  -ForegroundColor Green 

        Wait-Job  $jobArray | Receive-Job
}
 
 
