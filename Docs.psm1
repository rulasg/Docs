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
    static [string] hidden $SPLITTER = '-'
    static [string] hidden $DEFAULT_OWNER = "rulasg"
    static [string] hidden $DEFAULT_TYPE = "pdf"
    static [string] hidden $DEFAULT_DESCRIPTION = "DESCRIPTION"

    [string] $Date #Mandatory
    [string] $Owner #Mandatory
    [string] $Target
    [string] $Amount
    [string] $What
    [string] $Description #Mandatory
    [string] $Type #Mandatory

    #ctor
    DocName(){
        $this.Description = [string]::Empty
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
        if ($this.Owner)        { $o   = $this.Owner } else { $o = [DocName]::DEFAULT_OWNER }
        if ($this.Type)         { $t   = $this.Type  } else { $t = [DocName]::DEFAULT_TYPE }
        if ($this.Description)  { $des = $this.Description.Replace(' ','_') } else { $des = [DocName]::DEFAULT_DESCRIPTION }
    
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

    [bool] IsValid(){

        # Check date
        if (![DocName]::TestDate($this.Date)) {
            return $false
        }

        # Owner not empty
        if ([string]::IsNullOrWhiteSpace($this.Owner)) {
            return $false
        }

        # Description not empty
        if ([string]::IsNullOrWhiteSpace($this.Description)) {
            return $false
        }

        # Amount with # as separator
        if (![string]::IsNullOrWhiteSpace($this.Amount)) {
            if (![DocName]::TestAmmount($this.Amount)) {
                return $false
            }
        }

        return $true

    }

    [string] Sample(){

        return ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f "date", "owner", "target", "amount", "what", "desc", "type")
    }

    static [DocName] ConvertToDocName([string]$fileName){

        $doc = [DocName]::new()
        
        # Mandatory
        
        $splitted = $fileName -split [DocName]::SPLITTER,3
        if ($splitted.Count -ne 3) {
            return $null
        }
        $doc.Date = $splitted[0]
        $doc.Owner = $splitted[1]

        # Look for the extension
        $doc.Type = ($splitted[2] | Split-Path -Extension) -replace '\.',''
        
        # Second split
        $secondSplit = ($splitted[2] | Split-Path -LeafBase) -split [DocName]::SPLITTER,4

        switch ($secondSplit.Count) {
            4 { 
                $doc.Target = $secondSplit[0]
                $doc.Amount = $secondSplit[1]
                $doc.What = $secondSplit[2]
                $doc.Description = $secondSplit[3]
             }
             3{
                # Ammount before What
                $doc.Target = $secondSplit[0]

                if ([DocName]::TestAmmount($secondSplit[1])) {
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
            Default {
                $doc.Description = $secondSplit[0]
            }
        }

        return $doc
    }
    static [bool] hidden TestAmmount([string] $Amount){
        return $Amount -match '^[1-9]\d*(\#\d+)?$'
    }
    static [bool] hidden TestDate([string] $Date){
        return $Date -match "^\d+$"
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

    $StoresList.Add($Owner.ToLower(), $o)

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
        $ret = $script:StoresList[$Owner.ToLower()]
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
        [string]$Pattern,
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$Amount,
        [string]$What,
        [string]$Description,
        [string]$Type
    )

    if ($Pattern) {
        return $Pattern
    }

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

function Test-FileName{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path
        )
    process{

        $fileName = $Path | Split-Path -Leaf

        $doc = [DocName]::ConvertToDocName($fileName)
        
        return ($null -eq $doc) ?  $false : $doc.IsValid()
    }
} Export-ModuleMember -Function Test-FileName

function ConvertTo-DocName{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("PSPath")][ValidateNotNullOrEmpty()]
        [string[]] $Path
    )
    
    begin {
        
    }
    
    process {
        
    }
    
    end {
        
    }
}
function Find-File {
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
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type,
        [parameter()][switch] $Recurse
    )
    
        $retFiles = @()
        $Pattern = Get-FileNamePattern `
            -Pattern $Pattern          `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type 

        foreach ($store in $(Get-Stores -Exist)) {
            
            $retFiles += Get-ChildItem -Path $store.Path -Filter $Pattern -Recurse:$store.IsRecursive
        }

        return $retFiles
    
} Export-ModuleMember -Function Find-File

