<# Types #>
<# Utility Script for Doing fun windows powershell stuff #>

#############################################################################################################################
# P4 Client Spec Configuration Configuration Object
#############################################################################################################################
function Is-P4ClientSpecConfiguration( [psobject]$Configuration )
{
    $validated = ( Validate-Type-Properties         `
                    -InputObject $Configuration     `
                    -Properties @('WorkspaceName','Template'))
    
    return $validated
}

function New-P4ClientSpecConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceName,
        
        [Parameter(Mandatory=$false)]
        [string]$Template,
        
        [Parameter(Mandatory=$true)]
        [string]$P4Config
    )
    
    Write-Host "[New P4ClientSpecConfiguration] $Options $WorkspaceName $Template"
    # return the new object
    New-Object psobject -property @{
        WorkspaceName       = $WorkspaceName
        Template            = $Template
        P4Config            = $P4Config
    }
}

#############################################################################################################################
# P4 Workspace Global Configuration Configuration Object
#############################################################################################################################
function Is-P4WorkspaceConfiguration( [psobject]$Configuration )
{
    $validated = ( Validate-Type-Properties         `
                    -InputObject $Configuration     `
                    -Properties @( 'ClientSpecConfiguration', 'EnvironmentVariables' ) )
    
    $validated
}



function New-P4WorkspaceConfiguration {
    param(
        [Parameter(Mandatory=$false)]
        [psobject[]]$EnvironmentVariables,
        
        [Parameter(Mandatory=$true)]
        [psobject]$ClientSpecConfiguration
    )
    
    Write-Host "[New-P4WorkspaceConfiguration]"
    # return the new object
    New-Object psobject -property @{
        ClientSpecConfiguration     = $ClientSpecConfiguration
        EnvironmentVariables        = $EnvironmentVariables
    }
}


