#############################################################################################################################
<#
.SYNOPSIS
    
.DESCRIPTION
    
.NOTES
    File Name      : perforce.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE

#>
function Is-InstallerConfiguration( [psobject]$InputObject )
{
    $validated = ( Validate-Type-Properties         `
                        -InputObject $InputObject `
                        -Properties @('DownloadRequest'))

    $validated
}

#############################################################################################################################
<#
.SYNOPSIS
    
.DESCRIPTION
    
.NOTES
    File Name      : perforce.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE

#>
function New-InstallerConfiguration {
    param(
        [Parameter(
            Mandatory=$true
        )]
        $DownloadRequest
    )
    
    if(Is-DownloadRequest -InputObject $DownloadRequest){
        $retVal = New-Object psobject -property @{
            DownloadRequest             = $DownloadRequest
        }
    }
    else{
        $retVal = $null
    }
    
    $retVal
}


function Get-InstalledSoftware(){

    [System.Collections.ArrayList]$InstalledItems = New-Object System.Collections.ArrayList;
    
    $ScriptBlock = {
        
        if($_.DisplayName -ne $null){
         
            $obj = New-Object psobject @{
                Name            = $_.DisplayName
                Version         = $_.DisplayVersion
                Publisher       = $_.Publisher
                InstallDate     = $_.DisplayName.InstallDate
            }
            
            $InstalledItems.Add($obj)
        }
    }
    
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName| % $ScriptBlock
    Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Sort-Object DisplayName | % $ScriptBlock
    
    $InstalledItems
}

function Is-Installed([string]$InstalledProgramName, [bool]$ExactMatch=$true){

    Log-Message -Message "[Is-Installed]$InstalledProgramName ( ExactMatch $ExactMatch )" -Level $global:LOG_LEVEL.Pending
     $found = $false;
    if($ExactMatch){
        $ScriptBlock = {
            if($found -eq $false -and $_.Name -eq $InstalledProgramName){
                $found = $true
            }
        }
        Get-InstalledSoftware | % -Process $ScriptBlock
    }
    else{
        $ScriptBlock = {
            if($found -eq $false -and $_.Name.IndexOf($InstalledProgramName) -gt -1){
                $found = $true
            }
        }
        Get-InstalledSoftware | % -Process $ScriptBlock
    }
    Log-Message -Message "[Is-Installed]$InstalledProgramName ( ExactMatch $ExactMatch ) Result: $found" -Level $global:LOG_LEVEL.Success
    $found
}


<#
.SYNOPSIS
    Perform an Installation, using an Installation Configuration
.DESCRIPTION
    Perform an Installation, using an Installation Configuration
.NOTES
    File Name      : utilities.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
    
.LINK

.EXAMPLE
    
.EXAMPLE
    
