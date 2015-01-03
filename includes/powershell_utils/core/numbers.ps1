
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
function Format-Decimal-Number([float]$Value, [int]$Places)
{
    $raiseTo = [math]::Pow(10, $Places)
    $retVal = [math]::Round($Value * $raiseTo)/$raiseTo
    
    return $retVal
}
Write-Console -Message "[core.numbers] Library Script Included." -Color $MAGENTA