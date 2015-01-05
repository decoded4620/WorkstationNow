Add-Type -AssemblyName System.Xml
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

# Converts the Value to its likely type. I.E. 
# True / true are converted to [bool], 
# False / false are converted to [bool], 
# 0xffffff is converted to [uint32]
# 1 is converted to [int]
# 1.00 is converted to double
function Deserialize-Xml-Attribute([string]$ToDeserialize){
    $Deserialized = $ToDeserialize

    if($ToDeserialize.IndexOf(".") -gt -1){
        try{
            $DoubleValue = [System.Convert]::ToDouble($ToDeserialize);
            $Deserialized = $DoubleValue
        } catch [System.Exception]{}
    }
    elseif($ToDeserialize.IndexOf("0x") -eq 0 -or $ToDeserialize.IndexOf("0X") -eq 0){
        try{
            $UintValue = [System.Convert]::ToUint32($ToDeserialize)
            $Deserialized = $UintValue
        } catch [System.Exception]{$tryNext = $true;}
        
        if($tryNext -eq $true){
        
            $StringValue = $ToDeserialize
        }
    }
    else{
        try{
            $IntValue = [System.Convert]::ToInt32($ToDeserialize);
            $Deserialized = $IntValue
        } catch [System.Exception] { $tryNext = $true }
        
        if($tryNext){  

            $ToDeserializeLower = $ToDeserialize.ToLower()
            if($ToDeserializeLower -eq "true" -or $ToDeserialize -eq "false"){
                $BooleanValue = [System.Convert]::ToBoolean($ToDeserialize)
                $Deserialized = $BooleanValue
            }
            else{
                $StringValue = $ToDeserialize
                $Deserialized = $StringValue
            }
        }
    }
    $Deserialized
}

# TODO
function DeserializeXml-To-PSObject($ToDeserialize){

    Write-Host "Type $($ToDeserialize.GetType())"
    try{
        $IntValue = [System.Convert]::ToInt32($ToDeserialize);
    }
    catch [System.Exception]
    {
        Write-Host "Not Int"
    }
    try{
        $DoubleValue = [System.Convert]::ToDouble($ToDeserialize);
        
    }
    catch [System.Exception]
    {
        Write-Host "Not Double"
    }
    try{
        $UintValue = [System.Convert]::ToUint32($ToDeserialize);
    }
    catch [System.Exception]
    {Write-Host "Not Uint"}
    
    try{
        $StringValue = [System.Convert]::ToString($ToDeserialize)
    }
    catch [System.Exception]
    {Write-Host "Not String"}
    
    try{
        $BooleanValue = [System.Convert]::ToBoolean($ToDeserialize)
    }
    catch [System.Exception]
    {Write-Host "Not Boolean"}
    
    try{
        $ObjectValue = [psobject]$ToDeserialize
    }
    catch [System.Exception]
    {Write-Host "Not Object"}
    
    
    
    $retVal = New-Object psobject @{
        UintValue = $UintValue
        IntValue = $IntValue
        DoubleValue = $DoubleValue
        StringValue = $StringValue
        BooleanValue = $BooleanValue
        ObjectValue = $ObjectValue
    }
    
    Write-Host "Values $IntValue $DoubleValue $UintValue $StringValue $BooleanValue"
    
    $retVal
}


