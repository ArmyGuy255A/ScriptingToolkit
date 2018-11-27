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

#endregion

#region Initialization

#endregion

#region Globals

#Available Error Actions: {Continue | Ignore | Inquire | SilentlyContinue | Stop | Suspend}
$ErrorActionPreference = 'Continue'

#endregion

#region Functions

Function Test-Cmdlet() {
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

#endregion

