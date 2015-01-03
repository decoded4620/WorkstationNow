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
function Get-Invoke-Expression-Result
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$Expression,
        
        [Parameter(Mandatory=$false)]
        [string]$Explanation,
        
        [Parameter(Mandatory=$false)]
        [switch]$PrintResult
    )
    
    if($Expression -ne $null){
        
        if( $PrintResult ){
            if($Explanation -ne $null -and $Explanation -ne ''){
                Write-Console -Message " > $Expression [$Explanation]" -Color $DARKGRAY -WriteToLog
            }
            else{
                Write-Console -Message " > $Expression" -Color $DARKGRAY -WriteToLog
            }
            
          # $result = Invoke-Expression  -Command $Expression
          # Write-Console -Message " > $result" -Color $DARKGREEN
        }
        #else{
            Invoke-Expression  -Command $Expression
        #}
    }
    
    
}

function Get-Time-Remaining
{
    param(
        [Parameter(Mandatory=$true)]
        [int]$completed, 
        [Parameter(Mandatory=$true)]
        [int]$total, 
        [Parameter(Mandatory=$true)]
        [double]$timeTaken
    )
    
    
    #write-debug "Get-Time-Remaining $completed $total $timeTaken"
    $timeLeft = 0.0
    
    if($completed -eq 0 -and $total -eq 0)
    {
        $timeLeft = 0;
    }
    else{
        if($unitsTotal = 0){
            $pctComplete = 100;
        }
        else{
            $pctComplete = $completed / $total * 100
        }
        
        if($pctComplete -lt 100)
        {
            $timeSpentPerOnePercent = $timeTaken / $pctComplete
            
            $timeTotalEstimated = $timeSpentPerOnePercent * 100;
            
            $timeLeft = $timeTotalEstimated - $timeTaken
        }
    }
    
    return $timeLeft
}
Write-Console -Message "[utils.utilities] Library Script Included." -Color $MAGENTA