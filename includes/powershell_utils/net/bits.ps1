#import modules
Import-Module BitsTransfer

#20 minutes
$MaxDownloadTimeSeconds = 60 * 20;




function Is-DownloadRequest
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$InputObject
    )
    
    $validated = Validate-Type-Properties       `
                    -InputObject $InputObject   `
                    -Properties @('DisplayName', 'Source','Destination','DestinationDirectory','DataProvider')
                    
    $validated
}
<#
.SYNOPSIS
    Creates a new Download Request Object
.DESCRIPTION
    Prepares a DownloadRequest object for use with Download-Remote-Resource or Download-Multiple-Remote-Resources
.NOTES
    File Name      : utilities.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  $request = (New-Download-Request -Destination "" -DataProvider "")
  (Download-Remote-Resource -Request $request, -Parallel)
.EXAMPLE
    Example 2
#>
function New-Download-Request
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$DestinationDirectory,
        
        [Parameter(Mandatory=$true)]
        [psobject]$DataProvider
    )
    
   
    switch( $DataProvider.Protocol ){
        # World wide web request
        {($_ -eq "http") `
            -or ($_ -eq "https")`
            -or ($_ -eq "ftp")`
            -or ($_ -eq "sftp")`
            -or ($_ -eq "smtp") `
            -or ($_ -eq "ssh") `
            -or ($_ -eq "tcp") `
            -or ($_ -eq "telnet") `
            -or ($_ -eq "rtps")}{
            
             $Source = $_ + "://$($DataProvider.Url)"
        }
        # Windows shared folder, i.e. \\myshare\folder
        {($_ -eq "win-share")}
        {
            #use direct Url
            $Source = $DataProvider.Url
        }
        # Default Case
        default { 
            $Source = $_ + "://$($DataProvider.Url)"
        } 
    }
    
    if($DataProvider.Port -ne "" -and $DataProvider.Port -ne $null){
        $Source += ":$($DataProvider.Port)"
    }
    
    if($DataProvider.Path -ne "" -and $DataProvider.Path -ne $null ){
        $Source += $DataProvider.Path
    }
    
    if($DataProvider.Query -ne "" -and $DataProvider.Query -ne $null){
        $Source += "?$($DataProvider.Query)"
    }
    
    New-Object psobject -property @{
        DisplayName             = $DataProvider.Name
        Source                  = $Source
        Destination             = $DestinationDirectory + "\" + $DataProvider.LocalFile
        DestinationDirectory    = $DestinationDirectory
        DataProvider            = $DataProvider
        Status                  = 'Not Started'
        BytesTotal              = 0
        BytesTransferred        = 0
    }
}

<#
.SYNOPSIS
    Download A Single Remote File and store it locally in a destination directory
.DESCRIPTION
    Download A Single Remote File using the included DownloadRequest type provided by this utilities script
    and store the resulting File Locally based on the destination value in the DownloadRequest
.NOTES
    File Name      : utilities.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
    $req1 = New-Download-Request -DisplayName "Download Me" -Source "www.somesite.com/somefile.exe" -Destination "C:\somefile.exe" -DataProvider $null
    
    (Download-Remote-Resource -DownloadList $DownloadList)
.EXAMPLE
    Example 2
#>

function Download-Remote-Resource
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$Request,
        
        [Parameter(Mandatory=$true)]
        [switch]$Parallel
    )
    # Asynchronous Mode
    if($Parallel){
        (Start-BitsTransfer -TransferType Download -DisplayName $Request.DisplayName -Source $Request.Source -Destination $Request.Destination -Asynchronous)
        $job = (Get-BitsTransfer $Request.DisplayName)
        
        Write-Console -Message "$($job.JobId) - $($job.DisplayName) Started" -Color $COLOR_MSG_PROGRESS -WriteToLog
    }
    # Synchronous Mode
    else{
        (Start-BitsTransfer -TransferType Download -DisplayName $Request.DisplayName -Source $Request.Source -Destination $Request.Destination)
        
        Write-Console -Message "$($job.JobId) - $($job.DisplayName) Started" -Color $COLOR_MSG_PROGRESS -WriteToLog
    }
     
    return $job
}

