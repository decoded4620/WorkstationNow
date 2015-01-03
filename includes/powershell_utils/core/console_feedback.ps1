
# Global Vars
Set-Variable CONSOLE_WRITE_MODE                         -Scope Global      -value $global:MODE_APPEND

# PROMPT RETURN VALUES
if($includes_console_feedback_ps1 -ne $true)
{
    Set-Variable includes_console_feedback_ps1  -option Constant -Scope Global      -value $true
    
    
    # Logging Level Enumeration
    $LogLevel = New-Object psobject @{
        Error   = 0
        Warn    = 1
        Fail    = 2
        Verbose = 3
        Debug   = 4
        Success = 5
        Info    = 6
    }
    
    function Get-LogLevel-String([int]$Level){
    
        $retVal = "INFO"
        
        switch($Level)
        {
            {$_ -eq $LogLevel.Error}{
                $retVal = "ERROR"
            }
            {$_ -eq $LogLevel.Warn}{
                $retVal = "WARN"
            }
            {$_ -eq $LogLevel.Fail}{
                $retVal = "FAIL"
            }
            {$_ -eq $LogLevel.Verbose}{
                $retVal = ""
            }
            {$_ -eq $LogLevel.Debug}{
                $retVal = ""
            }
            {$_ -eq $LogLevel.Success}{
                $retVal = "SUCCESS"
            }
            {$_ -eq $LogLevel.Info}{
                $retVal = "INFO"
            }
            default{
                $retVal = "INFO"
            }
        }
        
        $retVal
    }
    
    
    
    Set-Variable LOG_LEVEL          -Option Constant    -Scope Global   -Value $LogLevel
   
    # Global Constants
    Set-Variable PROMPT_TIMEOUT         -option Constant    -Scope Global      -value -1
    Set-Variable PROMPT_OK              -option Constant    -Scope Global      -value 1
    Set-Variable PROMPT_CANCEL          -option Constant    -Scope Global      -value 2
    Set-Variable PROMPT_ABORT           -option Constant    -Scope Global      -value 3
    Set-Variable PROMPT_RETRY           -option Constant    -Scope Global      -value 4
    Set-Variable PROMPT_IGNORE          -option Constant    -Scope Global      -value 5
    Set-Variable PROMPT_YES             -option Constant    -Scope Global      -value 6
    Set-Variable PROMPT_NO              -option Constant    -Scope Global      -value 7
    Set-Variable PROMPT_TRYAGAIN        -option Constant    -Scope Global      -value 10
    Set-Variable PROMPT_CONTINUE        -option Constant    -Scope Global      -value 11
    
    # Message Defaults
    $PROMPT_DEFAULT_MSG_TIMEOUT     = "Timed out. No response from user."
    $PROMPT_DEFAULT_MSG_CANCEL      = "User Canceled the operation."
    $PROMPT_DEFAULT_MSG_ABORT       = "User Aborted the operation."
    $PROMPT_DEFAULT_MSG_IGNORE      = "User Ignored the operation request."
    $PROMPT_DEFAULT_MSG_NO          = "User declined the operation."

    $PROMPT_DEFAULT_MSG_OK          = "User accepted the operation."
    $PROMPT_DEFAULT_MSG_RETRY       = "User is retrying the operation."
    $PROMPT_DEFAULT_MSG_IGNORE      = "User ingored the operation request."
    $PROMPT_DEFAULT_MSG_YES         = "User agreed to the operation request."
    $PROMPT_DEFAULT_MSG_TRYAGAIN    = "User is retrying the operation."
    $PROMPT_DEFAULT_MSG_CONTINUE    = "User is continuing the operation."

    $PROMPT_RESPONSE_NEG_COLOR      = $COLOR_MSG_USER_DECLINE
    $PROMPT_RESPONSE_POS_COLOR      = $COLOR_MSG_JOB_COMPLETE

    $PROMPT_MSG_TIMEOUT             = $PROMPT_DEFAULT_MSG_TIMEOUT
    $PROMPT_MSG_CANCEL              = $PROMPT_DEFAULT_MSG_CANCEL
    $PROMPT_MSG_ABORT               = $PROMPT_DEFAULT_MSG_ABORT
    $PROMPT_MSG_IGNORE              = $PROMPT_DEFAULT_MSG_IGNORE
    $PROMPT_MSG_NO                  = $PROMPT_DEFAULT_MSG_NO

    $PROMPT_MSG_OK                  = $PROMPT_DEFAULT_MSG_OK
    $PROMPT_MSG_RETRY               = $PROMPT_DEFAULT_MSG_RETRY
    $PROMPT_MSG_YES                 = $PROMPT_DEFAULT_MSG_YES
    $PROMPT_MSG_TRYAGAIN            = $PROMPT_DEFAULT_MSG_TRYAGAIN
    $PROMPT_MSG_CONTINUE            = $PROMPT_DEFAULT_MSG_CONTINUE

    function Prompt-Result-Set-Defaults
    {
        #Colors for message types
        $PROMPT_RESPONSE_NEG_COLOR  = $COLOR_MSG_USER_DECLINE
        $PROMPT_RESPONSE_POS_COLOR  = $COLOR_MSG_JOB_COMPLETE

        $PROMPT_MSG_TIMEOUT         = $PROMPT_DEFAULT_MSG_TIMEOUT
        $PROMPT_MSG_CANCEL          = $PROMPT_DEFAULT_MSG_CANCEL
        $PROMPT_MSG_ABORT           = $PROMPT_DEFAULT_MSG_ABORT
        $PROMPT_MSG_IGNORE          = $PROMPT_DEFAULT_MSG_IGNORE
        $PROMPT_MSG_NO              = $PROMPT_DEFAULT_MSG_NO

        $PROMPT_MSG_OK              = $PROMPT_DEFAULT_MSG_OK
        $PROMPT_MSG_RETRY           = $PROMPT_DEFAULT_MSG_RETRY
        $PROMPT_MSG_YES             = $PROMPT_DEFAULT_MSG_YES
        $PROMPT_MSG_TRYAGAIN        = $PROMPT_DEFAULT_MSG_TRYAGAIN
        $PROMPT_MSG_CONTINUE        = $PROMPT_DEFAULT_MSG_CONTINUE
    }

    function Get-LastConsoleLine
    {
        $lastLine = '';
        
        $lines = (Get-Console-Buffer -lineCount 1)
        
        if($lines.length -gt 0){
        
            $lastLine = $lines[0]
        }
        
        $lastLine
    }

    function Set-ConsoleWriteMode{ 
    
        param(
            [Parameter(Mandatory=$true)]
            [string]$WriteMode
        )
        
        if($global:CONSOLE_WRITE_MODE -ne $WriteMode){
            
            Set-Variable CONSOLE_WRITE_MODE -Scope Global -Value $WriteMode
            
            switch($WriteMode){

                # Overwrite Mode Switch, Clear current buffer with a new line
                {$global:CONSOLE_WRITE_MODE -eq $global:MODE_OVERWRITE}{
                    
                }

                # Append Mode Switch, Overwrite current buffer with a new line
                {$global:CONSOLE_WRITE_MODE -eq $global:MODE_APPEND}{
                    $lastLine = Get-LastConsoleLine
                    
                    if($lastLine.length -gt 0){
                        Write-Host ( Pad-String -string "`r" -length $lastLine.length -padChar ' ' -padType 'right' ) -NoNewLine
                        Write-Host ""
                    }
                    else{
                        Write-Host ""
                    }
                }

                # Fall back to append mode to be safe
                default{
                    $global:CONSOLE_WRITE_MODE = $global:MODE_APPEND
                }
            }
        }else{
            Write-Debug "[Set-ConsoleWriteMode] - Not Changed"
        }
    }
    
    function Log-Message
    {
        param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
            [int]$Level=$global:LOG_LEVEL.Info,
            
            [Parameter(Mandatory=$false)]
            [switch]$WriteToLog
        )
            
        $LevelStr       = Get-LogLevel-String($Level);
        
        $Message        = "[$LevelStr] $Message"
        if( $global:LOGGER_LEVEL -ge $Level)
        {
            switch($Level)
            {
                {$_ -eq $global:LOG_LEVEL.Verbose}{
                    Write-Verbose $Message
                }
                {$_ -eq $global:LOG_LEVEL.Debug}{
                    Write-Debug $Message
                }
                {$_ -gt $global:LOG_LEVEL.Debug}
                {
                    Write-Host $Message -foregroundcolor "DarkCyan"
                }
                {$_ -eq $global:LOG_LEVEL.Warn}{
                    Write-Warning $Message
                }
                default{
                    Write-Error $Message
                }
            }
        }
        
        # always write to log if specified, even if we supress console output
        if($WriteToLog){
            if( Test-Path $global:POWERSHELL_UTILS_LOG_FILE ){
                $c = Add-Content $global:POWERSHELL_UTILS_LOG_FILE "`n$Message"
            }
        }
    }
    
    function Write-Headline
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [string]$Color=$WHITE,
            
            [Parameter(Mandatory=$false)]
            [switch]$WriteToLog
        )
        
        $headlineStr =  "-".PadRight($Message.Length, "-")
        
        if($WriteToLog){
            
            Write-Console -Message $headlineStr -Color $Color -WriteToLog
            Write-Console -Message $Message -Color $Color -WriteToLog
            Write-Console -Message $headlineStr -Color $Color -WriteToLog
        }
        else{
            
            Write-Console -Message $headlineStr -Color $Color
            Write-Console -Message  $Message -Color $Color     
            Write-Console -Message $headlineStr -Color $Color
        }
    }

    function Write-Console
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Message,
            
            [Parameter(Mandatory=$false)]
            [string]$Color=$WHITE,
            
            [Parameter(Mandatory=$false)]
            [switch]$WriteToLog,
            
            [Parameter(Mandatory=$false)]
            [bool]$Ticker=$false,
            
            [Parameter(Mandatory=$false)]
            [int]$TickInterval=5
        )


       # $Ticker = $false
        
        if($Color -eq '' -or $Color -eq $null){
            $Color = $global:WHITE
        }

        if($global:CONSOLE_WRITE_MODE -eq $global:MODE_OVERWRITE){
            # Overwite with carriage return
            $Message = "`r$Message"
             
            # overwite the ENTIRE line
            $width = $RawUI.BufferSize.Width-1
            
            if($Message.length -lt $width){
                $Message = $Message.PadRight($width)
            }

            if($Ticker)
            {   
                $MsgArray = $Message.ToCharArray()
                 
                for($i = 0; $i -lt $MsgArray.length; $i++)
                {
                    Write-Host $MsgArray[$i] -NoNewLine -foregroundcolor $Color
                    Start-Sleep -m $TickInterval
                }
            }
            else{
                Write-Host $Message -NoNewLine -foregroundcolor $Color
            }
        }
        else{
            if($Ticker)
            {   
                $MsgArray = $Message.ToCharArray()
                 
                for($i = 0; $i -lt $MsgArray.length; $i++)
                {
                    Write-Host $MsgArray[$i] -NoNewLine -foregroundcolor $Color
                    Start-Sleep -m $TickInterval
                }
                
                Write-Host ""
            }
            else{
                Write-Host $Message -foregroundcolor $Color
            }
        }
        
        if($WriteToLog)
        {
            $c = Add-Content $global:POWERSHELL_UTILS_LOG_FILE "`n$Message"
        }
    }

    function PromptResult-ProceedOrHalt
    {
        param(
            [Parameter(Mandatory=$true)]
            [int]$Response,

            [Parameter(Mandatory=$false)]
            [switch]$ResetToDefaults=$true,

            [Parameter(Mandatory=$false)]
            [int]$SleepOnPositive=0,
            
            [Parameter(Mandatory=$false)]
            [int]$SleepOnNegative=0
            
        )

        if( PromptResult-IsNegativeResponse -Response $Response ){
            if($Response -eq $PROMPT_TIMEOUT ){
                Log-Message -Message $PROMPT_MSG_TIMEOUT -Level $global:LOG_LEVEL.Warn -WriteToLog
            }
            elseif($Response -eq $PROMPT_CANCEL){
                Log-Message -Message $PROMPT_MSG_CANCEL -Level $global:LOG_LEVEL.Warn  -WriteToLog
            }
            elseif($Response -eq $PROMPT_ABORT ){
                Log-Message -Message $PROMPT_MSG_CANCEL  -Level $global:LOG_LEVEL.Warn -WriteToLog
            }
            elseif($Response -eq $PROMPT_IGNORE){
                Log-Message -Message $PROMPT_MSG_IGNORE -Level $global:LOG_LEVEL.Warn   -WriteToLog
            }
            elseif($Response -eq $PROMPT_NO){
                Log-Message -Message $PROMPT_MSG_NO  -Level $global:LOG_LEVEL.Warn  -WriteToLog
            }
            
            if($SleepOnNegative -gt 0){
                Start-Sleep -m $SleepOnNegative
            }
            
            if($ResetToDefaults){
                # Reset defaults
                Prompt-Result-Set-Defaults
            }
            $HALT
        }
        else{
            $result = $PROCEED

            if($Response -eq $PROMPT_OK ){
                Log-Message -Message $PROMPT_MSG_OK  -Level $global:LOG_LEVEL.Verbose  -WriteToLog
            }
            elseif($Response -eq $PROMPT_RETRY){
                Log-Message -Message $PROMPT_MSG_RETRY -Level $global:LOG_LEVEL.Verbose  -WriteToLog
            }
            elseif($Response -eq $PROMPT_YES ){
               Log-Message -Message $PROMPT_MSG_YES -Level $global:LOG_LEVEL.Verbose  -WriteToLog
            }
            elseif($Response -eq $PROMPT_TRYAGAIN){
                Log-Message -Message $PROMPT_MSG_TRYAGAIN -Level $global:LOG_LEVEL.Verbose  -WriteToLog
            }
            elseif($Response -eq $PROMPT_CONTINUE){
                Log-Message -Message $PROMPT_MSG_CONTINUE  -Level $global:LOG_LEVEL.Verbose  -WriteToLog
            }
            
            if($SleepOnPositive -gt 0){
                Start-Sleep -m $SleepOnPositive
            }
            
            if($ResetToDefaults){
                # Reset defaults
                Prompt-Result-Set-Defaults
            }
        
            $PROCEED
        }
    }
    function PromptResult-IsNegativeResponse([int]$Response)
    {
        if( $Response         -eq $PROMPT_TIMEOUT   `
                -or $Response -eq $PROMPT_CANCEL    `
                -or $Response -eq $PROMPT_ABORT     `
                -or $Response -eq $PROMPT_IGNORE    `
                -or $Response -eq $PROMPT_NO        )
        {
            $result = $true
        }
        else
        {
            $result = $false
        }

        return $result
    }

    function PromptResult-IsPositiveResponse([int]$Response)
    {
        if( $Response         -eq $PROMPT_YES       `
                -or $Response -eq $PROMPT_TRYAGAIN  `
                -or $Response -eq $PROMPT_RETRY     `
                -or $Response -eq $PROMPT_OK        `
                -or $Response -eq $PROMPT_CONTINUE  )
        {
            $result = $true
        }
        else
        {
            $result = $false
        }

        return $result
    }

        # setup default messaging
    Prompt-Result-Set-Defaults
    
    if($global:POWERSHELL_UTILS_LOG_DIR -ne $null){
        
        $exists = Test-Path -Path $global:POWERSHELL_UTILS_LOG_DIR
        if($exists){
        
            Write-Console -Message "-- $($global:POWERSHELL_UTILS_LOG_DIR) Exists" -Color $DARKGRAY
            
            $exists = Test-Path -Path $global:POWERSHELL_UTILS_LOG_FILE ;
            if( !$exists ){
                Write-Console -Message "-- Creating $($global:POWERSHELL_UTILS_LOG_FILE)"
                Set-Variable LOG_FILE -Option Constant -Scope Global -Value ( New-Item -type file -Path $global:POWERSHELL_UTILS_LOG_FILE )
            }
            else{
                $removeItem = Remove-Item -Path $global:POWERSHELL_UTILS_LOG_FILE
                Set-Variable LOG_FILE -Option Constant -Scope Global -Value ( New-Item -type file -Path $global:POWERSHELL_UTILS_LOG_FILE )
                Write-Console -Message "-- $($global:POWERSHELL_UTILS_LOG_FILE) Exists" -Color $DARKGRAY -Ticker $true -TickInterval 2 
            }
        }
        else{
        
            Write-Console -Message "-- Creating $($global:POWERSHELL_UTILS_LOG_DIR)" -Color $DARKGRAY -Ticker $true -TickInterval 2 
            Write-Console -Message "-- Creating $($global:POWERSHELL_UTILS_LOG_FILE)" -Color $DARKGRAY -Ticker $true -TickInterval 2 
            
            $logDir = New-Item -type directory -Path $global:POWERSHELL_UTILS_LOG_DIR
            Set-Variable LOG_FILE -Option Constant -Scope Global -Value ( New-Item -type file -Path $global:POWERSHELL_UTILS_LOG_FILE )
        }
        
    }
    else{
        Write-Warning "Logging Directory Not Defined"
    }
}





