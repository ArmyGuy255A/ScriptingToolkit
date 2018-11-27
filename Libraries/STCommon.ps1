#requires -version 5
<#
.SYNOPSIS
    This script should be called in each script within the toolkit. See the README.md for more
    information on how to integrate this script.

.DESCRIPTION
    This script references the other libraries required for use within the toolkit. This script
    also contains common functions that are used throughout the environment.

.INPUTS
    This script does not have any inputs

.OUTPUTS None
    This script does not have any outputs

.NOTES
    Version:        1.0
    Author:         Phillip A. Dieppa
    Creation Date:  27 JUL 2014
    Purpose/Change: Changed the comment section of the script.

.EXAMPLE
    
    Example 1: 
    if ($configData -eq $null) {
    cd $PSScriptRoot
    . "..\..\Libraries\Common.ps1"

    #get the config file's Fully Qualified name to pass into the Get-ConfigData
    $configFQName = Get-ChildItem -Path ..\..\Libraries\Config.ini | Select-Object FullName
    #load the Config.ini
    $configData = @{}
    $configData = Get-ConfigData $configFQName.FullName.ToString()
    } else {
    cd $PSScriptRoot
    . "..\..\Libraries\Common.ps1"
    }

    Example 2:
    . "Libraries\Common.ps1"
#>
#use dot-notation to include libraries.
. "$PSScriptRoot\STConfigData.ps1"
. "$PSScriptRoot\STCryptography.ps1"
. "$PSScriptRoot\STMenuSystem.ps1"
. "$PSScriptRoot\STLogging.ps1"
. "$PSScriptRoot\CustomCmdlets.ps1"
. "$PSScriptRoot\CustomFunctions.ps1"

<#
.RETURNS
Returns an Array of FileInfo objects and String objects with active scripts
#>
Function Get-ActiveScripts ([string]$Path, [int]$Depth=1) {

    $potentialDirectories = Get-ChildItem $Path -Filter Launcher*.ps1 -Depth $Depth
    
    if (!$potentialDirectories) {
        return $null
    }
        
    
    $directories = @()
    $choices = @()
    

    #Iterate through each directory and extract the actual title of the script's folder
    foreach ($launcherScript in $potentialDirectories) {
        try {
            #Verify that a valid script is located in the directory.
            #$launcherScript = Get-ChildItem $directory -Filter "launch*.ps1"
            if ($launcherScript.count -eq 1) {
                #Search for the required permissions in each script
                #$searchResult = $(Select-String $launcherScript -pattern "Rights Required").ToString()
                #$rightsRequired = $searchResult.Substring($searchResult.LastIndexOf(":")+1, $searchResult.LastIndexOf(" ") - $searchResult.LastIndexOf(":")).trim()
                #Add the permissions required to the end of each script. 
                #$choices += $directory.BaseName.Split("-")[1].Trim() + " [$rightsRequired]"
                $choices += $launcherScript.Name.ToString().Replace("Launcher","").Replace(".ps1","").Trim()
                $directories += $launcherScript
            } else {
                #TODO: I don't think I need to cleanup here, but maybe I should throw an error.
                Write-Warning "Unspecified error..."
            }
                
        } catch {
        }
    }
    $returnResult = @{"Directories" = $directories; "Choices" = $choices}
    return $returnResult

}
Function ConvertFrom-ArrayToHashtable ($array, $hashtable) {
    foreach ($item in $array) { 
        $hashtable.add($item,$null)
    }
    return $hashtable
}

Function Clear-Hashtable ($hashtable) {
    $hashtableClone = $hashtable.clone()

    foreach ($key in $hashtableClone.Keys) {
        $hashtable[$key] = $null
    }
    return $hashtable
}

Function Convert-HashtableToCSV ($array, $hashtable) {
    $string = $null
    foreach ($item in $array) { 
        $string += ($hashtable[$item] + ",")
    }
    $string = $string.TrimEnd(",")
    return $string
}

Function Convert-ArrayToCSVHeaders ($array) {
    $string = $null
    foreach ($item in $array) { 
        $string += ($item + ",")
    }
    $string = $string.TrimEnd(",")
    return $string
}

function Select-Folder($message='Select a folder', $path = 0) {  
    $object = New-Object -comObject Shell.Application  
    $folder = $object.BrowseForFolder(0, $message, 0, $path)
      
    if ($null -ne $folder) {    
        $folder.self.Path  
    }
    return $folder
}

Function delayInSeconds ($seconds) {
#This function will delay the script by the number of seconds passed into the argument
    <#
    $y = 1000
    while ($x -le ($y * $seconds)) {
        $x += 1        
    }
    #>

    for ($a=$seconds; $a -gt 1; $a--) {
      $percent = [int]$(100 - (($a / $seconds) * 100))
      Write-Progress -Activity "Waiting..." -SecondsRemaining $a -CurrentOperation "$percent% complete" -Status "Time"
      Start-Sleep 1
    }


    #Sleep $seconds
}


