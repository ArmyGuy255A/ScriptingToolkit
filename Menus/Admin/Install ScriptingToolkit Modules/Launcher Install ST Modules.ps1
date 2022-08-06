##############################################
# Written By: CW2 Dieppa, Phillip A.         #
# On: 02 APR 2019                            #
# 173rd IBCT                                 #
# This script installs the modules required  #
# for independent menu generation.           #
# Rights Required: WA			             #
##############################################

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

#This function imports the config.json data within the script
if ($configData -eq $null) {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory

    #get the config file's Fully Qualified name to pass into the Get-ConfigData
    $configFQName = Get-ChildItem -Path ..\..\..\Config\config.json | Select-Object FullName
    #load the config.json
    $configData = @{}
    $configData = Get-ConfigData $configFQName.FullName.ToString()
} else {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory
}
#endregion

Clear-Host
$UserPSModulePath = "$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules\ScriptingToolkit"


if (!$(Test-Path $UserPSModulePath)) {
    Write-Host "Creating $UserPSModulePath..." -ForegroundColor Yellow
    New-Item $UserPSModulePath -ItemType Directory -Force | out-Null
} else {
    Write-Host "Emptying $UserPSModulePath..." -ForegroundColor Yellow
    Get-ChildItem $UserPSModulePath -Recurse | Remove-Item
}

$libraries = Get-ChildItem ((Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName + "\Libraries")

foreach ($script in $libraries) {
    Write-Host "Copying $($script.FullName)..." -ForegroundColor DarkYellow
    Copy-Item $script.FullName -Destination ($UserPSModulePath + "\" + $script.Name) -Force
}

$modules = Get-ChildItem $UserPSModulePath -Name

[string]$STModule = ""
foreach ($module in $modules) {
    $STModule += ". `$PSScriptRoot\$module`n" 
}

Write-Host "Generating Module..." -ForegroundColor Yellow
$STModule | Out-File ($UserPSModulePath + "\ScriptingToolkit.psm1")

Get-Module ScriptingToolkit | Remove-Module
Import-Module ScriptingToolkit -Verbose

Write-Host "`n`nScripting Toolkit modules installed successfully.`n`n" -ForegroundColor Green

Write-Host "Scripting Toolkit Commands" -ForegroundColor Cyan
Get-Module -Name ScriptingToolkit | Select-Object -ExpandProperty ExportedCommands | Sort-Object

Show-STPromptForAnyKey