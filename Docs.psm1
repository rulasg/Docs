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

$script:StoresList = @()

# Varaibles
$splitter = '-'

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
    [string] hidden $DEFAULT_OWNER = "rulasg"
    [string] hidden $DEFAULT_TYPE = "pdf"
    [string] hidden $DEFAULT_DESCRIPTION = "DESCRIPTION"

    [string] $Date #Mandatory
    [string] $Owner #Mandatory
    [string] $Target
    [string] $Amount
    [string] $What
    [string] $Description #Mandatory
    [string] $Type #Mandatory

    #ctor
    DocName(){
    }

    # Interna Functions

    [string] hidden static Section([string] $sectionName) { if ($sectionName) {return "-$sectionName"} else {return [string]::Empty}}
    [string] hidden static SectionPatternMandatory([string] $p ) { if($p){ return "-*$p*" } else { return "-*" } }
    [string] hidden static SectionPatternOptional ([string] $p ) { if($p){ return "-*$p*" } else { return [string]::Empty } }
    [string] hidden static SectionPattern     ([string] $p ) { if($p){ return "*$p*" } else { return "*" } }

    # API

    [string] Name(){

        #Mandatory fields
        if ($this.Date)         { $d   = $this.Date  } else { $d = Get-Date -Format 'yyMMdd' }
        if ($this.Owner)        { $o   = $this.Owner } else { $o = $this.DEFAULT_OWNER }
        if ($this.Type)         { $t   = $this.Type  } else { $t = $this.DEFAULT_TYPE }
        if ($this.Description)  { $des = $this.Description.Replace(' ','_') } else { $des = $this.DEFAULT_DESCRIPTION }
    
        #d
        $o   = [DocName]::Section($o)
        $ta  = [DocName]::Section($this.Target)
        $am  = [DocName]::Section($this.Amount)
        $w   = [DocName]::Section($this.What)
        $des = [DocName]::Section($des)
        #t

        $name = "$d$o$ta$am$w$des.$t"

        Write-Verbose -Message $name

        return $name
    }

    [string] Pattern(){

        $d   = [DocName]::SectionPattern($this.Date)
        $o   = [DocName]::SectionPatternMandatory($this.Owner)
        $ta  = [DocName]::SectionPatternOptional($this.Target)
        $am  = [DocName]::SectionPatternOptional($this.Amount)
        $w   = [DocName]::SectionPatternOptional($this.What)
        $des = [DocName]::SectionPatternMandatory($this.Description.Replace(' ','_'))
        $t   = [DocName]::SectionPattern($this.Type)

        $pattern = "$d$o$ta$am$w$des.$t"

        Write-Verbose -Message $pattern

        return $pattern
    }

    [string] Sample(){

        return ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f "date", "owner", "target", "amount", "what", "desc", "type")
    }
}

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
        Initialize-StoresList
    }

    if (!($Path | Test-Path) -and $Force) {
        $null = New-item -ItemType Directory -Force -Path $Path 
    }

    $o = New-Store -Owner $Owner -Path $Path -IsRecursive:$IsRecursive

    $StoresList.Add($Owner, $o)

} Export-ModuleMember -Function Add-Store

function New-Store{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string] $Owner,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string] $Path,   
        [Parameter(ValueFromPipelineByPropertyName)][switch] $IsRecursive
    )
    $o = New-Object -TypeName DocsStore
    $o.Owner = $Owner
    if ($Path | Test-Path) {
        $o.Path = $Path | Convert-Path 
    } else {
        if ([System.IO.Path]::IsPathRooted($Path)) {
            $o.Path = $Path
        } else {
            Write-Error ("Path has to be rooted if it does not exit [{0}]" -F $Path)
            return
        }
    }
    $o.Path = [System.IO.Path]::IsPathRooted($Path) ? $Path : (Resolve-Path -Path $Path).Path
    $o.IsRecursive = $IsRecursive

    $o.Exist = Test-Path -Path $o.Path

    return $o
}

function Initialize-StoresList {
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
} Export-ModuleMember -Function Initialize-StoresList

function New-StoresList {
    [CmdletBinding()]
    param()

    return New-Object 'System.Collections.Generic.Dictionary[[string],[PSObject]]'
} Export-ModuleMember -Function New-StoresList

