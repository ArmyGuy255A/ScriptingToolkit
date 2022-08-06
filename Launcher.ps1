#requires -version 5


<#
.SYNOPSIS
The Launcher.ps1 is the starting point for the Scripting Toolkit. The launcher can be customized
to any environment. This script looks for folders in the 'Menus' directory, and scripts in any
subdirectories

.DESCRIPTION
This script should be used to interact with the Scripting Toolkit

.EXAMPLE
PS C:\ScriptingToolkit> .\Launcher.ps1

.LINK
'https://github.com/ArmyGuy255A/ScriptingToolkit'

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    $configData
)

Set-Location $PSScriptRoot

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
      return Get-ToolkitFile -Directory $path.Parent.Fullname -File $File -RecurseUp
  }
}

#This imports the common libraries for use throughout every script.
$stCommon = Get-ToolkitFile -File "Libraries/STCommon.ps1" -RecurseUp
. $stCommon.FullName

#get the config file's Fully Qualified name to pass into Get-ConfigData
$configFQName = Join-Path (Get-Location) "Config/config.json"

#load the config data
Test-ConfigFile $configFQName
$configData = @{}
$configData = Get-ConfigData $configFQName

#make the log directory
if (!$(Test-Path $configData.LogDirectory)) { 
    mkdir $configData.LogDirectory | Out-Null
}

$LauncherLogFile = $configData.LogDirectory + "\Launcher.log"

#Create the log file.
Write-STLog -Message $("Started " + $configData.ToolkitName) -OutFile $LauncherLogFile

#Check for an update
$versionInfo = @()
$menuItems = @()

