<# 
.Synopsis 
Docs

.Description
Module to manage documents

.Notes 
NAME  : Docs.psm1*
AUTHOR: rulasg   

CREATED: 05/26/2021
#>

# Write-Host "Loading Docs ..." -ForegroundColor DarkCyan
Write-Information "Loading Docs ..."

# Script Variables
$script:StoresList = @()

#region EnumAndClasses
# Enums

enum STATUS {
    UNKNOWN
    SUCCESS
    MOVED
    ARE_EQUAL
    ARE_NOT_EQUAL
    ARE_EQUAL_REMOVED_SOURCE
    ARE_NOT_EQUAL_RENAME_SOURCE
    FOLDER_NOT_FOUND
} 

# Classes
class DocsStore {
    [string] $Name
    [string] $Owner
    [string] $Target
    [string] $Path
    [bool] $IsRecursive
    [bool] $Exist
}

class DocName {
    static [string] $SPLITTER = "-"
    static [string] $DEFAULT_OWNER = "rulasg"
    static [string] $DEFAULT_TYPE = "pdf"
    static [string] $DEFAULT_DESCRIPTION = "DESCRIPTION"
    static [string] $DECIMALSEPARATOR = "#"

    [string] $Date #Mandatory
    [string] $Owner #Mandatory
    [string] $Target
    [string] $What
    [string] $Amount
    [string] $Description #Mandatory
    [string] $Type #Mandatory

    #ctor
    DocName() {
        $this.Date = [string]::Empty
        $this.Owner = [string]::Empty
        $this.Target = [string]::Empty
        $this.What = [string]::Empty
        $this.Amount = [string]::Empty
        $this.Description = [string]::Empty
        $this.Type = [string]::Empty
    }

    # Interna Functions

    [string] hidden static Section([string] $sectionName) { if ($sectionName) { return "-$sectionName" } else { return [string]::Empty } }
    [string] hidden static SectionPatternMandatory([string] $p ) { if ($p) { return "-$p" } else { return "-*" } }
    [string] hidden static SectionPatternOptional ([string] $p ) { if ($p) { return "-$p" } else { return [string]::Empty } }
    [string] hidden static SectionPattern     ([string] $p ) { if ($p) { return "$p" } else { return "*" } }

    # API

    [string] Name() {

        #Mandatory fields
        if ($this.Date) { $d = $this.Date } else { $d = Get-Date -Format 'yyMMdd' }
        if ($this.Owner) { $o = $this.Owner } else { $o = [DocName]::DEFAULT_OWNER }
        if ($this.Type) { $t = $this.Type } else { $t = [DocName]::DEFAULT_TYPE }
        if ($this.Description) { $des = $this.Description } else { $des = [DocName]::DEFAULT_DESCRIPTION }
    
        # Transformations
        $d = [DocName]::TransformString($d)
        $o = [DocName]::TransformString($o)
        $ta = [DocName]::TransformString($this.Target)
        $w = [DocName]::TransformString($this.What)
        $am = [DocName]::TransformString($this.Amount)
        $des = [DocName]::TransformString($des)
        $t = [DocName]::TransformString($t)

        $name2 = ($d,$o,$ta,$w,$am,$des).Where({ $_ -ne [string]::Empty }) -Join [DocName]::SPLITTER
        $name2 =($name2,$t) -join '.'

        #d
        $o = [DocName]::Section($o)
        $ta = [DocName]::Section($this.Target)
        $w = [DocName]::Section($this.What)
        $am = [DocName]::Section($this.Amount)
        $des = [DocName]::Section($des)
        #t
        $name = "$d$o$ta$w$am$des.$t"

        if ($name2 -ne $name) {
            "Check the difference" | Write-Verbose
        }

        "[DocName]::Name | {0}" -f $name | Write-Verbose

        return $name
    }

