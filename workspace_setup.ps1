param(
    [Parameter(Mandatory=$false)]
    [string]$PowerShellUtilsPath= "includes\powershell_utils",
    
    [Parameter(Mandatory=$false)]
    [string]$RunMode="normal",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFileUrl="config.xml" 
)

# Locale Setting
$Language = (get-host).CurrentCulture.Name;



[xml]$Configuration = Get-Content (Resolve-Path $ConfigFileUrl)

#######################################################################################################################
# 
# Program Settings
#
#######################################################################################################################
#get all settings nodes
$SettingsNodeList                   = $Configuration.SelectNodes("//setting")
$DownloadsCfgNode                   = $Configuration.SelectSingleNode("//downloads_config")
$EnvironmentCfgNode                 = $Configuration.SelectSingleNode("//environment_config")
$ActionsNode                        = $Configuration.SelectSingleNode("//actions")
$ActionsNodeList                    = $Configuration.SelectNodes("//actions/action")

# Validate Downloads File location
if($DownloadsCfgNode -eq $null -or $DownloadsCfgNode.url -eq $null){
    Write-Error "downloads_config NODE expected in Configuration File $ConfigFileUrl"
    exit;
}
else{
    Write-Host "Downloads Config Url $($DownloadsCfgNode.url)" -foregroundcolor "DarkCyan"
}

# Validate Environment File Location
if($EnvironmentCfgNode -eq $null -or $EnvironmentCfgNode.url -eq $null){
    Write-Error "environment_config NODE expected in Configuration File $ConfigFileUrl"
    exit;
}



#######################################################################################################################
# 
# set all the initial variable values from configuration
#
#######################################################################################################################
foreach($SettingNode in $SettingsNodeList){

    if($SettingNode.nature -eq 'assign'){
        $expr       = "$($SettingNode.id)='$($SettingNode.value)'"
    }
    elseif($SettingNode.nature -eq 'var'){
    
        $expr       = "Set-Variable $($SettingNode.id) -value $(SettingNode.value)"

        if($SettingNode.scope -ne  $null){
            $expr   += " -scope $SettingNode.scope"
        }
        
        # todo -explore multiple options
        if($SettingNode.option -ne $null){
            $expr   += " -option $($SettingNode.option)"
        }
    }

    Write-Host "  > $expr" -foregroundcolor "DarkGray"

    Invoke-Expression $expr
}

Write-Debug     "[Debugging Enabled]"
Write-Verbose   "[Verbose Logging Enabled]"


#######################################################################################################################
# 
# LOAD Environment and Installer XML
#
#######################################################################################################################
# configures our system for work
[string]$url = Resolve-Path $EnvironmentCfgNode.url
if(!(Test-Path $url)){
    Write-Error "Could not load Environment Configuration at url $url"
    exit
}
else{
    Write-Host "Environment Configuration Url $url" -foregroundcolor "DarkCyan"
}
[xml]$EnvironmentConfiguration      = Get-Content $url


$url = Resolve-Path $DownloadsCfgNode.url

if(!(Test-Path $url)){
    Write-Error "Could not load Downloads Configuration at url $url"
    exit
}
else{
    Write-Host "Environment Downloads Configuration Url $url" -foregroundcolor "DarkCyan"
}
# downloads the installers and opens the directory where they were downloaded
[xml]$DownloadsConfiguration        = Get-Content $url


# Initial running directory
Set-Variable POWERSHELL_UTILS_WORKING_DIR -Option Constant -Scope Global -Value (Get-Location).Path
Set-Variable WorkspaceRootDir             -Scope Global -Value (Get-Location).Path
Set-Variable DownloadDirectory            -Scope Global -Value ((Get-Location).Path + "/downloads")
#######################################################################################################################
# 
# The powershell utils library path loaded from configuration
#
#######################################################################################################################

if($LibraryPath -eq $null){
    Write-Error "Library Path was invalid, check Config.xml for <setting id=$LibraryPath/>"
    exit
}

Set-Variable POWERSHELL_UTILS_HOME      -Option Constant  -Scope Global -Value ( Resolve-Path $LibraryPath )

