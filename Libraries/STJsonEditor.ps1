#requires -version 5

<#
.SYNOPSIS
This script provides all of the JSON integrated functions for the Scripting Toolkit.

.DESCRIPTION
This library contains cmdlets that interacts with JSON files for use throughout the toolkit.

.EXAMPLE
#TODO Add examples

.NOTES
AUTHOR: Phillip A. Dieppa
EMAIL: mrdieppa@gmail.com
VERSION: 1.0.0
DATE: 2019-01-16

#>

#region Initialization

#endregion

#region Globals

#endregion

#region Functions
Function Show-STJsonEditor () 
{
    Param 
    (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [object]$jsonObject,
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$True)]
            [int]$jsonHeirarchyLevel=0
    )


    $jsonGroups = @()
    $jsonObject.PSObject.Properties | ForEach-Object {$jsonGroups += $_.Name}

    for ($x = 0; $x -lt $jsonGroups.Count; $x++) 
    {
        $buffer = $null
        0..($jsonHeirarchyLevel * 6) | ForEach-Object {$buffer += " "}

        if ($jsonObject.$($jsonGroups[$x]).GetType().Name -ieq "PSCustomObject") {
            $level = $jsonHeirarchyLevel + 1

            
            
            #This represents a new level in the heirarchy
            Write-Host $buffer $jsonGroups[$x] ": " -ForegroundColor White
            $jsonGroupValue = $jsonObject.$($jsonGroups[$x])
            Show-STJsonEditor $jsonObject.$($jsonGroups[$x]) -jsonHeirarchyLevel $level
        } else 
        {
            $propertyLabel = $buffer + $jsonGroups[$x] + " "
            Write-Host $propertyLabel ": " -NoNewLine -ForegroundColor White
            $jsonGroupValue = $jsonObject.$($jsonGroups[$x])
            Write-Host "[$jsonGroupValue]" -ForegroundColor Green -NoNewline
            Write-Host " : " -NoNewline -ForegroundColor White
        
            $result = $null
            $result = Read-Host

            #Confirm any changes
            $confirmed = $false
            if (!$result -or $result -ieq $jsonGroupValue) {
                $confirmed = $true
                $propertyLabelBuffer = ""
                0..($propertyLabel.Length + 1) |  ForEach-Object {$propertyLabelBuffer += " "} 
                Write-Host $propertyLabelBuffer "[$jsonGroupValue]" -ForegroundColor Green -NoNewline
                Write-Host " : " -NoNewline -ForegroundColor White
                Write-Host "Confirmed!" -ForegroundColor Green
            }

            while (!$confirmed) {
                $propertyLabelBuffer = ""
                0..($propertyLabel.Length + 1) |  ForEach-Object {$propertyLabelBuffer += " "} 
                Write-Host $propertyLabelBuffer "[$result]" -ForegroundColor Yellow -NoNewline
                Write-Host " : " -NoNewline -ForegroundColor White
        
                $confirmResult = $null
                $confirmResult = Read-Host

                if ($result -ne $confirmResult) {
                    if ($confirmResult) {
                        $result = $confirmResult
                    }
                    
                } else {
                    $confirmed = $true
                    $result = $confirmResult
                    $jsonObject.$($jsonGroups[$x]) = $confirmResult
                    Write-Host $propertyLabelBuffer "[$result]" -ForegroundColor Green -NoNewline
                    Write-Host " : " -NoNewline -ForegroundColor White
                    Write-Host "Confirmed!" -ForegroundColor Green

                }

            }

            #$jsonObject.$($jsonGroups[2])
            Write-Host ""
        }
        
    }

}