    [string] Pattern() {

        $d = [DocName]::SectionPattern($this.Date)
        $o = [DocName]::SectionPatternMandatory($this.Owner)
        $ta = [DocName]::SectionPatternOptional($this.Target)
        $w = [DocName]::SectionPatternOptional($this.What)
        $am = [DocName]::SectionPatternOptional($this.Amount)
        $des = [DocName]::SectionPatternMandatory($this.Description.Replace(' ', '_'))
        $t = [DocName]::SectionPattern($this.Type)

        $pattern = "$d$o$ta$am$w$des.$t"

        "[DocName]::Pattern - {0}" -f $pattern | Write-Verbose 

        return $pattern
    }

    [bool] IsValid() {

        # Check date
        if (![DocName]::TestDate($this.Date)) {
            "[DocName.IsValid] Date not valid [{0}]" -f $this.Date | Write-verbose
            return $false
        }
        
        # Owner not empty
        if ([string]::IsNullOrWhiteSpace($this.Owner)) {
            "[DocName.IsValid] Owner not valid [{0}]" -f $this.Owner | Write-verbose
            return $false
        }
        
        # Description not empty
        if ([string]::IsNullOrWhiteSpace($this.Description)) {
            "[DocName.IsValid] Description not valid [{0}]" -f $this.Description | Write-verbose
            return $false
        }
        
        # What has not Amount format
        if (![string]::IsNullOrWhiteSpace($this.What)) {
            if (([DocName]::TestAmmount($this.What, [DocName]::DECIMALSEPARATOR)) -or ([DocName]::TestAmmount($this.What, '.'))) {
                "[DocName.IsValid] What not valid [{0}]" -f $this.What | Write-verbose
                return $false
            }
        }
        
        # Amount with # as separator
        if (![string]::IsNullOrWhiteSpace($this.Amount)) {
            if (![DocName]::TestAmmount($this.Amount, [DocName]::DECIMALSEPARATOR)) {
                "[DocName.IsValid] Amount not valid [{0}]" -f $this.Amount | Write-verbose
                return $false
            }
        }

        return $true
    }

