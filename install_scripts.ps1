<#

  .SYNOPSIS
  Uploads scripts to Microsoft Endpoint Configutation Manager

  .DESCRIPTION
  This  PowerShell script will iterate through all ps1 files in mecm_scripts/ and create missing scripts or update changes to existing scripts.

#>

$SiteCode = "XXX"

try { Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' }
catch [System.Management.Automation.ParameterBindingException] {
  Write-Host "WARNING: an update to the console on this server is needed."
}
catch {
  Write-Host "An loading the ConfigurationManager PS Module occurred:"
  Write-Host $_
  Write-Host "This is fatal, stopping script."
  exit 1
}
try { cd ${SiteCode}: }
catch {
  Write-Host ("Failed to connect to site: " + $SiteCode + ". Does the current user have permissions?")
  Write-Host ("Curent User: " + $env:UserDomain + "\" + $env:UserName)
  Write-Host $_
  exit 1
}
$scriptIndex = Get-CMScript -Fast
if ($scriptIndex.Count -ne 0) {
  Write-Host ("Successfully downloaded " + $scriptIndex.Count + " existing scripts from MECM")
} else {
  Write-Host ("Script download returned "+ $scriptIndex.Count + "scripts. This is likely not right. Halting.")
  exit 1
}
Get-ChildItem "${env:CI_PROJECT_DIR}\mecm_scripts" -Filter *.ps1 | 
Foreach-Object {
  foreach ($var in "scriptName","scriptGuid","newScript","updateScript")
  {
    Clear-Variable $var -ErrorAction SilentlyContinue
  }
  Write-Host "-------------"
  write-host ("Working on " + $_.Name)
  $locateName = select-string -Path $_.FullName -Pattern '^\s*#*\s*Function:\s*(.*)$' -AllMatches
  if ($locateName.Matches.Count -gt 0){
    $ScriptName = $locateName.Matches.Groups[1].value
    write-host ("Located script name: " + $scriptName)
  } else {
    write-host ("Script name not set in script (see README.md), using `"" + $_.Name + "`"")
    $scriptName = $_.Name
  }
  $SendKeysSpecialChars = '{','}','[',']','~','+','^','%','(',')'
  $ToEscape = ($SendKeysSpecialChars|%{[regex]::Escape($_)}) -join '|'
  $escapedScriptName = $ScriptName -replace "($ToEscape)",'\$1'
  $findName = $scriptIndex -match "${escapedScriptName}"
  if ( $findName -ne "False" ) {
    if ( $findName.Length -gt 1 ) {
      Write-Host ("WARNING: multiple scripts named: " + $scriptName + ". Updating first match.")
    }
    
    $scriptGuid = $findName[0].ScriptGuid
    $localChecksum = Get-FileHash -Path $_.FullName -Algorithm $findName[0].ScriptHashAlgorithm
    if ( $findName[0].ScriptHash -ne $localChecksum.Hash ) {
      Write-Host "Local hash does not match uploaded hash.  Updating MECM copy."
      $updateScript = $true
    } else {
      Write-Host "Local hash matches uploaded hash. Skipping upload."
      $updateScript = $false
    }
  } else {
      Write-Host ("No Script found named `"" + $scriptName + "`".")
      Write-Host "This appears to be a new script."
      $newScript = $true
  }
  if ( $newScript -eq $true ) {
    Write-Host ("Creating `"" + $scriptName + "`".")
    try { New-CMScript -ScriptFile $_.FullName -ScriptName $scriptName -fast }
    catch {
      Write-Host "An error occurred:"
      Write-Host $_
      exit 1
    }
    Write-Host ("Uploaded `"" + $scriptName + "`".")
  } elseif ( $updateScript -eq $true -And $checksumMismatch -eq $true ) {
    Write-Host ("Updating `"" + $scriptName + "`".")
    try { Set-CMScript -ScriptGuid $scriptGuid -ScriptFile $_.FullName }
    catch {
      Write-Host "An error occurred:"
      Write-Host $_
      exit 1
    }
    Write-Host ("Updated `"" + $scriptName + "`" (GUID: " + $scriptGuid + ").")
  }
}
