<# Utility Script for Doing fun windows powershell stuff #>
#############################################################################################################################
<#
.SYNOPSIS
    
.DESCRIPTION
    
.NOTES
    File Name      : filesystem.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE

#>

$SubstConfig_TypeDef_Source = @"
public class SubstConfiguration {

    // if true, deletes the current SubstituteDrive, and ignores ActualDrive
    public bool DeleteCurrentSubstMapping;
    
    // if true, replaces any existing SubstituteDrive, by first deleting the current value
    // before resetting it to the new SubstituteDrive
    public bool ReplaceExistingDriveMapping;
    
    // The Actual Drive Letter
    public string VirtualDriveLocation;
    
    // The Substitute Drive Letter
    public string VirtualDriveLetter;
}
"@

Add-Type -TypeDefinition $SubstConfig_TypeDef_Source
#############################################################################################################################

<#
.SYNOPSIS
    
.DESCRIPTION
    
.NOTES
    File Name      : filesystem.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE

#>
function Remap-Drive
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$MappingConfiguration
    )
    
    if( $MappingConfiguration -ne $null -and (Is-DriveMappingConfiguration -Configuration $MappingConfiguration) ){
       # Write-Console -Message "[Remap-Drive] Mapping Drive $($MappingConfiguration.VirtualDriveLetter) => $($MappingConfiguration.VirtualDriveLocation) " -Color $COLOR_MSG_ITEM_START -WriteToLog
        # clear the old
        
        if($MappingConfiguration.DeleteCurrentSubstMapping -eq $true){
            
            if( (Drive-Exists -DriveLetter $MappingConfiguration.VirtualDriveLetter)) {
                Log-Message -Message "[Remap-Drive] Clear old mapping  $($MappingConfiguration.VirtualDriveLetter)" -Level $global:LOG_LEVEL.Info -WriteToLog
                Get-Invoke-Expression-Result -Expression ( "subst $($MappingConfiguration.VirtualDriveLetter): /D" ) -PrintResult
            }
        }
        else
        {
            if($MappingConfiguration.ReplaceExistingDriveMapping -eq $true){
            
                if( (Drive-Exists -DriveLetter $MappingConfiguration.VirtualDriveLetter)) {
                    Log-Message -Message "[Remap-Drive] Replace existing mapping  $($MappingConfiguration.VirtualDriveLetter)" -Level $global:LOG_LEVEL.Info -WriteToLog
                    Get-Invoke-Expression-Result -Expression ( "subst $($MappingConfiguration.VirtualDriveLetter): /D" ) -PrintResult
                }
            }

           Log-Message -Message "[Remap-Drive] Set New Mapping [ $($MappingConfiguration.VirtualDriveLetter) => $($MappingConfiguration.VirtualDriveLocation)]" -Level $global:LOG_LEVEL.Info -WriteToLog
           Get-Invoke-Expression-Result -Expression ("subst $($MappingConfiguration.VirtualDriveLetter): $($MappingConfiguration.VirtualDriveLocation)") -PrintResult
        }
        
        if( (Drive-Exists -DriveLetter $MappingConfiguration.VirtualDriveLetter)) {
                $MappingConfiguration.Status = $global:SUCCESS
        }
        else{
            $MappingConfiguration.Status = $global:FAIL
        }
    }
    else{
        $MappingConfiguration.Status = $global:FAIL
        Log-Message -Message "Mapping Configuration was NULL" -Level $global:LOG_LEVEL.Error -WriteToLog
    }
}

function SetReadWritePriviledges([string]$Path)
{
    # Create a'Read Write' FileSystemAccessRule for the current user
    $colRights          = [System.Security.AccessControl.FileSystemRights]"Read, Write" 

    $InheritanceFlag    = [System.Security.AccessControl.InheritanceFlags]::None 
    $PropagationFlag    = [System.Security.AccessControl.PropagationFlags]::None 

    $objType            =[System.Security.AccessControl.AccessControlType]::Allow 

    $accountStr = "$($env:USERGROUP)\$($env:USERNAME)";
    
    Log-Message -Message "[SetReadWritePriviledges] $Path for $accountStr" -Level $global:LOG_LEVEL.Info -WriteToLog
    $objUser = New-Object System.Security.Principal.NTAccount($accountStr)

    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType) 

    # Update the ACL to 'Read Write' for the current user
    $objACL = Get-ACL $Path 
    $objACL.AddAccessRule($objACE)
    Set-ACL $Path $objACL

}

