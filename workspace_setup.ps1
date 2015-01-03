param(
    [Parameter(Mandatory=$false, HelpMessage=" ")]
    [string]$PowerShellUtilsPath= $null,
    [string]$RunMode
)

$DebugPreference            = "Continue"
$VerbosePreference          = "Continue"

# Default location to check if none is provided at startup
if($PowerShellUtilsPath -eq $null){
    $PowerShellUtilsPath = "includes\powershell_utils"
}

Set-Variable POWERSHELL_UTILS_WORKING_DIR -Option Constant -Scope Global -Value((Get-Location).Path.ToString()) 
# Setup The powershell utils library globals. 
Set-Variable POWERSHELL_UTILS_HOME      -Option Constant  -Scope Global -Value ( Resolve-Path "includes\powershell_utils" )

# These globals are for the logger
Set-Variable POWERSHELL_UTILS_LOG_DIR   -Option Constant  -Scope Global -Value "$POWERSHELL_UTILS_HOME\~logs"
Set-Variable POWERSHELL_UTILS_LOG_FILE  -Option Constant  -Scope Global -Value "$POWERSHELL_UTILS_LOG_DIR\log.txt"

# Dot-Source the PowerShell Utils Library
# After globals have been set, include the library file from its 'absolute' location
# from here out, all of its includes will be based of the $POWERSHELL_UTILS_HOME constant
. "$POWERSHELL_UTILS_HOME\library.ps1"


if(Test-Path "downloads"){
    Recycle-Item -Path ( Resolve-Path "downloads" )
}


# Window Title
$ProgramTitle = "Workspace Setup"
$RawUI.WindowTitle = $Host.UI.RawUI.WindowTitle.Substring(0, $RawUI.WindowTitle.IndexOf('-')) + "- $ProgramTitle"
Write-Headline -Message "$($RawUI.WindowTitle) Starting..." -Color $GREEN -WriteToLog

Write-Console -Message "PowerShell Utils Working Directory => $POWERSHELL_UTILS_WORKING_DIR   " -Color $global:DARKCYAN -Ticker $true -TickInterval 5

$result = ( Show-Alert `
                -Message "$ProgramTitle will now configure your Workspace." `
                -Title "$ProgramTitle" `
                -DialogType 0x30 `
                -SecondsToWait 10 )
                
