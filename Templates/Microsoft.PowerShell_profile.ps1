<#
Place this script in the following directory for your user accounts.
C:\users\user\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#>

function runas-smartcard {
runas /smartcard powershell
}

function super-user {
start-process powershell -verb runas
}

function start-mmc {
mmc.exe
}

function start-toolkit {
& '<st directory>\Launcher.ps1'
}

$ScriptBlockToolkit = {
    toolkit
}

function workstation-admin {
super-user
start-process powershell -verb runas -ArgumentList "-Command & {$ScriptBlockToolkit}"
exit
}

function ou-admin {
start-mmc
start-process powershell -ArgumentList "-Command & {$ScriptBlockToolkit}"
}

function Copy-ADGroupPermission {
    $sourceADUser = $null
    $destADUser = $null

    While (!$sourceADUser) {
        try {
            $sourceUser = Read-Host "Please type the source user's pre-Windows 2000 logon name"
            $sourceADUser = Get-ADUser $sourceUser -Properties MemberOf
        } catch {
            $sourceADUser = $null
        }
    }

    while (!$destADUser) {
        try {
            $destUser = Read-Host "Please type the destination user's pre-Windows 2000 logon name"
            $destADUser = Get-ADUser $destUser -Properties MemberOf
        } catch {
            $destADUser = $null
        }
    }

    $sourceADUser.MemberOf | Where {$destADUser.MemberOf -notcontains $_} | Add-ADGroupMember -Members $destADUser

}

Set-Alias ras runas-smartcard -Description "Enables a user to start powershell using a smartcard credential"
Set-Alias sudo super-user -Description "Attempts to elevate permissions on a powershell window"
Set-Alias c2 start-mmc -Description "Starts the administrator MMC"
Set-Alias tk start-toolkit -Description "Launches the scripting toolkit"
Set-Alias wa workstation-admin -Description "Launches the tools for a WA"
Set-Alias oa ou-admin -Description "Launches the tools for an OA"