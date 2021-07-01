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

Write-Host "Loading Docs ..." -ForegroundColor DarkCyan


# Script Variables
$script:StoresList = @()

function Set-VerboseOn {
    $VerbosePreference = Continue
} Export-ModuleMember -Function Set-VerboseOn

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
    [string] $Owner
    [string] $Path
    [bool] $IsRecursive
    # [bool] $AddMonthFolder
    # [bool] $AddYearFolder
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

function New-Store {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Owner,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)][string] $Path,   
        [Parameter(ValueFromPipelineByPropertyName)][switch] $IsRecursive
    )
    $o = New-Object -TypeName DocsStore
    
    $o.Owner = $Owner
    $o.IsRecursive = $IsRecursive
    $o.Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    
    # if ($Path | Test-Path) {
    #     $o.Path = $Path | Convert-Path 
    # }
    # else {
    #     if ([System.IO.Path]::IsPathRooted($Path)) {
    #         $o.Path = $Path
    #     }
    #     else {
    #         Write-Error ("Path has to be rooted if it does not exit [{0}]" -F $Path)
    #         return
    #     }
    # }
    # $o.Path = [System.IO.Path]::IsPathRooted($Path) ? $Path : (Resolve-Path -Path $Path).Path

    $o.Exist = Test-Path -Path $o.Path

    return $o
}

function Add-Store {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] $Owner,
        [Parameter(Mandatory)][string] $Path,   
        [Parameter()][switch] $IsRecursive,
        [Parameter()][switch] $Force
    )
    
    if (! $script:StoresList) {
        Reset-StoresList
    }

    if (!($Path | Test-Path) -and $Force) {
        $null = New-item -ItemType Directory -Force -Path $Path 
    }

    $keyOwner = $Owner.ToLower()
    
    $o = New-Store -Owner $Owner -Path $Path -IsRecursive:$IsRecursive

    "[Add-Store] {0} - {1}" -f $keyOwner, $o.Path | Write-Verbose

    if ((Get-Owners) -contains $keyOwner) {
        $StoresList[$keyOwner] = $o
    }
    else {
        $StoresList.Add($Owner.ToLower(), $o)
    }

} Export-ModuleMember -Function Add-Store

function Get-Store {
    [CmdletBinding()]
    [Alias("gs")]
    param (
        [parameter()][string] $Owner,
        [parameter()][switch] $Exist
    )
    
    if ($Owner) {
        $ret = $script:StoresList[$Owner.ToLower()]
    }
    else {
        $ret = $script:StoresList.Values 
    }

    if (!$ret) {
        return
    }

    $ret | ForEach-Object {
        $r = $_ | New-Store

        if ($Exist) {
            if ($r.Exist) {
                $r
            }
        }
        else {
            $r
        }

    }

} Export-ModuleMember -Function Get-Store -Alias "gs"

function Reset-StoresList {
    [CmdletBinding()]
    param (
        $StoreList
    )

    if ($StoreList) {
        $script:StoresList = $StoreList        
    }
    else {
        $script:StoresList = New-StoresList
    }    

} Export-ModuleMember -Function Reset-StoresList

function New-StoresList {
    [CmdletBinding()]
    param()

    return New-Object 'System.Collections.Generic.Dictionary[[string],[PSObject]]'
} Export-ModuleMember -Function New-StoresList