Function Edit-STJsonFile() 
{
  <#
  .SYNOPSIS
  Displays a guided menu to configure sections of a JSON object.
  
  .DESCRIPTION
  Displays a guided menu to configure sections of a JSON object.
  
  .EXAMPLE
  #TODO: Provide an example... 
  
  #>
  
    Param 
    (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [string]$jsonPath,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$True)]
            [string]$Title,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [ConsoleColor]$BorderColor=[ConsoleColor]::DarkYellow,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [ConsoleColor]$TitleColor=[ConsoleColor]::Yellow
    )

    Begin 
    {
        #Input validation.

        #Test the file path
        if (!$(Test-Path $jsonPath)) 
        { 
            Write-STAlert -AlertType Warning -Message "The JSON object could not be located."
            Exit            
        }
    }

    Process {
        #Open the JSON file to ensure it's formatted properly before proceeding
        $jsonObject = $null
        try 
        {
            $jsonObject = Get-Content $jsonFile | ConvertFrom-Json 
        }
        catch 
        {
            Write-STAlert -AlertType Error -Message "Unable to process the JSON file."
            Exit
        }

        #build the display header
        $borderCharacter = "#"
        $padding = 0
        $titleMargin = 4
        $paddingString = $null

        $maxLength = $Title.Length + ($Title.Length % 2) + $titleMargin
        $maxLength = 100



        if ($MenuType -ieq "Default" -and $Choices) {
            foreach ($choice in $Choices) {
                if ($choice.ToString().Length -gt $maxLength) {
                    #Parse through the items and determine actual length
                    if ($choice.GetType() -eq [System.IO.FileInfo]) {
                        $maxLength = $choice.ToString().Length + ($choice.ToString().Length % 2) + $titleMargin
                    } else {
                        $maxLength = $choice.ToString().Length + ($choice.ToString().Length % 2) + $titleMargin
                    }
                
                }
            }
        }

        #don't forget about the prompt. Thanks Jerome Althoff!
        if ($Prompt.Length -gt $maxLength) {
            #$maxLength = $prompt.Length + ($prompt.Length % 2) + $titleMargin
        }
    
        $padding = (($maxLength - $Title.Length + ($Title.Length % 2) + $titleMargin) / 2) - $titleMargin
        if ($padding -eq 0) {
            #Odd condition, but add a small buffer to the Title if it's difference is 0
            $padding = $TitleMargin / 2
            $maxLength += $TitleMargin
        }
        
        for ($x = 0; $x -lt $padding; $x++) {
            #build the padding
            $paddingString += " "
        }

        #build the border
        if (($Title.Length %2) -eq 1) {
            #$Title += " "
            $border = $borderCharacter
        } else {
            $border = ""
        }
        
        for ($x = 0; $x -lt $maxLength; $x++) {
            $border += "#"
        }
    
        $titlePrefix = $borderCharacter + $borderCharacter + $paddingString
        $titleSuffix = $paddingString + $borderCharacter + $borderCharacter

        #Build the title
        Write-Host $border -ForegroundColor $BorderColor
        Write-Host $titlePrefix -ForegroundColor $BorderColor -NoNewline
        Write-Host $Title -ForegroundColor $TitleColor -NoNewline
        Write-Host $TitleSuffix -ForegroundColor $BorderColor
        Write-Host $border -ForegroundColor $BorderColor
        Write-Host ""
        Write-Host $Prompt -ForegroundColor Gray
        Write-Host ""

        #Show the interactive editor
        Show-STJsonEditor $jsonObject



        return $jsonObject
        Try
        {
            


        }
        Catch 
        {
            #Process any error handling here.
            Write-Host "ERROR: in function: $($MyInvocation.MyCommand)" -ForegroundColor Red
            Write-Host $PSItem.Exception
        }
    }

    End 
    {
        
    }
}


#endregion

#region Execution
<#
$jsonFile = 
$jsonFile = Get-Item -Path "C:\Users\b-phdiep\source\git\WDScriptingToolkit\Menus\Azure Resource Manager (ARM)\Templates\malnet.infra.vnet.parameters.json"
#Edit-STJsonFile -jsonPath $jsonFile.FullName -Title "$($jsonFile.Name) Customization Wizard"




#How to implement.
Clear-Host

#Get the JSON Object
#$jsonObject = Get-Content $jsonFile | ConvertFrom-Json 

#Edit the JSON Object
$jsonObject = Edit-STJsonFile $jsonFile -Title $($jsonFile.BaseName + " Configuration Wizard")

#Save the JSON Object, if there were changes
if ($jsonObject -ne $(Get-Content $jsonFile | ConvertFrom-Json ))
{
    Clear-Host
    Start-Sleep 2
    $newFileName = Show-STReadHostMenu -Title "Enter a File Name" -Prompt "Filename"
    if (!$newFileName.EndsWith(".json"))
    {
        $newFileName += ".json"
    }

    $newFileName = $jsonFile.DirectoryName + "\$newFileName"

    #Save it to a directory
    $jsonObject | ConvertTo-Json | Out-File $newFileName
    

}
#>
#endregion