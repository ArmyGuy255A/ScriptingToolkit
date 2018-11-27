if ($ExecutionContext.SessionState.LanguageMode -ine 'ConstrainedLanguage') {
Add-Type -TypeDefinition @"
public enum MenuType
{
    Default,
    YesNo,
    TrueFalse,
    AcceptDecline
}
"@
}

Function pressAnyKeyToContinue ($Message = "Press any key to continue . . . ") {
    If ($host.name -ine 'ConsoleHost' -and $ExecutionContext.SessionState.LanguageMode -ine "ConstrainedLanguage") {
        # The "ReadKey" functionality is not supported in Windows PowerShell ISE.
 
        $Shell = New-Object -ComObject "WScript.Shell"
        $Shell.Popup("Click OK to continue.", 0, "Script Paused", 0)

        return
    } elseif ($ExecutionContext.SessionState.LanguageMode -ieq "ConstrainedLanguage") {
        #Account for constrained language mode.
        Read-Host "Press enter to continue . . ."
        return
    }
 
    Write-Host -NoNewline $Message
    #left arror = 37
    #right arrow = 39
    $Ignore =
        16,  # Shift (left or right)
        17,  # Ctrl (left or right)
        18,  # Alt (left or right)
        20,  # Caps lock
        91,  # Windows key (left)
        92,  # Windows key (right)
        93,  # Menu key1
        144, # Num lock
        145, # Scroll lock
        166, # Back
        167, # Forward
        168, # Refresh
        169, # Stop
        170, # Search
        171, # Favorites
        172, # Start/Home
        173, # Mute
        174, # Volume Down
        175, # Volume Up
        176, # Next Track
        177, # Previous Track
        178, # Stop Media
        179, # Play
        180, # Mail
        181, # Select Media
        182, # Application 1
        183  # Application 2
 
    While ($null -eq $KeyInfo.VirtualKeyCode -Or $Ignore -Contains $KeyInfo.VirtualKeyCode) {
        $KeyInfo = $Host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown")
    }
 
    Write-Host
}
Function Show-STMenu () {

    <#
    .SYNOPSIS
    This cmdlet builds a menu based on several inputs. Customize the Choice colors by specifying !!! or ^^^ at the beginning of your choices.
  
    .DESCRIPTION
    See examples for more detailed usage examples.
  
    .EXAMPLE
    Show-STMenu -Title "Hello World : Array" -Choices @("Test1", "Test2", "Test3", "Test4", "Test5", "Test6", "Test7") -Back -Exit -Custom "!!!Look" -ItemsDisplayed 2

    .EXAMPLE
    Show-STMenu -Title "Custom Menu Item 1 : Array" -Choices @("Alpha", "Omega", "Zeta") -Back -Exit -Custom "!!!Look - Im Different"

    .EXAMPLE
    Show-STMenu -Title "Custom Menu Item 2 : Array" -Choices @("Alpha", "Omega", "Zeta") -Custom "^^^Look - Im Different"

    .EXAMPLE
    Show-STMenu -Title ($(Get-location | Select-Object -ExpandProperty Path).ToString() + " : FileInfo") -Choices $(Get-ChildItem).EnumerateDirectories() -Back -TitleColor Green

    .EXAMPLE
    Show-STMenu -Title "ConfigData : Hashtable" -Choices $configData -BorderColor Cyan -TitleColor Magenta -ItemColor White
  
    #>
    Param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$false)]
      [string]$Title,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [System.Collections.IEnumerable]$Choices,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [System.Collections.IEnumerable]$Info=$null,
    
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [Switch]$Back=$false,
    
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [Switch]$Exit=$false,
    
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [string]$Custom=$null,
    
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [ConsoleColor]$BorderColor=[ConsoleColor]::DarkYellow,
    
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [ConsoleColor]$TitleColor=[ConsoleColor]::Yellow,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [ConsoleColor]$ItemColor=[ConsoleColor]::Yellow,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [int]$ItemsDisplayed=20,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [string]$MenuType="Default"

    )

    Begin {
        
        #Ensure there are always choices so you can't get stuck.
        if (!$Choices -and $MenuType -ieq "Default") {
            #always make sure the back option is available
            $Back = $true
        } elseif ($Choices) {
            if ($Choices.GetType() -eq [hashtable]) {
                $newChoices = @()

                foreach ($key in $Choices.Keys) {
                    $key = $key
                    $value = $Choices.Item($key)
                    $newChoices += $key + " : " + $value
                }
                $Choices = $newChoices
            }
        }
    }

    Process {

        if ($MenuType -ine "Default") {
            #Clear out everything that will affect the specialized menus

            $Custom = $null
            $Choices = $null
            #Populate choices with the correct options

            
        }
        #This function requires a $Title and at least one $choice.
        #The   will display underneath the menu.
        #Clear the screen
        #####Clear-Host

        $customStringChar = $null
        $customString = $null

        #This stores all of the formetted number choices from $Choices
        $numericChoices = @{}
        #This stores all of the letter options from -Back -Exit and -Custom
        $letterChoices = @{}

        #build the display header
        $borderCharacter = "#"
        $padding = 0
        $titleMargin = 4
        $paddingString = $null

        $maxLength = $Title.Length + ($Title.Length % 2) + $titleMargin

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
        if ($prompt.Length -gt $maxLength) {
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
       
        
        #Build the numeric choices
        if ($MenuType -ieq "Default" -and $Choices) {
            for ($x = 0; $x -lt $Choices.Length ; $x++) {
                $numericChoices.Add($x + 1, $Choices.Get($x).ToString())
            }
        }
        

        #Build the letter choices

        if ($Custom -and $MenuType -ieq "Default") {
            $firstChar = $Custom.Substring(0,1).ToUpperInvariant()
            if ($firstChar -ne "E" -and 
                $firstChar -ne "B" -and 
                $firstChar -ne "!" -and 
                $firstChar -ne "^" -and 
                $Custom -cnotmatch '^[\d]+$') {

                #$option = $Custom
                #$optionPrefix = "[" + $firstChar + "]"
                $customStringChar += $firstChar
                $letterChoices.Add($firstChar, $Custom)
            } else {
                #Find the next available letter to use in the menu.
                $customString = $null
                $foundGoodChar = $false

                #Ensure it's not a numeric string
                if ($Custom -cnotmatch '^[\d]+$') {
                    for ($y = 0; $y -lt $Custom.ToCharArray().Length; $y++) {
                        if ($Custom.ToCharArray()[$y] -ine ("B") -and 
                            $Custom.ToCharArray()[$y] -ine ("E") -and
                            $Custom.ToCharArray()[$y] -ine ("!") -and
                            $Custom.ToCharArray()[$y] -ine ("^") -and 
                            !$foundGoodChar) {

                            $customString += $Custom.ToUpperInvariant().ToCharArray()[$y]
                            $customStringChar = $Custom.ToUpperInvariant().ToCharArray()[$y]
                            $foundGoodChar = $true
                            
                        } else {
                            #Add the remaining characters
                            $customString += $Custom.ToLowerInvariant().ToCharArray()[$y]

                        }
                    }
                }
                    

                if (!$customStringChar) {
                    #$option = $Custom
                    #$optionPrefix = "[Z]"
                    $customStringChar += "Z"
                    $letterChoices.Add("Z", $Custom)

                } else {
                    #$option = $customString
                    #$optionPrefix = "[" + $customStringChar + "]"
                    $letterChoices.Add($customStringChar, $customString)
                }
            }
        }

        #Build the selection option string for the Read-Host prompt
        $totalCharacterChoices = @()
        $totalCharacterChoiceString = ""

        if ($MenuType -ieq "AcceptDecline") {
            $letterChoices.Add("A", "Accept")
            $letterChoices.Add("D", "Decline")
            $totalCharacterChoices += "A"
            $totalCharacterChoices += "D"
        }

        if ($MenuType -ieq "YesNo") {
            $letterChoices.Add("Y", "Yes")
            $letterChoices.Add("N", "No")
            $totalCharacterChoices += "Y"
            $totalCharacterChoices += "N"
        }

        if ($MenuType -ieq "TrueFalse") {
            $letterChoices.Add("T", "True")
            $letterChoices.Add("F", "False")
            $totalCharacterChoices += "T"
            $totalCharacterChoices += "F"
        }

        if ($Back) {
            $letterChoices.Add("B", "Back")
            $totalCharacterChoices += "B"
        }

        if ($Exit) {
            $letterChoices.Add("E", "Exit")
            $totalCharacterChoices += "E"
        }

        if ($Custom) {
            $totalCharacterChoices += $customStringChar
        }


        foreach ($char in $totalCharacterChoices) {
            
            if ($char -ne $totalCharacterChoices[-1]) {
                $totalCharacterChoiceString += $char + ","
            } else {
                $totalCharacterChoiceString += $char
            }
        }


        #Build the prompt string
        $prompt = ""
        if ($MenuType -ieq "Default" -and $totalCharacterChoices.Count -eq 0 -and $numericChoices.Count -gt 0) {
            $prompt = "Please select an option from [1-$($numericChoices.Count)]: "
        } elseif ($MenuType -ieq "Default" -and $totalCharacterChoices.Count -gt 0 -and $numericChoices.Count -eq 0) {
            $prompt = "Please select an option from [$totalCharacterChoiceString]: "
        } elseif ($MenuType -ieq "Default" -and $totalCharacterChoices.Count -gt 0 -and $numericChoices.Count -gt 0) {
            $prompt = "Please select an option from [1-$($numericChoices.Count),$totalCharacterChoiceString]: "
        } else {
            $prompt = "Please select an option from [$totalCharacterChoiceString]: "
        }
        
        [string]$note = ""
        #Build and format the note.
        for ($x = 0; $x -lt $Info.Count ; $x+=2) {
            $infoTitle = $Info.Get($x)
            $infoDescription = $Info.Get($x + 1)
            if ($infoDescription.count -gt 1) {
                $newDescription = $null
                foreach ($desc in $infoDescription) {
                    $newDescription += $desc + "`n"
                }
    
                $note += $infoTitle + " : " + $newDescription + "`n"
            } else {
                $note += $infoTitle + " : " + $infoDescription + "`n"
            }
        }
        
        #Trim any line breaks at the end of the note.
        if ($note.EndsWith("`n")) {
            $note = $note.TrimEnd()
        }

        #Keep track of the pages.
        $script:currentPage = 0

        
        #Get the ceiling for the total number of pages. Unable to use [math]::ceiling due to constrained language mode.
        $remainder = ($numericChoices.Count % $itemsDisplayed)
        $quotient = ($numericChoices.Count - $remainder) / $itemsDisplayed
        $pages = $quotient - 1
        #FIXME: Not sure if it's possible to avoid the if statement, but it works. 
        if ($remainder) {$pages = $quotient}
        $script:lastPage = $pages

       
        if ($numericChoices.Count -eq 0) {
            #There's only one page.
            $script:lastPage = 0
        }


        #continue to show the prompt until there is valid input.
        $badInput = $true
        while ($badInput) {
            if ($configData.DebugMode -ine "on") {     Clear-Host }
            
            #Add the page number here.
            $pageString = "Page: ($($script:currentPage + 1) / $($script:lastPage + 1))"
            $pageStringPadding = $host.UI.RawUI.MaxWindowSize.Width - $border.Length - $pageString.Length - 1
            for ($x = 0; $x -lt $pageStringPadding; $x++) {
                $pageString = $pageString.Insert(0, " ")
            }

            #Output the border
            Write-Host $border -ForegroundColor $BorderColor -NoNewline
            Write-Host $pageString

            Write-Host $titlePrefix -ForegroundColor $BorderColor -NoNewline
            Write-Host $Title -ForegroundColor $TitleColor -NoNewline
            Write-Host $TitleSuffix -ForegroundColor $BorderColor
            Write-Host $border -ForegroundColor $BorderColor

            #Write the numeric choices to the console.
            if ($numericChoices.Count -gt 0) {
                $numericChoices = $numericChoices.GetEnumerator() | Sort-Object -Property Name
                for ($x = $script:currentPage * $ItemsDisplayed; $x -le $script:currentPage * $ItemsDisplayed + ($ItemsDisplayed - 1); $x++) {
                    if ($script:currentPage -lt $script:lastPage) {
                        #Write the choices on the screen
                        Write-Host $("[" + $numericChoices[$x].Name + "] ") -ForegroundColor $BorderColor -NoNewline

                        if ($numericChoices[$x].Value.Contains("!!!")) {
                            Write-Host $numericChoices[$x].Value.Replace("!!!","") -ForegroundColor Green
                        } elseif ($numericChoices[$x].Value.Contains("^^^")) {
                            Write-Host $numericChoices[$x].Value.Replace("^^^","") -ForegroundColor Red
                        } else {
                            Write-Host $numericChoices[$x].Value -ForegroundColor $ItemColor
                        }
                    } else {
                        while ($x -lt $numericChoices.Count) {
                            #Write the remaining choices on the screen
                            Write-Host $("[" + $numericChoices[$x].Name + "] ") -ForegroundColor $BorderColor -NoNewline

                            if ($numericChoices[$x].Value.Contains("!!!")) {
                                Write-Host $numericChoices[$x].Value.Replace("!!!","") -ForegroundColor Green
                            } elseif ($numericChoices[$x].Value.Contains("^^^")) {
                                Write-Host $numericChoices[$x].Value.Replace("^^^","") -ForegroundColor Red
                            } else {
                                Write-Host $numericChoices[$x].Value -ForegroundColor $ItemColor
                            }
                            
                            $x++
                        }
                    }
    
                }
            }
            
            #Display the custom letter choices first
            if ($letterChoices.Count -gt 0) {
                foreach ($letterChoice in $letterChoices.GetEnumerator()) {

                    if ($letterChoice.Key -ine "E" -and $letterChoice.Key -ine "B") {
                        Write-Host $("[" + $letterChoice.Name + "] ") -ForegroundColor $BorderColor -NoNewline
                        #Give custom options a different color if specified
                        if ($letterChoice.Value.Contains("!!!")) {
                            Write-Host $letterChoice.Value.Replace("!!!","") -ForegroundColor Green
                        } elseif ($letterChoice.Value.Contains("^^^")) {
                            Write-Host $letterChoice.Value.Replace("^^^","") -ForegroundColor Red
                        } else {
                            Write-Host $letterChoice.Value -ForegroundColor $ItemColor
                        }
                    }
                }
            }
            

            #Then display Back
            if ($Back) {
                Write-Host $("[B] ") -ForegroundColor $BorderColor -NoNewline
                Write-Host $letterChoices."B" -ForegroundColor $ItemColor
            }

            #Then display Exit
            if ($Exit) {
                Write-Host $("[E] ") -ForegroundColor $BorderColor -NoNewline
                Write-Host $letterChoices."E" -ForegroundColor $ItemColor
            }


            if ($note -ne "") {
                #Add a space between the menu and Info
                Write-Host ""
                Write-Host $note -ForegroundColor Gray
            }
            
            Write-Host $blankLine -NoNewline
            $result = $null

            #Get the current cursor position in the console window. This helps overwrite the line later on.
            $originalPosition = $host.UI.RawUI.CursorPosition
            $pageStringPosition = $host.UI.RawUI.CursorPosition

            

            #Two methods are needed to read input and scroll through the list.

            if ($host.name -ine 'ConsoleHost' -and $ExecutionContext.SessionState.LanguageMode -ne "ConstrainedLanguage") {
                #This is going to show a popup used for input and navigation of the menu
                Add-Type -AssemblyName System.Windows.Forms
                Add-Type -AssemblyName System.Drawing

                $Font = New-Object System.Drawing.Font("Arial",12,[System.Drawing.FontStyle]::Bold) 
                $form = New-Object System.Windows.Forms.Form
                $form.Text = 'ISE Selection Dialog'
                $form.Size = New-Object System.Drawing.Size(600,320)
                $form.StartPosition = 'CenterScreen'
                $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
                $form.MaximizeBox = $false
                #$form.FormBorderStyle = "FixedDialog"
                #$form.ControlBox = $true
                #$form.AutoScale = $true
                $form.Font = $Font
                #$form.AutoSize = $true
                
                $OKButton = New-Object System.Windows.Forms.Button
                $OKButton.Location = New-Object System.Drawing.Point(900,900)
                $OKButton.Size = New-Object System.Drawing.Size(75,23)
                $OKButton.Text = 'OK'
                $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
                $form.Controls.Add($OKButton)
                $form.AcceptButton = $OKButton

                
                $leftActionEventHandler = [System.EventHandler]{
                    #Decrement the page
                    
                    if ($script:currentPage -gt 0) {
                        #Write-Host "Decrementing Page"
                        #Set-Variable -Name $script:currentPage -Value $($script:currentPage - 1) -Scope Local
                        #return -1
                        $script:currentPage -= 1
                        #break
                        #$form.Close()
                    } else {
                        #Write-Host "Beginning page reached"
                    }
                    #$form.Close()
                    $form.Close()
                };

                $buttonWidth = ($form.Size.Width / 4) - 4
                $buttonHeight = ($form.Size.Height / 6) - 4
                $buttonYvalue = $form.Size.Height - ($form.size.Height / 4) - $buttonHeight

                $LeftArrowButton = New-Object System.Windows.Forms.Button
                $LeftArrowButton.Location = New-Object System.Drawing.Point((($form.Size.Width / 50) * 10),$buttonYvalue)
                $LeftArrowButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
                $LeftArrowButton.Text = '←'
                $LeftArrowButton.Add_Click($leftActionEventHandler)
                $LeftArrowButton.Font = $Font
                $form.Controls.Add($LeftArrowButton)


                $rightActionEventHandler = [System.EventHandler]{
                    #Increment the page
                    #
                    if ($script:currentPage -lt $script:lastPage) {
                        #Write-Host "Incrementing Page"
                        #Set-Variable -Name $script:currentPage -Value $($script:currentPage + 1) -Scope Local
                        $script:currentPage += 1
                        #return 1
                        #break
                        #$form.Close()
                    } else {
                        #Write-Host "Last page reached."
                    }
                    $form.Dispose()
                
                };

                
                $RightArrowButton = New-Object System.Windows.Forms.Button
                $RightArrowButton.Location = New-Object System.Drawing.Point((($form.Size.Width / 50) * 26),$buttonYvalue)
                $RightArrowButton.Size = New-Object System.Drawing.Size($buttonWidth,$buttonHeight)
                $RightArrowButton.Text = '→'
                $RightArrowButton.Add_Click($rightActionEventHandler)
                $RightArrowButton.Font = $Font
                $form.Controls.Add($RightArrowButton)

                $labelBoxHeight = $form.Size.Height / 4
                $labelBoxWidth = $form.Size.Width - 50
                $labelBoxYValue = 10
                $label = New-Object System.Windows.Forms.Label
                $label.Location = New-Object System.Drawing.Point(10,$labelBoxYValue)
                $label.Size = New-Object System.Drawing.Size($labelBoxWidth,$labelBoxHeight)
                $label.Text = $prompt
                $label.Font = $Font
                #$label.BackColor = "Red"
                #$label.AutoSize = $true
                $form.Controls.Add($label)

                $textBoxHeight = 90
                $textBoxWidth = ($form.Size.Width / 8) * 6
                $textBoxYvalue = $buttonYValue - $buttonHeight
                $textBox = New-Object System.Windows.Forms.TextBox
                $textBox.Font = $(New-Object System.Drawing.Font("Arial",24,[System.Drawing.FontStyle]::Bold)) 
                $textBox.AcceptsReturn = $true
                $textBox.Location = New-Object System.Drawing.Point(($form.Size.Width / 10),$textBoxYvalue)
                $textBox.Size = New-Object System.Drawing.Size($textBoxWidth,$textBoxHeight)
                
                
                #$textBox.AutoSize = $true
                $form.Controls.Add($textBox)

                $form.Topmost = $true
                #$form.AutoScale = $true
                #$form.AutoSize = $true

                $form.Add_Shown({$textBox.Select()})
                $result = $form.ShowDialog()

                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $result = $textBox.Text
                    
                } elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
                    #Exit
                }
                #$result = 2


            } elseif ($host.Name -ieq 'ConsoleHost' -and $ExecutionContext.SessionState.LanguageMode -ne "ConstrainedLanguage") {
                #Now read the result
                if ($script:lastPage -gt 0) {
                    Write-Host "`nUse the <- (Left) and -> (Right) keys to navigate through pages." -ForegroundColor Gray
                }
                Write-Host "`n$prompt" -NoNewLine

                #Keep looping until Enter is pressed
                $keyinfo = $null
                While ($keyinfo.VirtualKeyCode -ne 13) {
                    #read input
                    $keyinfo = $Host.UI.RawUI.ReadKey("IncludeKeyDown")

                    #Left and Up arrow keys
                    if ($keyinfo.VirtualKeyCode -eq 37 -or $keyinfo.VirtualKeyCode -eq 38) {
                        #Decrement the page
                        #Write-Host "Decrementing Page"
                        if ($script:currentPage -gt 0) {
                            $script:currentPage -= 1
                            break
                        }

                    } elseif ($keyinfo.VirtualKeyCode -eq 39 -or $keyinfo.VirtualKeyCode -eq 40) {
                        #Increment the page
                        #Write-Host "Incrementing Page"
                        if ($script:currentPage -lt $script:lastPage) {
                            $script:currentPage += 1
                            break
                        }
                    } elseif ($keyinfo.VirtualKeyCode -ne 13) {
                        $result += $keyinfo.Character.ToString()
                        $originalPosition = $host.UI.RawUI.CursorPosition

                    }
                }

            } else {
                #Pagination with primitive navigation system

                #Now read the result
                if ($script:lastPage -gt 0) {
                    Write-Host "`nType '<' or '>' to navigate through pages.`nOptionally, type p# to navigate to a specific page." -ForegroundColor Gray
                }
                Write-Host "`n$prompt" -NoNewLine

                $result = Read-Host

                #do some input validation
                #Left and Up arrow keys
                if ($result.Contains("<")) {
                    #Decrement the page
                    #Write-Host "Decrementing Page"
                    if ($script:currentPage -gt 0) {
                        $script:currentPage -= 1
                        #break
                    }

                } elseif ($result.Contains(">")) {
                    #Increment the page
                    #Write-Host "Incrementing Page"
                    if ($script:currentPage -lt $script:lastPage) {
                        $script:currentPage += 1
                        #break
                    }
                } elseif ($result -cmatch '([Pp])\d{1,6}') {
                    #Remove the P or p
                    $result = [int]($result -creplace '[Pp]', "")
                    $result -= 1
                    #Subtract one from the page
                    if ($result -ge $script:lastPage) {
                        $script:currentPage = $script:lastPage
                    } elseif ($result -le 0) {
                        $script:currentPage = 0
                    } else {
                        $script:currentPage = $result
                    }
                    #break         
                    $result = ""  
                    

                } 
            }
            

            #Check for a numeric string to typecast
            if ($result -cmatch '^[0-9]*$' -and $numericChoices.Count -gt 0) {
                #Check to ensure the length isn't too big
                if ($result.Length -lt [long]::MaxValue.ToString().Length -1) {
                    #Check for a valid number
                    if ([long]$result -gt 0 -and [long]$result -le $numericChoices.Count) {
                        $badInput = $false
                        #Convert the result to an integer
                        $result = [int]$result

                    }
                } else {

                }
                
                
            } elseif ($Back -and $result -ieq "B") {

                $badInput = $false
            } elseif ($Exit -and $result -ieq "E") {

                $badInput = $false
            } elseif ($Custom -and $result -ieq $customStringChar) {

                $badInput = $false
            } elseif ($MenuType -ieq "AcceptDeny" -and ($result -ieq "A" -or $result -ieq "D")) {

                $badInput = $false
            } elseif ($MenuType -ieq "TrueFalse" -and ($result -ieq "T" -or $result -ieq "F")) {

                $badInput = $false
            } elseif ($MenuType -ieq "YesNo" -and ($result -ieq "Y" -or $result -ieq "N")) {

                $badInput = $false
            } else {

            }


            
        }
        
        if ($configData.DebugMode -ine "on") {     Clear-Host }
        #Input Validation
        if ($result.GetType() -eq [string]) {
            return $result.ToUpperInvariant()
        } else {
            return $result
        }
        
    }

    End {

    }

}

