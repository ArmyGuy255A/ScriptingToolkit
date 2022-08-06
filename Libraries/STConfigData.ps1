function Find-ScriptLauncher {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Directory, 
        [Parameter()]
        [switch]
        $RecurseUp
    )
    $launcher = Get-ChildItem -Path $Directory -Filter Launcher.ps1 

    if ($null -ne $launcher) {
        return $launcher
    } elseif ($RecurseUp) {
        $path = (Get-Item -Path $Directory)
        Find-ScriptLauncher -Directory $path.Parent.Fullname
    }
}

function Get-ScriptRoot {
    $launcher = $null
    if ([string]::IsNullOrEmpty($PSScriptRoot)) {
        $launcher = Find-ScriptLauncher -Directory (Get-Location | Get-Item).FullName -RecurseUp
    } else {
        $path = Get-Item -Path $PSScriptRoot
        $launcher = Find-ScriptLauncher -Directory $path.Parent.FullName -RecurseUp
    }
    
    return $launcher.Directory
}

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
    $serverConfigData = (Get-ConfigData ($configData.UpdateDirectory + "\config\config.json"))

    #Update the config.json file
    #Using Get-Content in paranthesis ensures we examine the entire document as a whole instead of line-by-line. This helps when replacing a specific value such as a verison number.
    (Get-Content $configFile) -replace $configData.Version, $serverConfigData.Version | Set-Content $configFile

    #TODO:WORK ON REMOVING OLD CONFIG DATA
    #Clean up old keys on the user's config data that are not in the server's config data
    foreach ($key in $configData.keys) {
        #Write-Host "$key exists"
        if (!$serverConfigData.Contains($key)) {
            Write-Host "Found an unnecessary key [$key]. Removing from config file." -ForegroundColor Yellow
            $serverConfigData.Item($key) = $configData.Item($key)

            #Delete the key and valuesfrom the config.json file
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

function Get-ObjectNoteProperties ($object) {
    return ($object | Get-Member) | Where MemberType -eq NoteProperty | Select -ExpandProperty Name
}

function Add-MemberToJson ($jsonObject, $key, $value) {
    $jsonObject | Add-Member -Name $key -MemberType NoteProperty -Value $value
}

function Migrate-ConfigData ($configData, $configFQName) {
    #load the server's config data
    $serverConfigData = @{}
    $serverConfigData = (Get-ConfigData ($configData.UpdateDirectory + "\config\config.json"))
    
    #Compare the server's config data with the user's config data. If they're different, add the fields that are missing from the server.
    $serverMembers = Get-ObjectNoteProperties -object $serverConfigData
    $localMembers = Get-ObjectNoteProperties -object $configData
    foreach ($key in $serverMembers) {
        #Write-Host "$key exists"
        if (!$localMembers.Contains($key)) {
            Write-Host "Found a missing key [$key]. Adding to config file." -ForegroundColor Yellow
            Add-MemberToJson -jsonObject $configData -key $key -value $serverConfigData.$key
        }
    }

    #Remove any double line breaks
    $configData | ConvertTo-Json -Depth 10 | Set-Content $configFQName -NoNewline
}


function Check-ConfigVersion ($configData) {
    
    #Fetch the version in the UpdateFolder and compare it to the current version
    $serverConfigData = @{}
    $updateDirectory = $configData.UpdateDirectory + "\config\config.json"

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
    #Major versions trigger a complete update. The config.json file is backed up and migrated to the newest version.
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
    
    $updateData = @($currentVersion, $serverVersion, $result)

    return $updateData
}

Function Test-ConfigFile ($ConfigFile) {
    if (Test-Path -Path $ConfigFile) {
        Write-Verbose "Config file detected."
    } else {
        Write-Verbose "Config file not present. Detected first-time use"
        #Copy the template over
        $root = Get-ScriptRoot
        $configTemplate = Join-Path $root "Templates/config.json"
        $configPath = Join-Path $root "Config/config.json"
        Copy-Item $configTemplate $configPath
    }
}

Function Get-ConfigData {
    [CmdletBinding()]
    param (
        [string]
        $ConfigFile
    )

    #Ensure the data exists, if not, create a new config.json file

    Test-ConfigFile $ConfigFile

    $configData = Get-Content $ConfigFile | ConvertFrom-Json

    return $configData
}