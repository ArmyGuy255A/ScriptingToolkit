#requires -version 5

<#
.SYNOPSIS
<MANDATORY: Replace this with a short overview>

.DESCRIPTION
<OPTIONAL: Replace this with a description of the INPUTs and OUTPUTs>

.EXAMPLE
<MANDATORY: Replace this with an example>

.EXAMPLE
<OPTIONAL: Replace this with an additional example>

.NOTES
<OPTIONAL: Replace this with a any additional information or custom launch options>
Window Mode: {NewWindow | CurrentWindow | HiddenWindow}
Rights Required: WA, OA, SA, DA, EA
Author: <Name>
Author Email: <Email>
Date Created: <Date>
Version: <X.X.X>

.LINK
<OPTIONAL: Replace this with a URL or library dependencies>

#>

#region Parameters

#Allow the script to accept $configData from any other script in the toolkit
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

#This config.ini data within the script
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
#Return back to the script's execution directory.
Set-Location $PSScriptRoot
#endregion

#region Initialization

#endregion

#region Globals

#Available Error Actions: {Continue | Ignore | Inquire | SilentlyContinue | Stop | Suspend}
$ErrorActionPreference = 'Stop'

#endregion

#region Functions

Function Test-Function() {
<#
.SYNOPSIS
<MANDATORY: Replace this with a short overview>

.DESCRIPTION
<OPTIONAL: Replace this with a description of the INPUTs and OUTPUTs>

.EXAMPLE
<MANDATORY: Replace this with an example>

.EXAMPLE
<OPTIONAL: Replace this with an additional example>

.NOTES
<OPTIONAL: Replace this with a any additional information>

.LINK
<OPTIONAL: Replace this with a URL or library dependencies>

#>

  Param (
  [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [Array]$files 
  )

  Begin {
    #Call any code before the pipeline object is processed here.
  }

  Process {
    Try {
        foreach ($file in $files) {
          Write-Host $file.FullName -ForegroundColor Green
        }
    }

    Catch {
      #Process any error handling here.
      Write-Host "ERROR: in function: $($MyInvocation.MyCommand)" -ForegroundColor Red
    }
  }

  End {
    If ($?) {
      #Call any code after the pipeline objects are processed here.
      Write-Host "The Process block Completed Successfully"
    } else {
      Write-Host "The Process Block Failed"
    }
  }
}
#endregion

#region Execution


Try {

  #Get-Help Copy-AdUserPermission
  Write-Host "Example Get-Help"
  Get-Help Test-Function -Full

  #Example Piped Usage
  Write-Host "Example Piped Usage"
  Get-ChildItem | Test-Function

  #Example Standard Usage
  Write-Host "Example Standard Usage:"
  Test-Function $(Get-ChildItem)

}

Catch {
  #Process any error handling here.
}

#endregion

