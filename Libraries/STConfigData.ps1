. "$PSScriptRoot\STMenuSystem.ps1"

function Increment-ConfigVersion ($configData, $configFile, $updateType) {
    #Update Types: 1 = Major, 2 = Minor, 3 = Revision

    $cv = $configData.Version.Split(".")
    $currentVersion = @{}
    $currentVersion.Major = $cv[0]
    $currentVersion.Minor = $cv[1]
    $currentVersion.Revision = $cv[2]
    switch ($updateType) {
        1 {
            [int]$currentVersion.Major += 1
            [int]$currentVersion.Minor = 0
            [int]$currentVersion.Revision = 0
        }

        2 {
            [int]$currentVersion.Minor += 1
            [int]$currentVersion.Revision = 0
        }

        3 {
            [int]$currentVersion.Revision += 1
        }
    }

    #Build the updated version
    $newVersion = [string]$currentVersion.Major + "." + [string]$currentVersion.Minor + "." + [string]$currentVersion.Revision

    #Update the configFile.
    (Get-Content $configFile) -replace $configData.Version, $newVersion | Set-Content $configFile
    $configData.Version = $newVersion

}

function Update-ConfigVersion ($configData, $configFile) {
    #Load the server's config data
    $serverConfigData = @{}
    $serverConfigData = (Get-ConfigData ($configData.UpdateDirectory + "\config\config.ini"))

    #Update the config.ini file
    #Using Get-Content in paranthesis ensures we examine the entire document as a whole instead of line-by-line. This helps when replacing a specific value such as a verison number.
    (Get-Content $configFile) -replace $configData.Version, $serverConfigData.Version | Set-Content $configFile

    #TODO:WORK ON REMOVING OLD CONFIG DATA
    #Clean up old keys on the user's config data that are not in the server's config data
    foreach ($key in $configData.keys) {
        #Write-Host "$key exists"
        if (!$serverConfigData.Contains($key)) {
            Write-Host "Found an unnecessary key [$key]. Removing from config file." -ForegroundColor Yellow
            $serverConfigData.Item($key) = $configData.Item($key)

            #Delete the key and valuesfrom the config.ini file
            (Get-Content $configFile) -replace ("["+$key+"]"), "" | Set-Content $configFile
            foreach ($value in $configData.Item($key)) {
                #Add-Content $configFile $value
                (Get-Content $configFile) -replace $value, "" | Set-Content $configFile
            }
            #Add-Content $configFile ""
            #Add-Content $configFile '#close'
        }
    }

    #Update the variable 
    $configData.Version = $serverConfigData.Version
}

function Migrate-ConfigData ($configData, $configFile) {
    #load the server's config data
    $serverConfigData = @{}
    $serverConfigData = (Get-ConfigData ($configData.UpdateDirectory + "\config\config.ini"))
    
    #Compare the server's config data with the user's config data. If they're different, add the fields that are missing from the server.
    foreach ($key in $serverConfigData.keys) {
        #Write-Host "$key exists"
        if (!$configData.Contains($key)) {
            Write-Host "Found a missing key [$key]. Adding to config file." -ForegroundColor Yellow
            $configData.Item($key) = $serverConfigData.Item($key)

            #Append the key and values to the end of the config.ini file
            #(Get-Content $configFile) -replace '#close', ("["+$key+"]") | Set-Content $configFile
            $configini
            Add-Content $configFile ""
            Add-Content $configFile $("["+$key+"]")
            foreach ($value in $serverConfigData.Item($key)) {
                Add-Content $configFile $value
            }
        }
    }

    #Remove any double line breaks
    (Get-Content config\config.ini -Raw) -replace "\n\s\n\s*\s*", "`n`n" | Set-Content $configFile -NoNewline
}


