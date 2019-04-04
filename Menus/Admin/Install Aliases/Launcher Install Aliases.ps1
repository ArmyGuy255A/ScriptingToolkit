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
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [hashtable]$configData
)

#This function imports the common libraries for use throughout every script.
function Get-STCommonDirectory () {
    $notFound = $true
    $libraryDirectory = $PSScriptRoot
    while ($notFound) {
        #Iterate through the directories until STCommon.ps1 is found.
        Set-Location $libraryDirectory
        $STCommon = Get-ChildItem -Path ..\..\..\Libraries\STCommon.ps1 -ErrorAction:SilentlyContinue
        if (!$STCommon) {
            Set-Location ..
            $libraryDirectory = Get-Location
        } else {
            #Found STCommon.ps1 - Return the directory
            $notFound = $false
            return $STCommon[0].FullName

        }
    }
}

#This function imports the config.ini data within the script
if ($configData -eq $null) {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory

    #get the config file's Fully Qualified name to pass into the Get-ConfigData
    $configFQName = Get-ChildItem -Path ..\..\..\Config\config.ini | Select-Object FullName
    #load the config.ini
    $configData = @{}
    $configData = Get-ConfigData $configFQName.FullName.ToString()
} else {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory
}
#endregion

Clear-Host
$pshellProfile = $configData.ToolRootDirectory + "\Templates\Microsoft.PowerShell_profile.ps1"

if (Test-Path $profile) {
    #Profile exists, inject functions into existing profile
    
    #Check if functions already exist
    $profileContent = Get-Content $profile -Raw
    if (!$profileContent -or !$profileContent.Contains("Set-Alias tk")) {
        Get-Content $pshellProfile -Raw | Add-Content $profile
    }
} else {
    #Profile doesn't exist, create it
    New-Item $profile -Force | Out-Null
    Copy-Item $pshellProfile $profile -Force
    (Get-Content $profile) -replace '<st directory>', ($configData.ToolRootDirectory) | Set-Content $profile
}

Write-Host "The following aliases have been installed: ras, sudo, c2, wa, oa, tk" -ForegroundColor Yellow

pressAnyKeyToContinue