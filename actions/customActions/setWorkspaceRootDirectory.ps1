<#
.SYNOPSIS
    Reset the Workspace Root Directory
.DESCRIPTION
    This Custom Action will allow the user to choose his root workspace location via Directory Browsing Dialog
    This should be run near the beginning of the action list of a workspace setup, prior to any WorkspaceRootDir dependent actions / filesystem changes
.NOTES
    File Name      : setWorkspaceRootDirectory.ps1
    Author         : Bow Archer
    Prerequisite   : PowerShell V2
.LINK

.EXAMPLE
  
.EXAMPLE
#>
function setWorkspaceRootDirectory
{
    Log-Message -Message "[setWorkspaceRootDirectory] execute" -Level $global:LOG_LEVEL.Info
    
    # for a directory location
    $global:WorkspaceRootDir = (Read-FolderBrowserDialog -Message "Select a Workspace Root Location" -Title "$ProgramTitle" )

    if(![string]::IsNullOrEmpty($global:WorkspaceRootDir))
    {
        Log-Message -Message "Workspace Root Selected $global:WorkspaceRootDir" -Level $global:LOG_LEVEL.INFO -WriteToLog
        
        # change to the new location
        Get-Invoke-Expression-Result -Expression "cd $global:WorkspaceRootDir" -PrintResult
        
        # The Selected Workspace Root Directory
        $global:WorkspaceRootDir           = (Get-Location).Path;
    }
    
    # Update the workspace environment variable here
    $WorkspaceRootConfigXML     = $EnvironmentConfiguration.SelectSingleNode("//WorkspaceRoot");

    # Used to set the environment variable for workspace root
    [string]$WorkspaceRootKey   = $WorkspaceRootConfigXML.environmentVarKey
    [string]$level              = 'User'
    [string]$valueType          = 'STRING'

    # Set our environment variable
    ( Set-Environment-Variable -Name $WorkspaceRootKey -Value $global:WorkspaceRootDir -Level $level -ValueType $valueType -Prompt $false -AppendToCurrentValue $false -AsJob )
}