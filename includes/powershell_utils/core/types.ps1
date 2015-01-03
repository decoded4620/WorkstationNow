if($types_ps1_included -ne $true)
{
    # Insure this runs ONLY one time by setting this to be 'constant'
    Set-Variable types_ps1_included -option Constant   -Scope Global    -value $true
    
    # Shell Session Global Reference
    Set-Variable SHELL              -Option Constant -Scope Global      -value (New-Object -ComObject Wscript.Shell)
    
    # The Application Global Reference
    Set-Variable APPLICATION        -Option Constant -Scope Global      -value (New-Object -ComObject Shell.Application)

    # Prompt Action Values
    Set-Variable PROCEED            -Option Constant    -Scope Global   -value 1;
    Set-Variable HALT               -Option Constant    -Scope Global   -value 0;

    # Modes
    Set-Variable MODE_APPEND        -Option Constant    -Scope Global   -value 0
    Set-Variable MODE_OVERWRITE     -Option Constant    -Scope Global   -value 1
    
    # Console Colors
    Set-Variable BLACK              -Option Constant    -Scope Global   -Value "Black"
    Set-Variable BLUE               -Option Constant    -Scope Global   -Value "Blue"
    Set-Variable CYAN               -Option Constant    -Scope Global   -Value "Cyan"
    Set-Variable DARKBLUE           -Option Constant    -Scope Global   -Value "DarkBlue"
    Set-Variable DARKCYAN           -Option Constant    -Scope Global   -Value "DarkCyan"
    Set-Variable DARKGRAY           -Option Constant    -Scope Global   -Value "DarkGray"
    Set-Variable DARKGREEN          -Option Constant    -Scope Global   -Value "DarkGreen"
    Set-Variable DARKMAGENTA        -Option Constant    -Scope Global   -Value "DarkMagenta"
    Set-Variable DARKRED            -Option Constant    -Scope Global   -Value "DarkRed"
    Set-Variable DARKYELLOW         -Option Constant    -Scope Global   -Value "DarkYellow"
    Set-Variable GRAY               -Option Constant    -Scope Global   -Value "Gray"
    Set-Variable GREEN              -Option Constant    -Scope Global   -Value "Green"
    Set-Variable MAGENTA            -Option Constant    -Scope Global   -Value "Magenta"
    Set-Variable RED                -Option Constant    -Scope Global   -Value "Red"
    Set-Variable WHITE              -Option Constant    -Scope Global   -Value "White"
    Set-Variable YELLOW             -Option Constant    -Scope Global   -Value "Yellow"



    #Colors for message types
    $COLOR_MSG_ERROR                = $RED
    $COLOR_MSG_WARN                 = $DARKRED
    $COLOR_MSG_PROGRESS             = $DARKGRAY
    $COLOR_MSG_JOB_START            = $CYAN
    $COLOR_MSG_JOB_COMPLETE         = $GREEN
    $COLOR_MSG_ITEM_START           = $DARKCYAN
    $COLOR_MSG_ITEM_COMPLETE        = $DARKGREEN
    $COLOR_MSG_USER_DECLINE         = $DARKRED


    function Validate-Type-Properties([psobject]$InputObject, [string[]]$Properties)
    {
        $validateReason = ""
        $validated = $false

        if( $Properties -ne $null ){
            $validationReason = "Properties object was null"
            $validated = $true;
        }

        if($validated){
            #validate that each property exists
            # print error for each missing property
            $ScriptBlock = {
                if((Get-Member -Name $_ -InputObject $InputObject) -eq $null ){
                    if($validate -eq $true){
                        $validationReason = "One or more properties were missing or incorrect"
                        Write-Host "**Validation Failed** `r $Properties`r$InputObject" -foregroundcolor $COLOR_MSG_ERROR -WriteToLog
                    }

                    Write-Host "    Missing Property: $_" -foregroundcolor $COLOR_MSG_ERROR -WriteToLog
                    $validated = $false;
                }
            }

            $Properties | ForEach-Object -Process $ScriptBlock
        }

        $validated
    }
}
else
{
    Write-Host "Types Already Included, definitions protected from double inclusion" -foregroundcolor $global:RED
}

Write-Host "[core.types] Types Included" -foregroundcolor $global:MAGENTA