    [string] Sample() {

        return ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f "date", "owner", "target", "what", "amount", "desc", "type")
    }

    # Just for testing purposes
    hidden [string] TestTransformStr([string]$field){
        return [DocName]::TransformString($field)
    }

    static [string] TransformString([string]$field) {
        # Replaces Spacaes, / [ ] - 
        # Split
        $reg = "[\s-/\[\]\.]" 
        $splitted = $field -split  $reg
        # Remove empty
        $splitted = $splitted | Where-Object {$_}
        # Join field back
        $ret = $splitted -join '_'

        return $ret
    }

    static [DocName] Convert([string]$Path) {

        $doc = [DocName]::new()

        #Extension
        $ext = $Path | Split-Path -Extension
        $doc.Type = [string]::IsNullOrWhiteSpace($ext) ? $null : $ext.Substring(1)

        $fileName = $Path | Split-Path -LeafBase
        
        # Check Date - Add empty date if not valid
        $splitted = $fileName -split [DocName]::SPLITTER, 2
        if (![docname]::TestDate($splitted[0])) {
            $fileName = [DocName]::SPLITTER + $fileName
        }   

        $splitted = $fileName -split [DocName]::SPLITTER, 3
        $h2 = $null
        switch ($splitted.Count) {
            3 {
                $doc.Date = $splitted[0]
                $doc.Owner = $splitted[1]
                $h2 = $splitted[2]
            }
            2 {
                $doc.Date = $splitted[0]
                $h2 = $splitted[1]
            }
            1 {
                $doc.Date = $splitted[0]
                $h2 = $null
            }

        }
        
        # Second split
        $secondSplit = $h2 -split [DocName]::SPLITTER, 4

        switch ($secondSplit.Count) {
            4 { 
                $doc.Target = $secondSplit[0]
                
                # Check if 1 is correct amount and log it to amount
                if ([docname]::TestAmmount($secondSplit[1], [DocName]::DECIMALSEPARATOR)) {
                    $doc.Amount = $secondSplit[1]
                    $doc.What = $secondSplit[2]
                    $doc.Description = $secondSplit[3]
                }
                else {
                    $doc.What = $secondSplit[1]
                    # check if 2 is correct amound and log or move it to description
                    if ([docname]::TestAmmount($secondSplit[2], [DocName]::DECIMALSEPARATOR)) {
                        $doc.Amount = $secondSplit[2]
                        $doc.Description = $secondSplit[3]
                    }
                    else {
                        $doc.Description = $secondSplit[2] + [DocName]::SPLITTER + $secondSplit[3]
                    }
                }
            }
            3 {
                # Ammount before What
                $doc.Target = $secondSplit[0]

                # If amount correct log it, if not What
                if ([docname]::TestAmmount($secondSplit[1], [DocName]::DECIMALSEPARATOR)) {
                    $doc.Amount = $secondSplit[1]
                }
                else {
                    $doc.What = $secondSplit[1]
                }

                $doc.Description = $secondSplit[2]
            }
            2 {
                $doc.Target = $secondSplit[0]
                $doc.Description = $secondSplit[1]
            }
            1 {
                $doc.Description = $secondSplit[0]
            }
        }

        return $doc
        
        # if ($doc.IsValid()) {
        #     return $doc
        # }
        # else {
        #     "DocName object not valid with given parameters" | Write-Error
        #     return $null
        # }
    }
    static [bool] hidden TestAmmount([string] $Amount, [string] $decimalSeparator = [DocName]::DECIMALSEPARATOR) {
        $ret = $Amount -match "^[1-9]\d*(\{0}\d+)?$" -f $decimalSeparator

        # if (!$ret) {
        #     "Amount format is not correct [ {0}]" -f $Amount | Write-Verbose
        # }

        return $ret
    }
    static [bool] hidden TestDate([string] $Date) {
        # $ret = $Date -match "^\d+$"
        
        if (!($Date -match "^[0-9]{2,6}$")) {
            return $false
        }

        # Check if date is correct
        # We may fall in issues with the date format

        
        try {
            switch ($Date.Length) {
                2 { $null = [datetime]::ParseExact($Date, "yy", $null) }
                4 { $null = [datetime]::ParseExact($Date, "yymm", $null) }
                6 { $null = [datetime]::ParseExact($Date, "yymmdd", $null) }
                Default {
                    return $false
                }
            }
        }
        catch {
            return $false
        }

        return $true
    }
}

#endregion EnumAndClasses

#region Stores

$ANY_TARGET = "any"

function New-DocsStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Owner,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Target,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Path,   
        [Parameter(ValueFromPipelineByPropertyName)][switch] $IsRecursive
    )
    $o = New-Object -TypeName DocsStore
    
    $o.Name = $Owner + "_" + $Target
    $o.Owner = $Owner
    $o.IsRecursive = $IsRecursive
    $o.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $o.Target = $Target

    $o.Exist = Test-Path -Path $o.Path

    return $o
}

function Add-DocsStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] $Owner,
        [Parameter(Mandatory)][string] $Path,   
        [Parameter()][string] $Target,
        [Parameter()][switch] $IsRecursive,
        [Parameter()][switch] $Force
    )
    
    if (! $script:StoresList) {
        Reset-DocsStoresList
    }

    if (!($Path | Test-Path) -and $Force) {
        $null = New-item -ItemType Directory -Force -Path $Path 
    }

    if ($Target) {
        $targetValue = $Target.ToLower()
    } else {
        $targetValue = $ANY_TARGET
    }
    
    $key = $Owner.ToLower() + "_" + $targetValue
    
    $o = New-DocsStore -Owner $Owner -Path $Path -IsRecursive:$IsRecursive -Target $targetValue

    "[Add-DocsStore] {0} - {1}" -f $key, $o.Path | Write-Verbose

    if (($StoresList.Keys) -contains $key) {
        $StoresList[$key] = $o
    }
    else {
        $StoresList.Add($key, $o)
    }

} # Export-ModuleMember -Function Add-DocsStore

