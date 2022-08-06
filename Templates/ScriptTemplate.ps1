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
    $configData
)

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

# Note, ensure RecurseUp is enabled if this function is called below the root directory
if ($null -eq $configData) {
  $configData =  Get-ToolkitFile -File "Config/config.json" -RecurseUp | Get-Content -Encoding utf8 | ConvertFrom-Json 
}

#This imports the common libraries for use throughout every script.
$stCommon = Get-ToolkitFile -File "Libraries/STCommon.ps1" -RecurseUp
. $stCommon.FullName
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