<#
.SYNOPSIS
    Download Multiple Remote Files and store them locally
.DESCRIPTION
    Download Multiple Remote Files using the included DownloadRequest type provided by this utilities script
    and store the resulting Files Locally based on the destination value in the DownloadRequest
.NOTES
    File Name      : utilities.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
    
.LINK

.EXAMPLE
    $req1 = new-object -Typename DownloadRequest    
    $req1.DisplayName = "Download My File"    
    $req1.Source = "http://www.mysite.com/sourcefile"    
    $req1.Destination = "C:\Users\Me\Downloads\sourcefile"    
    $req1.ExitUponComletion = $false    
    
    $req2 = new-object -Typename DownloadRequest
    $req2.DisplayName = "Download My File"
    $req2.Source = "http://www.mysite.com/sourcefile"
    $req2.Destination = "C:\Users\Me\Downloads\sourcefile"
    $req2.ExitUponComletion = $true
    
    # Define the array
    [DownloadRequest[]]$Requests = @()
    
    # push requests
    $Requests+=$req1
    $Requests+=$req2
    
    # run multiple downloads, sequentially
    (Download-Multiple-Remote-Files -Requests $Requests)
    
    #or
    # run multiple downloads in parallel
    (Download-Multiple-Remote-Files -Requests $Requests -Parallel)
.EXAMPLE
    Example 2