function Get-DocsStore {
    [CmdletBinding()]
    [Alias("gs")]
    param (
        [parameter()][string] $Owner,
        [parameter()][string] $Target,
        [parameter()][switch] $Exist
    )

    $stores = $script:StoresList.Values 
    
    if ($Owner) {
        
        $retOwner = $stores | Where-Object {$_.Owner -like $Owner}

        $ret = $Target ? ($retOwner | Where-Object {$_.Target -like $Target}) : ($retOwner | Where-Object {$_.Target -like $ANY_TARGET})
        
        # If we can not find store for specific Target return ANY_TARGET for given OWNER
        if(!$ret -and ($Target -ne $ANY_TARGET)){
            $ret = $retOwner | Where-Object {$_.Target -like $ANY_TARGET}
        }

    } elseif ($Target){

        $ret = $stores | Where-Object {$_.Target -like $Target}

    } else  {
        $ret = $stores
    }

    # Return empty
    if (!$ret) {
        "Store not found for Owner[$Owner] Target[$Target]" | Write-Verbose
        return
    }
    
    if ($Exist) {
        $ret = $ret | Where-Object{$_.Exist}
    }
    
    $count = $ret.Count
    "Found Count[$count] for Owner[$Owner] Target[$Target] with Exist[{$Exist}]" | Write-Verbose

    return $ret
  
} # Export-ModuleMember -Function Get-DocsStore -Alias "gs"

function Reset-DocsStoresList {
    [CmdletBinding()]
    param (
        $StoreList
    )

    if ($StoreList) {
        $script:StoresList = $StoreList        
    }
    else {
        $script:StoresList = New-DocsStoresList
    }    

} # Export-ModuleMember -Function Reset-DocsStoresList

function New-DocsStoresList {
    [CmdletBinding()]
    param()

    return New-Object 'System.Collections.Generic.Dictionary[[string],[PSObject]]'
} # Export-ModuleMember -Function New-DocsStoresList

function Set-DocsLocationToStore {
    [CmdletBinding()]
    [Alias("sdl")]

    param (
        [parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [ArgumentCompletions( {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                Get-DocsOwners -Owner $Owner
            })]
        [ValidateScript( {
                $_ -in (Get-DocsOwners)
            }
        )]
        [string] $Owner
    )
    $location = Get-DocsStore -Owner $Owner

    if (!$location) {
        "Owner unknown" | Write-Error
    }
    elseif (!$location.Exist) {
        "Locations does not exist" | Write-Error
    }
    else {
        $location | Set-Location
        Get-ChildItem
    }
} # Export-ModuleMember -Function Set-DocsLocationToStore # -Alias "sl"

function Get-DocsOwners {
    [CmdletBinding()]
    [Alias("go")]
    param (
        [Parameter()][string] $Owner
    )
    if ([string]::IsNullOrWhiteSpace($Owner)) {
        $Owner = "*"
    }
    $script:StoresList.Values | Where-Object { $_.Owner -like $Owner } | ForEach-Object{$_.Owner} | Select-Object -Unique
    
} # Export-ModuleMember -Function Get-DocsOwners -Alias "go"

#endregion Store

#region DocName
function New-DocsDocName {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)][DocName] $DocName,
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$What,
        [string]$Amount,
        [string]$Description,
        [string]$PreDescription,
        [string]$Type
    )

    $dn = New-Object -TypeName DocName

    $dn.Date = ($Date)        ? $Date        : $DocName.Date
    $dn.Owner = ($Owner)       ? $Owner       : $DocName.Owner
    $dn.Target = ($Target)      ? $Target      : $DocName.Target
    $dn.What = ($What)        ? $What        : $DocName.What
    $dn.Amount = ($Amount)      ? $Amount      : $DocName.Amount
    $dn.Type = ($Type)        ? $Type        : $DocName.Type
    
    $dn.Description = ($Description) ? $Description : $DocName.Description
    $dn.Description = ($PreDescription) ? ("{0}_{1}" -f $PreDescription, $DocName.Description) : $dn.Description

    return $dn
} # Export-ModuleMember -Function New-DocsDocName

