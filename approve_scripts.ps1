<#

    .SYNOPSIS
    Approves scripts in Microsoft Endpoint Configutation Manager

    .DESCRIPTION
   This  PowerShell script will iterate through all ps1 files in mecm_scripts/ and approve them.


#>

$SiteCode = "XXX"

Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
cd ${SiteCode}:
$scriptIndex = Get-CMScript -Fast
if ($scriptIndex.Count -ne 0) {
  Write-Host ("Successfully downloaded " + $scriptIndex.Length + " existing scripts from MECM")
} else {
  Write-Host ("Script download returned "+ $scriptIndex.Length + "scripts. This is likely not right. Halting.")
  exit 1
}
Get-ChildItem "${env:CI_PROJECT_DIR}\mecm_scripts" -Filter *.ps1 | 
Foreach-Object {
  Remove-Variable unsetName -ErrorAction SilentlyContinue
  Clear-Variable newScript -ErrorAction SilentlyContinue
  Clear-Variable updateScript -ErrorAction SilentlyContinue
  Write-Host "-------------"
  write-host ("Working on " + $_.Name)
  $scriptContent = Get-Content $_.FullName
  $locateName = select-string -Path $_.FullName -Pattern '^\s*#*\s*Function:\s*(.*)$' -AllMatches
  if ($locateName.Matches.Count -gt 0){
    $scriptName = $locateName.Matches.Groups[1].value
    write-host ("Located script name: " + $scriptName)
  } else {
    write-host ("Script name not set in script (see README.md), using `"" + $_.Name + "`"")
    $unsetName = $true
    $scriptName = $_.Name
  }
  $findName = $scriptIndex -match $scriptName
  $findFile= $scriptIndex -match $_.Name
  if ( $findName.Length -ne 0 -And -Not $unsetName -eq $true ) {
    if ( $findName.Length -gt 1 ) {
      Write-Host ("WARNING: multiple scripts named: " + $scriptName + ". Approving first match.")
    }
    $updateScript = $true
    $scriptGuid = $findName[0].ScriptGuid
    $scriptName = $findName[0].ScriptName
    
  } else {
    if( $unsetName -ne $true ) {
      Write-Host ("No Script found named `"" + $scriptName + "`".")
    }
    if ($findFile.Length -ge 1 ) {
      if ($findFile.Length -gt 1 ) {
        Write-Host ("WARNING: multiple scripts named: " + $_.Name + ". Approving first match.")
      }
      $approveScript = $true
      $scriptGuid = $findFile[0].ScriptGuid
      $scriptName = $findFile[0].ScriptName
    } elseif ( $findFile.Length -eq 0 ) {
      Write-Host ("No Script found named `"" + $_.Name + "`".")
      Write-Host "Script must be uploaded before being approved.  Run `"install_scripts.ps1`""
    }
  }
  
  if ( $approveScript -eq $true) {
    Write-Host ("Approving `"" + $scriptName + "`".")
    try { Approve-CMScript -ScriptGuid $scriptGuid -Comment "Approved via GitLab-CI" }
    catch {
      Write-Host "An error occurred:"
      Write-Host $_
      exit 1
    }
    Write-Host ("Approved `"" + $scriptName + "`" (GUID: " + $scriptGuid + ").")
  }
}