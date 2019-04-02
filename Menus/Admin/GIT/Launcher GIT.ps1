#requires -version 5

<#
.SYNOPSIS
This script Commits, Pushes, and Pulls the latest files from the git repository located in the Config.ini file

.EXAMPLE
Sync-STGitRepo

.NOTES
Must have GIT installed on the local machine in order to work.

.LINK
https://microsoft.visualstudio.com/M365 Security and Compliance/M365 Security and Compliance Team/_git/ScriptingToolkit

#>

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

#This function imports the config.ini data within the script
if ($configData -eq $null) {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory

    #get the config file's Fully Qualified name to pass into the Get-ConfigData
    $configFQName = Get-ChildItem -Path Config\config.ini | Select-Object FullName
    #load the config.ini
    $configData = @{}
    $configData = Get-ConfigData $configFQName.FullName.ToString()
} else {
    #Import the STCommon.ps1 libraries
    $STCommonDirectory = Get-STCommonDirectory
    . $STCommonDirectory
}
#endregion

#region Initialization

#Set Error Action to Silently Continue
$ErrorActionPreference = 'Stop'
Set-Location $configData.ToolRootDirectory
#endregion

#region Globals
$logFile = $configData.LogDirectory + "\GIT\GIT.log"
#endregion

#region Functions