#>
function Download-Multiple-Remote-Resources( [System.Collections.ArrayList]$Requests, [switch]$Parallel ){
    
    
    # start multiple downloads
    if($Requests -ne $null){
    
        $CompletedRequests = @()
        
        $Status = New-Object psobject -property @{
            Status                  = 'Not Started'
            BytesTotal              = 0
            BytesTransferred        = 0
            MBytesTotal             = 0.0
            MBytesTransferred       = 0.0
            TimeElapsed             = 0.0
            TimeRemaining           = 0.0
        }
        
        # Inner search function for the download list
        function Find-DownloadRequest( [string]$RequestDisplayName){
        
            $retVal     = $null
            $rLen       = $Requests.Count;
        
            for( $j = 0; $j -lt $rLen; $j++){
            
                $Request    = $Requests[$i]
                
                if($Request -ne $null ){
                
                    $requestDisplayName     = $Request.DisplayName;
                    
                    if($Request.DisplayName -eq $RequestDisplayName){
                        $retVal             = $Request;
                        break;
                    }
                }
            }
            
            if($retVal -eq $null){
                Write-Console "Download Request $RequestDisplayName Not Found!" -Color $COLOR_MSG_ERROR -WriteToLog
            }
            return $retVal
        }
        
        function Get-BitsTransfer-ByRequest([psobject]$Request)
        {
            $job = Get-BitsTransfer $Request.DisplayName
            
            $job
        }

        
        # kill any previous transfer
        Get-BitsTransfer | Remove-BitsTransfer
        
        #run asynchronously
        if($Parallel){
            
            # Calculate Total Bytes Here
            $CalculateDownloadBytesTotal = {
                $retVal = 0
                  # Processed for each request object
                $ScriptBlock = { 
                    if($_.BytesTotal -ne $null -and $_.BytesTotal -gt 0){
                        $retVal+= $_.BytesTotal;
                    }
                }
                    
                $Requests | ForEach-Object -Process $ScriptBlock
                $Status.BytesTotal  = $retVal

                # Convert To Megabytes for easy reading output
                $Status.MBytesTotal       = (Format-Decimal-Number -Value ($Status.BytesTotal/1000000) -Places 5 )
            }
            
            $CalculateDownloadBytesTransferred = {
                $retVal = 0
                  # Processed for each request object
                $ScriptBlock = { 
                    if($_.BytesTotal -ne $null -and $_.BytesTransferred -gt 0){
                        $retVal+= $_.BytesTransferred;
                    }
                }
                
                $Requests | ForEach-Object -Process $ScriptBlock
                
                $Status.BytesTransferred  = $retVal
                # Convert To Megabytes for easy reading output
                $Status.MBytesTransferred  =  (Format-Decimal-Number -Value ($Status.BytesTransferred/1000000)  -Places 5 )
            }
            
            $CalculateMetrics =  {
                & $CalculateDownloadBytesTotal
                & $CalculateDownloadBytesTransferred
                
               # Write-Debug "Calculate-Metrics Bytes [$($Status.BytesTransferred) / $($Status.BytesTotal)] => Megabytes [$($Status.MBytesTransferred) / $($Status.MBytesTotal)]"
            }
            $maxTimeRemainingCalculated = 0
            $totalTimeTaken             = 0
            
            $Error                      = $false;
            $ErrorReason                = ""
            $startTime                  = (Get-Date -UFormat %s)
            $ExpectedCompleteTime       = $startTime + $MaxDownloadTimeSeconds
            
            $jobs                       = New-Object System.Collections.ArrayList

            for($i = 0; $i -lt $Requests.Count; $i++){
                $Request                = $Requests[$i]
                
                $jobDestination         = $Request.Destination;
                $jobSource              = $Request.Source
                $jobName                = $Request.DisplayName
                
                $newIndex = $jobs.Add($Request.DisplayName)
                
                $job = Download-Remote-Resource -Request $Request -Parallel
            }
            
            # Create a holding pattern while we wait for the connection to be established            
            # and the transfer to actually begin.  Otherwise the next Do...While loop may            
            # exit before the transfer even starts.  Print the job status as it changes            
            # from Queued to Connecting to Transferring.            
            # If the download fails, remove the bad job and exit the loop.
            Set-ConsoleWriteMode($global:MODE_OVERWRITE)
            
            while($jobs.Count -gt 0){

                $StatusStrings                  = @()

                # Delete any jobs if necessary prior to procssing any status
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)

                    Set-ConsoleWriteMode($global:MODE_APPEND)

                    if ($key.key -eq "X" -and $key.modifiers -eq "Control") {

                        # Create the Status Strings for when 'CTRL+X' is pressed
                        $ScriptBlock = { 
                            
                            $job = Get-BitsTransfer $_
                            
                            if($job -ne $null){

                                $btr = (Format-Decimal-Number -Value ($job.BytesTransferred)  -Places 2 )
                                $btot = (Format-Decimal-Number -Value ($job.BytesTotal)  -Places 2 )
                                $bprog = (Format-Decimal-Number -Value ($job.BytesTransferred/$job.BytesTotal * 100)  -Places 4 ) 
                                
                                $nameStr = "$_"
                                $nameStr = $nameStr.PadRight(64)
                                $StatusStrings += "    $($StatusStrings.length) $nameStr $btr of $btot  ( $bprog % )"
                            }
                        }

                        $jobs | ForEach-Object -Process $ScriptBlock
                        
                        $StatusStrings += "    $($StatusStrings.length) Resume All Downloads"
                        $StatusStrings += "    $($StatusStrings.length) Cancel All Downloads"
                        
                        # Suspend transfers
                        Get-BitsTransfer | Suspend-BitsTransfer
                        
                        Write-Console -Message "Halting Transfers... Press the number next to the Job you wish to cancel." -Color $COLOR_MSG_WARN -WriteToLog -Ticker $true -TickInterval 6

                        $i                      = 0
                        $ScriptBlock            = { Write-Console -Message "$($StatusStrings[$i++])" -Color $COLOR_MSG_WARN -WriteToLog -Ticker $true -TickInterval 1 }
                        $StatusStrings          | ForEach-Object -Process $ScriptBlock

                        [int]$choiceNum         = -1;
                        $parsed                 = $false

                        while(!$parsed){

                            $key                = [Console]::ReadKey($true)
                            $parsed             = [int]::TryParse($key.keychar , [ref]$choiceNum )

                            if( $parsed -eq $true ){
                            
                                if($choiceNum -ge $jobs.Count){
                                
                                    if($choiceNum -eq $jobs.Count){
                                        Write-Console -Message "Resume All Downloads" -Color $COLOR_MSG_JOB_START -WriteToLog -Ticker $True -TickInterval 3
                                        break;
                                    }
                                    elseif($choiceNum -eq ($jobs.Count + 1)){
                                        Get-BitsTransfer | Remove-BitsTransfer
                                        $jobs.Clear();
                                        
                                        Write-Console -Message "Cancel All Downloads, bytes transferred: $($Status.BytesTransferred), bytes total $($Status.BytesTotal)" -Color $COLOR_MSG_WARN -WriteToLog
                                        
                                        # Update the values by running the calculation block
                                        & $CalculateMetrics
                                        
                                        break;
                                    }
                                    else{
                                        $parsed = $false;
                                        Write-Console  -Message "Error: Selection $($key.keychar) Was Invalid, Please try again" -Color $COLOR_MSG_ERROR -WriteToLog
                                    }
                                }
                                else
                                {
                                    $job = Get-BitsTransfer $jobs[$choiceNum]

                                    if($job -ne $null){
                                        Remove-BitsTransfer $job
                                    }

                                    # Update the values by running the calculation block
                                    & $CalculateMetrics
                                    
                                    Write-Console -Message "Cancelled Download $($jobs[$choiceNum])" -Color $COLOR_MSG_WARN -WriteToLog
                                    
                                    $jobs.RemoveAt($choiceNum)
                                    $parsed     = $true;
                                    break;
                                }
                            }
                            else{
                                Write-Console -Message "Error: Selection $($key.keychar) Was Invalid, Please try again" -Color $COLOR_MSG_ERROR -WriteToLog
                            }
                        }
                        
                        if($jobs.Count -gt 0){
                            Write-Console "Resuming $($jobs.Count) Transfers..." -Color $COLOR_MSG_ITEM_COMPLETE -WriteToLog -Ticker $true -TickInterval 5
                            
                            # Resume all BitsTransfer objects Asynchronously
                            Get-BitsTransfer | Resume-BitsTransfer -Asynchronous
                        }
                        
                        Set-ConsoleWriteMode($global:MODE_OVERWRITE)
                    }
                }
                
                # This is not executed using For-Each, because the List gets Modified during some of the Cases below.
                # ForEach and ForEach-Object don't support modifying the collection while iterating.
                for( $i = 0; $i -lt $jobs.Count; ++$i){
                
                    $jobName                            = $jobs[$i];
                    $job                                = Get-BitsTransfer $jobName
                    $Request                            = (Find-DownloadRequest -RequestDisplayName $jobName )

                    if($Request -ne $null){
                    
                        if($job.JobState -ne "Transferred" -and $job.JobState -ne "Error"){

                            if($job.BytesTotal -gt 0){
                                $Request.BytesTotal             = $job.BytesTotal;
                            }
                                
                            if($job.BytesTransferred -gt 0){
                                $Request.BytesTransferred       = $job.BytesTransferred;
                            }
                        }

                        $Request.Status                 = $job.JobState
                        $jobSource                      = $Request.Source
                        $jobDestination                 = $Request.Destination

                       # Write-Debug "Process Request $jobDestination => $($Request.BytesTransferred)/$($Request.BytesTotal)   $($Status.BytesTransferred) / $($Status.BytesTotal) from $jobSource"
                    }
                    
                    # Update the values by running the calculation block
                    & $CalculateMetrics
                    
                    $now                                = (Get-Date -UFormat %s)
                    $elapsed                            = [math]::Round($now-$startTime)
                    
                    $removeJob                          = $false
                    Switch($job.JobState){
                        
                        "Transferred" 
                        {
                            $removeJob = $true
                            Write-Console -Message "[Download Complete] $jobName" -Color $COLOR_MSG_ITEM_COMPLETE -WriteToLog
                        }
                        "Error" 
                        {
                            if($Request -ne $null ){
                                $jobSource              = $Request.Source;
                                $jobDestination         = $Request.Destination;
                            }
                            else{
                                Write-Console -Message "Request $jobName was null" -Color $COLOR_MSG_ERROR -WriteToLog
                            }
                            
                            $jobState                   = $job.JobState
                            
                            Write-Console -Message "[Download Error] $jobName **$jobState Status Received [Source $jobSource, Dest $jobDestination]***" -Color $COLOR_MSG_ERROR -WriteToLog
                            
                            $removeJob = $true
                        }
                    }

                    if($removeJob -eq $true)
                    {
                        Set-ConsoleWriteMode($global:MODE_APPEND)
                        Set-ConsoleWriteMode($global:MODE_OVERWRITE)
                        
                        
                        if($job.JobState -eq "Transferred"){
                            Complete-BitsTransfer -BitsJob $job
                        }
                        else{
                            Remove-BitsTransfer -BitsJob $job
                        }

                        # Print the transfer status as we go:            
                        #   Date & Time   BytesTransferred   BytesTotal   PercentComplete            
                                
                        # Print the final status once complete.            
                        $jobs.RemoveAt($i--)
                    }
                }
                
                $now                                = (Get-Date -UFormat %s)
                $elapsed                            = [math]::Round($now-$startTime)
                
                if( $elapsed -gt $MaxDownloadTimeSeconds ){
                    Get-BitsTransfer | Remove-BitsTransfer
                    $jobs.Clear()
                    $Error = $true
                    $ErrorReason ="[Download Error] Download took longer than expected (Max Time: $MaxDownloadTimeSeconds)."
                    break;
                }
                
                
                $mbPs                        = (Format-Decimal-Number -Value ($Status.MBytesTransferred/$elapsed) -Places 2 )
                           
                $PctComplete                 = 0;
               
                if($Status.BytesTotal -eq 0){
                     $PctComplete           = 0;
                }
                else{
                    $PctComplete            = $Status.BytesTransferred / $Status.BytesTotal * 100

                    $PctComplete            = [math]::min($PctComplete, 100)
                }

                if($Status.BytesTransferred -gt 0 -and $Status.BytesTotal -gt 0) {
                    $timeRemaining          = Format-Decimal-Number -Value (Get-Time-Remaining -completed $Status.BytesTransferred -total $Status.BytesTotal -timeTaken $elapsed) -Places 1
                   
                    if($elapsed -gt 2) {
                        $maxTimeRemainingCalculated  = [math]::max($maxTimeRemainingCalculated, $timeRemaining);
                    }
                }
                else{
                    $timeRemaining          = "Calculating... [$($Status.BytesTransferred) of $($Status.BytesTotal)]"
                }
                
                Write-Console "Download in progress $PctComplete % - $($Status.MBytesTransferred) of $($Status.MBytesTotal)  (at $mbPs MB / Sec)  elapsed time - $elapsed seconds, time remaining: $timeRemaining seconds" -Color $COLOR_MSG_PROGRESS
               
                Start-Sleep -m 250
            }
            
            Set-ConsoleWriteMode($global:MODE_APPEND)
            
            if($Error){
                Write-Console -Message "Error Downloading Files, Reason : $ErrorReason - only $Status.MBytesTransferred were transferred" -Color $COLOR_MSG_ERROR
            }
            else{
                Write-Console -Message "All Files Downloaded  ($Status.MBytesTotal MB), Time actually taken: $totalTimeTaken, Original Max Estimated: $maxTimeRemainingCalculated  Average Estimate: $averageOfTimeEstimates" -Color $COLOR_MSG_JOB_COMPLETE
            }
        }
        else{
            # Processed for each Request
            $ScriptBlock = {
                if( $_ -ne $null ){
                   $job = ( Download-Remote-Resource -Request $_ )
                }
            }
            
            # Process all requests
            $Requests | ForEach-Object -Process $ScriptBlock
        }
    }
}

Write-Console -Message "[net.bits] Library Script Included." -Color $MAGENTA 
