#requires -version 5

<#
.SYNOPSIS
This script provides all of the logging functions for the Scripting Toolkit.

.DESCRIPTION
This library contains cmdlets that outputs alerts, warnings, errors, and informational messages
to log files and the console.

.EXAMPLE
Get-Help Backup-STFile
Get-Help Write-STLog
Get-Help Write-STAlert

.NOTES
AUTHOR: Phillip A. Dieppa
EMAIL: mrdieppa@gmail.com
VERSION: 1.0.0
DATE: 2018-10-31

#>

#region Initialization

#endregion

#region Globals
if ($ExecutionContext.SessionState.LanguageMode -ine 'ConstrainedLanguage') {
Add-Type -TypeDefinition @"
   public enum AlertType
   {
      Success,
      Failure,
      Informational,
      Warning,
      Error
   }
"@
}
#endregion

#region Functions
Function Backup-STFile() {
  <#
  .SYNOPSIS
  This cmdlet creates a backup of the specified file
  
  .DESCRIPTION
  This cmdlet copys a source file to a target directory and renames the log to a numbered sequence.
  
  .EXAMPLE
  Backup-STFile -SourceFile c:\ScriptingToolkit\Config\config.json
  
  .EXAMPLE
  Backup-STFile -SourceFile c:\ScriptingToolkit\Config\config.json -DestinationDirectory c:\ScriptingToolkit\Config\ConfigBackups
  
  #>
  
  Param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [System.IO.FileInfo]$SourceFile,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [string]$DestinationDirectory=$null

  )

  Begin {
    #Input validation.

    #Test the source file
    if (!$(Test-Path $SourceFile)) { 
      Write-STAlert -Message "$SourceFile does not exist" -AlertType Warning
      continue
    }

    #Test the destination directory. If it is null, use the file's directory.
    if ($DestinationDirectory.Length -eq 0) { 
      $DestinationDirectory = $SourceFile.Directory.ToString()
    } 

    #Test the destination directory path
    if (!$(Test-Path $DestinationDirectory)) { 
      New-Item $DestinationDirectory -ItemType Directory -Force | Out-Null
      Write-STAlert -Message "Created $DestinationDirectory" -AlertType Informational
    }

    #Remove any "\" from the end of the destination directory
    if ($DestinationDirectory.EndsWith("\")) {
        $DestinationDirectory = $DestinationDirectory -replace "(\\)(?=$|\\)", ""
    }

  }

  Process {
  
    Try {
      #Get all of the files in the destination directory
      $files = Get-Item $($DestinationDirectory + "\" + $SourceFile.BaseName + "-*")

      [string]$newFileName = $null
      if ($files.Count -eq 0) {
          $newFileName = $SourceFile.BaseName + "-1.bak"
      } else {
          $newFileName = $SourceFile.BaseName + "-" + ($files.Count + 1) + ".bak"
      }

      Copy-Item $SourceFile -Destination $($DestinationDirectory + "\$newFileName") | Out-Null

    }
    Catch {
      #Process any error handling here.
      Write-Host "ERROR: in function: $($MyInvocation.MyCommand)" -ForegroundColor Red
    }
  }

  End {
    If ($?) {
      #Call any code after the pipeline objects are processed here.
      #Write-Host "The Process block Completed Successfully"
    } else {
      #Write-Host "The Process Block Failed"
    }
  }
}

Function Write-STLog() {
  <#
  .SYNOPSIS
  Writes an entry to a .log file. Log files can have a maximum size of 5MB. Log files are backed up using the Backup-STFile cmdlet. The backup log
  files are stored in the $OutFile's root directory.
  
  .DESCRIPTION
  Writes entries and alerts to a .log file
  
  .EXAMPLE
  Write-STLog -Message "Account not found" -OutFile "C:\ScriptingToolkit\Logs\AccountCreation\AccountCreation.log"
  This command is the basic format required to run this cmdlet
  
  .EXAMPLE
  Write-STLog -Message "Account not found" -AlertType Warning -OutFile "C:\ScriptingToolkit\Logs\AccountCreation\AccountCreation.log"
  This command creates an entry in the log file and produces a Warning entry.
  
  .EXAMPLE
  Write-STLog -Message "Account not found" -AlertType Warning -OutFile "C:\ScriptingToolkit\Logs\AccountCreation\AccountCreation.log" | Write-STAlert
  This command creates an entry in the log file and also generates an STAlert in the console window.
  
  .EXAMPLE
  $logInfo = Write-STLog -Message "Account not found" -AlertType Warning -OutFile "C:\ScriptingToolkit\Logs\AccountCreation\AccountCreation.log" | fl
  This example stores an STAlertInfo object into $logInfo. [STAlertInfo] contains the Message, AlertType, OutFile, Append, and WithTimeStamp parameters
  
  
  #>
  
  Param (
    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
      [string[]]$Message,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [string]$AlertType="Informational",

    [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
      [string]$OutFile,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [bool]$Append=$true,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [bool]$WithTimestamp=$true,

    [Parameter(Mandatory=$False, ValueFromPipeline=$True)]
      [hashtable]$PipelineInput=$null
  )

  Begin {
    #Input validation.

    #Test the file patch
    if (!$(Test-Path $OutFile)) { 
      #Write-Host "Making Log Directory"
      New-Item $OutFile -Force| Out-Null
    }

    $File = Get-Item $OutFile

    #Test the file size and back it up if it is over 5MB
    if (($File.Length / 1024) -ge 5120) {
      #Backup the file
      Backup-STFile $File

      #Set append to false
      $Append = $false
    }
  }

  Process {
    if ($PipelineInput) {
        $Message = $PipelineInput.Message
        $OutFile = $PipelineInput.OutFile
        $Append = $PipelineInput.Append
        $AlertType = $PipelineInput.AlertType
        $WithTimestamp = $PipelineInput.WithTimestamp
    }

  [string]$messagePrefix = $null
  
  Try {
      switch ($AlertType) {
        "Success" {  
          $messagePrefix = "SUCCESS"
                      
        }
        "Failure" {  
          $messagePrefix = "FAILURE"
          
        }
        "Informational" {  
          $messagePrefix = "INFORMATIONAL"
          
        }
        "Warning" {  
          $messagePrefix = "WARNING"
          
        }
        "Error" {  
          $messagePrefix = "ERROR"
          
        }
        Default {}
      }
      #Build the Log entry
      [string]$entry = ""

      #Write the prefix
      if ($WithTimestamp) {
        $entry += $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "; "
      }

      if ($null -ne $messagePrefix) {
        $entry += $messagePrefix + "; "
      }

      $entry += $Message
      if ($Append) {
        Out-File -FilePath $File -InputObject $entry -Encoding ASCII -Append
      } else {
        Out-File -FilePath $File -InputObject $entry -Encoding ASCII
      }
      #write-host ($PSCmdlet.MyInvocation |out-string)


    }
    Catch {
      #Process any error handling here.
      Write-Host "ERROR; in function: $($MyInvocation.MyCommand)" -ForegroundColor Red
      Write-Host $PSItem.Exception
    }
  }

  End {
    If ($?) {
      #Call any code after the pipeline objects are processed here.
      #Write-Host "The Process block Completed Successfully"
      if ($PSCmdlet.MyInvocation.PipelineLength -gt 1 -and $PSCmdlet.MyInvocation.PipelinePosition -lt $PSCmdlet.MyInvocation.PipelineLength) {
        $Object = @{
                      "Message" =  $Message
                      "AlertType" = $AlertType
                      "OutFile" = $OutFile
                      "WithTimestamp" = $WithTimestamp
                      "Append" = $Append
                  }
        return $Object
      }
            

    } else {
      #Write-Host "The Process Block Failed"
    }
  }
}

Function Write-STAlert() {
<#
.SYNOPSIS
Prints an alert in the console window. Optionally outputs to a .log file.

.DESCRIPTION
Writes in informational, alert, warning, or error message to the console.

.EXAMPLE
Write-STAlert -Message "Account Created" -AlertType Success
Output: 2018-05-30 18:10:08 : SUCCESS : Account Created

.EXAMPLE
Write-STAlert -Message "Account Not Found" -AlertType Failure
Output: 2018-05-30 18:10:08 : FAILURE : Account Not Found

.EXAMPLE
Write-STAlert -Message "Account Exists" -AlertType Informational
Output: 2018-05-30 18:10:08 : INFORMATIONAL : Account Exists

.EXAMPLE
Write-STAlert -Message "Account Deleted" -AlertType Warning
Output: 2018-05-30 18:10:08 : WARNING : Account Deleted

.EXAMPLE
Write-STAlert -Message "Account Corrupted" -AlertType Error
Output: 2018-05-30 18:10:08 : ERROR : Account Corrupted

.EXAMPLE
Write-STAlert "Account Exists"
Output: 2018-05-30 18:10:08 : INFORMATIONAL : Account Exists

.EXAMPLE
Write-STAlert "Account Exists" -WithTimestamp $false
Output: INFORMATIONAL : Account Exists

.EXAMPLE
Write-STAlert -Message $errorMessage -AlertType Warning -OutFile c:\logs\alert.log
Generates an alert in the console window and logs the alert using the Write-STLog cmdlet

#>

  Param (
    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [string[]]$Message,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [AlertType]$AlertType=[AlertType]::Informational,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [string]$OutFile,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [bool]$Append=$true,

    [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
      [bool]$WithTimestamp=$true,

    [Parameter(Mandatory=$False, ValueFromPipeline=$True)]
      [hashtable]$PipelineInput=$null
  )

  Begin {
    #Input validation.
  }

  Process {
    if ($PipelineInput) {
        $Message = $PipelineInput.Message
        $OutFile = $PipelineInput.OutFile
        $Append = $PipelineInput.Append
        $AlertType = $PipelineInput.AlertType
        $WithTimestamp = $PipelineInput.WithTimestamp
    }
    [string]$messagePrefix
    [ConsoleColor]$messagePrefixBackgroundColor = [ConsoleColor]::White
    [ConsoleColor]$messagePrefixForegroundColor = [ConsoleColor]::White

    Try {
        switch ($AlertType) {
          Success {  
            $messagePrefix = "SUCCESS"
            $messagePrefixBackgroundColor = [ConsoleColor]::DarkGreen
            $messagePrefixForegroundColor = [ConsoleColor]::White
            
          }
          Failure {  
            $messagePrefix = "FAILURE"
            $messagePrefixBackgroundColor = [ConsoleColor]::Red
            $messagePrefixForegroundColor = [ConsoleColor]::White

          }
          Informational {  
            $messagePrefix = "INFORMATIONAL"
            $messagePrefixBackgroundColor = [ConsoleColor]::White
            $messagePrefixForegroundColor = [ConsoleColor]::Black

          }
          Warning {  
            $messagePrefix = "WARNING"
            $messagePrefixBackgroundColor = [ConsoleColor]::Yellow
            $messagePrefixForegroundColor = [ConsoleColor]::Black

          }
          Error {  
            $messagePrefix = "ERROR"
            $messagePrefixBackgroundColor = [ConsoleColor]::DarkRed
            $messagePrefixForegroundColor = [ConsoleColor]::White

          }
          Default {}
        }
        #Write the prefix
        if ($WithTimestamp) {
          Write-Host $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") "; " -NoNewLine
        }
        Write-Host $messagePrefix -ForegroundColor $messagePrefixForegroundColor -BackgroundColor $messagePrefixBackgroundColor -NoNewline
        Write-Host " ; $message"
        
        if ($OutFile -and $PSCmdlet.MyInvocation.PipelinePosition -eq 1) {
            Write-STLog -Message $Message -AlertType $AlertType -OutFile $OutFile -Append $Append
        }

    }

    Catch {
      #Process any error handling here.
      Write-Host "ERROR; in function: $($MyInvocation.MyCommand)" -ForegroundColor Red
      Write-Host $PSItem.Exception
    }
  }

  End {
    If ($?) {
      #Call any code after the pipeline objects are processed here.
      #Write-Host "The Process block Completed Successfully"
      if ($PSCmdlet.MyInvocation.PipelineLength -gt 1 -and $PSCmdlet.MyInvocation.PipelinePosition -lt $PSCmdlet.MyInvocation.PipelineLength) {
        $Object = @{
                      Message =  $Message
                      AlertType = $AlertType
                      OutFile = $OutFile
                      WithTimestamp = $WithTimestamp
                      Append = $Append
                  }
        return $Object
      }
    } else {
      #Write-Host "The Process Block Failed"
    }
  }
}
#endregion

#region Execution


#endregion