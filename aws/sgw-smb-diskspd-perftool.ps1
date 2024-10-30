###
# Edit these variables as needed for your specific test
###
$WORKLOAD_LOCATION = "K:\SGW-PERFTEST\"
$BLOCK_SIZE_ARRAY = "4k","16k","128k","1m"
$DISKSPD_LOCATION = "C:\kjmtmp\DiskSpd.exe"
$TESTFILE_BASENAME =  $WORKLOAD_LOCATION + "${env:computername}-perftest-"
$TESTFILE_SIZE = "1024000000" #In Bytes
$LOGFILE_BASENAME = "C:\kjmtmp\results\sgw-smb-diskspd-bs"

###
# Create the test files (1G each)
###

foreach ($bs in $BLOCK_SIZE_ARRAY)
{
  $fscommand = "fsutil file createnew " + $TESTFILE_BASENAME + $bs + ".dat " + $TESTFILE_SIZE
  Write-Host "Creating test file with: " $fscommand 
  Invoke-Expression -Command:$fscommand | Out-Null 
}
Write-Host ""
Write-Host ""

###
# TEST #1 100% random writes
#
#      -d120 - Duration = 120 seconds; 
#      -w100 - 100% writes; 
#      -r    - random IO; 
#      -t64  - use 64 threads; 
#      -o12  - limit outstanding IO requests to 12; 
#      -L    - measure latency; 
#      -Sr   - disable local caching, with remote sw caching enabled; only valid for remote filesystems
#
###
foreach ($bs in $BLOCK_SIZE_ARRAY)
{ 
  Write-host "Starting TEST #1 - 100% random WRITE test, using BlockSize's of " $BLOCK_SIZE_ARRAY
  $command = $DISKSPD_LOCATION + " -d120 -w100 -r -t64 -o12 -b" + $bs + " -Sr -L " + $TESTFILE_BASENAME + $bs + ".dat" 
  Write-Host "Running:" $command
  $DTS = (Get-Date).ToString("yyyyMMddHHmm")
  $LOGFILE = $LOGFILE_BASENAME + $bs + "-random-write-" + $DTS + ".txt"
  Write-host "Logfile is:" $LOGFILE
  Invoke-Expression -Command:$command | Out-File $LOGFILE -Encoding UTF8
}
Write-Host ""
Write-Host ""

###
# TEST #2 100% random reads
#
#      -d120 - Duration = 120 seconds; 
#      -w0   - ZERO writes (Implies 100% read)
#      -r    - random IO; 
#      -t64  - use 64 threads; 
#      -o12  - limit outstanding IO requests to 12; 
#      -L    - measure latency; 
#      -Sr   - disable local caching, with remote sw caching enabled; only valid for remote filesystems
#
###
foreach ($bs in $BLOCK_SIZE_ARRAY)
{
  Write-host "Starting TEST #2 - 100% random READ test, using BlockSize's of " $BLOCK_SIZE_ARRAY
  $command = $DISKSPD_LOCATION + " -d120 -w0 -r -t64 -o12 -b" + $bs + "  -Sr -L " + $TESTFILE_BASENAME + $bs + ".dat" 
  Write-Host "Running:" $command
  $DTS = (Get-Date).ToString("yyyyMMddHHmm")
  $LOGFILE = $LOGFILE_BASENAME + $bs + "-random-read-" + $DTS + ".txt"
  Write-host "Logfile is:" $LOGFILE
  Invoke-Expression -Command:$command | Out-File $LOGFILE -Encoding UTF8
}
Write-Host ""
Write-Host ""

###
# TEST #3 100% sequential reads
#
#      -d120 - Duration = 120 seconds; 
#      -w0   - 100% reads; 
#      -si   - sequential stride size, offset between subsequent I/O operations.  NOTE:  This forces the flow to be sequential, which may reduce throughput.
#      -t64  - use 64 threads; 
#      -o12  - limit outstanding IO requests to 12; 
#      -L    - measure latency; 
#      -Sr   - disable local caching, with remote sw caching enabled; only valid for remote filesystems
#
###

foreach ($bs in $BLOCK_SIZE_ARRAY)
{
  Write-host "Starting TEST #3 - 100% sequential READ test, using BlockSize's of " $BLOCK_SIZE_ARRAY
  $command = $DISKSPD_LOCATION + " -d120 -w0 -si -t64 -o12 -b" + $bs + "  -Sr -L " + $TESTFILE_BASENAME + $bs + ".dat" 
  Write-Host "Running:" $command
  $DTS = (Get-Date).ToString("yyyyMMddHHmm")
  $LOGFILE = $LOGFILE_BASENAME + $bs + "-sequential-read-bs" + $DTS + ".txt"
  Write-host "Logfile is:" $LOGFILE
  Invoke-Expression -Command:$command | Out-File $LOGFILE -Encoding UTF8
}
Write-Host ""
Write-Host ""

###
# TEST #4 100% sequential writes
#
#      -d120 - Duration = 120 seconds; 
#      -w100 - 100% writes; 
#      -si   - sequential stride size, offset between subsequent I/O operations.  NOTE:  This forces the flow to be sequential, which may reduce throughput.
#      -t64  - use 64 threads; 
#      -o12  - limit outstanding IO requests to 12; 
#      -L    - measure latency; 
#      -Sr   - disable local caching, with remote sw caching enabled; only valid for remote filesystems
#
###

foreach ($bs in $BLOCK_SIZE_ARRAY)
{
  Write-host "Starting TEST #4 - 100% sequential WRITE test, using BLOCK_SIZE_ARRAYs of " $BLOCK_SIZE_ARRAY
  $command = $DISKSPD_LOCATION + " -d120 -w100 -si -t64 -o12 -b" + $bs + "  -Sr -L " + $TESTFILE_BASENAME + $bs + ".dat" 
  Write-Host "Running:" $command
  $DTS = (Get-Date).ToString("yyyyMMddHHmm")
  $LOGFILE = $LOGFILE_BASENAME + $bs + "-sequential-write-bs" + $DTS + ".txt"
  Write-host "Logfile is:" $LOGFILE
  Invoke-Expression -Command:$command | Out-File $LOGFILE -Encoding UTF8
}
Write-Host ""
 

