function setupPerforceWorkspace{
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
}