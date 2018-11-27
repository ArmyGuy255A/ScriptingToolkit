. "$PSScriptRoot\STCommon.ps1"

#get the config file's Fully Qualified name to pass into the Get-ConfigData
$configFQName = Get-ChildItem -Path $PSScriptRoot\..\config\config.ini -ErrorAction SilentlyContinue | Select-Object FullName

#load the config.ini
Test-ConfigFile $configFQName
$configData = @{}
$configData = Get-ConfigData $configFQName.FullName.ToString()

#$configData

##################Execution

$items = Get-ChildItem

<#
foreach ($item in $items) {
    Write-Host $item.Name
    Write-Host $item
}
#>

Function Convert-PSObjectToHashtable
{
  <#
  .SYNOPSIS
  This cmdlet converts any PSObject to a hashtable
  
  .DESCRIPTION
  This cmdlet can be used as a pipeline endpoint
  
  .EXAMPLE
  Convert-PSObjectToHashtable $anyPSObject
  
  .EXAMPLE
  Get-ChildItem | Select-Object -Property * | Convert-PSObjectToHashtable
  
  #>
    Param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    Begin {

    }

    Process {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) { Convert-PSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [PSObject]) {
            $hash = @{}
            # TODO Finish this function
            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = Convert-PSObjectToHashtable $property.Value
            }

            return $hash
        } 
        else {
            return $InputObject
        }
    }

    End {

    }
}

Function Convert-ArrayToHashtable
{
  <#
  .SYNOPSIS
  This cmdlet converts any Array to a hashtable
  
  .DESCRIPTION
  This cmdlet can be used as a pipeline endpoint
  
  .EXAMPLE
  Convert-ArrayToHashtable $anyArray
  
  .EXAMPLE
  @(1, 2, 3, 4, 5) | Convert-ArrayToHashtable
  
  #>
    Param (
        [Parameter(ValueFromPipeline)]
        [array]$InputArray
    )

    Begin {

    }

    Process {
        if ($null -eq $InputArray) { return $null }
        $hash = @{}
        foreach ($item in $InputArray) {
                $hash[$property.Name] = Convert-PSObjectToHashtable $property.Value
        }
    }

    End {

    }
}

<#

$dump = $items | Select-Object -Property *



$array = @(1, 2, 3,4 , 5)
$var = "string"
$items = Get-ChildItem
$a = Convert-PSObjectToHashtable $array
$b = Convert-PSObjectToHashtable $var
$c = Convert-PSObjectToHashtable $items
$a | Out-File test1.log -Encoding ASCII
$b | Out-File test1.log -Encoding ASCII -Append
$c | Out-File test1.log -Encoding ASCII -Append

$array | Out-File test2.log -Encoding ASCII
$var | Out-File test2.log -Encoding ASCII -Append
$items | Select-Object -Property * | Out-File test2.log -Encoding ASCII -Append

ConvertFrom-ArrayToHashtable $array $c
#>


#Array
#Show-STMenu -Title "Hello World : Array" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7") -Back -Exit -Custom "!!!Look" -ItemsDisplayed 2
<#
#Array with Custom Menu Option
Show-STMenu -Title "Custom Menu Item 1 : Array" -Choices @("Alpha", "Omega", "Zeta") -Back -Exit -Custom "!!!Look - Im Different"

#Array with Custom Menu Option
Show-STMenu -Title "Custom Menu Item 2 : Array" -Choices @("Alpha", "Omega", "Zeta") -Custom "^^^Look - Im Different"

#File Collection
Show-STMenu -Title ($(Get-location | Select-Object -ExpandProperty Path).ToString() + " : FileInfo") -Choices $(Get-ChildItem).EnumerateDirectories() -Back -TitleColor Green

#Hashtable
Show-STMenu -Title "ConfigData : Hashtable" -Choices $configData -BorderColor Cyan -TitleColor Magenta -ItemColor White

#>
#pressAnyKeytoContinue
Show-STMenu -Title "Do you like the Sun?" -MenuType YesNo -Back -Exit

<#
#Demo on how to explore the Powershell Library!
$modules = Get-Command | Select-Object -Property Module -ExpandProperty Module -Unique | Sort-Object -Property Name
$result = $null


while ($result -ne "E") {
    $result = Show-STMenu -Title "PowerShell Modules : Array" -Choices $modules -Exit -BorderColor Cyan -TitleColor Magenta -ItemColor White    
    if ($result -ne "E") {
        $secondResult = $null

        while ($secondResult -ne "E" -or $secondResult -ne "B") {
            $commands = Get-Command -Module $modules[$result - 1]  | Sort-Object -Property Name
            $secondResult = Show-STMenu -Title ($modules[$result - 1].ToString() + " : Array") -Choices $commands -Back -Exit -BorderColor DarkGreen -TitleColor Green -ItemColor Gray

            if ($secondResult -eq "E") {
                Exit
            } elseif ($secondResult -eq "B") {
                Break
            } else {
                Get-Help $commands[$secondResult - 1]
                pressAnyKeytoContinue
            }
        }

    }

}

#>
#pressAnyKeyToContinue
