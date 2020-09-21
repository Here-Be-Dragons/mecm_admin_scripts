##### Disable IPV6 On All Network Adapters #####
$ScriptInfo = @"
    Function: Disable IPV6 On All Network Adapters
    Author: Oscar Carrillo
    Created: 2019-10-10
"@

# Get TS Variables
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment 
$logPath = $tsenv.Value("LogPath") 
$logFile = "$logPath\$($myInvocation.MyCommand -replace "/^\s*Function:\s*(.*)$/m").log"
 
# Start the logging 
Start-Transcript $logFile
$ErrorActionPreference = "SilentlyContinue"
Write-Host $ScriptInfo

# Disable IPV6 on all Network Adapters
Disable-NetAdapterBinding -Name * -ComponentID ms_tcpip6 -PassThru

0
[gc]::collect()
[gc]::collect()
#& reg unload "HKU\DefaultUsers" >$null 2>&1
Remove-PSDrive -Name HKU

# Stop logging 
Stop-Transcript