Write-Host "RESULT: $result"
$PROMPT_MSG_TIMEOUT         = "User didn't start Workspace Setup, shutting down"
# A Code, either 0, or 1 (Halt or Proceed, respectively)
$proceedOrHalt = PromptResult-ProceedOrHalt `
                    -SleepOnPositive 1000 `
                    -SleepOnNegative 500 `
                    -Response $result

if( $proceedOrHalt -eq $HALT ){
    exit;
}
# Running Location of THIS Script
$Location                   = Get-Location

 # for a directory location
$NewLocation = (Read-FolderBrowserDialog -Message "Select a Workspace Root Location" -Title "$ProgramTitle" )

if(![string]::IsNullOrEmpty($NewLocation))
{
    Write-Console -Message "Workspace Root Selected $NewLocation" -Color $global:COLOR_MSG_ITEM_COMPLETE
    
    # change to the new location
    Get-Invoke-Expression-Result -Expression "cd $NewLocation" -PrintResult
    
    $Location               = Get-Location
}

[string]$WorkspaceRootDir   = $Location.Path;

# STEP 1
#Get the Perforce Home Repository Location (we *could* use this for a path variable as well)

#######################################################################################################################
# 
# LOAD Environment and Installers XML
#
#######################################################################################################################
# configures our system for work
[xml]$EnvironmentConfiguration      = Get-Content "$POWERSHELL_UTILS_WORKING_DIR\env.xml"
# downloads the installers and opens the directory where they were downloaded
[xml]$DownloadsConfiguration        = Get-Content "$POWERSHELL_UTILS_WORKING_DIR\downloads.xml"


#######################################################################################################################
# 
# CREATE COMMON DRIVE MAPPING
#
#######################################################################################################################
# Map our hard disk to a local 'substitute' so we can all have
# the same 'path' to our workspaces, but still have them in 'unique' locations
Write-Headline -Message "$ProgramTitle is Configuring Mapped Hard-Disks" -Color $COLOR_MSG_JOB_START
$Config = ( Configure-Drive-Mapping -XML $EnvironmentConfiguration -xPath "Environment/System/WorkspaceDriveMapping" -WorkspaceRoot $WorkspaceRootDir -Prompt $true   )

Write-Host "CONFIG: $Config"
if($Config -ne $null )
{
    Write-Host "Mapping Created"
    #  if subst was a success, we'll update our working directories for further transactions now.
    # This means the Perforce workspace mappings, and other directory based settings will use this new mapped
    # drive value
    $WorkspaceRootDir           = $Config.VirtualDriveLetter
    
    # Change to new drive
    Get-Invoke-Expression-Result                                        `
        -Expression "$($Config.VirtualDriveLetter):"                 `
        -Explanation "Change Drive [$($Config.VirtualDriveLetter)]" `
        -PrintResult
        
    # change to our new current mapped directory. This way p4 workspace commands will use this mapping
    # rather than the actual drive letters                  
    Get-Invoke-Expression-Result                            `
        -Expression "dir"                  `
        -Explanation ""  `
        -PrintResult
    
    $WorkspaceRootConfigXML     = $EnvironmentConfiguration.SelectSingleNode("Environment/System/WorkspaceRoot");
    # Used to set the environment variable for workspace root
    [string]$WorkspaceRootKey   = $WorkspaceRootConfigXML.environmentVarKey
    [string]$level              = $WorkspaceRootConfigXML.level
    [string]$valueType          = $WorkspaceRootConfigXML.valueType
    [bool]$prompt               = ( $WorkspaceRootConfigXML.prompt -eq 'true' )
    [bool]$append               = ( $WorkspaceRootConfigXML.append -eq 'true' )
    
    # Set our environment variable
    ( Set-Environment-Variable -Name $WorkspaceRootKey -Value $WorkspaceRootDir -Level $level -ValueType $valueType -Prompt $prompt -AppendToCurrentValue $append -AllowDuplicateAppend $false )
}
else{
    Write-Error "No Mappings!"
    exit;
}

#######################################################################################################################
# 
# DOWNLOADED INSTALLERS
#
#######################################################################################################################


$result             = ( Show-Alert -Message "Would you like to download and install software?" -Title "$ProgramTitle" -DialogType 0x4 -SecondsToWait 20 )

# A Code, either 0, or 1 (Halt or Proceed, respectively), also prints the result message on the screen
$PROMPT_MSG_NO      = "User Declined to Download Software."
$PROMPT_MSG_TIMEOUT = "User failed to Download Software in a timely manner."

$proceedOrHalt      = PromptResult-ProceedOrHalt -SleepOnPositive 1000 -SleepOnNegative 500 -Response $result

if($proceedOrHalt -eq $PROCEED )
{
    Write-Host ""
    Write-Host "$ProgramTitle is preparing to"
    Write-Host "-------------------------------------------------------------------------------------------"
    Write-Host "______                    _                 _   _____        __ _                          "
    Write-Host "|  _  \                  | |               | | /  ___|      / _| |                         "
    Write-Host "| | | |_____      ___ __ | | ___   __ _  __| | \ `--.  ___ | |_| |___      ____ _ _ __ ___ "
    Write-Host "| | | / _ \ \ /\ / / '_ \| |/ _ \ / _` |/ _` |  `--. \/ _ \|  _| __\ \ /\ / / _` | '__/ _ \"
    Write-Host "| |/ / (_) \ V  V /| | | | | (_) | (_| | (_| | /\__/ / (_) | | | |_ \ V  V / (_| | | |  __/"
    Write-Host "|___/ \___/ \_/\_/ |_| |_|_|\___/ \__,_|\__,_| \____/ \___/|_|  \__| \_/\_/ \__,_|_|  \___|"
    Write-Host "-------------------------------------------------------------------------------------------"

    # Where we WANT to download
    $DownloadsDir               = "$POWERSHELL_UTILS_WORKING_DIR\downloads"
    
    # Does our download dir exist?
    $Downloads_Dir_Exists       = Test-Path "$DownloadsDir" -pathType 'container'
    
    # if not, create it
    if($Downloads_Dir_Exists -eq $false){
        New-Item -ItemType directory -Path "$DownloadsDir"
    }

    $InstallerNodes = $DownloadsConfiguration.SelectNodes("//Installer");

    [System.Collections.ArrayList]$InstallerDownloadRequests = New-Object System.Collections.ArrayList
    [System.Collections.ArrayList]$InstallerConfigurations = New-Object System.Collections.ArrayList
    
    $ScriptBlock = { 
        $Request                = New-Download-Request -DestinationDirectory $DownloadsDir -DataProvider $_; 
        $addIndex               = $InstallerDownloadRequests.Add($Request); 
        $addIndex               = $InstallerConfigurations.Add((New-InstallerConfiguration -DownloadRequest $Request))
    }
    # Configure ALL Installers
    $InstallerNodes | ForEach-Object  -Process $ScriptBlock
    
    # Check for duplicate URL's in the request so we don't double download
    # NOTE: The Installers for these requests were NOT removed, so the install process will still attempt
    # to install the existing files that were found
    
    # Change the console output style to overwrite the current line for this block
    # It's informative without trashing the output window
    Set-ConsoleWriteMode -WriteMode $global:MODE_OVERWRITE;
    for($i = 0; $i -lt $InstallerDownloadRequests.Count; $i++){
    
        $InstallerDownloadRequest   = $InstallerDownloadRequests[$i]
        $jobDestination             = $InstallerDownloadRequest.Destination;
        $jobName                    = $InstallerDownloadRequest.DisplayName
        
        if(File-Exists -File $jobDestination ){
            Write-Console -Message "Skipping download $jobName [$jobDestination]" -Color $COLOR_MSG_ITEM_COMPLETE -WriteToLog
            $InstallerDownloadRequests.RemoveAt($i--)
        }
        else{
            $padded = "Queueing download : $jobName [$jobDestination]".PadRight(156);
            Write-Console -Message  $padded -Color $COLOR_MSG_ITEM_START -WriteToLog
        }
        Start-Sleep -m 250
    }
    Set-ConsoleWriteMode -WriteMode $global:MODE_APPEND;
    
    # Dowload any remaining resources
    if($InstallerDownloadRequests.Count -gt 0){
        (Download-Multiple-Remote-Resources -Requests $InstallerDownloadRequests -Parallel)
    }
    else{
        Write-Host "No Resources downloaded, all requested files currently exist in the download directory" -foregroundcolor $COLOR_MSG_JOB_COMPLETE
    }
    
    # Install the installers as configured prior to the download stage
    (Install -List $InstallerConfigurations)
}

