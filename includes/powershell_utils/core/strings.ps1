
function Join-ArrayList
{
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$ArrayList,
        
        [Parameter(Mandatory=$false)]
        [string]$Separator = ','
    )
    
    $retVal = "";
    $sepVal = "$Separator "
    
    $cnt = $ArrayList.Count
    for($i = 0; $i -lt $cnt; ++$i)
    {
        if($i -gt 0){
            $retVal += $sepVal
        }
        
        if($ArrayList[$i] -ne $null){
            $retVal += $ArrayList[$i].ToString()
        }else{
            $retVal += "null"
        }
    }
    
    $retVal
}

function Pad-String
{
    param(
        [Parameter(Mandatory=$false)]
        [string]$string=" ", 
        
        [Parameter(Mandatory=$true)]
        [int]$length, 
        
        [Parameter(Mandatory=$false)]
        [string]$padChar=' ', 
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('center', 'right', 'left')]
        [string]$padType='right', 
        
        [Parameter(Mandatory=$false)]
        [string]$postFix="..."
    )
    
    $returnString = "";
    
    if($string -eq '' -or $string -eq $null){
        $returnString = $padChar
    }
    else{
        if($string.length -gt $length)
        {
            $hasPostFix = ($postFix -ne $null -and $postFix -ne '')
            
            # TERNARY ASIGNMENT FTW, if we have a postfix, we'll include that in the substring op
            $newLen = @{ $true = $length-$postFix.length;$false = $length }[$hasPostFix]
            
            if($newLen -lt 1){
                $newLen = 1
            }
            
            $string = $string.Substring(0, $newLen) + $postFix
        }
        else
        {
            $returnString = $string
            
            # avoid infinite loop if needed
            if($padChar -eq $null -or $padChar -eq ''){
                $padChar = ' '
            }
            
            switch($padType)
            {
                {$_ -eq 'right'}{
                    
                    while($returnString.length -lt $length){
                        $returnString += $padChar
                    }
                }
            
                {$_ -eq 'left'}{
                    while($returnString.length -lt $length){
                        $returnString = $padChar + $returnString
                    }
                }
                
                {$_ -eq 'center' -or $_ -eq 'middle'}{
                    
                    $cnt = 0;
                    while($returnString.length -lt $length){
                        if($cnt++ % 2 -eq 0 )
                        {
                            $returnString = $padChar + $returnString
                        }
                        else
                        {
                            $returnString += $padChar
                        }
                    }
                }
                
                default{
                    while($returnString.length -lt $length){
                        $returnString += $padChar
                    }
                }
            }
            
        }
    }
    
    $returnString
}

Write-Console -Message "[core.strings] Library Script Included." -Color $MAGENTA