function ConvertTo-DocsDocName {
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")] [string[]] $Path,
        [parameter()][string]$Description,
        [parameter()][string]$PreDescription,
        [parameter()][string]$Date,
        [parameter()][string]$Owner,
        [parameter()][string]$Target,
        [parameter()][string]$Amount,
        [parameter()][string]$What,
        [parameter()][string]$Type
    )
        
    process {
        $fileName = $Path | Split-Path -Leaf
        $docname = [DocName]::Convert($fileName)

        $param = @{
            DocName = $docname
            Description = $Description
            PreDescription = $PreDescription
            Date = $Date
            Owner = $Owner
            Target = $Target
            Amount = $Amount
            What = $What
            Type = $Type
        }
        
        $NewDocName = New-DocsDocName  @param
        
        "Converted to DocName [$fileName] " | Write-Verbose
        return $NewDocName
    }
    
} # Export-ModuleMember -Function ConvertTo-DocsDocName

#endregion DocName

#region File
function Get-FileNamePattern {
    [CmdletBinding()]
    Param(
        [string]$Pattern,
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$What,
        [string]$Amount,
        [string]$Description,
        [string]$Type
    )

    if ($Pattern) {
        return (($Pattern -contains '*') -or ($Pattern -contains '?')) ? $Pattern : ("*{0}*" -f $Pattern)
    }

    $dn = New-DocsDocName               `
        -Date $Date                `
        -Owner $Owner              `
        -Target $Target            `
        -What $What                `
        -Amount $Amount            `
        -Description $Description  `
        -Type $Type                

    return $dn.Pattern()
} 

function Get-DocsFileName {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [Parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [Parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [Parameter(ValueFromPipelineByPropertyName)][string]$What,
        [Parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [Parameter(ValueFromPipelineByPropertyName, Mandatory)][string]$Description,
        [Parameter(ValueFromPipelineByPropertyName)][string]$Type
    )

    process {

        $dn = New-DocsDocName              `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -PreDescription $PreDescription  `
            -Type $Type 
            
    
        return $dn.Name()

    }
    
} # Export-ModuleMember -Function Get-DocsFileName

function Test-DocsFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("Name")]
        [string] $FileName
    )

    process {
        $doc = ConvertTo-DocsDocName -Path $FileName  

        $isValid = $doc.IsValid()

        return $isValid
    }
} # Export-ModuleMember -Function Test-FileName

function Find-DocsFile {
    [CmdletBinding()]
    [Alias("fdf")]
    Param(
        [parameter(ValueFromPipeline, Position = 0)][string]$Pattern,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $JustName,
        [parameter()][switch] $Recurse
    )
    process {
        
        $Pattern | Write-Verbose
        $Pattern = Get-FileNamePattern `
        -Pattern $Pattern          `
        -Date $Date                `
        -Owner $Owner              `
        -Target $Target            `
        -Amount $Amount            `
        -What $What                `
        -Description $Description  `
        -Type $Type 
        
        $Pattern | Write-Verbose

        $stores = GEt-DocsStore -Exist

        $files = $stores | ForEach-Object {
            $isRecurse = $Recurse -or $_.IsRecursive
            $_.Path | Get-ChildItem -Filter $Pattern -Recurse:$isRecurse
        }
        
        
        # $files = Get-DocsStore -Exist | Get-ChildItem -Filter $Pattern -Recurse:$store.IsRecursive -File
        
        $ret = $files | Select-Object -Unique | Convert-Path
        
        if ($JustName) {
            return $ret | Split-Path -Leaf
        } else {
            return $ret
        }
        
    } 
} # Export-ModuleMember -Function Find-DocsFile -Alias "f"

function Get-DocsFile {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path,
        [parameter()][string]$Pattern,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $Recurse
    )
    begin {
        $retFiles = @()
    }
    
    process {

        $Path = $Path ?? "."

        $Pattern = Get-FileNamePattern `
            -Pattern $Pattern          `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type 

        # file name format
        $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse:$Recurse -File

        foreach ($file in $files) {
            $dn = ConvertTo-DocsDocName -Path $file

            if ( ($dn)?.IsValid()) {
                # Add to ret
                $retFiles += $file
            }
            else {
                "File format not valid [{0}]" -f $file.Name | Write-Verbose
            }
        }
    }
    
    end {
        "FilesToMove - Found [{0}] Valid [{1}]" -f $files.Length, $retFiles.Length | Write-Verbose
        return $retFiles
    }
} # Export-ModuleMember -Function Get-DocsFile


function Get-DocsName{
    [CmdletBinding()]
    [Alias("gdn")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)][Alias("PSPath")] [string[]] $Path,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$PreDescription,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type
    )

    # 201001-rulasg-edp-FacturaLuzGas-203#08-1HSN201000025360.pdf
    
    process{

        $param = @{
            Description =  $Description
            PreDescription = $PreDescription
            Date = $Date
            Owner = $Owner
            Target = $Target
            Amount = $Amount
            What = $What
            Type = $Type
        }
        
        $files = Get-ChildItem -Path $Path -File
        
        foreach ($file in $files) {


            # #4   feat: [function]How Can I Create File Names Based on Their Time Stamp?
            # Set default values for file name based on the file
            $param.Date = [string]::IsNullOrWhiteSpace($param.Date) ? $file.CreationTime.ToString("yyMMdd") : $param.Date

            $ret = $file | ConvertTo-DocsDocName @param

            $ret | Add-MyMember -NotePropertyName Path -NotePropertyValue $file
            $ret | Add-MyMember -NotePropertyName NewName -NotePropertyValue $ret.Name()

            $ret
        }
    }
}

function global:Get-DocsNameSample{
    [CmdletBinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)][Alias("PSPath")][string[]]$Path,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount
    ) 

    begin{

    }
    
    process{

        $param =  @{
            date = $Date
            owner = 'SampleOwner'
            target = 'SampleTarget'
            what = 'SampleWhat'
            amount = ($Amount ?? '00#00')
        }

        Get-DocsName -path $path @param
    }
}

function Rename-DocsFile {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)][Alias("PSPath")] [string[]] $Path,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][string]$PreDescription,
        [parameter()][switch]$PassThru
    )

    process {

        #Path 
        $files = Get-ChildItem -Path $Path -File
        
        foreach ($File in $Files) {
            
            $docName = $File | ConvertTo-DocsDocName
            $NewDocFile = New-DocsDocName      `
                -DocName $docName          `
                -Date $Date                `
                -Owner $Owner              `
                -Target $Target            `
                -Amount $Amount            `
                -What $What                `
                -Description $Description  `
                -PreDescription $PreDescription  `
                -Type $Type 

            $newFileName = $NewDocFile.Name()
            $fileName = $file | Split-Path -leaf
            
            if ($fileName -ne $newFileName) {
                
                if ($PSCmdlet.ShouldProcess($File.Name, ("Renaming to {0}" -f $newFileName))) {
                    $ret = $File | Rename-Item -NewName $newFileName -PassThru:$PassThru
                }
                elseif ($WhatIfPreference) {
                    "[Rename-DocsFile] | {0} -> {1}" -f $fileName, $newFileName | Write-Verbose
                }
                else {
                    "[Rename-DocsFile] | {0} -> {1}" -f $fileName, $newFileName | Write-Warning
                }
            } 
            else {
                "[Rename-DocsFile] | {0} == {1}" -f $fileName, $newFileName | Write-Verbose
            }

            # Only if rename is called with Passthru
            $ret
        }
    }
} # Export-ModuleMember -Function Rename-DocsFile

