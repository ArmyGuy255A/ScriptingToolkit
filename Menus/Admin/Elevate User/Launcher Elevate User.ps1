#############################################
# Written on 05 JAN 2018                    #
# By: CW2 Dieppa, Phillip A.                #
# This script is designed to simply change  #
# the user account using a smartcard        #
# credential. This script will not elevate  #
# the toolkit                               #
# Windowed				                    #
# Rights Required: WA, OA  		            #
#############################################

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
    }
    elseif ($RecurseUp) {
        $path = (Get-Item -Path $Directory)
        Get-ToolkitFile -Directory $path.Parent.Fullname -File $File -RecurseUp
    }
}
  
# Note, ensure RecurseUp is enabled if this function is called below the root directory
if ($null -eq $configData) {
    $configData = Get-ToolkitFile -File "Config/config.json" -RecurseUp | Get-Content | ConvertFrom-Json 
}
    
#This imports the common libraries for use throughout every script.
$stCommon = Get-ToolkitFile -File "Libraries/STCommon.ps1" -RecurseUp
. $stCommon.FullName
#endregion


$launcher = (Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName
try {
    Start-Process powershell -Verb runas -ArgumentList "-NoExit -Command & $Launcher"
}
catch {
    Write-Warning "Insufficient permissions."
    Sleep 5
}

