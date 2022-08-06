#Version History

## v1.0.1 (11/19/2018)
* Added a compatibility mode to allow the toolkit to run in "ConstrainedLanguage" mode

## v1.0.0 (9/7/2018)
* Completely revamped the folder structure and menu system files. This was a major overhaul of the core of the program
* Created a Libraries directory and split the common.ps1 file into separate files
  * Created STCommon.ps1
  * Created STConfigData.ps1
  * Created STCryptography
  * Created STLogging
  * Created STMenuSystem
* Added GIT capability to the Admin menu
  * Must have GIT installed from the [Dependencies](README.md#dependencies) page
  * Must have the [config.json](Templates\CONFIG.md) setup for GIT integration
* Added a demo menu to the Menus folder
* Added a modular and standardized logging capability
  * Importing STLogging.ps1 enables the following useful logging cmdlets
    ```powershell
    Write-STLog [-Message] <String[]> [[-AlertType] {Success | Failure | Informational | Warning | Error}] [-OutFile] <String> [[-Append] <Boolean>] [[-WithTimestamp] <Boolean>] [[-PipelineInput] <Hashtable>]
    [<CommonParameters>]
    Get-Help Backup-STFile -Examples
    ```
    ```powershell
    Backup-STFile [-SourceFile] <FileInfo> [[-DestinationDirectory] <String>] [<CommonParameters>]
    Get-Help Backup-STFile -Examples
    ```
    ```powershell
    Write-STAlert [[-Message] <String[]>] [[-AlertType] {Success | Failure | Informational | Warning | Error}] [[-OutFile] <String>] [[-Append] <Boolean>] [[-WithTimestamp] <Boolean>] [[-PipelineInput] <Hashtable>]
    [<CommonParameters>]
    Get-Help Write-STAlert -Examples
    ```
* Added a customizable menu system
  * Importing STMenuSystem.ps1 enables the following menu cmdlets
    ```powershell
    Show-STMenu [-Title] <String> [[-Choices] <IEnumerable>] [[-Info] <IEnumerable>] [-Back] [-Exit] [[-Custom] <String>] [[-BorderColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow
    | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White}] [[-TitleColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan |
    Red | Magenta | Yellow | White}] [[-ItemColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White}]
    [[-ItemsDisplayed] <Int32>] [[-MenuType] {Default | YesNo | TrueFalse | AcceptDecline}] [<CommonParameters>]

    Get-Help Show-STMenu -Examples
    ```
    ```powershell
    Show-STPromptForChoiceMenu [-Title] <String> [[-Prompt] <String>] [[-Choices] <IEnumerable>] [[-DefaultChoice] <Int32>] [-Help] [[-HelpInfo] <IEnumerable>] [[-BorderColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | 
    DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White}] [[-TitleColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow 
    | White}] [<CommonParameters>]

    Get-Help Show-STPromptForChoiceMenu -Examples
    ```
    ```powershell
    Show-STReadHostMenu [-Title] <String> [[-Prompt] <String>] [[-Info] <IEnumerable>] [-AsSecureString] [[-BorderColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | 
    Magenta | Yellow | White}] [[-TitleColor] {Black | DarkBlue | DarkGreen | DarkCyan | DarkRed | DarkMagenta | DarkYellow | Gray | DarkGray | Blue | Green | Cyan | Red | Magenta | Yellow | White}] [<CommonParameters>]

    Get-Help Show-STReadHostMenu -Examples
    ```
  * Examples
    Show-STMenu
    <br />
    ![](Help/Show-STMenu.png?raw=true)
    
    ```powershell
    $directoryChoices = Get-ActiveScripts -Path ".\Menus\Admin"
    $result = Show-STMenu -Title "Admin Tools" -Choices $directoryChoices.Choices -Exit -Back -TitleColor Green -BorderColor White -ItemColor Yellow
    ```  
    Show-STPromptForChoiceMenu
    <br />
    ![](Help/Show-STPromptForChoiceMenu.png?raw=true)
    
    ```powershell
    Show-STPromptForChoiceMenu -Title "Elevate Credentials" -Prompt "Do you want to try elevating to Local Administrator before proceeding?" -Choices @("Elevate Cre&dentials", "&Current Credentials") -Default 1
    ```  
    Show-STReadHostMenu
    <br />
    ![](Help/Show-STReadHostMenu.png?raw=true)
    
    ```powershell
    Show-STReadHostMenu -Title "Enter a Commit Message" -Prompt "Message" -Info @("Message Length", "Ensure the message does not exceed 72 characters.") -BorderColor Green -TitleColor Red
    ```  

## v0.5.2 (2/2/2018)
* Added an auto-increment feature that updates the config.json version when the toolkit is uploaded.

## v0.5.0 (2/2/2018)

* Changed all launcher files to Launcher.ps1 for future capabilities
* Added version to the main launcher
* Added formatting to all launcher information fields