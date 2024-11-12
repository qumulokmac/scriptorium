###############################################################################################
#
# Script: heromaker.ps1
# Author: kmac@qumulo.com
# Date: August 21st, 2024
#
# Description: Script to dynamically create the FIO INI file for the hero runs, and
#              supporting DOS scripts needed to mount SMB shares.
#
# Operations:
# - Initialize files
# - Resolve DNS to get IP addresses
# - Mount drives
# - Create directories and FIO jobs
# - Generate FIO configs
# - Launch FIO processes
#
# Usage: heromaker.ps1
# 
# Note: This script retrieves the nodes IP addresses from DNS 
###############################################################################################

Clear-Host

$BASEDIR = "C:\Users\Administrator"
$MOUNT_SCRIPT = "$BASEDIR\mountscript.cmd"
$MKDIR_FILE = "$BASEDIR\mkdir-windows.cmd"
$FIO_JOB_FILE = "$BASEDIR\fio.jobs"
$HERO_IOPS_FILE = "$BASEDIR\hero-smb-iops.ini"
$HERO_TPUT_FILE = "$BASEDIR\hero-smb-tput.ini"

function Resolve-DNS {
    $timeout = 900 
    $interval = 15 
    $startTime = Get-Date
    Clear-DnsClientCache
    while ($true) {
        try {
            $ips = [System.Net.Dns]::GetHostAddresses("cnq.qumulo.net") | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
            if ($ips.Count -gt 0) {
                Write-Host "There are $($ips.Count) IPs for cnq.qumulo.net"
                return $ips.IPAddressToString
            } else {
                Write-Host "No IP addresses found for cnq.qumulo.net. Retrying in $interval seconds..." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "DNS resolution failed. Retrying in $interval seconds..." -ForegroundColor Red
        }

        $elapsedTime = (Get-Date) - $startTime
        if ($elapsedTime.TotalSeconds -ge $timeout) {
            Write-Host "No IP addresses found after 15 minutes. Exiting." -ForegroundColor Red
            exit 1
        }

        Start-Sleep -Seconds $interval
    }
}

function Initialize-Files {
    Remove-Item -Path $FIO_JOB_FILE, $MKDIR_FILE, $MOUNT_SCRIPT -Force -ErrorAction SilentlyContinue
}

function Mount-Drives {
    $drive_letter = 'F'
    $ips = Resolve-DNS
    foreach ($ip in $ips) {
        $path = "${drive_letter}:"
        if (Test-Path $path) {
            Write-Host "Drive $path is mounted. Unmounting..."
            net use $path /delete /yes
            Write-Host "Drive $path unmounted."
        }

        $mountCommand = "net use $path \\$ip\Files /user:admin Qumulo1! /persistent:no"
        Write-Host "Executing: $mountCommand"
        Invoke-Expression $mountCommand
        Write-Host "Drive $path mounted to \\$ip\Files"
        
        $drive_letter = [char]([int][char]$drive_letter + 1)
    }
}

function Create-DirectoriesAndJobs {
    $drive_letter = 'F'
    $count = 0
    $jobLines = @()
    $ips = Resolve-DNS

    foreach ($ip in $ips) {
        $randString = -join ((65..90) + (48..57) | Get-Random -Count 9 | ForEach-Object {[char]$_})
        $directoryPath = "${drive_letter}:\FIODATA\$randString"
        $fioDirectoryPath = "${drive_letter}\:FIODATA\$randString"

        if (Test-Path "${drive_letter}:") {
            Start-Sleep -Seconds 2  
            New-Item -Path $directoryPath -ItemType Directory -Force
            Write-Host "Created directory: $directoryPath"

            $jobLines += "[job$count]"
            $jobLines += "directory=$fioDirectoryPath"
            $jobLines += "numjobs=1"
            $jobLines += ""
        } else {
            Write-Host "Skipping $directoryPath; share not mounted." -ForegroundColor Red
        }

        $drive_letter = [char]([int][char]$drive_letter + 1)
        $count++
    }

    $jobLines | Set-Content -Path $FIO_JOB_FILE -Encoding ASCII
}

function Generate-FioConfigs {
    $iopsConfig = @"
[global]
  blocksize=4KiB
  direct=1
  filesize=100MiB
  iodepth=32
  ioengine=windowsaio
  kb_base=1000
  numjobs=16
  rw=read
  runtime=14400s
  time_based=1
"@

    $tputConfig = @"
[global]
  blocksize=1MiB
  direct=1
  filesize=1GiB
  iodepth=32
  ioengine=libaio
  ioengine=windowsaio
  kb_base=1000
  numjobs=16
  rw=read
  runtime=14400s
  time_based=1
"@

    $iopsConfig | Set-Content -Path $HERO_IOPS_FILE -Encoding ASCII
    $tputConfig | Set-Content -Path $HERO_TPUT_FILE -Encoding ASCII
    Get-Content $FIO_JOB_FILE | Add-Content $HERO_IOPS_FILE
    Get-Content $FIO_JOB_FILE | Add-Content $HERO_TPUT_FILE
}

function Print-Scripts {
    Write-Host ""
    Write-Host "Hero IOPS FIO Definition file: $HERO_IOPS_FILE"
    Write-Host "Hero Throughput FIO Definition file: $HERO_TPUT_FILE"
}

function Launch-FioProcesses {
    Start-Process -FilePath "fio" -ArgumentList $HERO_IOPS_FILE -NoNewWindow -PassThru | Out-Null
    Start-Process -FilePath "fio" -ArgumentList $HERO_TPUT_FILE -NoNewWindow -PassThru | Out-Null
    Write-Host "FIO processes launched in the background."
}

Initialize-Files
Mount-Drives
Create-DirectoriesAndJobs
Generate-FioConfigs
Print-Scripts
Launch-FioProcesses 