function Move-DocsFile {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path,
        [parameter()][string]$Pattern,
        [parameter()][string]$Description,
        [parameter()][string]$Date,
        [parameter()][string]$Owner,
        [parameter()][string]$Target,
        [parameter()][string]$Amount,
        [parameter()][string]$What,
        [parameter()][string]$Type,
        [parameter()][switch] $Recurse,
        [parameter()][switch] $Force
    )

    process {

        $files = Get-DocsFile        `
            -Path $Path                `
            -Pattern $Pattern          `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type                `
            -Recurse:$Recurse

        foreach ($file in $files) {
            
            # Get Doc name info
            $docName = ConvertTo-DocsDocName -Path $file

            $retOwner = $docName.Owner
            $retTarget = $docName.Target

            # Move file to Store

            try {

                # Get Store by owner and Target
                $store = Get-DocsStore -Owner $retOwner -Target $retTarget
                if ($store.Count -ne 1) {
                    $status = ($store.Count -eq 0 ? "Unknown" : "Unclear")
                    $destination = [string]::Empty
                    "{0} store {1} ..." -f $file.Name, $status | Write-Verbose
                } 
                else {
                    
                    if (!$store.Exist) {
                        throw "FOLDER_NOT_FOUND"
                    }

                    $destination = $store.Path 
        
                    $destinationPath = $destination | Join-Path -ChildPath $File.Name
                    
                    if (!(Test-Path -Path $destinationPath)) {
                        #File do not exist

                        $File | Move-Item -Destination $destinationPath -Confirm:$false
                        $Status = "MOVED"
                    }
                    elseif (($file | convert-Path) -eq ($destinationPath | Convert-Path) ) {
                        # Is the same file. Found in the store
                        $status = "ARE_THE_SAME"
                    }
                    else {
                        #File Exists
        
                        $hashSource = Get-FileHash -Path $File
                        $hashDestination = Get-FileHash -Path $destinationPath
        
                        if ($hashSource.Hash -eq $hashDestination.Hash) {
                            #Files are equal                    
                            if ($PSCmdlet.ShouldProcess("$File.Name", "Equal. Leave source ") -and !$Force) {
                                $status = "ARE_EQUAL"
                            }
                            else {
                                Remove-Item -Path $File
                                $status = "ARE_EQUAL_REMOVED_SOURCE"
                            }
                        }
                        else {
                            
                            if ($PSCmdlet.ShouldProcess("$File.Name", "Not Equal. Do not copy") -and !$Force) {
                                $status = "ARE_NOT_EQUAL"
                            }
                            else {
                                $newFilename = GetFileCopyName($File)
                                $newDestination = $Destination | Join-Path -ChildPath $newFilename
                                $File | Copy-Item -Destination $newDestination
                                $File | Remove-Item
                                $status = "ARE_NOT_EQUAL_RENAME_SOURCE"
                            }
                        }
                    }
                }
            }
            catch {
                $Status = $_.Exception.Message
            }
            
            # Build move reference and yield
            $retObject = New-Object -TypeName psobject
            $retObject | Add-Member -NotePropertyName "FullName" -NotePropertyValue $File.FullName
            $retObject | Add-Member -NotePropertyName "Name" -NotePropertyValue $File.Name
            $retObject | Add-Member -NotePropertyName "Owner" -NotePropertyValue $retOwner
            $retObject | Add-Member -NotePropertyName "Target" -NotePropertyValue $retTarget
            $retObject | Add-Member -NotePropertyName "Store" -NotePropertyValue $store.Name
            $retObject | Add-Member -NotePropertyName "Destination" -NotePropertyValue ($destination ?? [string]::Empty) 
            $retObject | Add-Member -NotePropertyName "Status" -NotePropertyValue $Status
            
            $retObject
        }
    }

} # Export-ModuleMember -Function Move-DocsFile