# These globals are for the logger, $LoggingDirectory is expected to be in configuration
Set-Variable POWERSHELL_UTILS_LOG_DIR   -Option Constant  -Scope Global -Value ( Resolve-Path $LoggingDirectory )
Set-Variable POWERSHELL_UTILS_LOG_FILE  -Option Constant  -Scope Global -Value "$POWERSHELL_UTILS_LOG_DIR\$LogFile"

# Dot-Source the PowerShell Utils Library
# After globals have been set, include the library file from its 'absolute' location
# from here out, all of its includes will be based of the $POWERSHELL_UTILS_HOME constant
. "$POWERSHELL_UTILS_HOME\library.ps1"


# if we supplied a logger level
if($LoggerLevel -ne $null){
    Set-Variable LOGGER_LEVEL               -Scope Global -Value $LoggerLevel
}
# default to debug
else{
    Set-Variable LOGGER_LEVEL              -Scope Global -Value $global:LOG_LEVEL.Debug
}
# Set the window title from the $ProgramTitle from config file
if($ProgramTitle -ne $null){
    $RawUI.WindowTitle              = $Host.UI.RawUI.WindowTitle.Substring(0, $RawUI.WindowTitle.IndexOf('-')) + "- $ProgramTitle"
}

Log-Message -Message "Language: $Language"                                  -Level $global:LOG_LEVEL.Info -WriteToLog
Log-Message -Message "Running Directory: $POWERSHELL_UTILS_WORKING_DIR"     -Level $global:LOG_LEVEL.Info -WriteToLog

Start-Sleep -s 2

$result                             = ( Show-Alert                                                      `
                                        -Message "$ProgramTitle will now configure your Workspace." `
                                        -Title "$ProgramTitle"                                      `
                                        -DialogType 0x30                                            `
                                        -SecondsToWait 10 )

$PROMPT_MSG_TIMEOUT                 = "User didn't start Workspace Setup, shutting down"

# A Code, either 0, or 1 (Halt or Proceed, respectively)
$proceedOrHalt                      = PromptResult-ProceedOrHalt `
                                        -SleepOnPositive 1000   `
                                        -SleepOnNegative 500    `
                                        -Response $result

if( $proceedOrHalt -eq $HALT ){
    exit; 
}

# SETUP ACTIONS
$actionsDirectory = $ActionsNode.directory;

#dot-source and run actions
foreach($ActionNode in $ActionsNodeList){

    $actionScriptLocation = Resolve-Path "$($global:POWERSHELL_UTILS_WORKING_DIR)\$actionsDirectory\$($ActionNode.url)"
    
    if(File-Exists -File $actionScriptLocation){
        Log-Message -Message "Loading Action $actionScriptLocation" -Level $global:LOG_LEVEL.Verbose -WriteToLog
        
        . $actionScriptLocation
        
        if($ActionNode.hook -ne $null)
        {
            #single word check
            $regex = "\w+" #"^[a-z]+\.[a-z]+@contoso.com$"
            # $regexName = "(^[a-z,A-Z]+\-*)+[a-z,A-Z]+"
            if($ActionNode.hook -notmatch $regex){
                Write-Error "Hooks must be a single word, a valid function name with no parameters to initialize the script"
            }
            else{
                $found = $false
                Get-Command -CommandType function | % { if($_.Name -eq $ActionNode.hook){ $found = $true}}
                if($found){
                    Invoke-Expression $ActionNode.hook
                    
                    # remove the custom action, its ONLY a one off, use the force flag to avoid
                    # constant or global 'hacks'
                    Invoke-Expression "Remove-Item function:$($ActionNode.hook) -force"
                    
                }
                else{
                    Write-Error "Initial Method $($ActionNode.hook) could not be executed, please check the hook name for valid format and spelling, and try again"
                }
            }
        }
    }
    else{
        Log-Message -Message "Action $actionScriptLocation Could not be loaded"
    }
}

Write-Host ""
Write-Host "Workspace Setup has Completed" -foregroundcolor $COLOR_MSG_JOB_COMPLETE

Get-Invoke-Expression-Result -Expression "cd $POWERSHELL_UTILS_WORKING_DIR" -PrintResult