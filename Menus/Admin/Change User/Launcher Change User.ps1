#requires -version 5

<#
.SYNOPSIS
This script is designed to change user accounts using a username/password or a smartcard credential

.DESCRIPTION
A menu presents the option to change users using a username/password or a smartcard.

.EXAMPLE
<MANDATORY: Replace this with an example>

.EXAMPLE
<OPTIONAL: Replace this with an additional example>

.NOTES
Window Mode: Windowed
Rights Required: WA, OA
Author: CW2 Dieppa, Phillip A.
Author Email: mrdieppa@gmail.com
Date Created: 05 JAN 2018
Version: 1.0.0

.LINK
'https://microsoft.visualstudio.com/M365%20Security%20and%20Compliance/_git/ScriptingToolkit'

#>

#Allow the script to accept $configData from any other script in the toolkit
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
            #Move up a directory and keep searching
            Set-Location ..
            $libraryDirectory = Get-Location
        } else {
            #Found STCommon.ps1 - Return the directory
            $notFound = $false
            return $STCommon[0].FullName

        }
    }
}

#This function checks the status of the seclogon service that's required to switch users.
function Test-SecLogon () {

    $color = "Yellow"
    $seclogon = Get-Service seclogon
    switch ($seclogon.Status) {
        "Stopped" {  
            $color = "red"
        }
        Default {
            $color = "green"
        }
    }

    Write-Host "The Secondary Logon (seclogon) service is: " -NoNewline
    Write-Host ("[{0}]" -f $seclogon.Status.ToString().ToUpper()) -ForegroundColor $color
}

#This config.json data within the script
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
#Return back to the script's execution directory.
Set-Location $PSScriptRoot
#endregion
$ErrorActionPreference = 'Stop'

$result = -1

while ($result -eq -1) {
    #logonType - 0 = smartcard and 1 = username/password
    $logonType = 0
    $logonChoices = @("Smartcard User", "Username / Password")
    
    $logonType = Show-STMenu -Title "Change User" -Choices $logonChoices -Custom "Cancel"
    
    if ($logonType -ieq "C") {
        #Cancel 
        Exit
    } else {
        #Subtract 1 from the result because we're dealing with an array.
        $logonType -= 1

        #Find Launcher.ps1
        $notFound = $true
        $LauncherScriptDirectory = $PSScriptRoot
        $Launcher = ""
        while ($notFound) {
            #Iterate through the directories until Launcher.ps1 is found.
            Set-Location $LauncherScriptDirectory
            $Launcher = Get-Item -Path Launcher.ps1 -ErrorAction:SilentlyContinue
            if (!$Launcher) {
                #Move up a directory and keep searching
                Set-Location ..
                $LauncherScriptDirectory = Get-Location
            } else {
                #Found STCommon.ps1 - Return the directory
                $notFound = $false
                $Launcher =  $Launcher[0].FullName
                Set-Location $PSScriptRoot
            }
        }
        Clear-Host
        if ($logonType -eq 0) {
            #Run the /smartcard option
            try {
                runas /smartcard "powershell -Command 'Start-Process -Credential $credential powershell -ArgumentList '-NoExit -Command & $Launcher''"
            } catch {
                Test-SecLogon
            }
            
        } else {
            #Run the /user option
            $username = Show-STReadHostMenu -Title "Enter Username" -Prompt "Username" -Info @("Hint     ","Include the domain with the username", "Example 1", "username@contoso.com", "Example 2", "CONTOSO\username")
            if (!$configData.DebugMode) {     Clear-Host }
            $password = Show-STReadHostMenu -Title "Enter Password" -Prompt "Password" -AsSecureString
            $credential = New-Object System.Management.Automation.PSCredential($username, $password)

            #runas /user:$username "powershell -Command & '$Launcher'"
            try {
                Start-Process -Credential $credential powershell -ArgumentList "-NoExit -Command & $Launcher" -WorkingDirectory "C:\Windows\System32"

            } catch {
                Test-SecLogon                
            }
        }
        
        Show-STPromptForAnyKey
    } 
}