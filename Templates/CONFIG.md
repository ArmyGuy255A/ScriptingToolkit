# The Config.ini File
The config.ini is the component that makes this toolkit portable between environments. The toolkit converts the `config.ini` into a global variable upon launching. The code responsible for all interaction with the `config.ini` is the [ConfigData.ps1](..\Libraries\ConfigData.ps1) file. There are two categories of parameters contained within the `config.ini`. There are [required](#required-parameters) and [environment](#environment-parameters) parameters. [Required parameters](#required-parameters) must be present for the toolkit framework to function. [Environment parameters](#environment-parameters) are custom parameters needed for your environment. Examples of [Required parameters](#required-parameters) are used for features like versioning and updates. Examples of [Environment parameters](#environment-parameters) include special directories, expiration requirements, server names, naming conventions, or boolean values. Using the parameters within your environment is very easy. See the section on [Using Parameters](#using-parameters) within your scripts. See the section on [Creating New Parameters](#creating-new-parameters) for customizing your environment.

## Required Parameters
### \[ToolkitName\]
This parameter rebrands the toolkit to your environment
### \[Version\]
The current version of the toolkit in the following format: \[Major\].\[Minor\].\[Revision\] <br />
**1** - Major Versions - Any changes to the config.ini should result in a major version change <br />
**2** - Minor Versions - Any new scripts, files or directories should result in a minor version change <br />
**3** - Revisions - Any updates made to existing scripts or files should result in a revision change <br />
### \[LogDirectory\]
The directory where all log files will be deposited. This may be a relative or static directory location
### \[UpdatesEnabled\]
Enables the download feature in the toolkit
### \[UpdateDirectory\]
The shared directory where the toolkit can be uploaded and downloaded
### \[GITEnabled\]
Enables GIT funcationality in the Admin menu. Ensure the [GIT Optional Dependency](..\README.MD#optional-dependencies) is installed before enabling this parameter
### \[GITRepository\]
The GIT repository of the current branch
### \[EnableAdminUploader\]
Enables the upload feature in the toolkit
### \[DebugMode\]
Turns off the Clear-Host commands to make error viewing easier.

## Environment Parameters
This section should be filled out when a new parameter is created. See the section on [creating](#creating-new-parameters) new parameters.


## Using Parameters

## Creating New Parameters
Parameters can be easily added at any time during the development process. There are only three rules to follow when creating new parameters
1. **Avoid spaces in parameter names** <br />
   **Example:** Use \[UserAccountOU\] instead of \[User Account OU\]
2. **Ensure the parameter is enclosed with square brackets** <br />
   **Example:** Use **[**\UserAccountOU**]** instead of UserAccoun OU
3. **Ensure there is at least one space between different parameter sections** <br />
   **Example:** <br />
   **Use**<br />
   `[UserAccountOU]`<br />
   `OU=Users,OU=Finance,DC=CONTOSO,DC=COM`<br /><br />
   `[WorkstationOU]`<br />
   `OU=Computers,OU=Finance,DC=CONTOSO,DC=COM`<br /><br />
   `[ServerOU]`<br />
   `OU=Servers,DC=CONTOSO,DC=COM`<br />
   **Instead of**
   `[UserAccountOU]`<br />
   `OU=Users,OU=Finance,DC=CONTOSO,DC=COM`<br />
   `[WorkstationOU]`<br />
   `OU=Computers,OU=Finance,DC=CONTOSO,DC=COM`<br />
   `[ServerOU]`<br />
   `OU=Servers,DC=CONTOSO,DC=COM`<br />

### Parameters with Multiple Values
Parameters can have multiple values that will be turned into an array at runtime. For example:
`\[UserAccountOU\]<br />
OU=Users,OU=Finance,DC=CONTOSO,DC=COM<br />
OU=Users,OU=Marketing,DC=CONTOSO,DC=COM<br />
OU=Users,OU=Sales,DC=CONTOSO,DC=COM<br />
OU=Users,OU=Engineering,DC=CONTOSO,DC=COM<br />`

The UserAccountOU parameter will be turned into a 4 object array of strings that can be accessed by typing `$configData.UserAccountOU`. You can use a standard `foreach` statement to iterate through the parameter or you can access individual members by specifying the index of the object such as `$configData.UserAccountOU[0]`

### Parameters with Single Values
Parameters convert to common [PowerShell Data Types](https://ss64.com/ps/syntax-datatypes.html) at runtime. They convert into booleans, strings, decimals, or dates based on the value.
* Booleans
  * True
  * Yes
  * On
  * False
  * No
  * Off
* Strings
  * Any variable that contains non-numeric ASCII characters
* Decimals
  * Any numeric ASCII value with a decimal
* Integer
  * Any numeric ASCII value