function Iterate-Object(){
    
    param(
    
        [Parameter(Mandatory=$true)]
        $PSObject,
        
        [Parameter(Mandatory=$true)]
        $tabStr
    )
    if($tabStr -eq $null){
        $tabStr = ""
    }
    
    
    if($PSObject -ne $null)
    { 
        $isObject = $PSObject -is [psobject]
        $isArray = $PSObject -is [system.array]

        if($isObject)
        {
            Write-Host "$tabStr{"
            
            $properties = $PSObject.PSObject.Properties;
            
            if($PSObject -ne $null -and $properties -ne $null){
                
                foreach ($property in $properties) 
                { 
                    $Value = $properties[$property.Name].Value;
                    
                    
                    if($Value -is [System.Array]){
                        Write-Host "$tabStr   $($property.Name)="
                        for($i = 0; $i -lt $Value.Length; $i++)
                        {   
                            #Write-Host "$tabStr    [$i] $($Value[$i].GetType()) = $($Value[$i])"
                            
                            if( $Value[$i] -ne $null ){
                                Iterate-Object -PSObject $Value[$i] -tabStr "$tabStr    ";
                            }
                        }
                    }
                    elseif($Value -is [psobject]){
                        Write-Host "$tabStr    $($property.Name)="
                        Iterate-Object -PSObject $Value  -tabStr "$tabStr    "
                    }
                    else{
                        Write-Host "$tabStr    $($property.Name)=$Value"
                    }
                }
            }
            
            Write-Host "$tabStr}"
        }
        elseif($isArray){
        
            Write-Host "$tabStr ["
            for($i = 0; $i -lt $PSObject.Length; $i++)
            {   
                if($PSObject[$i] -ne $null ){
                   # Write-Host "$tabStr $($[i])="
                    Iterate-Object -PSObject ($PSObject[$i]) -tabStr "$tabStr    "
                    
                }
            }
           # Write-Host "$tabStr ]"
        } 
        else{
            Write-Host "$tabStr    $($property.Name)=$Value)"
        }
       
    }
}
function PSObject-To-XML(){
     param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            [psobject]$PSObject,
            
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            $Container,
            
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
            $XmlDoc,
            
            [Parameter(Mandatory=$false)]
            [string]$tabStr=$null
        )
    if($tabStr -eq $null){
        $tabStr = ""
    }
    if($PSObject -ne $null)
    {
        $isObject = $PSObject -is [psobject]
        $isArray = $PSObject -is [system.array]

        if($isObject)
        {
            #Write-Host "$tabStr{"
            
            
            $properties = $PSObject.PSObject.Properties;
            
            if($PSObject -ne $null -and $properties -ne $null){
                
                foreach ($property in $properties) 
                { 
                    $Value = $properties[$property.Name].Value;
                    
                    
                    if($Value -is [System.Array]){
                       
                       # Write-Host "$tabStr   $($property.Name)="
                        for($i = 0; $i -lt $Value.Length; $i++)
                        {    
                            $ChildContainer = $XmlDoc.CreateElement($property.Name)
                            
                            #Write-Host "$tabStr    [$i] $($Value[$i].GetType()) = $($Value[$i])"
                            
                            if( $Value[$i] -ne $null ){
                               PSObject-To-XML -PSObject $Value[$i] -Container $ChildContainer -XmlDoc $XmlDoc -tabStr "$tabStr    ";
                            }
                            
                            $Container.AppendChild($ChildContainer)
                        }
                    }
                    elseif($Value -is [psobject]){
                        $ChildContainer = $XmlDoc.CreateElement($property.Name)
                        #Write-Host "$tabStr    $($property.Name)="
                        PSObject-To-XML -PSObject $Value  -Container $ChildContainer -XmlDoc $XmlDoc -tabStr "$tabStr    "
                        
                        $Container.AppendChild($ChildContainer)
                    }
                    else{
                        $Container.SetAttribute($property.Name, $Value);
                        #Write-Host "$tabStr    $($property.Name)=$Value"
                    }
                }
            }
            
            #Write-Host "$tabStr}"
        }
        elseif($isArray){
        
            Write-Error "ODDD"
            #Write-Host "$tabStr ["
            for($i = 0; $i -lt $PSObject.Length; $i++)
            {   
                if($PSObject[$i] -ne $null ){
                    $ChildContainer = $XmlDoc.CreateElement("")
                   # Write-Host "$tabStr $($[i])="
                    PSObject-To-XML -PSObject ($PSObject[$i]) -Container $ChildContainer -XmlDoc $XmlDoc -tabStr "$tabStr    "
                    
                    $Container.AppendChild($ChildContainer)
                    
                }
            }
           # Write-Host "$tabStr ]"
        } 
        else{  
            Write-Error "Reall ODD"
            Write-Host "$tabStr    $($property.Name)=$Value)"
        }
    }
}
function XML-To-PSObject(){

    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        $Xml,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [psobject]$Container,
        
        [Parameter(Mandatory=$false)]
        [string]$tabStr=$null
    )
    
    if($tabStr -eq $null){
        $tabStr = ""
    }
    
        
    if($Xml -ne $null)
    {
        Switch($Xml.GetType())
        {
            { ( $_ -eq [System.Xml.XmlComment] ) }{
                Write-Debug "Comment Node"
            }
            
            { ($_ -eq [System.Xml.XmlElement])}{
                Write-Host "$tabStr<$($Xml.LocalName)" -NoNewLine
                #Write-Verbose "Element Node"
                
                
                
                # Attributes are converted into primitives, and then set as normal properties
                if($Xml.Attributes -ne $null){
                    foreach($Attribute in $Xml.Attributes){
                        Write-Host " $($Attribute.Name)='$($Attribute.Value)'" -NoNewLine
                       # Write-Host "Adding Attribute Property $($Attribute.Name)=$($Attribute.Value)"
                        $Container | Add-Member NoteProperty $Attribute.Name (Deserialize-Xml-Attribute($Attribute.Value))
                    }
                }
                
                Write-Host ">"
                
                # If we have children nodes
                if($Xml.ChildNodes -ne $null){
                    [System.Collections.ArrayList]$nodeMapNames = New-Object System.Collections.ArrayList;
                    
                    foreach($ChildXml in $Xml.ChildNodes){

                        if($ChildXml -is [System.Xml.XmlComment]){
                            Write-Verbose "Node is a Comment $($ChildXml)"
                            continue;
                        }
                        
                        
                        if($nodeMapNames.Contains($ChildXml.LocalName)){
                              Write-Verbose "Already Processed $($ChildXML.LocalName)"
                            continue;
                        }
                        
                        # select all nodes at this level for that match this nodes' name
                        $multipleNodes = $Xml.SelectNodes($ChildXml.LocalName);
                        
                        # Write-Host "Process ChildXML $($ChildXml.LocalName) -> Multiple: $multipleNodes $($multipleNodes.Count)"
                        # if the node list returns more than one item, this item name is technically an 'array' of 
                        # the same item type (assuming all the XML has the same attributes and same value types).
                        #
                        if( $multipleNodes.Count -gt 1)
                        {
                            # Create the array
                            $ChildObjects = @()
                            
                            # Go through the node list NOW and push each one onto the array
                            # Serializing
                            foreach($MultiChild in $multipleNodes) {
                                $ChildContainer = New-Object PSObject;
                                
                                XML-To-PSObject -Xml $MultiChild -Container $ChildContainer -tabStr "$tabStr    ";
                                
                                $ChildObjects += $ChildContainer;
                            }
                            
                            if(($Container | Get-Member -Name $ChildXml.LocalName.ToString()) -ne $null){
                                    Write-Warning "$tabStr$($ChildXml.LocalName) Already Exists in Object!"
                            }else{
                                $Container | Add-Member NoteProperty -Name $ChildXml.LocalName.ToString() -Value $ChildObjects
                            }
                            
                            
                            if($multipleNodes.Count -eq $Xml.ChildNodes.Count){
                               # Write-Host "Got all the child nodes on first run!" -foregroundcolor "Red"
                                break;
                            }
                           # else{
                               # Write-Host "Got $($multipleNodes.Count) of $($Xml.ChildNodes.Count) Nodes"
                           # }
                        }
                        else{ 
                            $ChildContainer = New-Object PSObject;
                             #Write-Host "Got $($multipleNodes.Count) of $($Xml.ChildNodes.Count) Nodes"
                            #Write-Host "NODE OBJECT"
                            # Just convert this object directly, and set the value to the converted object
                            XML-To-PSObject -Xml $ChildXml -Container $ChildContainer -tabStr "$tabStr    ";
                            
                            if(($Container | Get-Member -Name $ChildXml.LocalName.ToString()) -ne $null){
                                Write-Warning "$tabStr$($ChildXml.LocalName) Already Exists in Object!"
                            }
                            else{
                                $Container | Add-Member NoteProperty -Name $ChildXml.LocalName.ToString() -Value $ChildContainer
                            }
                        }
                        
                        # insure we don't re-add this
                        $index = $nodeMapNames.Add($ChildXml.LocalName);
                    }
                    
                    
                }
                elseif($Xml.InnerText -ne $null -and $Xml.InnerText -ne ""){
                    
                    if(($Container | Get-Member -Name $Xml.LocalName.ToString()) -ne $null){
                        Write-Warning "$($Xml.Name) Already Exists in Object!"
                    }
                    else{
                        $Container | Add-Member NoteProperty -Name $Xml.LocalName.ToString() -Value (Deserialize-Xml-Attribute($Xml.InnerText))
                    }
                }
                
                 Write-Host "$tabStr<$($Xml.LocalName)/>"
            }
        }
    }
    else{
        Write-Error "XMLNode was NULL!!"
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