function Set-LocationToStore {
    [CmdletBinding()]
    [Alias("sl")]

    param (
        [parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [ArgumentCompletions( {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                Get-Owners -Owner $Owner
            })]
        [ValidateScript( {
                $_ -in (Get-Owners)
            }
        )]
        [string] $Owner
    )
    $location = Get-Store -Owner $Owner

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
} Export-ModuleMember -Function Set-LocationToStore -Alias "sl"

function Get-Owners {
    [CmdletBinding()]
    [Alias("go")]
    param (
        [Parameter()][string] $Owner
    )
    if ([string]::IsNullOrWhiteSpace($Owner)) {
        $Owner = "*"
    }
    $script:StoresList.Keys | Where-Object { $_ -like $Owner }
    
} Export-ModuleMember -Function Get-Owners -Alias "go"

#endregion Store

#region DocName
function New-DocName {
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
} Export-ModuleMember -Function New-DocName

function ConvertTo-DocName {
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
        $filenName = $Path | Split-Path -Leaf
        $docname = [DocName]::Convert($filenName)

        $NewDocName = New-DocName      `
            -DocName $docName          `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -PreDescription $PreDescription  `
            -Type $Type 

        return $NewDocName
    }
    
} Export-ModuleMember -Function ConvertTo-DocName

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

    $dn = New-DocName               `
        -Date $Date                `
        -Owner $Owner              `
        -Target $Target            `
        -What $What                `
        -Amount $Amount            `
        -Description $Description  `
        -Type $Type                

    return $dn.Pattern()
} 

function Get-FileName {
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

        $dn = New-DocName              `
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
    
} Export-ModuleMember -Function Get-FileName

function Test-FileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("Name")]
        [string] $FileName
    )

    process {
        $doc = ConvertTo-DocName -Path $FileName  

        $isValid = $doc.IsValid()

        return $isValid
    }
}Export-ModuleMember -Function Test-FileName

function Find-File {
    [CmdletBinding()]
    [Alias("f")]
    Param(
        [parameter(ValueFromPipeline, Position = 0)][string]$Pattern,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $Recurse
    )
    
    $retFiles = @()
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

    foreach ($store in $(Get-Store -Exist)) {
        "Searching {0}..." -f ($store.Path | Join-Path -ChildPath $Pattern)  | Write-Verbose
        $files = Get-ChildItem -Path $store.Path -Filter $Pattern -Recurse:$store.IsRecursive -File
        foreach ($file in $files) {
            if ($retFiles -notcontains $file.FullName) {
                $retFiles += $file.FullName
                $file
            }
        }
    }
    
} Export-ModuleMember -Function Find-File -Alias "f"

function Get-File {
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
            $dn = ConvertTo-DocName -Path $file

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
} Export-ModuleMember -Function Get-File

function Rename-File {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter( ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")] [string[]] $Path,
        [parameter()][string]$Description,
        [parameter()][string]$PreDescription,
        [parameter()][string]$Date,
        [parameter()][string]$Owner,
        [parameter()][string]$Target,
        [parameter()][string]$Amount,
        [parameter()][string]$What,
        [parameter()][string]$Type,
        [parameter()][switch]$PassThru
    )

    process {

        #Path 
        $files = Get-ChildItem -Path $Path -File
        
        foreach ($File in $Files) {
            
            $docName = $File | ConvertTo-DocName
            $NewDocFile = New-DocName      `
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
                    "[Rename-File] | {0} -> {1}" -f $fileName, $newFileName | Write-Verbose
                }
                else {
                    "[Rename-File] | {0} -> {1}" -f $fileName, $newFileName | Write-Warning
                }
            } 
            else {
                "[Rename-File] | {0} == {1}" -f $fileName, $newFileName | Write-Verbose
            }

            # Only if rename is called with Passthru
            $ret
        }
    }
} Export-ModuleMember -Function Rename-File

function Move-File {
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

        $files = Get-File        `
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
            
            # Get Owner from file
            $owner = (ConvertTo-DocName -Path $file).Owner

            # Move file to Store

            try {

                # Get Store by owner
                $store = Get-Store -Owner $Owner
                if ($store.Count -ne 1) {
                    $status = ($store.Count -eq 0 ? "Unknown" : "Unclear")
                    $destination = [string]::Empty
                    "{0} store {1} ..." -f $file.Name, $status | Write-Verbose
                } 
                else {
                    
                    if (!$store.Exist) {
                        throw "FOLDER_NOT_FOUND"
                    }

                    $destination = $Store.Path 
        
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
            $retObject | Add-Member -NotePropertyName "Owner" -NotePropertyValue $Owner
            $retObject | Add-Member -NotePropertyName "Destination" -NotePropertyValue ($destination ?? [string]::Empty) 
            $retObject | Add-Member -NotePropertyName "Status" -NotePropertyValue $Status
            
            $retObject
        }
    }

} Export-ModuleMember -Function Move-File

function Test-File {
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
                $ret = $file.Name | Test-FileName
            }
            $ret
        }
    }
} Export-ModuleMember -Function Test-File

function Move-FileItem {
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

} Export-ModuleMember -Function Move-FileItem

function GetFileCopyName([string] $Path) {
    $file = $Path | Get-Item 
    $nameBase = $file.Name
    $targetFullname = $file.FullName
    $count = 0
    while (Test-Path -Path $targetFullname) {
        $count++
        $nameBase = $File.BaseName + "($count)" + $File.Extension
        $targetFullname = Join-Path -Path $file.Directory -ChildPath $nameBase
    }

    return $nameBase
}
#endregion File

#region Formats
function Format-MoveStatus {
    [Alias("fms")]
    param (
    )
    $input | Format-Table Name, Status
} Export-ModuleMember -Function Format-MoveStatus -Alias "fms"

function Format-Name {
    [Alias("fname")]
    param (
    )
    $input | ForEach-Object { $_.Name() }
} Export-ModuleMember -Function Format-Name -Alias "fname"

#endregion Formats