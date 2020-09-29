<#

  .SYNOPSIS
  Approves scripts in Microsoft Endpoint Configutation Manager

  .DESCRIPTION
  This PowerShell script will iterate through all ps1 files in mecm_scripts/ and approve them as needed.

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
  Write-Host ("Successfully downloaded " + $scriptIndex.Length + " existing scripts from MECM")
} else {
  Write-Host ("Script download returned "+ $scriptIndex.Length + "scripts. This is likely not right. Halting.")
  exit 1
}
Get-ChildItem "${env:CI_PROJECT_DIR}\mecm_scripts" -Filter *.ps1 | 
Foreach-Object {
  foreach ($var in "findName","escapedScriptName","scriptName","scriptGuid","newScript","updateScript")
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
      Write-Host ("WARNING: multiple scripts named: " + $scriptName + ". Approving first match.")
    }
    if ( $findName[0].ApprovalState -eq 0 ) {
      Write-Host "Script awaiting approval, running approval command."
      $approveScript = $true
      $scriptGuid = $findName[0].ScriptGuid
    } else {
      Write-Host "Script not awaiting approval, skipping."
      $approveScript = $false
    }
  } else {
    Write-Host ("No Script found named `"" + $scriptName + "`".")
  }
  
  if ( $approveScript -eq $true) {
    $gitAuthor = git log -n 1 --pretty=format:"%an" $_.FullName
    if ( $gitAuthor ) {
      $lastMod = ", last modified by ${gitAuthor}."
    } else {
      $lastMod = "."
    }
    Write-Host ("Approving `"" + $scriptName + "`".")
    try { Approve-CMScript -ScriptGuid $scriptGuid -Comment "Approved via GitLab-CI${lastMod}" }
    catch {
      Write-Host "An error occurred:"
      Write-Host $_
      exit 1
    }
    Write-Host ("Approved `"" + $scriptName + "`" (GUID: " + $scriptGuid + ").")
  }
}