Function Show-STReadHostMenu () {
<#
    .SYNOPSIS
    This cmdlet builds a standardized menu used to read user input
  
    .DESCRIPTION
    None
  
    .EXAMPLE
    Show-STReadHostMenu -Title "Enter a Commit Message" -Prompt "Message" -Info @("Message Length", "Ensure the message does not exceed 72 characters.")
  
#>

    Param (
    [Parameter(Mandatory=$True, ValueFromPipeline=$false)]
      [string]$Title,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
      [string]$Prompt,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
        [System.Collections.IEnumerable]$Info=$null,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
        [Switch]$AsSecureString=$false,

    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
        [ConsoleColor]$BorderColor=[ConsoleColor]::DarkYellow,
  
    [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
        [ConsoleColor]$TitleColor=[ConsoleColor]::Yellow
    )

    Begin {

    }

    Process {
        #build the display header
        $borderCharacter = "#"
        $padding = 0
        $titleMargin = 4
        $paddingString = $null

        $maxLength = $Title.Length + ($Title.Length % 2) + $titleMargin

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
        if ($prompt.Length -gt $maxLength) {
            $maxLength = $prompt.Length + ($prompt.Length % 2) + $titleMargin
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

        Write-Host $border -ForegroundColor $BorderColor
        Write-Host $titlePrefix -ForegroundColor $BorderColor -NoNewline
        Write-Host $Title -ForegroundColor $TitleColor -NoNewline
        Write-Host $TitleSuffix -ForegroundColor $BorderColor
        Write-Host $border -ForegroundColor $BorderColor

        [string]$note = ""
        #Build and format the note.
        for ($x = 0; $x -lt $Info.Count ; $x+=2) {
            $infoTitle = $Info.Get($x)
            $infoDescription = $Info.Get($x + 1)
            if ($infoDescription.count -gt 1) {
                $newDescription = $null
                foreach ($desc in $infoDescription) {
                    $newDescription += $desc + "`n"
                }
    
                $note += $infoTitle + " : " + $newDescription + "`n"
            } else {
                $note += $infoTitle + " : " + $infoDescription + "`n"
            }
        }

        #Print the note
        if ($note -ne "") {
            #Add a space between the menu and Info
            Write-Host ""
            Write-Host $note -ForegroundColor Gray
        }

        if ($AsSecureString) {
            $result = Read-Host -Prompt $Prompt -AsSecureString
        } else {
            $result = $(Read-Host -Prompt $Prompt)
        }
        

        return $result
    }

    End {

    }
}

Function Show-STPromptForChoiceMenu () {
<#
    .SYNOPSIS
    This cmdlet builds a prompt menu used just like $host.ui.promptforchoice()
    
    .DESCRIPTION
    None
    
    .EXAMPLE
    #Show-STPromptForChoiceMenu -Title "Elevate Credentials" -Prompt "Do you want to try elevating to Local Administrator before proceeding?" -Choices @("Elevate Cre&dentials", "&Current Credentials") -Default 1

    .EXAMPLE
    Show-STPromptForChoiceMenu -Title "Continue Running" -Prompt "Do you want to continue running the script?" -Choices @("Yes", "No")

    .EXAMPLE
    Show-STPromptForChoiceMenu -Title "How many Cookies do you want?" -Prompt "Select the number of cookies" -Choices @("1", "2") -Default 0 -Help -HelpInfo @("1 - One Cookie", "2 - Two Cookies")
#>
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$false)]
            [string]$Title,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [string]$Prompt,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [System.Collections.IEnumerable]$Choices=$null,
        
        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [int]$DefaultChoice=0,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [Switch]$Help=$false,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [System.Collections.IEnumerable]$HelpInfo=$null,

        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [ConsoleColor]$BorderColor=[ConsoleColor]::DarkYellow,
    
        [Parameter(Mandatory=$False, ValueFromPipeline=$false)]
            [ConsoleColor]$TitleColor=[ConsoleColor]::Yellow
    )

    Begin {

    }

    Process {
        #build the display header
        $borderCharacter = "#"
        $padding = 0
        $titleMargin = 4
        $paddingString = $null

        $maxLength = $Title.Length + ($Title.Length % 2) + $titleMargin

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

        #Build the choices
        $defaultLetter = ""
        $letterChoices = @()
        $badInput = $true
        #Continue looping until a correct choice is selected
        while ($badInput) {
            #Write each choice into the console
            $letterChoices = @()
            foreach ($choice in $Choices) {
                $letter = $choice.Substring($choice.IndexOf("&") + 1, 1)
                $letter = $letter.ToUpperInvariant()
                
                #Ensure there isn't a duplicate letter
                foreach ($item in $letterChoices) {
                    if ($letter -ieq $item) {
                        Write-Host ""
                        throw "Duplicate letter detected. Define different letter choices in the array by using an ampersand '&'. See the cmdlet help for examples."
                    } 
                }
                $letterChoices += $letter

                if ($choice -ieq $Choices[$DefaultChoice]) {
                    #Change the color of the default choice
                    $defaultLetter = $letter
                    Write-Host "[$letter]" $choice.Replace("&","") "" -ForegroundColor Yellow -NoNewline
                } else {
                    Write-Host "[$letter]" $choice.Replace("&","") "" -ForegroundColor White -NoNewline
                }

            }

            #Write the Help letter, if enabled
            if ($Help) {
                Write-Host "[?] Help " -NoNewline
            }

            #Write the default value
            Write-Host "(default is `"$defaultLetter`"): " -NoNewline

            #Read user input
            $result = Read-Host

            if ($result.trim() -eq "") {
                #This is the default choice
                $badInput = $false
                return $letterChoices[$DefaultChoice]
            }

            #Input validation
            if ($result.Length -gt 1) {
                continue
            } 

            #Validate against letter choices
            foreach ($letter in $letterChoices) {
                if ($result -ieq $letter) {
                    #Good match
                    $badInput = $false
                    return $letter
                }
            }

            #Show the help information
            if ($result -ieq "?") {
                foreach ($item in $HelpInfo) {
                    #Good match, but keep looping
                    Write-Host $item -ForegroundColor DarkGray
                }
            }
        }

    }

    End {

    }
}
Function Show-STTimeIntervalMenu ($title) {
    $timeResult = 0
    while ($timeResult -eq 0) {
        #Clear the screen
    
        $title = $title
        $choices = @("1 minute", 
        "5 minutes",
        "10 minutes",
        "30 minutes",
        "1 hour",
        "3 hours",
        "6 hours",
        "12 hours",
        "1 day",
        "3 days",
        "7 days"
        )
        #$info = @("Workstation OU", $configData.Get_Item("WorkstationOU"), "User Account OU", $configData.Get_Item("UserAccountOU"), "Log Directory", $configData.Get_Item("LogDirectory"))
        #$info = @()
        [int]$timeResult = Show-STMenu $title $choices #$info

        #Only accept data within the bounds of the choices - reject everything else.
        if (($timeResult -le 0) -or ($timeResult -gt $choices.Length)) {
            $timeResult = 0
        }

    }

    $timeDelay = 0
    switch ($timeResult) {
        1 {
            $timeDelay = 60
        }

        2 {
            $timeDelay = 300  
        }

        3 {
            $timeDelay = 600   
        }

        4 {
            $timeDelay = 1800   
        }

        5 {
            $timeDelay = 3600   
        }

        6 {
            $timeDelay = 10800
        }
        
        7 {
            $timeDelay = 21600
        }

        8 {
            $timeDelay = 43200
        }

        9 {
            $timeDelay = 86400
        }

        10 {
            $timeDelay = 259200
        }

        11 {
            $timeDelay = 604800
        }

    }
    return $timeDelay
}

Function Show-STDateIntervalMenu ($title) {
    $dateResult = 0
    while ($dateResult -eq 0) {
        #Clear the screen
    
        $title = $title
        $choices = @("1 day", 
        "7 days",
        "30 days",
        "60 days",
        "90 days",
        "120 days",
        "180 days",
        "358 days",
        "365 days"
        )
        [int]$dateResult = Show-STMenu $title $choices #$info

        #Only accept data within the bounds of the choices - reject everything else.
        if (($dateResult -le 0) -or ($dateResult -gt $choices.Length)) {
            $dateResult = 0
        }

    }

    $dateDelay = 0
    switch ($dateResult) {
        1 {
            $dateDelay = 1
        }

        2 {
            $dateDelay = 7  
        }

        3 {
            $dateDelay = 30   
        }

        4 {
            $dateDelay = 60   
        }

        5 {
            $dateDelay = 90   
        }

        6 {
            $dateDelay = 120
        }
        
        7 {
            $dateDelay = 180
        }

        8 {
            $dateDelay = 358
        }

        9 {
            $dateDelay = 365
        }
    }
    return $dateDelay
}

Function Show-STConfirmationMenu ($selection, $title) {
$result = 0
    while ($result -eq 0) {
        #Clear the screen
        if ($configData.DebugMode -ine "on") {     Clear-Host }

        if ($title.Length -eq 0) {
            $title = "Please confirm your selection"
        }


        $choices = @("Yes", 
        "No"
        )

        $info = @("Your Selection", $selection)
        #$info = @()
        [int]$result = Show-STMenu $title $choices $info

        #Only accept data within the bounds of the choices - reject everything else.
        if (($result -le 0) -or ($result -gt $choices.Length)) {
            $result = 0
        }

    }



p1v5_stby
p0v75_stby
    switch ($result) {
        1 {
            return $true
        }

        2 {
            return $false
        }

        default {
            return $false
        }

    }

}

Function Show-STDirectoryScriptMenu ($path) {
    $scripts = $null
    $directories = $null

    #Get all scripts in the path
    $scripts = Get-ChildItem -Path $path -Filter *.ps* | Sort-Object
    #Get all directories in the path
    $directories = Get-ChildItem -Path $path -Filter * -Directory | Where {$_.BaseName -ne "Admin"} | Sort-Object

    #Add each item to the menu options
    $menuOptions = @()
    foreach ($directory in $directories) {
        #TODO: Search for Launcher*.ps1 files and add those instead of the directories
        $menuOptions += $directory.BaseName
    }

    foreach ($script in $scripts) {
        $menuOptions += "!!!" + $script.Name
    }

    $result = -1
    

    while ($result -eq -1) {
        $result = Show-STMenu -Title $(Get-Item -Path $path).Name  -Choices $menuOptions -Back

        if ($result -ieq "B") {
            continue
        }

        if (($result - 1) -ge 0 -and ($result - 1) -lt $directories.Count) {
            #TODO: Add a condition that checks whether the selection is a directory or a script
            
            #The result is a directory choice. Show the directory menu again
            showSubDirectoryMenu -path $directories[$result - 1].FullName
        }

        #Reset the result so it's easier to select the correct script, if any.
        $result = $result - $directories.Count

        if (($result - 1) -ge 0 -and ($result - 1) -lt $scripts.Count) {
            #Execute the script.
            & $scripts[$result - 1].FullName
        }

        #Reset result back to -1
        $result = -1
        
    } 

}
    
Function Show-STDatePicker {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    $objForm = New-Object Windows.Forms.Form 
    
    $objForm.Text = "Select a Date and press ENTER" 
    $objForm.Size = New-Object Drawing.Size @(480,350) 
    $objForm.StartPosition = "CenterScreen"
    
    $objForm.KeyPreview = $True
    
    $objForm.Add_KeyDown({
        if ($_.KeyCode -eq "Enter") 
            {
                $objForm.Close()
                           
            }
        })
    
    $objForm.Add_KeyDown({
        if ($_.KeyCode -eq "Escape") 
            {
                $objForm.Close()
            }
        })
    
    $objCalendar = New-Object System.Windows.Forms.MonthCalendar 
    $objCalendar.ShowTodayCircle = $true
    $objCalendar.MaxSelectionCount = 1
    $objCalendar.CalendarDimensions = New-Object Drawing.Size @(2,2)
    $objForm.Controls.Add($objCalendar) 
    
    $objForm.Topmost = $True
    
    $objForm.Add_Shown({$objForm.Activate()})  
    [void] $objForm.ShowDialog() 
    
    return $objCalendar.SelectionStart
    
}
    