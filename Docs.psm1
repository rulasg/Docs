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
        $des = [DocName]::SectionPatternMandatory($this.Description)
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
        [Parameter()][switch] $IsRecursive
    )
    
    if (! $script:StoresList) {
        Initialize-StoresList
    }

    $o = New-Object -TypeName DocsStore
    $o.Owner = $Owner
    $o.Path = [System.IO.Path]::IsPathRooted($Path) ? $Path : (Resolve-Path -Path $Path).Path
    $o.IsRecursive = $IsRecursive

    $o.Exist = Test-Path -Path $o.Path

    $StoresList.Add($Owner, $o)
} Export-ModuleMember -Function Add-Store

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
    )
    
    $script:StoresList.Values 

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

Function New-FileName(){return New-Object -TypeName DocName}

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

    $dn = New-FileName

    $dn.Date = $Date
    $dn.Owner = $Owner
    $dn.Target = $Target
    $dn.Amount = $Amount
    $dn.What = $What
    $dn.Description = $Description
    $dn.Type = $Type

    return $dn.Pattern()
} Export-ModuleMember -Function Get-FileNamePattern

function Get-FileName{
    [CmdletBinding()]
    Param(
        [string]$Date,
        [string]$Owner,
        [Parameter(Mandatory = $true)] [string]$Target,
        [string]$Amount,
        [string]$What,
        [Parameter(Mandatory = $true)][string]$Description,
        [string]$Type
    )

    $dn = New-DocName

    $dn.Date = $Date
    $dn.Owner = $Owner
    $dn.Target = $Target
    $dn.Amount = $Amount
    $dn.What = $What
    $dn.Description = $Description
    $dn.Type = $Type

    return $dn
    
} Export-ModuleMember -Function Get-FileName

function Find-File {
    [CmdletBinding()]
    Param(
        [string]$Pattern,
        [string]$Description,
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$What,
        [string]$Type
    )
    
    begin {
        
    }
    
    process {
        
    }
    
    end {
        
    }
}