function Recycle-Item( [string] $Path  )
{
    $result = $false
    Log-Message -Message "[Recycle-Item]$Path" -Level $global:LOG_LEVEL.Info -WriteToLog


    $item = $global:APPLICATION.Namespace(0).ParseName("$Path")
    if($item -ne $null)
    {
        $item.InvokeVerb("delete")
        
        $result = !(Test-Path $Path)
        
    }
    
    Log-Message -Message "[Recycle-Item] Result $result, Path $Path" -Level $global:LOG_LEVEL.Info -WriteToLog
    $result
}

function Get-Parent( [string]$Path )
{
    return Split-Path $Path -resolve
   
    <#
    $absPath =  $Path
    
    $lastIndexOfSlash = $absPath.LastIndexOf('\');
    
    if($lastIndexOfSlash -eq -1)
    {
        $retPath = $absPath
    }
    else{
        $retPath = $absPath.Substring(0, $lastIndexOfSlash)
    }
    
    Resolve-Path $retPath
    #>
}

function File-Exists
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$File
    )
    Test-Path "$File" -pathType leaf
}


function Directory-Exists
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$File
    )
    Test-Path "$File" -pathType container
}

function Drive-Exists
{
    param(
        [Parameter(Mandatory=$true)]
        [char]$DriveLetter
    )
    Test-Path "$DriveLetter:/" -pathType container
}


#############################################################################################################################
# Drive Mapping Configuration
#############################################################################################################################


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
function Is-DriveMappingConfiguration( [psobject]$Configuration )
{
    $validated = ( Validate-Type-Properties         `
                        -InputObject $Configuration `
                        -Properties @('VirtualDriveLocation', 'VirtualDriveLetter','DeleteExistingDriveMapping','ReplaceExistingDriveMapping'))
    $validated
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
function New-DriveMappingConfiguration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VirtualDriveLocation,
        
        [Parameter(Mandatory=$true)]
        [string]$VirtualDriveLetter,
        
        [Parameter(Mandatory=$true)]
        [string]$DeleteExistingDriveMapping,
        
        [Parameter(Mandatory=$true)]
        [string]$ReplaceExistingDriveMapping
    )
    
    Write-Host "[New-DriveMappingConfiguration]$VirtualDriveLetter => $VirtualDriveLocation"
    
    # return the new object
    New-Object psobject -property @{
        VirtualDriveLocation            = $VirtualDriveLocation
        VirtualDriveLetter              = $VirtualDriveLetter
        DeleteExistingDriveMapping      = $DeleteExistingDriveMapping
        ReplaceExistingDriveMapping     = $ReplaceExistingDriveMapping
        Status                          = $global:STATUS_UNKNOWN
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
function Configure-Drive-Mapping
{
    param(
        [Parameter(Mandatory=$true)]
        [psobject]$MappingConfiguration,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkspaceRoot,
        
        [Parameter(Mandatory=$false)]
        [bool]$Prompt = $false
    )

    Write-Console -Message "[Configure-Drive-Mapping] => $xPath [$WorkspaceRoot]" -Color $COLOR_MSG_PROGRESS

    $MappingConfiguration.Status = $global:STATUS_PENDING
    
    $proceedOrHalt = $global:PROCEED
    
    if( $Prompt ) {
    
        $PROMPT_MSG_NO      = "User declined to set drive mapping"
        $PROMPT_MSG_TIMEOUT = "User failed to set drive mapping in a timely manner"
        
        $proceedOrHalt = PromptResult-ProceedOrHalt `
                            -Response ( `
                                Show-Alert `
                                    -Message "Setup Virtual Hard-Drive $($DriveMapping.VirtualDriveLetter) to location $($WorkspaceRoot)?" `
                                    -Title "Create Virtual Hard-Drive" `
                                    -DialogType 0x4 )
    }
    
    if($proceedOrHalt -eq $global:PROCEED ){
       # $MappingConfigurations.Add($MappingConfiguration)
        
        # Perform the Substitute using the configuration

        Remap-Drive -MappingConfiguration $MappingConfiguration

        Write-Headline -Message "[Configure-Drive-Mapping] $($MappingConfiguration.VirtualDriveLetter) => $($MappingConfiguration.VirtualDriveLocation) Status: $($MappingConfiguration.Status)" -Color $COLOR_MSG_ITEM_COMPLETE
    }
    else{
        Write-Console -Message "[Configure-Drive-Mapping] Drive Not Remapped $($MappingConfiguration.VirtualDriveLocation)" -Color $COLOR_MSG_ERROR
        $MappingConfiguration.Status = $global:NOT_AUTHORIZED
    }
}
