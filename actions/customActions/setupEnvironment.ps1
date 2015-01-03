function setupEnvironment{
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
}