Function mainMenuAction ($result) {
    if ($result -ieq "a") {
        #Admin menu
        $directoryChoices = Get-ActiveScripts -Path ".\Menus\Admin"
        Write-STLog -Message "Showing STMenu: Admin Tools" -OutFile $LauncherLogFile 
        $result = Show-STMenu -Title "Admin Tools" -Choices $directoryChoices.Choices -Exit -Back -TitleColor Green -BorderColor White -ItemColor Yellow
        Write-STLog -Message "Show-STMenu result: $result" -OutFile $LauncherLogFile 
        if ($result -ieq "e") {
            #Close the log file entry.
            Write-STLog -Message $("Closed " + $configData.ToolkitName + " from Admin Tools") -OutFile $LauncherLogFile
            exit
        } elseif ($result -ieq "b") {
            #do nothing, and exit the loop naturally
        } else {
            #Run the script in the folder
            & $directoryChoices.Directories[$result - 1].FullName
        }
        
        return
    } elseif ($result -ieq "b") {
        return
        #Back action
    } elseif ($result -ieq "e") {
        #Exit action.
        #Close the log file entry.
        Write-STLog -Message $("Closed " + $configData.ToolkitName + " from Main Menu") -OutFile $LauncherLogFile
        exit
    }

    #Value is definitely an integer.
    $result = [int]$result - 1

    #Determine the total number of Folders and subtract the number of non-folder items.
    $folderItems = $menuItems.Count
    if ($configData.EnableUpdates) {
        $folderItems -= 1
    }
    if ($configData.EnableAdminUploader) {
        $folderItems -= 1
    }

    #Proceed to the Menus folder submenus.
    if ($result -ge 0 -and $result -lt $folderItems) {
        #Do specific things in directories here.
        $directory = Get-Item ".\Menus\$($menuItems[$result])"

        #Just show the directory contents
        Write-STLog -Message "Showing STMenu: $($directory.Name)" -OutFile $LauncherLogFile 
        #Navigate through the folder structure.
        Show-STDirectoryScriptMenu -Path $directory
        Write-STLog -Message "Skipping the result" -OutFile $LauncherLogFile 

    } elseif ($menuItems[$result].Contains("Update")) {

        if ($updateAvailable.Contains("!!!")) {
            Write-STLog -Message "Updating Toolkit." -OutFile $LauncherLogFile | Write-STAlert
            #Update Available
            $logName = "Update" + $versionInfo[1].Major + "-" + $versionInfo[1].Minor + "-" + $versionInfo[1].Revision
            $logDir = $configData.LogDirectory + "\Updates\$logName.log"

            <#Update Guidelines:
                Major versions trigger a complete update. The config.json file is backed up and migrated to the newest version, plus any minor and revision changes are made.
                Minor versions trigger an update to .ps1 files and their dependencies such as CSV files. If a CSV file changes, it triggers a minor update
                Revision versions trigger an update to only existing .ps1 files. If the code is corrected without notice to the user, it's a revision
            #>
            #Write-Output "Breakpoint!"
            #Determines the type of update that will be performed. Major, Minor, or Revision
            if ($versionInfo[0].Major -lt $versionInfo[1].Major) {
                #Major Update
                robocopy $configData.UpdateDirectory.ToString() (Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName.ToString() *.ps1 *.csv *.jpg *.exe /R:3 /W:5 /TEE /ETA /S /XD Development HBSS SharePoint Workstations inactive* /XF config.json

                #Schema could have changed during the major revision. Transfer the current config data to the serverConfigData format and update the config.json file with the changes.
                Migrate-ConfigData $configData $configFQName
                Write-STLog -Message "Loosely migrated config.json Data." -OutFile $LauncherLogFile 

                #The delay helps ensure the files are not being accessed during the next step
                delayInSeconds(1)

                #Update Revision number in config.json file
                Update-ConfigVersion $configData $configFQName
           
            } elseif ($versionInfo[0].Minor -lt $versionInfo[1].Minor) {
                #Minor Update
                robocopy $configData.UpdateDirectory.ToString() (Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName.ToString() *.ps1 *.csv *.jpg *.exe /R:3 /W:5 /TEE /ETA /S /XD Development HBSS SharePoint Workstations inactive* /XF config.json

                #Update Revision number in config.json file
                Update-ConfigVersion $configData $configFQName

            } elseif ($versionInfo[0].Revision -lt $versionInfo[1].Revision) {
                #Revision Update
                <#
                /R:3  - Retry limit to 3
                /W:5  - Wait time between retries (in seconds)
                /TEE  - Log output to console
                /ETA  - Display estimated time of arrival
                /S    - Copy subdirectories but not empty ones
                /LOG: - Create a log file
                /XD   - Exclude Directories
                *.ps1 - Only copy .ps1 files
                #>
                robocopy $configData.UpdateDirectory.ToString() (Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName.ToString() *.ps1 *.jpg /R:3 /W:5 /TEE /ETA /S /XD Development HBSS SharePoint Workstations inactive* /XF config.json

                #Update Revision number in config.json file
                Update-ConfigVersion $configData $configFQName
            } 
            Write-STLog -Message "Toolkit Updated." -AlertType Success -OutFile $LauncherLogFile | Write-STAlert
        } else {
            #No update Available.
        }
    } elseif ($menuItems[$result].Contains("Upload")) {

        #Present a menu to update the config.json file's revision number
        $title = "Upload Wizard"
        $choices = @("Publish Major Version", 
        "Publish Minor Version",
        "Publish Revision")
        $versionText1 = "Clients perform a complete update. The config.json file is backed up and migrated to the newest version, plus any minor and revision changes are made."
        $versionText2 = "Clients perform an update to .ps1 files and their dependencies such as CSV files. If a CSV file format changes, it should be a minor update"
        $versionText3 = "Revision versions trigger an update to only existing .ps1 files. If the code is corrected without operational impact to the user, it's a revision"
        $info = @("Major Versions", $versionText1, "Minor Versions", $versionText2, "Revisions", $versionText3)

        #Set the result of the menu to 0 and continue looping until a valid value is passed.
        $result = 0
        while ($result -eq 0) {
            Write-STLog -Message "Showing STMenu: $title" -OutFile $LauncherLogFile
            $result = Show-STMenu $title $choices $info -Back
            Write-STLog -Message "Show-STMenu Result: $result" -OutFile $LauncherLogFile

            if ($result -ieq "b") {
                continue
            } 

            #Automatically update the config.json file
            switch ($result) {
                1 {
                    #Major Versions
                    Write-STLog -Message "Incrementing config.json Major Version" -OutFile $LauncherLogFile
                    Increment-ConfigVersion $configData $configFQName 1
                }

                2 {
                    #Minor Versions
                    Write-STLog -Message "Incrementing config.json Minor Version" -OutFile $LauncherLogFile
                    Increment-ConfigVersion $configData $configFQName 2
                }

                3 {
                    #Revisions
                    Write-STLog -Message "Incrementing config.json Revision" -OutFile $LauncherLogFile
                    Increment-ConfigVersion $configData $configFQName 3
                }

            }

            #Delete old data at the server's directory
            try {
                Write-STLog -Message "Deleting contents at: $($configData.UpdateDirectory)" -OutFile $LauncherLogFile
                Remove-Item -Path ($configData.UpdateDirectory.ToString() + "\*") -Force -Recurse
                Write-STLog -Message "Deleted contents at: $($configData.UpdateDirectory)" -AlertType Success -OutFile $LauncherLogFile
            } catch {
                Write-STLog -Message "Failed to delete contents at: $($configData.UpdateDirectory)" -AlertType Failure -OutFile $LauncherLogFile
            }
            

            #Upload the toolkit to the server
            try {
                Write-STLog -Message "Uploading toolkit to: $($configData.UpdateDirectory)" -OutFile $LauncherLogFile
                robocopy  (Get-ToolkitFile -File "Launcher.ps1" -RecurseUp).FullName.ToString() $configData.UpdateDirectory.ToString() * /R:3 /W:5 /TEE /ETA /S /XD Development Temp Test Logs inactive* logs /XF *.log *.csv *.xls *.xlsx
                Write-STLog -Message "Uploaded toolkit to: $($configData.UpdateDirectory)" -AlertType Success -OutFile $LauncherLogFile
            } catch {
                Write-STLog -Message "Failed to upload toolkit to: $($configData.UpdateDirectory)" -AlertType Failure -OutFile $LauncherLogFile
            }
            

            Start-Sleep -Seconds 2
        }

    }

}

Function main {
    #Main Loop
    while (!$exitMain) {
    #Sometimes, other scripts may change the present working directory. Set the location just in case.
    
    Set-Location $PSScriptRoot
    $configData = Get-ConfigData $configFQName

        #Show the main menu
        $result = 0
        
        $menuItems = @()

        $title = $configData.ToolkitName

        #Get the folder names in the Menus folder. Create the Menu system based on this value.
        Write-STLog -Message "Populating Menus subdirectory. Excluding the Admin folder" -AlertType Success -OutFile $LauncherLogFile
        $folders = Get-ChildItem Menus -Directory -Exclude Admin
        foreach ($folder in $folders) {
            $menuItems += $folder.Name
        }

        #Check for an update
        $updateAvailable = ""
        if ($configData.EnableUpdates) {
            Write-STLog -Message "Updates Enabled. Checking for update." -AlertType Success -OutFile $LauncherLogFile
            $versionInfo = Check-ConfigVersion $configData
            $updateAvailable = $versionInfo[2]
            $menuItems += "$updateAvailable"
            if ($configData.EnableAdminUploader) {
                Write-STLog -Message "Uploader Enabled. Adding 'Admin Uploader' to the menu system" -AlertType Success -OutFile $LauncherLogFile
                $menuItems += "Upload Toolkit (Admin Only)"
            } else {
                Write-STLog -Message "Uploader Disabled. Skipping." -OutFile $LauncherLogFile
            }
        } else {
            Write-STLog -Message "Updates Disabled. Skipping." -OutFile $LauncherLogFile
        }

        $info = @("Toolkit Version", $configData.Version.Trim(), "Currently Runninng As", $($env:USERDOMAIN + "\" + $env:USERNAME))
        $result = 0
        #Write-Host $menuItems
        Write-STLog -Message "Showing STMenu: $title" -OutFile $LauncherLogFile
        $result = Show-STMenu -Title $title -Choices $menuItems -Info $info -Exit -Custom "Admin Tools"

        Write-STLog -Message "Show-STMenu Result: $result" -OutFile $LauncherLogFile

        #Process the result from the menu
        mainMenuAction($result)
    }
}

#Check for admin rights
if (!$configData.DebugMode) {
    Clear-Host
}

If ($ExecutionContext.SessionState.LanguageMode -ine "ConstrainedLanguage" -and -NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $choices = @("&Elevate Credentials","&Current Credentials") 
    $prompt = "WARNING: This toolkit may require different/elevated credentials in order to work properly`nDo you want to try elevating to Local Administrator before proceeding?`n`nCurrently running as: $($env:USERDOMAIN + "\" + $env:USERNAME)"
    $userchoice = Show-STPromptForChoiceMenu -Title "Elevate Credentials" -Prompt $prompt -Choices $choices -Default 1
    Write-STLog -Message "Option Selected: $($choices[$userchoice])" -OutFile $LauncherLogFile 
    #Determine action to take  
    switch ($userchoice) {  
        "E" {  
            #Attempt to elevate the user
            $launcher = $PSScriptRoot + "\Launcher.ps1"
            try {
                #Write-Host $launcher
                Write-STLog -Message "Attempting to Elevate user: $env:username to local admin." -OutFile $LauncherLogFile
                Start-Process powershell -Verb runas -ArgumentList "-NoExit -Command & $launcher"
                Write-STLog -Message "Elevated user: $env:username to local admin." -AlertType Success -OutFile $LauncherLogFile
            } catch {
                Write-STLog -Message "Unable to elevate the user. Entering the toolkit as a normal user." -AlertType Warning -OutFile $LauncherLogFile | Write-STAlert
                Start-Sleep -Seconds 2
                main
            }
        }  
        "C" {  
            #Continue using current credentials  
            Write-STLog -Message "Not attempting to elevate credentials." -OutFile $LauncherLogFile
            main
        }  
    }  
} else {
    main
}