function Check-ConfigVersion ($configData) {
    
    #Fetch the version in the UpdateFolder and compare it to the current version
    $serverConfigData = @{}
    $updateDirectory = $configData.UpdateDirectory + "\config\config.ini"

    if (Test-Path $updateDirectory) {
        $serverConfigData = Get-ConfigData $updateDirectory
    } else {
        $serverConfigData = $configData
        #$serverConfigData.version = "0.0.0"
    }
    
    $cv = $configData.Version.Split(".")
    $sv = $serverConfigData.Version.Split(".")
    $currentVersion = @{}
    $serverVersion = @{}
    #Major versions trigger a complete update. The config.ini file is backed up and migrated to the newest version.
    $currentVersion.Major = $cv[0]
    $serverVersion.Major = $sv[0]
    #Minor versions trigger an update to missing directories and the contents within existing folders
    $currentVersion.Minor = $cv[1]
    $serverVersion.Minor = $sv[1]
    #Revision versions trigger an update to only existing .ps1 files
    $currentVersion.Revision = $cv[2]
    $serverVersion.Revision = $sv[2]

    $currentVersionNumeric = ([int]$currentVersion.Major * 1000) + ([int]$currentVersion.Minor * 100) + [int]$currentVersion.Revision
    $serverVersionNumeric = ([int]$serverVersion.Major * 1000) + ([int]$serverVersion.Minor * 100) + [int]$serverVersion.Revision

    $result = ""
    if ($serverVersionNumeric -gt $currentVersionNumeric) {
        #Update Available
        $result = "!!!Update Available - " + $serverVersion.Major + "." + $serverVersion.Minor + "." + $serverVersion.Revision
    } else {
        $result = "Up To Date"
    }
    

    <#
    #$v = (Get-Content .\config\version.txt | S).Split(".")
    $versionFile = ".\config\version.txt"
    $v = ((Get-Content $versionFile)[0]).Remove(0,1).Trim()
    #>
    $updateData = @($currentVersion, $serverVersion, $result)

    return $updateData
}

Function Test-ConfigFile ($configFile) {
    if ($null -eq $configFile) {
        #File doesn't exist.
        $result = Show-STMenu "Config.ini not found." @("Create Config.ini Template","Exit")
        switch ($result) {
                    1 {
                        $temp = 
"<#
Group headers are turned into variables within the configData variable. This
variable is passed to each script and loaded upon execution. The data located
in this config.ini file is available throughout the entire scripting toolkit.

You can safely add a new group by enclosing your group name between square
brackets similar to the groups below. For example, the UserAccountOU will be
available in the scripts as configData.UserAccountOU and so on.

Ensure the groups are separated by a single line and the end of the file
contains a close statement. If your config file becomes unstable or unusable,
simply delete the config.ini file and the toolkit will prompt you if you want
to generate a new config.ini.
#>

[ToolkitName]
The Scripting Toolkit

[Version]
1.0.0

[LogDirectory]
.\Logs

[EnableUpdates]
true

[UpdateDirectory]
C:\UpdateDirectory\ScriptingToolkit

[GITEnabled]
true

[GITRepository]
https://github.com/ArmyGuy255A/ScriptingToolkit

[EnableAdminUploader]
true
"
                        $temp | Out-File -FilePath "config\config.ini" -Confirm:$false -Force:$true
                     }   
        
                    2 {
                        exit
                    }

                    default {
                        if ($configData.DebugMode -ine "on") {     Clear-Host }
                        Test-ConfigFile
                    }

            }
    }
}

#Test the path on the configFile. If it doesn't exist, prompt to create one.
Function Read-ConfigData ($configFile, $searchString) {
    #This function will load data until it reaches a blank line following the config file
    $param = Select-String $configFile -Pattern $searchString.Replace("[", "\[").Replace("]","\]") | Select-Object LineNumber

    $val1 = ((Get-Content $configFile)[$param.LineNumber[-1]]).Trim()
    $val2 = ""
    try {
        $val2 = (Get-Content $configFile)[$param.LineNumber[-1] + 1]
        if ($val2) { $val2 = $val2.Trim() }
    } catch {
        #End of file.
        $val2 = ""
    }
    

    if ($val2.Length -gt 0 -and $val2.Contains("[") -eq $False) {
        #Keep going until we find the end of the block.
        $temp = @($val1, $val2)
        $lineNumber = $param.LineNumber[-1] + 2
        $cont = $true
        while ($cont -eq $true) {
            #if val2 contains text, it will need to be an array with multiple values.
            $val2 = $null
            $val2 = ((Get-Content $configFile)[$lineNumber])
            if ($val2) {
                $lineNumber++
                $temp += $val2.Trim()
                #Add the third line and continue incrementing.
            } else {
                $cont = $false
            }
        }
        return $temp
    } else {
        #It's a one line block, return it.
        return $val1
    }
}

Function Get-ConfigData ($configFile) {
    #Ensure the data exists, if not, create a new config.ini file
    Test-ConfigFile $configFile

    #Get all of the headers in the config.ini file
    $configFileHeaders = Select-String $configFile -Pattern "\[*\]" | Select-Object Line

    #Read the config file and populate the variable.
    $configData = @{}
    foreach ($dataHeader in $configFileHeaders) {
        $header = $dataHeader.line
        $configData.add($dataHeader.line.Substring(1, $dataHeader.line.Length - 2),(Read-ConfigData $configFile $header))
    }

    #Add the root script folder to the configData.
    $rootDir = Get-ChildItem $configFile | Select-Object Directory
    $configData.add("ToolRootDirectory", $($rootDir.directory.ToString() -replace '\\config', ""))

    return $configData
}
