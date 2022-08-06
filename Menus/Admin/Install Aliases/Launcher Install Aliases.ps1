##############################################
# Written By: CW2 Dieppa, Phillip A.         #
# On: 27 FEB 2018                            #
# 173rd IBCT                                 #
# This script disables all user accounts     #
# that are in the compliance groups. The     #
# script allows the user to select a         #
# frequency at which the accounts will be    #
# disabled.                                  #
#                                            #
# Rights Required: WA			             #
##############################################

#region Parameters

#region Parameters
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    $configData
)

function Get-ToolkitFile {
  [CmdletBinding()]
  param (
      [Parameter()]
      [string]
      $Directory = ".",
      [Parameter()]
      [string]
      $File,
      [Parameter()]
      [switch]
      $RecurseUp
  )
  $tkFile = Get-ChildItem -Path $Directory -Filter $File -Depth 1 -ErrorAction Ignore

  if ($null -ne $tkFile) {
      return $tkFile
  } elseif ($RecurseUp) {
      $path = (Get-Item -Path $Directory)
      Get-ToolkitFile -Directory $path.Parent.Fullname -File $File -RecurseUp
  }
}

# Note, ensure RecurseUp is enabled if this function is called below the root directory
if ($null -eq $configData) {
    $configData =  Get-ToolkitFile -File "Config/config.json" -RecurseUp | Get-Content -Encoding utf8 | ConvertFrom-Json 
  }
  
#This imports the common libraries for use throughout every script.
$stCommon = Get-ToolkitFile -File "Libraries/STCommon.ps1" -RecurseUp
. $stCommon.FullName
#endregion

Clear-Host
$pshellProfile = Get-ToolkitFile -File "Templates/Microsoft.PowerShell_profile.ps1" -RecurseUp

if (Test-Path $PROFILE) {
    #Profile exists, inject functions into existing profile
    
    #Check if functions already exist
    $profileContent = Get-Content $PROFILE -Raw
    if (!$profileContent -or !$profileContent.Contains("Set-Alias tk")) {
        Get-Content $pshellProfile.FullName -Raw | Add-Content $PROFILE
    }
} else {
    #Profile doesn't exist, create it
    New-Item $PROFILE -Force | Out-Null
    Copy-Item $pshellProfile $PROFILE -Force
}

#Update the TK root directory.
(Get-Content $PROFILE) -replace '<st directory>', ((Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName) | Set-Content $PROFILE


Write-Host "The following aliases have been installed: ras, sudo, c2, wa, oa, tk" -ForegroundColor Yellow

Show-STPromptForAnyKey