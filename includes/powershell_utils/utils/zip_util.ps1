function Unzip([string]$file, [string]$destination)
{
    [string]$tmpDir = $null
    
    if($tmpDir -eq $null){
        $tmpDir -eq $destination
    }
    
    $result = $false
    $ComShell = New-Object -com shell.application
    Write-Console -Message "[Unzip] $file to $destination" -Color $COLOR_MSG_JOB_COMPLETE
    
    $zip = $ComShell.NameSpace($file)
     
    if($zip -ne $null){
        
        $exists = Test-Path $destination
        
        if($exists){
            Write-Console -Message "[Unzip] Removing $destination" -Color $COLOR_MSG_WARN
            
            Recycle-Item($destination)
        }
        
        # recreate
        New-Item -ItemType directory -Path $destination
        
        $extractedDirectory = $ComShell.NameSpace($destination)

        if($extractedDirectory -ne $null){
            Write-Console -Message "[Unzip] Copying Items" -Color $COLOR_MSG_ITEM_COMPLETE
            foreach($item in $zip.items()){
                $extractedDirectory.copyhere($item)
            }

            $result = $true
        }
    }

    $result
}
<# 
function Zip()
{
    param([string]$zipfilename)

    if(-not (test-path($zipfilename)))
    {
        set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (dir $zipfilename).IsReadOnly = $false  
    }

    $zipPackage = $ComShell.NameSpace($zipfilename)

    foreach($file in $input) 
    { 
            $zipPackage.CopyHere($file.FullName)
            Start-sleep -milliseconds 500
    }

} #>


Write-Console -Message "[utils.zip] Library Script Included." -Color $MAGENTA