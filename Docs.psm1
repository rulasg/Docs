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
        $this.Date        = [string]::Empty
        $this.Owner       = [string]::Empty
        $this.Target      = [string]::Empty
        $this.What        = [string]::Empty
        $this.Amount      = [string]::Empty
        $this.Description = [string]::Empty
        $this.Type        = [string]::Empty
    }

    # Interna Functions

    [string] hidden static Section([string] $sectionName) { if ($sectionName) { return "-$sectionName" } else { return [string]::Empty } }
    [string] hidden static SectionPatternMandatory([string] $p ) { if ($p) { return "-*$p*" } else { return "-*" } }
    [string] hidden static SectionPatternOptional ([string] $p ) { if ($p) { return "-*$p*" } else { return [string]::Empty } }
    [string] hidden static SectionPattern     ([string] $p ) { if ($p) { return "*$p*" } else { return "*" } }

    # API

    [string] Name() {

        #Mandatory fields
        if ($this.Date) { $d = $this.Date } else { $d = Get-Date -Format 'yyMMdd' }
        if ($this.Owner) { $o = $this.Owner } else { $o = [DocName]::DEFAULT_OWNER }
        if ($this.Type) { $t = $this.Type } else { $t = [DocName]::DEFAULT_TYPE }
        if ($this.Description) { $des = $this.Description.Replace(' ', '_') } else { $des = [DocName]::DEFAULT_DESCRIPTION }
    
        #d
        $o = [DocName]::Section($o)
        $ta = [DocName]::Section($this.Target)
        $w = [DocName]::Section($this.What)
        $am = [DocName]::Section($this.Amount)
        $des = [DocName]::Section($des)
        #t

        $name = "$d$o$ta$w$am$des.$t"

        Write-Verbose -Message $name

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
            2{
                $doc.Date = $splitted[0]
                $h2 = $splitted[1]
            }
            1{
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
                if ([docname]::TestAmmount($secondSplit[1],[DocName]::DECIMALSEPARATOR)) {
                    $doc.Amount = $secondSplit[1]
                    $doc.What = $secondSplit[2]
                    $doc.Description = $secondSplit[3]
                } else {
                    $doc.What = $secondSplit[1]
                    # check if 2 is correct amound and log or move it to description
                    if ([docname]::TestAmmount($secondSplit[2],[DocName]::DECIMALSEPARATOR)) {
                        $doc.Amount = $secondSplit[2]
                        $doc.Description = $secondSplit[3]
                    } else {
                        $doc.Description = $secondSplit[2] + [DocName]::SPLITTER + $secondSplit[3]
                    }
                }
            }
            3 {
                # Ammount before What
                $doc.Target = $secondSplit[0]

                # If amount correct log it, if not What
                if ([docname]::TestAmmount($secondSplit[1],[DocName]::DECIMALSEPARATOR)) {
                    $doc.Amount = $secondSplit[1]
                } else {
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
        $ret = $Date -match "^\d+$"

        # if (!$ret) {
        #     "Date format is not correct [ {0}]" -f $Date | Write-Verbose
        # }

        return $ret
    }
}

function Set-VerboseOn {
    $VerbosePreference = Continue
} Export-ModuleMember -Function Set-VerboseOn

# Stores

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

function Find-Store {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)][string] $Owner
    )
    # Get Store by owner
    $store = Get-Stores -Owner $Owner
    
    $status = [STATUS]::SUCCESS

    if (!$store -or $store.Count -ne 1) {
        $status = ($store.Count -eq 0 ? "OWNER_UNKNOWN" : "OWNER_STORE_UNCLEAR")
        "{0} store {1} ..." -f $file.Name, $status | Write-Verbose
        throw $Status
    } 

    if ($status -ne [STATUS]::SUCCESS) {
        throw $status
    }

    return $store
} Export-ModuleMember -Function Find-Store

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

function Get-Stores {
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

} Export-ModuleMember -Function Get-Stores -Alias "gs"

function Set-LocationStore {
    [CmdletBinding()]
    [Alias("sl")]

    param (
        [parameter(Mandatory, Position = 1, ValueFromPipeline)]
        [ArgumentCompletions(
            {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)
                Get-Owners -Owner $Owner
            })]
        [ValidateScript(
            {
                $_ -in (Get-Owners)
            }
        )]
        [string] $Owner
    )
    $location = Get-Stores -Owner $Owner

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
} Export-ModuleMember -Function Set-LocationStore -Alias "sl"

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

# Files

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

    # $dn.Date = $Date
    # $dn.Owner = $Owner
    # $dn.Amount = $Amount
    # $dn.Target = $Target
    # $dn.What = $What
    # $dn.Description = $Description
    # $dn.Type = $Type

    # if ($dn.IsValid()) {
    #     return $dn
    # } else {
    #     "DocName object not valid with given parameters" | Write-Error
    #     return $null
    # }
    
    return $dn
}

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
        return ($Pattern -contains '*') ? $Pattern : ("*{0}*" -f $Pattern)
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
} Export-ModuleMember -Function Get-FileNamePattern

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
            
        # Mandatory Default values
        $dn.Date = (![string]::IsNullOrWhiteSpace($dn.Date)) ? $dn.Date : (Get-Date -Format 'yyMMdd')
        $dn.Owner = (![string]::IsNullOrWhiteSpace($dn.Owner)) ? $dn.Owner : ([DocName]::DEFAULT_OWNER)
        $dn.Description = (![string]::IsNullOrWhiteSpace($dn.Description)) ? $dn.Description : ([DocName]::DEFAULT_DESCRIPTION)
        $dn.Type = (![string]::IsNullOrWhiteSpace($dn.Type)) ? $dn.Type : ([DocName]::DEFAULT_TYPE) 
    
        if ($dn.IsValid()) {
            return $dn.Name()
        }
        
        # "[Get-FileName] Error" | Write-Error
        # return $null
        throw "[Get-FileName] DocName not valid"
    }
    
} Export-ModuleMember -Function Get-FileName