# function Test-FileName {
#     [CmdletBinding()]
#     Param(
#         [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
#         [Alias("PSPath")][ValidateNotNullOrEmpty()]
#         [string[]] $Path
#     )
#     begin{

#         $basepattern = Get-FileNamePattern
#     }
#     process{

#         # Exists and is not a director/folder
#         if (!(Test-Path -Path $Path )) { 
#             return $false }
#         if (Test-Path -Path $Path -PathType Container) {
#             return $false}

#         $file = Get-Item -Path $Path

#         return $file.Name -Like $basepattern
#     }
# } Export-ModuleMember -Function Test-FileName

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
        if (!$Path) { $Path = "." }

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

        foreach ($file in $files) 
        {
            if (Test-FileName -Path $file) {
                # Add to ret
                $retFiles += $file
            }
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
    begin{

    }

    process{

        $files = Get-FileToMove        `
            -Path $Path                `
            -Pattern $Pattern          `
            -Date $Date                `
            -Owner $Owner              `
            -Target $Target            `
            -Amount $Amount            `
            -What $What                `
            -Description $Description  `
            -Type $Type 

        foreach ($file in $files) {
            # Get Owner from file
            $owner = ([DocName]::ConvertToDocName($file.Name)).Owner

            # Get Store by owner
            $store = Get-Stores -Owner $Owner
            if ($store.Count -ne 1) {
                Continue
            }
            
            # Move file to Store

            $status = "MOVED"
            try {
                MoveFile -Path $File.FullName -Destination $Store.Path 
            }
            catch {
                $status = $_.Exception.Message
            }
            

            # Build move reference and yeld
            $o = New-Object -TypeName psobject
            $o | Add-Member -NotePropertyName "Owner" -NotePropertyValue $Owner
            $o | Add-Member -NotePropertyName "Status" -NotePropertyValue $Status
            $o | Add-Member -NotePropertyName "Name" -NotePropertyValue $File.Name
            $o | Add-Member -NotePropertyName "FullName" -NotePropertyValue $File.FullName
            $o | Add-Member -NotePropertyName "Destination" -NotePropertyValue $store.Path
            
            $o
        }

    }

    end{
    }
} Export-ModuleMember -Function Move-File

function MoveFile {
    [CmdletBinding()]
    param (
        [parameter(Mandatory, Position=0, ValueFromPipeline,ValueFromPipelineByPropertyName)] $Path,
        [parameter(Mandatory, Position=1)] $Destination,
        [parameter()] [switch] $Force
    )
    
    begin {
        if ( -not (Test-Path $destination)) { 
            New-Item -ItemType Directory -Path  $destination | Out-Null 
        }
    }
    
    process {

        Get-ChildItem -Path $Path  | ForEach-Object{

            $destinationPath = Join-Path -Path  $destination -ChildPath $_.Name

            if (Test-Path -Path $destinationPath) {
                #File Exists
                $hashSource = Get-FileHash -Path $_
                $hashDestination = Get-FileHash -Path $destinationPath

                if ($hashSource.Hash -eq $hashDestination.Hash) {
                    #Files are equal
                    if ($Force) {
                        Remove-Item -Path $_
                    }
                    else {
                        throw FILES_ARE_EQUAL
                    }
                }
                else {
                    if ($Force) {
                        $_ | Move-Item -Destination $destinationPath -Force
                    }
                    else{
                        throw FILES_ARE_NOT_EQUAL
                    }
                }
            }
            else {
                $_ | Move-Item -Destination $destinationPath
            }
        }
    }

    end {
        
    }
}

