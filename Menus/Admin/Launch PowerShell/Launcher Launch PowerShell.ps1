#############################################
# Written on 05 JAN 2018                    #
# By: CW2 Dieppa, Phillip A.                #
# Simply launches a powershell window       #
# Rights Required: WA, OA  		            #
#############################################

#region Parameters
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    $configData
)

#This function imports the common libraries for use throughout every script.
function Get-STCommonDirectory () {
    $notFound = $true
    $libraryDirectory = $PSScriptRoot
    while ($notFound) {
        #Iterate through the directories until STCommon.ps1 is found.
        Set-Location $libraryDirectory
        $STCommon = Get-ChildItem -Path Libraries\STCommon.ps1 -ErrorAction:SilentlyContinue
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

#This function imports the config.json data within the script
if ($configData -eq $null) {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory

    #get the config file's Fully Qualified name to pass into the Get-ConfigData
    $configFQName = Get-ChildItem -Path Config\config.json | Select-Object FullName
    #load the config.json
    $configData = @{}
    $configData = Get-ConfigData $configFQName.FullName.ToString()
} else {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory
}
#endregion


Start-Process powershell 