function Get-Stores {
    [CmdletBinding()]
    param (
        [parameter()][string] $Owner,
        [parameter()][switch] $Exist
    )
    
    if ($Owner) {
        $ret = $script:StoresList[$Owner]
    } else {
        $ret = $script:StoresList.Values 
    }

    if (!$ret) {
        return
    }

    $ret | ForEach-Object {
        $r =  $_ | New-Store

        if ($Exist) {
            if ($r.Exist) {
                $r
            }
        } else {
            $r
        }

    }

} Export-ModuleMember -Function Get-Stores

function Get-Owners {
    [CmdletBinding()]
    param (
        
    )
    
    Get-Stores | ForEach-Object{

        $v = $_
        $o = New-Object -TypeName psobject

        $o | Add-Member -MemberType NoteProperty -Name Owner -Value $v.Owner
        $o | Add-Member -MemberType NoteProperty -Name Path -Value $v.Path
        $o | Add-Member -MemberType NoteProperty -Name IsRecursive -Value $v.IsRecursive

        $o | Add-Member -MemberType NoteProperty -Name Exist -Value (Test-Path -Path $v.Path)

        $o
    }
} Export-ModuleMember -Function Get-Owners

# Files

function NewDocName {
    [CmdletBinding()]
    Param(
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$Amount,
        [string]$What,
        [string]$Description,
        [string]$Type
    )

    $dn =  New-Object -TypeName DocName

    $dn.Date = $Date
    $dn.Owner = $Owner
    $dn.Target = $Target
    $dn.Amount = $Amount
    $dn.What = $What
    $dn.Description = $Description
    $dn.Type = $Type

    return $dn
}
function Get-FileNamePattern{
    [CmdletBinding()]
    Param(
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$Amount,
        [string]$What,
        [string]$Description,
        [string]$Type
    )

    $dn = NewDocName               `
        -Date $Date                `
        -Owner $Owner              `
        -Target $Target            `
        -Amount $Amount            `
        -What $What                `
        -Description $Description  `
        -Type $Type                

    return $dn.Pattern()
} Export-ModuleMember -Function Get-FileNamePattern

function Get-FileName{
    [CmdletBinding()]
    Param(
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$Amount,
        [string]$What,
        [Parameter(Mandatory)][string]$Description,
        [string]$Type
    )

    $dn = NewDocName               `
        -Date $Date                `
        -Owner $Owner              `
        -Target $Target            `
        -Amount $Amount            `
        -What $What                `
        -Description $Description  `
        -Type $Type                

    return $dn
    
} Export-ModuleMember -Function Get-FileName

function Find-File {
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][string]$Pattern
    )
    
    begin {
        
        $retFiles = @()
    }
    
    process {
        if (!$Pattern) {
            $Pattern = Get-FileNamePattern               `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type 
        }

        Get-Stores -Exist | ForEach-Object{
            $retFiles += Get-ChildItem -Path $_.Path -Filter $Pattern -Recurse:$_.IsRecursive
        }
    }
    
    end {
        return $retFiles
    }
} Export-ModuleMember -Function Find-File

function Test-FileName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path
    )
    begin{

        $basepattern = Get-FileNamePattern
    }
    process{

        # Exists and is not a director/folder
        if (!(Test-Path -Path $Path )) { 
            return $false }
        if (Test-Path -Path $Path -PathType Container) {
            return $false}

        $file = Get-Item -Path $Path

        return $file.Name -Like $basepattern
    }
} Export-ModuleMember -Function Test-FileName

function Get-FileToMove {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path,
        [parameter()][string]$Pattern,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $Recursive
    )
    begin {
        if (!$Pattern) {
            $Pattern = Get-FileNamePattern               `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type 
        }

        $retFiles = @()
    }
    
    process {
        if (!$Path) { $Path = "." }

        # file name format
        $files = Get-ChildItem -Path $Path -Filter $Pattern -Recurse:$Recursive

        foreach ($file in $files) 
        {
            $nameSplit = $file.Name.Split($splitter)
            
            # Check date
            $date = $nameSplit[0]
            if (!($date -match "^\d+$")) {
                Continue
            }
            
            # # Check owners
            # $owner = $nameSplit[1]
            # $store = Get-Stores -Owner $Owner -Exist
            # if (!$store) {
            #     Continue
            # }

            # Add to ret
            $retFiles += $file
        }

    }
    
    end {
        return $retFiles
    }
} Export-ModuleMember -Function Get-FileToMove

function Move-File{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path,
        [parameter()][string]$Pattern,
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $Recursive
        )
}