function Test-File {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        [string[]] $Path
    )
    process {

        if (!$Path) { $Path = "." }

        $Pattern = Get-FileNamePattern

        # file name format
        $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse:$Recurse

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

function ConvertTo-DocName {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path
    )
        
    process {
        $filenName = $Path | Split-Path -Leaf
        [DocName]::Convert($filenName)
    }
    
} Export-ModuleMember -Function ConvertTo-DocName

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

    foreach ($store in $(Get-Stores -Exist)) {
        "Searching {0}..." -f ($store.Path | Join-Path -ChildPath $Pattern)  | Write-Verbose
        $files = Get-ChildItem -Path $store.Path -Filter $Pattern -Recurse:$store.IsRecursive 
        foreach ($file in $files) {
            if ($retFiles -notcontains $file.FullName) {
                $retFiles += $file.FullName
                $file
            }
        }
    }
    
} Export-ModuleMember -Function Find-File -Alias "f"

function Get-FileToMove {
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
        $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse:$Recurse

        if ($VerbosePreference) {
            $all = Get-ChildItem -Path $Path -Recurse:$Recurse
        }

        foreach ($file in $files) {
            if (Test-File -Path $file) {
                # Add to ret
                $retFiles += $file
            }
        }
    }
    
    end {
        "FilesToMove - Found [{0}] Valid [{1}]" -f $all.Length, $retFiles.Length | Write-Verbose
        return $retFiles
    }
} Export-ModuleMember -Function Get-FileToMove

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
        $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse:$Recurse

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

    begin {

    }

    process {

        #Path 
        $files = Get-File -Path $Path         
        
        foreach ($File in $Files) {
            
            $docName = $File | ConvertTo-DocsDocName
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
            $fileName = $docName.Name()
            
            if ($fileName -ne $newFileName) {
                "{0} -> {1}" -f $fileName, $newFileName | Write-Verbose

                if ($PSCmdlet.ShouldProcess($File.Name, "Renamed")) {
                    $File | Rename-Item -NewName $newFileName -PassThru:$PassThru
                }
            } 
            else {
                "{0} =={1}" -f $fileName, $newFileName | Write-Verbose
            }
        }
    }

    end {
    }
} Export-ModuleMember -Function Rename-File

function ConvertTo-File {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")] [string[]] $Path,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        # [parameter(ValueFromPipelineByPropertyName)][string]$PreDescription,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch]$PassThru
    )

    begin {
    }

    process {

        #Path 
        $files = Get-ChildItem -Path $Path

        foreach ($File in $Files) {
            
            $docName = New-DocName
            $docName.Description = $file.BaseName
            $docName.Type = $file.Extension?.Substring(1)

            $NewDocFile = New-DocName            `
                -DocName $docName                `
                -Date $Date                      `
                -Owner $Owner                    `
                -Target $Target                  `
                -Amount $Amount                  `
                -What $What                      `
                -PreDescription $Description  `
                -Type $Type 
                # -Description $Description        `

            # $NewDocFile.Description = $Description ? ("{0}_{1}" -f $Description, $file.BaseName) : $file.BaseName
            
            # $NewDocFile.Type = $file.Extension.Substring(1)
            
            $newFileName = $NewDocFile.Name()
            $fileName = $File.Name
            
            if ($fileName -ne $newFileName) {
                
                if ($PSCmdlet.ShouldProcess($File.Name, "Renamed")) {
                    $ret = $File | Rename-Item -NewName $newFileName -PassThru:$PassThru
                }
                elseif ($WhatIfPreference) {
                    "{0} -> {1}" -f $fileName, $newFileName | Write-Warning
                }
                else {
                    "{0} -> {1}" -f $fileName, $newFileName | Write-Verbose
                }
            } 
            else {
                "{0} =={1}" -f $fileName, $newFileName | Write-Verbose
            }

            # ONly with value if Passthru
            $ret
        }
    }

    end {
    }
} Export-ModuleMember -Function ConvertTo-File

function Move-File {
    [CmdletBinding(SupportsShouldProcess)]
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
        [parameter()][switch] $Recurse,
        [parameter()][switch] $Force
    )
    begin {

    }

    process {

        $files = Get-FileToMove        `
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
                $store = Get-Stores -Owner $Owner
                if ($store.Count -ne 1) {
                    $status = ($store.Count -eq 0 ? "Unknown" : "Unclear")
                    $destination = [string]::Empty
                    "{0} store {1} ..." -f $file.Name, $status | Write-Verbose
                } 
                else {
                    
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
            $retObject | Add-Member -NotePropertyName "Destination" -NotePropertyValue $destination
            $retObject | Add-Member -NotePropertyName "Status" -NotePropertyValue $Status
            
            $retObject
        }
    }

    end {
    }
} Export-ModuleMember -Function Move-File

function Move-FileItem {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)] $Path,
        [parameter(Mandatory, Position = 1)] $Destination,
        [parameter()] [switch] $Force
    )
    
    begin {

    }
    
    process {
        # Destination

        if ( -not (Test-Path $destination -PathType Container )) {
            if ($Force) 
            {
                New-Item -ItemType Directory -Path  $destination | Out-Null 
            } 
            else 
            {
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

    end {
        
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