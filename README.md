# PowerShell Scripting Toolkit
The PowerShell Scripting Toolkit was built specifically for administrators that need to standardize their scripting environments for ease of use, reusability and portability. The PowerShell Scripting Toolkit standardizes every aspect of the scripting environment and provides the following capabilities:<br />
* Standardized Script Formats
* Standardized Log Formats
* Standardized Global Variables
* Standardized Input Validation
* Standardized Menu System
* Automatic Version Control
* Automatic/Manual Updating
* Common Functions and Cmdlet libraries
* Central Configuration
* Automatic script integration into the menu system

### Problem Set
Many Windows administrators will typically write or reuse PowerShell scripts for their environment. Natural problems occurr when the administrator tries sharing their scripts with other administrators. Often times, other administrators do not know how to modify the script for their environment. This can cause confusion, delay, and sometimes disastrous side effects. 

### Purpose
The purpose of the toolkit is designed for administrators that want to to share and distribute their custom tools to other people in their community. Administrators can share their scripting tools by adding the scripts to the "Menus" directory and the toolkit will handle the rest.

## Getting Started

1. Copy or clone the contents of the toolkit to a directory. For example: `C:\scripts`
   - A sample of the toolkit directory is listed below. Note, your structure may have fewer folders. That's because some scripts are not ready for release.
    <br />
    ![](Help/DirectoryListing.png?raw=true)
    
2. Generate the config.json file by [launching](#launching-the-toolkit) the `.\Launcher.ps1` from the PowerShell CLI in the toolkit's root directory. 
   - If the `Config\config.json` file already exists, it will be migrated to the latest version in `Templates\config.json` and the old version will be backed up.
   - Running the toolkit for the first time will generate a new config.json and place it into the `\Config` directory. 

3. Modify the [config.json](#the-config.json) file based on your environment's requirements.
   - Take the time to ensure no unnecessary changes happened to your config.json file.

4. Add your PowerShell scripts to the Menus directory.
   - Only .ps1 and .ps1m files will show up in the menu system.
   - Folders turn into navigable items like in the examples below.   
   - Scripts can be organized by folders or all within the Menus directory.
     - Developer Note: I think it's easier to manage the scripts if you place them in subdirectories like in the images below.

   <br />

   ![](Help/DirectoryToMenu.png?raw=false)

   
   <br />

   ![](Help/ScriptToMenu.png?raw=false)

   

## Launching the Toolkit
Launching the toolkit can be accomplished using several methods.

### Method 1 - First Launch
1. Ensure you are using the latest version of PowerShell and WMI by viewing the [dependencies](#dependencies)
2. Launch an Administrator PowerShell CLI by typing this in a regular PowerShell window: `start-process powershell -verb runas`
3. Ensure the **ExecutionPolicy** is set to **RemoteSigned** by issing the following command: `Get-ExecutionPolicy`
   - The execution policy may be changed to **RemoteSigned** or **Unrestricted** by typing: `Set-ExecutionPolicy RemoteSigned` or `Set-ExecutionPolicy Unrestricted`
4. Navigate to the root directory where you downloaded the ScriptingToolkit. Example: `cd c:\scripts\ScriptingToolkit`
5. Launch the toolkit by typing: `.\Launcher.ps1`
   - Ensure you can see the .Launcher.ps1 file by typing: `ls`

### Method 2 - Using Toolkit Shortcuts
1. Ensure you install the [shortcuts](#toolkit-shortcuts) by using the (Admin)[#the-admin-menu] menu within the toolkit.
2. Launch a PowerShell CLI
3. Type `tk`

## Toolkit Shortcuts
The toolkit comes with a standard set of shortcuts that eases launching the toolkit and performing common tasks. It accomplishes this by installing a [PowerShell profile](https://technet.microsoft.com/en-us/library/bb613488(v=vs.85).aspx) to `%UserProfile%\My Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`. The template is located in [Templates\Microsoft.PowerShell_profile.ps1](Templates\Microsoft.PowerShell_profile.ps1). You can add additional aliases to the template by adding to the examples in the file.

### Available Shortcuts
* `ras` - Launches a PowerShell CLI with a smartcard
* `sudo` - Launches an administrator PowerShell CLI
* `tk` - Launches the ScriptingToolkit

### Installing the Shortcuts
1. With the toolkit running, navigate to the [Admin](#the-admin-menu) menu
2. Locate the **Install Aliases** option
3. Press the number next to the option and press enter

### Using the Shortcuts
1. Launch a PowerShell CLI
2. Type one of the shortcuts such as `tk`

## The config.json
The [config.json](Templates\config.json) is the main component of the toolkit that allows the use of standardized variables throughout the environment. Please see the [CONFIG.md](Templates\CONFIG.md) help file to learn more about customizing the file.

## The Admin Menu
The Admin menu is where you can perform certain actions to simplify repetitive tasks like launching a new administrative PowerShell window.

# Dependencies

## Required Dependencies
The dependencies listed in this section are **required** for the toolkit to run.
1. [Windows Management Framework 5](https://www.microsoft.com/en-us/download/details.aspx?id=54616) or higher

## Optional Dependencies
The dependencies listed in this section are **not required** for the toolkit to run. There are optional features like GIT integration, remote access, and log viewing that typically helps in any scripting environment.
1. [Windows Sysinternals](https://technet.microsoft.com/en-us/sysinternals/dd443648.aspx)
2. [Git 2.19.1](https://git-scm.com/downloads) or higher
3. [Configuration Manager Trace Log Viewer](https://www.microsoft.com/en-us/download/details.aspx?id=50012)
   - `CMTrace.exe` Located in `C:\Program Files (x86)\ConfigMgr 2012 Toolkit R2\ClientTools` after the install

# About the Developer
Phillip A. Dieppa developed and refined this toolkit framework for nearly 6 years. He initially developed over 30 different scripts that were used when he was serving as a Server Administrator while deployed with the US Army in Afghanistan. His scripts became popular while deployed and many administrators relied on the scripts he developed. He developed a beta version of the toolkit that packaged the scripts but lacked a central repository that was easily updatable. He continued to generate more scripts, in addition to refining his old scripts at Fort Campbell, Kentucky. He addressed issues and developed new features that composes this robust framework in 2015. He continues to periodically refine the toolkit based off feedback from administrators. Feel free to send your feedback directly to his e-mail at mrdieppa@gmail.com 

Phillip A. Dieppa is currently serving in the US Army as a Chief Warrant Officer 3 stationed in Redmond, Washington with duty at Microsoft Headquarters. Phil has served in the IT industry with the US Army for 14 consecutive years and has served in Georgia, North Carolina, Tennessee, Washington, Italy, Iraq and Afghanistan. His typical duties include server administration. He has formal education in the form of an Associate's and Bachelor's degree in Computer Science. He considers his programming niche to be language agnostic but he tends to develop in PowerShell and C#.

If you want to learn more about Phillip A. Dieppa, check out his [LinkedIn](https://www.linkedin.com/in/phillipdieppa/) profile. 