#############################################################################################################################
<# Functions #>

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
function Create-Perforce-Workspace
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$Configuration
    )
    Write-Host "[Create-Perforce-Workspace] $Configuration"
    if( (Is-P4WorkspaceConfiguration -Configuration $Configuration ))
    {
        if($Configuration.EnvironmentVariables -ne $null )
        {
            for($i = 0; $i -lt $Configuration.EnvironmentVariables.length; $i++)
            {
                [psobject]$EnvironmentVariableConfig = $Configuration.EnvironmentVariables[$i];
                
                if($EnvironmentVariableConfig -ne $null -and (Is-EnvironmentVariableConfiguration -InputObject $EnvironmentVariableConfig))
                {
                    $prompt         = ($EnvironmentVariableConfig.prompt -eq 'true')
                    $append         = ($EnvironmentVariableConfig.setType -eq 'APPEND' )
                    $allowDup       = ($EnvironmentVariableConfig.stripDupOnAppend -eq 'false')
                    
                    ( Set-Environment-Variable                                  `
                            -Name $EnvironmentVariableConfig.key          `
                            -Value $EnvironmentVariableConfig.defaultValue      `
                            -Level $EnvironmentVariableConfig.level       `
                            -ValueType $EnvironmentVariableConfig.valueType     `
                            -Prompt $prompt                                     `
                            -AppendToCurrentValue $append                       `
                            -AllowDuplicateAppend $false )
                }
            }
        }
        
        $ClientSpecConfig = $Configuration.ClientSpecConfiguration

        if($ClientSpecConfig -ne $null )
        {
            $P4User = ''
        
            if($ClientSpecConfig.P4Config -eq $null -or $ClientSpecConfig.P4Config -eq '')
            {
                Write-Host "Perforce Config was not found, cannot continue" -foregroundColor "DarkRed"
            }
            else
            {
                # Use the P4CONFIG Environment Variable to login to p4 without a prompt and perform automated workspace setup
                ( Set-Environment-Variable -Name "P4CONFIG" -Value $ClientSpecConfig.P4Config -Level 'Machine' -ValueType 'STRING' )
                
                [object[]]$Lines = ( Get-Content $ClientSpecConfig.P4Config )
                
                if($Lines -ne $null -and $Lines.length -gt 0)
                {
                    foreach($Line in $Lines)
                    {
                        [string]$LineStr = $Line.ToString()
                        
                        if($LineStr.IndexOf("P4USER") -gt -1)
                        {
                            $UserData = $LineStr.Split("=");
                            $P4User = $UserData[1];
                            break;
                        }
                    }
                }
                    
                $ScriptBlock = { 
                    Get-Invoke-Expression-Result -Expression "p4 set P4CONFIG=$($ClientSpecConfig.P4Config)" -PrintResult
                }
                
                Change-OutputColor-For-ScriptBlock -ScriptBlock $ScriptBlock -Color "DarkGreen"
                
                
                $err = $false
                if($ClientSpecConfig.WorkspaceName -ne $null) {
                    
                    $result = ( Show-Alert -Message "Would you like to remove previous clientspec $($ClientSpecConfig.WorkspaceName)?" -Title "Workspace Setup" -DialogType 0x4 -SecondsToWait 20 )

                    # Default Negative Response messages
                    $PROMPT_MSG_NO = "User Declined to setup perforce."
                    $PROMPT_MSG_TIMEOUT = "User failed to setup perforce in a timely manner."
                    # A Code, either 0, or 1 (Halt or Proceed, respectively), also prints the result message on screnn
                    $proceedOrHalt = PromptResult-ProceedOrHalt -Response $result -SleepOnPositive 1000 -SleepOnNegative 500
                    
                    if($proceedOrHalt -eq $PROCEED)
                    {
                        $ScriptBlock = { Delete-Perforce-ClientSpec -ClientSpec $ClientSpecConfig.WorkspaceName -User $P4User}
                    
                        Change-OutputColor-For-ScriptBlock -ScriptBlock $ScriptBlock -Color "DarkGreen"
                    }
                    
                    $expr = 'p4 client'
                    
                    if($ClientSpecConfig.Template -ne $null) {
                        $expr += ' -t ' + $ClientSpecConfig.Template;
                    }
                
                    $expr += ' ' + $ClientSpecConfig.WorkspaceName
                   
                    $ScriptBlock = {
                        Get-Invoke-Expression-Result                        `
                            -Expression $expr                               `
                            -Explanation "Create New Perforce Workspace"    `
                            -PrintResult
                    }
                     Change-OutputColor-For-ScriptBlock -ScriptBlock $ScriptBlock -Color "DarkGreen"
                }
                else{
                    $err = $true
                }
                
                if( $err -eq $true ){
                    Write-Error "Could not create workspace, input information was invalid"
                }
            }
            $ScriptBlock = 
            {
                # Logout
                Get-Invoke-Expression-Result            `
                    -Expression "p4 logout -a"          `
                    -Explanation "Logout of Perforce"
                    
            }
            
            Change-OutputColor-For-ScriptBlock -ScriptBlock $ScriptBlock -Color "DarkGreen"
        }
    }
    else
    {
        Write-Error "Object Type Invalid, Expected P4WorkspaceConfiguration Type PSObject"
    }
}
#############################################################################################################################
function Configure-Perforce-Workspace
{
    param(
        [Parameter(Mandatory=$true)]
        [xml]$XML,
        
        [Parameter(Mandatory=$true)]
        [string]$xPath
    )
    Write-Host "[Configure-Perfporce-Workspace] $xPath"
    $P4WorkspaceXML = $XML.SelectSingleNode($xPath)
    $P4WorkspaceConfiguration = $null
    
    if($P4WorkspaceXML -ne $null )
    {
        # Environment Vars P4WorkspaceXML
        [psobject[]]$EnvironmentVariablesList = @()
         
        $VarNodes = $XML.SelectNodes("$xPath/EnvironmentVars/Var")
        
        foreach( $Var in $VarNodes)
        {
        
            [psobject]$P4VarsConfig = ( New-EnvironmentVariableConfiguration    `
                                            -Key $Var.key                       `
                                            -Level $Var.level                   `
                                            -ValueType $Var.valueType           `
                                            -SetType $Var.setType               `
                                            -Prompt ($Var.prompt -eq 'true')    `
                                            -AllowDuplicateAppend ($Var.allowDuplicateAppend -eq 'true') `
                                            -DefaultValue $Var.defaultValue )

            $EnvironmentVariablesList += $P4VarsConfig
        }

        $P4ClientSpecConfiguration = ( Configure-Perforce-ClientSpec -XML $XML -xPath $xPath )
        
        # Create a new P4 Workspace Configuration from XML Data
        [psobject]$P4WorkspaceConfiguration = ( New-P4WorkspaceConfiguration                            `
                                                    -EnvironmentVariables $EnvironmentVariablesList     `
                                                    -ClientSpecConfiguration $P4ClientSpecConfiguration )
        
        # Create Perforce Workspace Configuration
        (Create-Perforce-Workspace -Configuration $P4WorkspaceConfiguration )
    }
    
    $P4WorkspaceConfiguration
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
function Configure-Perforce-ClientSpec( [xml]$XML, [string]$xPath )
{
    $ClientSpecNode = $XML.SelectSingleNode("$xPath/ClientSpec")
    [psobject]$P4ClientSpecConfiguration =  ( New-P4ClientSpecConfiguration                     `
                                                -Template $ClientSpecNode.Template              `
                                                -WorkspaceName $ClientSpecNode.WorkspaceName    `
                                                -P4Config $ClientSpecNode.P4Config              )

    $P4ClientSpecConfiguration
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
function Does-Perforce-ClientSpec-Exist
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientSpec,
        
        [Parameter(Mandatory=$false)]
        [string]$User=''
    )
    $result = $false;
    
    if($User -eq '' -or $User -eq $null)
    {
        $Clients = Get-Invoke-Expression-Result -Expression "p4 clients"
    }
    else{
        $Clients = Get-Invoke-Expression-Result -Expression "p4 clients -u $User"
    }
    
    if($Clients.length -gt 0 )
    {
        foreach($Client in $Clients)
        {
            if($Client -ne $null -and $Client.IndexOf("$ClientSpec") -gt -1)
            {
                $ClientPts = $Client.Split(" ");
                
                if($ClientPts[1] -eq $ClientSpec)
                {
                    $result = $true;
                    break;
                }
            }
        }
    }
    
    return $result
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
function Get-Perforce-ClientSpec
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientSpec,
        
        [Parameter(Mandatory=$false)]
        [string]$User=''
    )
    $result = $null;

    if($User -eq '' -or $User -eq $null)
    {
        $Clients = Get-Invoke-Expression-Result -Expression "p4 clients"
    }
    else{
        $Clients = Get-Invoke-Expression-Result -Expression "p4 clients -u $User"
    }
    
    if($Clients.length -gt 0 )
    {
        foreach($Client in $Clients)
        {
            if($Client -ne $null -and $Client.IndexOf("$ClientSpec") -gt -1)
            {
                $ClientPts = $Client.Split(" ");
                
                if($ClientPts[1] -eq $ClientSpec)
                {
                    $result = $Client;
                    break;
                }
            }
        }
    }
    
    return $result
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
function Delete-Perforce-ClientSpec
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientSpec,
        
        [Parameter(Mandatory=$false)]
        [string]$User=''
    )
    
    if(Does-Perforce-ClientSpec-Exist -ClientSpec $ClientSpec -User $User)
    {
        $ScriptBlock = 
        {
            Get-Invoke-Expression-Result                                                `
                                -Expression "p4 client -d $ClientSpec"                  `
                                -Explanation "Delete existing workspace $ClientSpec"    `
        }
        
        Change-OutputColor-For-ScriptBlock -ScriptBlock $ScriptBlock -Color "DarkGreen"
    }
    else
    {
        Write-Host "Client Spec $ClientSpec doesn't exist!" -foregroundColor "red"
    }
}
#############################################################################################################################

Write-Console -Message "[utils.perforce] Library Script Included." -Color $MAGENTA