Function Get-FileName() {
    <#
    .SYNOPSIS
    <MANDATORY: Replace this with a short overview>
    
    .DESCRIPTION
    <OPTIONAL: Replace this with a description of the INPUTs and OUTPUTs>
    
    .EXAMPLE
    <MANDATORY: Replace this with a short overview>
    
    .NOTES
    <OPTIONAL: Replace this with a any additional information>
    
    .LINK
    <OPTIONAL: Replace this with a URL or library dependencies>
    
    #>
    
      Param (
      [string]$initialDirectory, 
      [decimal]$title, 
      [array]$filterOption)
    
      Begin {
        #Write-LogInfo -LogPath $sLogFile -Message '<description of what is going on>...'
      }
    
      Process {
        Try {
          #Filters: 0 = CSV, 1 = TXT, 2 = JPG, 3 = AES
            $filters = @("CSV (*.csv)| *.csv",
            "TXT (*.txt)| *.txt"
            "JPG (*.jpg)| *.jpg"
            "AES (*.aes)| *.aes"
            )
            [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.initialDirectory = $initialDirectory
            $OpenFileDialog.filter = $filters[$filterOption]
            $OpenFileDialog.Title = $title
            $OpenFileDialog.ShowDialog() | Out-Null
            $OpenFileDialog.filename
            }
    
        Catch {
          #Write-LogError -LogPath $sLogFile -Message $_.Exception -ExitGracefully
          #Break
        }
      }
    
      End {
        If ($?) {
          #Write-LogInfo -LogPath $sLogFile -Message 'Completed Successfully.'
          #Write-LogInfo -LogPath $sLogFile -Message ' '
        }
      }
    }

Function LoadExchangeSnapin {
    if (! (Get-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction:SilentlyContinue) ) {
        Write-Host "Loading the Exchange Management Snap-In's." -ForegroundColor Green
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
        Write-Host "Loaded..." -ForegroundColor Green
    } else {
        Write-Host "Exchange Management Snap-In's Previously Loaded..." -ForegroundColor Green
    }
}

Function LoadADModule {
    if (! (Get-Module ActiveDirectory -ErrorAction:SilentlyContinue) ) {
        Write-Host "Loading the Active Directory Module." -ForegroundColor Green
        Import-Module ActiveDirectory
        Write-Host "Loaded..." -ForegroundColor Green
    } else {
        Write-Host "Active Directory Module previously loaded...." -ForegroundColor Green
    }
}


Function getMailboxDatabaseNames ($exchangeServers) {
    $databases = @()
    #Get all the databases on each Exchange Server and display them.
    ForEach ($exchServer in $exchangeServers) {
        $dbObjects = Get-MailboxDatabase -Server $exchServer
        ForEach ($dbObject in $dbObjects) {
            #add the database string to the databases array.
            $databases += $dbObject.Name
        }
    }
    #Delete the duplicate database values
    $databases = $databases | Sort-Object -Unique
    return $databases
}

Function isComputerOnline($comp) {
    try {
       if ($(New-Object System.Net.NetworkInformation.Ping).Send($comp).Status -eq "Success") {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}


#############################################################################################
#External Independent Functions
#############################################################################################
Function Test-IsAdmin {  
<#     
.SYNOPSIS     
   Function used to detect if current user is an Administrator.  
     
.DESCRIPTION   
   Function used to detect if current user is an Administrator. Presents a menu if not an Administrator  
      
.NOTES     
    Name: Test-IsAdmin  
    Author: Boe Prox   
    DateCreated: 30April2011    
      
.EXAMPLE     
    Test-IsAdmin  
      
   
Description   
-----------       
Command will check the current user to see if an Administrator. If not, a menu is presented to the user to either  
continue as the current user context or enter alternate credentials to use. If alternate credentials are used, then  
the [System.Management.Automation.PSCredential] object is returned by the function.  
#>  
    [cmdletbinding()]  
    Param()  
      
    Write-Verbose "Checking to see if current user context is Local Administrator"  
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {  
        Write-Warning "You are not currently running this under a Local Administrator account! `nThere is potential that this command could fail if not running under an Administrator account."  
        Write-Verbose "Presenting option for user to pick whether to continue as current user or use alternate credentials"  
        #Determine Values for Choice  
        $choice = [System.Management.Automation.Host.ChoiceDescription[]] @("Use &Alternate Credentials","&Continue with current Credentials")  

        #Determine Default Selection  
        [int]$default = 0  
  
        #Present choice option to user  
        $userchoice = $host.ui.PromptforChoice("Warning","Please select to use Alternate Credentials or current credentials to run command",$choice,$default)  
  
        Write-Debug "Selection: $userchoice"  
  
        #Determine action to take  
        Switch ($Userchoice) {  
            0 {  
                #Prompt for alternate credentials  
                Write-Verbose "Prompting for Alternate Credentials"  
                $Credential = Get-Credential  
                Write-Output $Credential
            }  
            
            1 {  
                #Continue using current credentials  
                Write-Verbose "Using current credentials"  
                Write-Output "CurrentUser"  
            }  
        }          
          
    } Else {
        Write-Verbose "Passed Administrator check"  
    }  
}