function Test-DocsFile {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path
    )
    process {

        $Path ??= "."

        # file name format
        $files = Get-ChildItem -Path $Path -File 2> $null

        if ($files.Length -eq 0) {
            return $false
        }

        foreach ($file in $files) {
   
            # Does not exist or is a folder
            if ( $file | Test-Path -PathType Container) {
                $ret = $false
            }
            else {
                $ret = $file.Name | Test-DocsFileName
            }
            $ret
        }
    }
} # Export-ModuleMember -Function Test-DocsFile

function Move-DocsFileItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)] $Path,
        [parameter(Mandatory, Position = 1)] $Destination,
        [parameter()] [switch] $Force
    )
    
    process {
        # Destination

        if ( -not (Test-Path $destination -PathType Container )) {
            if ($Force) {
                New-Item -ItemType Directory -Path  $destination | Out-Null 
            } 
            else {
                return [STATUS]::FOLDER_NOT_FOUND
            }
        }
                
        $Files = Get-ChildItem -Path $Path -File

        foreach ($File in $Files) {
            
            $destinationPath = $destination | Join-Path -ChildPath $File.Name

            if (!(Test-Path -Path $destinationPath)) {

                $File | Move-Item -Destination $destinationPath -Confirm:$false
                $Status = [STATUS]::MOVED
            } 
            else {
                #File Exists
                $hashSource = Get-FileHash -Path $File
                $hashDestination = Get-FileHash -Path $destinationPath

                if ($hashSource.Hash -eq $hashDestination.Hash) {

                    #Files are equal                    
                    if ($PSCmdlet.ShouldProcess("$File.Name", [STATUS]::ARE_EQUAL_REMOVED_SOURCE)) {
                        Remove-Item -Path $File
                        $status = [STATUS]::ARE_EQUAL_REMOVED_SOURCE
                    }
                    else {
                        $status = [STATUS]::ARE_EQUAL
                    }
                }
                else {
                    if ($Force) {
                        $newFilename = GetFileCopyName($File)
                        $newDestination = $Destination | Join-Path -ChildPath $newFilename
                        $File | Copy-Item -Destination $newDestination
                        $File | Remove-Item
                        $status = [STATUS]::ARE_NOT_EQUAL_RENAME_SOURCE
                    }
                    else {
                        $status = [STATUS]::ARE_NOT_EQUAL
                    }
                }
            }

            $Status
        }
    }

} # Export-ModuleMember -Function Move-DocsFileItem

