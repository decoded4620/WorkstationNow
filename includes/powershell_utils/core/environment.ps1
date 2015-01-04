
####################################################################################
# Environment Variable Configuration Object
####################################################################################
function Is-EnvironmentVariableConfiguration
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$InputObject
    )
    
    $validated = ( Validate-Type-Properties -InputObject $InputObject -Properties @('Key', 'Level','SetType','ValueType','Prompt','DefaultValue'))
    $validated
}

function New-EnvironmentVariableConfiguration () {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('User', 'Machine')]
        [string]$Level='User',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('SET','APPEND')]
        [string]$SetType='SET',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('STRING','PATH')]
        [string]$ValueType='STRING',
        
        [Parameter(Mandatory=$false)]
        [bool]$Prompt,
        
        [Parameter(Mandatory=$false)]
        [bool]$AllowDuplicateAppend,
        
        [Parameter(Mandatory=$false)]
        [string]$DefaultValue
    )
    
    # return the new object
    New-Object psobject -property @{
        Key                     = $Key
        Level                   = $Level
        SetType                 = $SetType
        ValueType               = $ValueType
        DefaultValue            = $DefaultValue
        AllowDuplicateAppend    = $AllowDuplicateAppend
    }
}

#############################################################################################################################
<#
.SYNOPSIS
    Set an environment variable
.DESCRIPTION
    Set an environment variable
.NOTES
    File Name      : perforce.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  Set-Environment-Variable -Name "Path" -Value "C:\Append\This\To\Current\Path" -AppendToCurrentValue
.EXAMPLE
  Set-Environment-Variable -Name "JustSetMeDontAppend" -Value "C:\Just\Set\To\This\Value"
#>
function Set-Environment-Variable{

    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$Value="",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('User','Machine', 'Process')]
        [string]$Level='User',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('STRING','PATH')]
        [string]$ValueType='STRING',
        
        [Parameter(Mandatory=$false)]
        [bool]$Prompt=$false,
        
        [Parameter(Mandatory=$false)]
        [bool]$AppendToCurrentValue=$false,
        
        [Parameter(Mandatory=$false)]
        [bool]$AllowDuplicateAppend=$true,
        
        [Parameter(Mandatory=$false)]
        [switch]$AsJob
    )

    if($Prompt)
    {
        # prompt the user, populate with default
        if($ValueType -eq 'PATH'){
            $message = "Select a Location for $Name"
            
            if($AppendToCurrentValue){
                $message = "Select a Location to append to $Name"
            }
            
            if((Test-Path $Value -pathType container) -eq $false ){
                $Value = ""
            }
            # for a directory location
            $Value = (Read-FolderBrowserDialog -Message $message -InitialDirectory $Value)
            
        }
        else{
            $message = "Enter a value for $Name";
            
            if($AppendToCurrentValue){
                $message = "Enter a value to append to $Name"
            }
            # for a value
            $Value = (Read-InputBoxDialog -Message $message -DefaultText $Value)
        }
    }
    
    # if they chose a value
    if(![string]::IsNullOrEmpty($Value)){
        $updateLocalEnv = $false
        
        # overwrite the final result if we aren't already that value
        $BusinessLogic = {
        
            # Get the current Value, if any
            $CurrentValue = [Environment]::GetEnvironmentVariable($Name, $Level)
            
            # append the final result
            if($AppendToCurrentValue){
            
                if($AllowDuplicateAppend -eq $false){
                    # strip old occurrences and append to the end
                    $Value = $CurrentValue.Replace($Value, "") + $Value;
                }
                else{
                    # just append to the end
                    $Value = $CurrentValue + $Value
                }
            }
            
            if($CurrentValue -ne $Value){
            
                Log-Message -Message "[Set-Environment-Variable] $Name = $Value, $Level" -Level $global:LOG_LEVEL.Pending -WriteToLog
                
                [Environment]::SetEnvironmentVariable($Name, $Value, $Level)
                
                 # Get the current Value, if any
                $NewCurrentValue = [Environment]::GetEnvironmentVariable($Name, $Level)
                
                if($NewCurrentValue -ne $Value ){
                    Log-Message -Message "[Set-Environment-Variable] Update Complete, values don't match! $Name, $CurrentValue !=  $NewCurrentValue" -Level $global:LOG_LEVEL.Fail -WriteToLog
                }
                else{
                    $updateLocalEnv = $true
                    Log-Message -Message "[Set-Environment-Variable] $Name = $NewCurrentValue, $Level" -Level $global:LOG_LEVEL.Success -WriteToLog
                }
                
                if($updateLocalEnv){
                    # Update the shell session as well
                    $Accessor = '$env:' + $Name
                    $ScriptBlockStr = $Accessor + '="' + $NewCurrentValue + '"'
                    
                    Get-Invoke-Expression-Result -Expression $ScriptBlockStr -PrintResult
                }
            }
            else{
                $updateLocalEnv = $true;
                $NewCurrentValue = $CurrentValue;
                Log-Message -Message "[Set-Environment-Variable] $Name - Not updated, values were equal." -Level $global:LOG_LEVEL.Success -Color $GRAY -WriteToLog
            }
        }
        
        if($AsJob){
            # run it on a thread
            $job = start-job -ScriptBlock $BusinessLogic
        }
        else{
            #just run it
            & $BusinessLogic
        }
    }
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
function Get-Environment-Variable([string]$Name, [string]$Level )
{
    $retVal = [Environment]::GetEnvironmentVariable($Name, $Level)
    
    return $retVal
}