#>
function Install ( [System.Collections.ArrayList]$List )
{
    $BeginScript = { $SoftwareList = "`n" }
    $ScriptBlock = {
        $jobName = $_.DownloadRequest.DataProvider.Name
        $source = $_.DownloadRequest.Source
        
        $SoftwareList += "`n  -- $jobName"
    }
    
    $EndScript = {
        $result = ( Show-Alert                                                  `
                        -Message    "Installing Software Suite $SoftwareList"   `
                        -Title      "Installer Shell"                           `
                        -DialogType 0x0                                         `
                        -SecondsToWait 10 )
    }
    $List | ForEach-Object -Process $ScriptBlock -End $EndScript -Begin $BeginScript
    
    $BeginBlock = { }
    
    # Loop Body Executed for every item in $List
    $ScriptBlock = {
        
        if((Is-InstallerConfiguration -InputObject $_) -eq $true)
        {
            $DownloadRequest            = $_.DownloadRequest
            # Configuration DataProvider (XmlNode)
            $DataProvider               = $DownloadRequest.DataProvider

            $alreadyInstalled = $false;
            
            if($DataProvider.InstalledProgramName -ne $null){
                $alreadyInstalled = Is-Installed -InstalledProgramName $DataProvider.InstalledProgramName -ExactMatch ($DataProvider.InstalledNameCheckExactMatch -ne $false)
            }
            
            $jobSource                  = $DownloadRequest.Source;
            $jobDestination             = $DownloadRequest.Destination;
            
            if( $alreadyInstalled -eq $false ){
            
                if( Test-Path $jobDestination -pathType leaf )
                {
                    $jobName                = $DataProvider.Name
                    Log-Message -Message "Installing $jobName in 1 second" -Level $global:LOG_LEVEL.Verbose
                    Start-Sleep -s 1

                    $Nature                 = $DataProvider.Nature
                    $InstallerFile          = $DataProvider.InstallerFile
                    $extractTo              = $DataProvider.ExtractTo
                    $moveTo                 = $DataProvider.MoveTo
                    
                    # For Zip Files, we need to extract and move the contents.
                    if($Nature -eq 'zip'){

                        $jobDestParentDirectory = Get-Parent -Path $jobDestination
                        SetReadWritePriviledges -Path $jobDestParentDirectory;
                        
                        $unzipDestination = "$jobDestParentDirectory\$extractTo";
                        $zipResult = Unzip -File $jobDestination -Destination $unzipDestination

                        if($zipResult -eq $true)
                        {
                            $fileName = Split-Path $unzipDestination -leaf
                            
                            $existenceCheckPath = "$moveTo$fileName"
                            if(Test-Path "$moveTo$fileName"){
                                Log-Message -Message "Removing old item $fileName => $existenceCheckPath" -Level $global:LOG_LEVEL.Pending -WriteToLog
                                
                                $recyled = Recycle-Item($existenceCheckPath)
                                
                                if($recyled){
                                    $lvl = $global:LOG_LEVEL.SUCCESS
                                }else{
                                    $lvl = $global:LOG_LEVEL.FAIL
                                }

                                Log-Message -Message "Item Removed: $recycled" -Level $lvl -WriteToLog
                            }

                            $expr ='move ' + '"'+ $unzipDestination + '" "' + $moveTo + '"';
                            
                            Get-Invoke-Expression-Result -Expression $expr -PrintResult
                            
                            #  If there is an additional installer file to run, we'll run it
                            if($InstallerFile -ne '' -and $InstallerFile -ne $null){
                                Log-Message -Message "Process starting $unzipDestination/$InstallerFile" -Level $global:LOG_LEVEL.Info -WriteToLog
                                $ProcessDesc = Start-Process -FilePath "$unzipDestination/$InstallerFile" -Wait -Passthru
                            }
                        }
                        else
                        {
                            Write-Console "File $jobDestination could not be extracted to $unzipDestination"
                        }
                    }
                    elseif($Nature -eq 'msi' -or $Nature -eq 'exe'){
                        Write-Console -Message "Process starting $jobDestination" -Color $COLOR_MSG_JOB_START
                        $ProcessDesc = Start-Process -FilePath "$jobDestination" -Wait -Passthru
                    }
                    elseif( $Nature -eq 'iso'){
                        Write-Console -Message "Storing ISO file, will need to be installed via Virtual Machine Software" -Color $COLOR_MSG_JOB_START
                    }
                    else{
                        Write-Console -Message "Warning nature not specified for $jobDestination" -Color $COLOR_MSG_ERROR
                    }

                    if($DataProvider.Env -ne $null){
                    
                        foreach($Variable in $DataProvider.Env.Var){
                        
                            Set-Environment-Variable                    `
                                -Name $Variable.key                     `
                                -Level $Variable.level                  `
                                -ValueType $Variable.valueType          `
                                -Prompt ($Variable.prompt -eq 'true')   `
                                -AppendToCurrentValue ($Variable.setType -eq 'APPEND') `
                                -AllowDuplicateAppend ($Variable.allowDuplicateAppend -eq 'true') `
                                -Value $Variable.defaultValue
                        }
                    }

                    # Refresh the Local Path Variable in case it was changed
                    $newValue = Get-Environment-Variable -Name "Path" -Level "Machine"
                    
                    if($env:Path -ne $newValue){
                        Write-Console -Message "Path Updated to $newValue after installation of $jobName" -Color $COLOR_MSG_ITEM_START -WriteToLog
                        $env:Path = $newValue;
                    }

                    if( $DataProvider.ScriptHook -ne $null)
                    {
                        $ScriptHookPath = "$($global:POWERSHELL_UTILS_WORKING_DIR)\$($DataProvider.ScriptHook)";
                        
                        Log-Message -Message "Include Dynamic Script $ScriptHookPath" -Level $global:LOG_LEVEL.Info -WriteToLog
                        
                        if(Test-Path ($ScriptHookPath)){
                            $ScriptHookPath = Resolve-Path $ScriptHookPath
                            
                            # .source the file
                            . $ScriptHookPath
                            
                            if($DataProvider.ScriptHookStart -ne $null){
                            
                                Log-Message -Message "Calling Script Method $($DataProvider.ScriptHookStart)" -Level $global:LOG_LEVEL.Info -WriteToLog
                                #single word check
                                $regex = "\w+"
                                
                                if($DataProvider.ScriptHookStart -notmatch $regex){
                                    Log-Message -Message "Hooks must be a single word, a valid function name with no parameters to initialize the script" -Level $global:LOG_LEVEL.Error -WriteToLog
                                }
                                else{
                                    $found = $false
                                    Get-Command -CommandType function | % { if($found -eq $false -and $_.Name -eq $DataProvider.ScriptHookStart){ $found = $true }}
                                    if($found){
                                        Invoke-Expression $DataProvider.ScriptHookStart
                                        
                                        # remove the custom action, its ONLY a one off, use the force flag to avoid
                                        # constant or global 'hacks'
                                        Invoke-Expression "Remove-Item function:$($DataProvider.ScriptHookStart) -force"
                                        
                                    }
                                    else{
                                        Log-Message -Message "Initial Method $($DataProvider.ScriptHookStart) could not be executed, please check the hook name for valid format and spelling, and try again" -Level $global:LOG_LEVEL.Error -WriteToLog
                                    }
                                }
                            }
                        }
                        else{
                            Log-Message -Message "Dynamic Script $ScriptHookPath not found" -Level $global:LOG_LEVEL.Error -WriteToLog
                        }
                    }
                    
                    if($DataProvider.Commands -ne $null){
                    
                        foreach($Command in $DataProvider.Commands.Command){
                        
                            if($Command.Value -ne "" -and $Command.Value -ne $null){
                                Get-Invoke-Expression-Result -Expression $Command.Value -PrintResult
                            }
                            
                            Start-Sleep -m 50
                        }
                    }
                }
                else{
                    Log-Message -Message "Could not find installer at $jobDestination" -Level $global:LOG_LEVEL.Error -WriteToLog
                }
            }else{
                Log-Message -Message "$($DataProvider.InstalledProgramName) is already installed on this machine" -Level $global:LOG_LEVEL.Warn -WriteToLog
            }
        }
        else{
            Log-Message -Message "Object was Incorrectly Typed, exected an InstallerConfiguration, use New-InstallerConfiguration to create one" -Level $global:LOG_LEVEL.Error -WriteToLog
        }
    }
    
    $EndBlock = { }
    
    # Run the Loop with the List Contents
    $List | ForEach-Object -Begin $BeginBlocK -End $EndBlock -Process $ScriptBlock 
}