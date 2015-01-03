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
    
    $BeginBlock = { Set-ConsoleWriteMode -WriteMode $global:MODE_OVERWRITE }
    
    # Loop Body Executed for every item in $List
    $ScriptBlock = {
        
        if((Is-InstallerConfiguration -InputObject $_) -eq $true)
        {
            $DownloadRequest            = $_.DownloadRequest
            # Configuration DataProvider (XmlNode)
            $DataProvider               = $DownloadRequest.DataProvider

            $jobSource                  = $DownloadRequest.Source;
            $jobDestination             = $DownloadRequest.Destination;
            
            if( Test-Path $jobDestination -pathType leaf)
            {
                $jobName                = $DataProvider.Name
                Write-Console "Installing $jobName in 1 second"
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
                            Write-Console -Message "Removing old item $fileName => $existenceCheckPath" -Color $COLOR_MSG_WARN
                            
                            Recycle-Item($existenceCheckPath)
                           
                            
                        }

                        $expr ='move ' + '"'+ $unzipDestination + '" "' + $moveTo + '"';
                        
                        Get-Invoke-Expression-Result -Expression $expr -PrintResult
                        
                        #  If there is an additional installer file to run, we'll run it
                        if($InstallerFile -ne '' -and $InstallerFile -ne $null){
                            Write-Console -Message "Process starting $extractTo/$InstallerFile" -Color $COLOR_MSG_JOB_START
                            $ProcessDesc = Start-Process -FilePath "$extractTo/$InstallerFile" -Wait -Passthru
                        }
                    }
                    else
                    {
                        Write-Console "File $jobDestination could not be extracted to $unzipDestination"
                    }
                }
                elseif($Nature -eq 'msi' -or $Nature -eq 'exe'){
                    Write-Console -Message "Process starting $extractTo/$InstallerFile" -Color $COLOR_MSG_JOB_START
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

                if($DataProvider.Commands -ne $null){
                
                    foreach($Command in $DataProvider.Commands.Command){
                    
                        if($Command.Value -ne "" -and $Command.Value -ne $null){
                            Get-Invoke-Expression-Result -Expression $Command.Value -PrintResult
                        }
                        
                        Start-Sleep -m 50
                    }
                }
            }
            else
            {
                Write-Console -Message "`rCould not find installer at $jobDestination" -Color $COLOR_MSG_ERROR -WriteToLog
            }
        }
        else
        {
            Write-Console -Message "Object was Incorrectly Typed, exected an InstallerConfiguration, use New-InstallerConfiguration to create one" -Color $COLOR_MSG_ERROR -WriteToLog
        }
    }
    
    $EndBlock = { Set-ConsoleWriteMode -WriteMode $global:MODE_APPEND}
    
    # Run the Loop with the List Contents
    $List | ForEach-Object -Begin $BeginBlocK -End $EndBlock -Process $ScriptBlock 
}

Write-Console -Message "[utils.install_manager] Library Script Included." -Color $MAGENTA -Ticker $true -TickInterval 2 