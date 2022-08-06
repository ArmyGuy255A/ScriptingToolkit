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

$ErrorActionPreference = "SilentlyContinue"

#Array
Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 3 -Info @("Command", 'Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 3')
Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 4 -Info @("Command", 'Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 4')
Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 5 -Info @("Command", 'Show-STMenu -Title "Array Menu" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7", "Test8", "Test9", "Test10") -Back -Exit -Custom "Extra Option" -ItemsDisplayed 5')

#Array with Custom Menu Option
#Show-STMenu -Title "Array with Custom Choice 1" -Choices @("Alpha", "Omega", "Zeta") -Back -Exit -Custom "!!!Look - Im Different" -Info @("Command", 'Show-STMenu -Title "Array with Custom Choice 1" -Choices @("Alpha", "Omega", "Zeta") -Back -Exit -Custom "!!!Look - Im Different"')

#Array with Custom Menu Option
#Show-STMenu -Title "Array with Custom Choice 2" -Choices @("Alpha", "Omega", "Zeta") -Custom "^^^Look - Im Different" -Info @("Command", 'Show-STMenu -Title "Array with Custom Choice 2" -Choices @("Alpha", "Omega", "Zeta") -Custom "^^^Look - Im Different"')

#File Collection
#Show-STMenu -Title ($(Get-location | Select-Object -ExpandProperty Path).ToString() + " : FileInfo") -Choices $(Get-ChildItem).EnumerateDirectories() -Back -TitleColor Green -Info @("Command", 'Show-STMenu -Title ($(Get-location | Select-Object -ExpandProperty Path).ToString() + " : FileInfo") -Choices $(Get-ChildItem).EnumerateDirectories() -Back -TitleColor Green')

#Hashtable
#Show-STMenu -Title "Hashtable" -Choices $configData -BorderColor Cyan -TitleColor Magenta -ItemColor White -Info @("Command", 'Show-STMenu -Title "Hashtable" -Choices $configData -BorderColor Cyan -TitleColor Magenta -ItemColor White ')

#Prebuilt Menu
#Show-STMenu -Title "Built-In Menu" -MenuType YesNo -Back -Exit -Info @("Command", 'Show-STMenu -Title "Built-In Menu" -MenuType YesNo -Back -Exit -Info @("Command", "Test")')


<#
Clear-Host
Write-Host "Loading The PowerShell Library. Hang Tight, this could take a little time."
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