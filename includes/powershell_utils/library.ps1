Write-Host "---------------------------------------------------------------------------" -foregroundcolor "DarkCyan"
Write-Host "PowerShell Utils Version 1.0"                                                -foregroundcolor "DarkCyan"
Write-Host "Author Bow M Archer"                                                         -foregroundcolor "DarkCyan"
Write-Host "Copyright, All Rights Reserved 2014"                                         -foregroundcolor "DarkCyan"
Write-Host "---------------------------------------------------------------------------" -foregroundcolor "DarkCyan"
Write-Host "POWERSHELL_UTILS_HOME               $POWERSHELL_UTILS_HOME"         -foregroundcolor "DarkCyan"
Write-Host "POWERSHELL_UTILS_WORKING_DIR        $POWERSHELL_UTILS_WORKING_DIR"  -foregroundcolor "DarkCyan"
Write-Host "POWERSHELL_UTILS_LOG_DIR            $POWERSHELL_UTILS_LOG_DIR"      -foregroundcolor "DarkCyan"
Write-Host "POWERSHELL_UTILS_LOG_FILE           $POWERSHELL_UTILS_LOG_FILE"     -foregroundcolor "DarkCyan"

########################################
# LOW LEVEL SCRIPTS
########################################

. "$POWERSHELL_UTILS_HOME/core/types.ps1"               <# PowerShell Utility Base Types #>
. "$POWERSHELL_UTILS_HOME/core/console_feedback.ps1"    <# Console Messaging Operations #>
. "$POWERSHELL_UTILS_HOME/core/numbers.ps1"             <# Number-Based Operations #>
. "$POWERSHELL_UTILS_HOME/core/strings.ps1"             <# String-Based Operations #>
. "$POWERSHELL_UTILS_HOME/core/filesystem.ps1"          <# File System Operations #>
. "$POWERSHELL_UTILS_HOME/core/ui.ps1"                  <# Console UI Operations #>
. "$POWERSHELL_UTILS_HOME/core/environment.ps1"         <# Console Environment Operations #>
. "$POWERSHELL_UTILS_HOME/utils/zip_util.ps1"                <# Zip Utility #>
. "$POWERSHELL_UTILS_HOME/utils/install_manager.ps1"    <# Installation Manager #>
. "$POWERSHELL_UTILS_HOME/utils/perforce.ps1"           <# Perforce Operations #>
. "$POWERSHELL_UTILS_HOME/utils/utilities.ps1"          <# Utility Script #>
. "$POWERSHELL_UTILS_HOME/net/bits.ps1"                 <# BitsTransfer #>