Function Sync-STGitRepo() {
<#
.SYNOPSIS
This cmdlet performs a Commit, Push, and Pull operation for the $configData.ToolRootDirectory

.DESCRIPTION
The

.EXAMPLE
Sync-STGitRepo -URL "https://microsoft.visualstudio.com/M365 Security and Compliance/M365 Security and Compliance Team/_git/ScriptingToolkit" -Directory $configData.ToolRootDirectory

.EXAMPLE
Sync-STGitRepo -URL "https://microsoft.visualstudio.com/M365 Security and Compliance/M365 Security and Compliance Team/_git/ScriptingToolkit" -Directory C:\ScriptingToolkit

.NOTES
Must have GIT installed on the local machine in order to work.

.LINK
https://microsoft.visualstudio.com/M365 Security and Compliance/M365 Security and Compliance Team/_git/ScriptingToolkit

#>

  Param (
  [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string]$URL,
    
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string]$Directory, 

    [Parameter(Mandatory=$False, ValueFromPipeline=$True)]
    [string]$GITExecutablePath=$null 
  )

  Begin {
    #Call any code before the pipeline object is processed here.
    Write-STLog -Message "START OF SCRIPT" -OutFile $logFile
  }

  Process {
    Try {
        #Test if GIT is installed
        $gitInfo = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation | Where-Object {$_.DisplayName -match 'git'}

        #Abort the function if git is not installed
        if (!$gitInfo -and !$GITExecutablePath) {
            Write-STAlert -Message "GIT is not installed. Install the option GIT dependency listed in the README.md" -AlertType Error -OutFile $logFile
            return 1
        }


        #Set the location for git.exe
        if (!$GITExecutablePath) {
            #use the installLocation from the registry
            $GITExecutablePath = $gitInfo.InstallLocation + "bin\git.exe"
        } else {
            #Ensure \Git is within the executable path
            if ($GITExecutablePath -match '\\Git(.*)') {
                #Now, replace everything after the provided \Git directory and force the use of 'bin\git.exe'
                $GITExecutablePath = $GITExecutablePath -replace '\\Git(.*)', '\Git\bin\git.exe'
            }
        }

        #Ensure git.exe is located in the directory path
        if (!(Test-Path $GITExecutablePath)) {
            Write-STAlert -Message "git.exe not found in \Git\bin" -AlertType Error
            return 1
        }
        
        #TODO: Add logic to increment the config version automatically before pushing and pulling from the repo.

        $masterChanges = $null
        try {
            & $GITExecutablePath fetch 
        }
        catch {
            Write-STAlert -Message "Captured Master Changes"
            
        }

        $masterChanges = & $GITExecutablePath diff HEAD...origin --name-only
        
        #Use a while loop instead of an if statement so the script can break out after any necessary submenu actions like prompting yes or no.
        while ($masterChanges) {

            #Get all of the changes in the master directory
            $changesInfo = & $GITExecutablePath diff HEAD...origin --shortstat --numstat -C $configData.ToolRootDirectory
            #Parse through the change information and format it nicely for the STMenu
            $info = ""            
            foreach ($item in $changesInfo) {
                $info += "`n" + $item.Trim()
            }
            Write-STAlert -Message "Master has changed: $info" -OutFile $logFile

            #Display a confirmation menu
            $result = Show-STMenu -Title "Master changed. Do you want to PULL?" -MenuType YesNo -Info @("Information", $info)
            if ($result -ieq "n") {
                #exit the loop
                Write-STAlert -Message "User skipped pulling from Master" -OutFile $logFile
                break
            }

            #Pull the files
            try {
                $response = & $GITExecutablePath -C $configData.ToolRootDirectory merge
                Write-STAlert -Message "Pulled From Master: $response" -AlertType Success -OutFile $logFile
                $masterChanges = $null
            } catch {
                if ($PSItem.Exception -match 'from http') {
                    #This is actually where the success alerts come from. For some reason, powershell interprets git.exe exit action as an error.
                    Write-STAlert -Message "Pulled From Master: $changesInfo" -AlertType Success -OutFile $logFile
                    $masterChanges = $null
                } else {
                    Write-STAlert -Message $PSItem.Exception -OutFile $logFile
                }
            }
        }

        #Determine any changes on the local machine
        $branchChanges = $null
        try {
            $branchChanges = & $GITExecutablePath diff master --name-only -C $configData.ToolRootDirectory
        }
        catch {
            Write-STAlert -Message "Captured Branch Changes"
        }
        
        #Build the overall length for the commitMessage used to ensure messages do not exceed a certain length
        $maxCharacterLength = 72
        $commitMessage = ""
        for ($x = 0 ; $x -le 72; $x++) {
            $commitMessage += " "
        }

        #Use a while loop instead of an if statement so the script can break out after any necessary submenu actions like prompting yes or no.
        while ($branchChanges) {
            
            #Get all of the changes on the branch directory
            $changesInfo = & $GITExecutablePath diff master --shortstat --numstat -C $configData.ToolRootDirectory
            #Parse through the change information and format it nicely for the STMenu
            $info = ""            
            foreach ($item in $changesInfo) {
                $info += "`n" + $item.Trim()
            }
            Write-STAlert -Message "Branch has changed: $info" -OutFile $logFile

            #Display a confirmation menu
            $result = Show-STMenu -Title "Branch Changed. Do you want to PUSH?" -MenuType YesNo -Info @("Information", $info)
            if ($result -ieq "n") {
                #exit the loop
                Write-STAlert -Message "User skipped pushing to Master" -OutFile $logFile
                break
            }

            #Read user input and only accept messages whose length is > 0 and <= 72
            while ($commitMessage.Length -gt 72 -or $commitMessage.Length -lt 1) {
                if ($configData.DebugMode -ine "on") {     Clear-Host }
                $commitMessage = Show-STReadHostMenu -Title "Commit Message" -Prompt "Enter a commit message ($maxCharacterLength MAX characters)"
                $commitMessage = $commitMessage.Trim()
                if ($configData.DebugMode -ine "on") {     Clear-Host }
            }

            #Stage the files
            try {
                $response = & $GITExecutablePath -C $configData.ToolRootDirectory add .
                Write-STAlert -Message "Staged all files: $response" -AlertType Success -OutFile $logFile
            } catch {
                Write-STAlert -Message $PSItem.Exception -OutFile $logFile
            }

            #Commit the files
            try {
                $response = & $GITExecutablePath -C $configData.ToolRootDirectory commit -a -m $commitMessage
                Write-STAlert -Message "Committed all files: $response" -AlertType Success -OutFile $logFile
            } catch {
                Write-STAlert -Message $PSItem.Exception -OutFile $logFile
            }

            #Push the files
            try {
                $response = & $GITExecutablePath -C $configData.ToolRootDirectory push
                Write-STAlert -Message "Pushed To Master: $response `n $changesInfo" -AlertType Success -OutFile $logFile
                $branchChanges = $null
            } catch {
                if ($PSItem.Exception -match 'to http') {
                    #This is actually where the success alerts come from. For some reason, powershell interprets git.exe exit action as an error.
                    Write-STAlert -Message "Pushed To Master: $changesInfo" -AlertType Success -OutFile $logFile
                    $branchChanges = $null
                } else {
                    Write-STAlert -Message $PSItem.Exception -OutFile $logFile
                }
                
            }

        }

        #Generate final alert / log messages to indicate status of script

        if ($masterChanges) { 
            Write-STAlert -Message "Master has changes" -AlertType Warning -OutFile $logFile
        }

        if ($branchChanges) {
            Write-STAlert -Message "Branch has pending changes" -AlertType Warning -OutFile $logFile
        }

        if (!$branchChanges -and !$masterChanges) {
            Write-STAlert -Message "Branch / Master Synchronized" -AlertType Success -OutFile $logFile
        }  
    }

    Catch {
        #Process any error handling here.
        Write-STAlert -Message $("An error occurred in function: $($MyInvocation.MyCommand)") -AlertType Error -OutFile $logFile
        Write-STAlert -Message $PSItem.Exception -AlertType Error -OutFile $logFile
        $invocationInfo = "`n" + $PSItem.InvocationInfo.PositionMessage | Out-String
        Write-STAlert -Message $invocationInfo -AlertType Error -OutFile $logFile
    }
  }

  End {
    If ($?) {
        #Call any code after the pipeline objects are processed here.
        #Write-Host "The Process block Completed Successfully"
        Write-STLog -Message "END OF SCRIPT" -OutFile $logFile
    } else {
        #Write-Host "The Process Block Failed"
    }
  }
}
#endregion

#region Execution


Try {
    #Launch the function
    if ($configData.GITEnabled -ieq "true") {
        Sync-STGitRepo -URL $configData.GITRepository -Directory $configData.ToolRootDirectory
    }   
}

Catch {
  #Process any error handling here.
}

#endregion