#######################################################################################################################
# 
# PERFORCE
#
#######################################################################################################################

$result = ( Show-Alert -Message "Would you like to setup a Perforce Workspace?" -Title "$ProgramTitle" -DialogType 0x4 -SecondsToWait 60 )

# Default Negative Response messages
$PROMPT_MSG_NO      = "User Declined to setup perforce."
$PROMPT_MSG_TIMEOUT = "User failed to setup perforce in a timely manner."

# A Code, either 0, or 1 (Halt or Proceed, respectively), also prints the result message on the screen
$proceedOrHalt      = PromptResult-ProceedOrHalt -SleepOnPositive 1000 -SleepOnNegative 500 -Response $result

if($proceedOrHalt -eq $PROCEED ){
    Write-Host ""
    Write-Host "$ProgramTitle will now setup"
    Write-Host "-------------------------------------"
    Write-Host "______          __                   "
    Write-Host "| ___ \        / _|                  "
    Write-Host "| |_/ /__ _ __| |_ ___  _ __ ___ ___ "
    Write-Host "|  __/ _ \ '__|  _/ _ \| '__/ __/ _ \"
    Write-Host "| | |  __/ |  | || (_) | | | (_|  __/"
    Write-Host "\_|  \___|_|  |_| \___/|_|  \___\___|"
    Write-Host "-------------------------------------"

    ( Configure-Perforce-Workspace -XML $EnvironmentConfiguration -xPath "Environment/Perforce" )
}



$result             = ( Show-Alert -Message "Would you like to Update Environment Variables?" -Title "$ProgramTitle" -DialogType 0x4 -SecondsToWait 60 )

$PROMPT_MSG_NO      = "User Declined to update environment variables."
$PROMPT_MSG_TIMEOUT = "User failed to update environment variables in a timely manner."

# A Code, either 0, or 1 (Halt or Proceed, respectively), also prints the result message on the screen
$proceedOrHalt = PromptResult-ProceedOrHalt -SleepOnPositive 1000 -SleepOnNegative 500 -Response $result

if($proceedOrHalt -eq $PROCEED )
{
    Write-Host ""
    Write-Host "$ProgramTitle is updating Your System"
    Write-Host "------------------------------------------------------------"
    Write-Host " _____           _                                      _   "
    Write-Host "|  ___|         (_)                                    | |  "
    Write-Host "| |__ _ ____   ___ _ __ ___  _ __  _ __ ___   ___ _ __ | |_ "
    Write-Host "|  __| '_ \ \ / / | '__/ _ \| '_ \| '_ ` _ \ / _ \ '_ \| __|"
    Write-Host "| |__| | | \ V /| | | | (_) | | | | | | | | |  __/ | | | |_ "
    Write-Host "\____/_| |_|\_/ |_|_|  \___/|_| |_|_| |_| |_|\___|_| |_|\__|"
    Write-Host "------------------------------------------------------------"
                                                            
    #######################################################################################################################
    # 
    # SYSTEM LEVEL ENVIRONMENT VARIABLES FROM env.xml
    #
    #######################################################################################################################

    $VarNodes       = $EnvironmentConfiguration.SelectNodes("Environment/System/Settings/Vars/Var");

    # Read the Settings File and Updated Variables
    foreach( $Var in $VarNodes)
    {
        $key                        = $Var.key
        $valueType                  = $Var.valueType
        $level                      = $Var.level
        $setType                    = $Var.setType
        $prompt                     = ( $Var.prompt -eq 'true' )
        $append                     = ( $Var.setType -eq 'APPEND')
        $defaultValue               = $Var.defaultValue
        $isFolder                   = ( $Var.valueType -eq 'PATH' )
        $allowDuplicateAppend       = ( $Var.allowDuplicateAppend -eq 'true' )
        
        ( Set-Environment-Variable          `
            -Name $key                      `
            -Value $defaultValue            `
            -Level $level                   `
            -ValueType $valueType           `
            -Prompt $prompt                 `
            -AppendToCurrentValue $append   `
            -AllowDuplicateAppend $allowDuplicateAppend )
    }
}


Write-Host ""
Write-Host "Workspace Setup has Completed" -foregroundcolor $COLOR_MSG_JOB_COMPLETE

Get-Invoke-Expression-Result -Expression "cd $POWERSHELL_UTILS_WORKING_DIR" -PrintResult