function GetFileCopyName([string] $Path) {
    $file = $Path | Get-Item 
    $nameBase = $file.Name
    $targetFullname = $file.FullName
    $count = 0
    while (Test-Path -Path $targetFullname) {
        $count++
        $nameBase = $file.BaseName + "($count)" + $file.Extension
        $targetFullname = Join-Path -Path $file.Directory -ChildPath $nameBase
    }

    return $nameBase
}
#endregion File

#region Formats
function Format-DocsMoveStatus {
    [Alias("fdms")]
    param (
    )
    $input | Format-Table Name, Status, Destination
} # Export-ModuleMember -Function Format-DocsMoveStatus -Alias "fdms"

function Format-DocsName {
    [Alias("fname")]
    param (
    )
    $input | ForEach-Object { $_.Name() }
} # Export-ModuleMember -Function Format-DocsName -Alias "fname"

#endregion Formats

#region Utils
function Add-MyMember   
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory,ValueFromPipeline)][Object] $object,
        [parameter(Mandatory)][string]$NotePropertyName,
        [parameter(Mandatory)][string]$NotePropertyValue
        )
    process {

        if ($Object.$NotePropertyName) {
            $Object.$NotePropertyName = $NotePropertyValue
        } else {
            $object | Add-Member -NotePropertyName $NotePropertyName -NotePropertyValue $NotePropertyValue
        }
    } 
}
#endregion Utils
