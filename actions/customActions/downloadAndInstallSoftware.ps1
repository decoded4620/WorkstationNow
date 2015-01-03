<#
.SYNOPSIS
    Reset the Workspace Root Directory
.DESCRIPTION
    This Custom Action will allow the user to choose his root workspace location via Directory Browsing Dialog
    This should be run near the beginning of the action list of a workspace setup, prior to any WorkspaceRootDir dependent actions / filesystem changes
.NOTES
    File Name      : setWorkspaceRootDirectory.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE
#>
function downloadAndInstallSoftware
{
    #######################################################################################################################
    # 
    # DOWNLOADED INSTALLERS
    #
    #######################################################################################################################

    $result                     = ( Show-Alert -Message "Would you like to download and install software?" -Title "$ProgramTitle" -DialogType 0x4 -SecondsToWait 20 )

    # A Code, either 0, or 1 (Halt or Proceed, respectively), also prints the result message on the screen
    $PROMPT_MSG_NO              = "User Declined to Download Software."
    $PROMPT_MSG_TIMEOUT         = "User failed to Download Software in a timely manner."

    $proceedOrHalt              = PromptResult-ProceedOrHalt -SleepOnPositive 1000 -SleepOnNegative 500 -Response $result

    if($proceedOrHalt -eq $PROCEED )
    {
        Write-Headline -Message "Download And Install Software"

        # Does our download dir exist?
        $Downloads_Dir_Exists = Test-Path $DownloadDirectory -pathType 'container';
        if($Downloads_Dir_Exists){
            # Where we WANT to download software to
            $DownloadDirectory = Resolve-Path $DownloadDirectory
            Recycle-Item -Path ( $DownloadDirectory )
        }
        
        # if not, create it
        if($Downloads_Dir_Exists -eq $false){
            New-Item -ItemType directory -Path "$DownloadDirectory"
        }

        $InstallerNodes = $DownloadsConfiguration.SelectNodes("//Installer");

        [System.Collections.ArrayList]$InstallerDownloadRequests = New-Object System.Collections.ArrayList
        [System.Collections.ArrayList]$InstallerConfigurations = New-Object System.Collections.ArrayList
        
        $ScriptBlock = { 
            $Request                = New-Download-Request -DestinationDirectory $DownloadDirectory -DataProvider $_; 
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
}