<#
.SYNOPSIS
    ScriptHookStart Method for WinMerge Installer Script 
.DESCRIPTION
    This method is invoked upon completion of the win merge installer
    
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
function Install-WinMerge()
{
    Log-Message -Message "[InstallerScript][Install Winmerge] -- Run" -Level $global:LOG_LEVEL.Pending -WriteToLog
    
    ( Set-Environment-Variable          `
    -Name 'P4DIFF'                  `
    -Value ""                       `
    -Level "Machine"                `
    -ValueType "STRING"             `
    -Prompt $false                  `
    -AppendToCurrentValue $false    `
    -AllowDuplicateAppend $false )

    Log-Message -Message "[InstallerScript][Install Winmerge] -- Complete" -Level $global:LOG_LEVEL.Success -WriteToLog
}