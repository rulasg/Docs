<# 
.Synopsis 
DocsTest

.Description
Testing module for Docs

.Notes 
NAME  : DocsTest.psm1*
AUTHOR: rulasg   

CREATED: 05/26/2021
#>

Write-Host "Loading DocsTest ..." -ForegroundColor DarkCyan

[string] $SPLITTER = "-"

function ResetDocsList([switch]$PassThru) {

    $TestStoreList = New-DocsStoresList
    Reset-DocsStoresList -StoreList $TestStoreList 

    if ($PassThru) {
        return $TestStoreList
    } 
}

function Get-SampleFunction1{
    [CmdletBinding()]

    param(
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$PreDescription,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type
    )


        $result = @{
            Description = $Description
            PreDescription = $PreDescription
            Date = $Date
            Owner = $Owner
            Target = $Target
            Amount = $Amount
            What = $What
            Type = $Type
        }

        return $result
}

function Get-SampleFunction2{
    [CmdletBinding()]

    param(
        [parameter(ValueFromPipelineByPropertyName)][string]$Description,
        [parameter(ValueFromPipelineByPropertyName)][string]$PreDescription,
        [parameter(ValueFromPipelineByPropertyName)][string]$Date,
        [parameter(ValueFromPipelineByPropertyName)][string]$Owner,
        [parameter(ValueFromPipelineByPropertyName)][string]$Target,
        [parameter(ValueFromPipelineByPropertyName)][string]$Amount,
        [parameter(ValueFromPipelineByPropertyName)][string]$What,
        [parameter(ValueFromPipelineByPropertyName)][string]$Type
    )


    begin {
    }
    
    process{
        $result = @{
            Description = $Description
            PreDescription = $PreDescription
            Date = $Date
            Owner = $Owner
            Target = $Target
            Amount = $Amount
            What = $What
            Type = $Type
        }

        return $result
    }

}

function DocsTest_NamedParameter{

    $files = @()
    $files +=  New-TestingFile -Name "test1.txt" -Content "test" -PassThru
    $files += New-TestingFile -Name "test2.txt" -Content "test" -PassThru

    $docName = Get-ChildItem $files | Get-DocsName -Owner "MyOwner" -Target "MyTarget"  -What MyWhat -Type MyType -Amount MyAmount 

    $result1 = $docName | Get-SampleFunction1
    
    Assert-AreEqual -Expected "MyOwner" -Presented $result1.Owner
    
    $result2 = $docName | Get-SampleFunction2
    
    Assert-AreEqual -Expected @("MyOwner","MyOwner").ToString() -Presented $result2.Owner.ToString()
    
    $result3 = $docName | Get-DocsName
    
    Assert-AreEqual -Expected @("MyOwner","MyOwner").ToString() -Presented $result3.Owner.ToString()
}

function DocsTest_ResetStores {

    $TestStoreList = ResetDocsList -PassThru

    Assert-Count -Expected 0 -Presented $TestStoreList
    
    Add-DocsStore -Owner "SampleOwner" -Path "." -IsRecursive 
    
    Assert-Count -Expected 1 -Presented $TestStoreList
    
    $result = ResetDocsList -PassThru

    Assert-Count -Expected 0 -Presented $result
}

function DocsTest_AddStores {
    
    $TestStoreList = ResetDocsList -PassThru
    $fakeFolderPath = Join-Path -Path $Home -ChildPath"fackefolder"
    Add-DocsStore -Owner "SampleOwner" -Path "." -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path $fakeFolderPath

    Assert-Count -Expected 2 -Presented $TestStoreList

    $o1 = $TestStoreList["SampleOwner_any".ToLower()]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $TestStoreList["SampleOwner2_any".ToLower()]
    Assert-IsFalse -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected $fakeFolderPath -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist
}

function DocsTest_AddStoreWithTarget{

    $TestStoreList = ResetDocsList -PassThru
    $fakeFolderPath = Join-Path -Path $Home -ChildPath"fackefolder"

    Add-DocsStore -Owner "SampleOwner" -Path "."  -Target "t1"
    Add-DocsStore -Owner "SampleOwner" -Path $fakeFolderPath -IsRecursive -Target "t2"
    Add-DocsStore -Owner "SampleOwner" -Path "." -IsRecursive 
    Add-DocsStore -Owner "SampleOwner1" -Path "." -IsRecursive 

    Assert-Count -Expected 4 -Presented $TestStoreList
    
    $o1 = $TestStoreList["SampleOwner_any".ToLower()]
    Assert-AreEqual -Expected "SampleOwner" -Presented $o1.Owner
    Assert-AreEqual -Expected "any" -Presented $o1.Target
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o1 = $TestStoreList["SampleOwner_t1".ToLower()]
    Assert-AreEqual -Expected "SampleOwner" -Presented $o1.Owner
    Assert-AreEqual -Expected "t1" -Presented $o1.Target
    Assert-IsFalse -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o1 = $TestStoreList["SampleOwner_t2".ToLower()]
    Assert-AreEqual -Expected "SampleOwner" -Presented $o1.Owner
    Assert-AreEqual -Expected "t2" -Presented $o1.Target
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected $fakeFolderPath -Presented $o1.Path
    Assert-IsFalse -Condition $o1.Exist
    
}

function DocsTest_AddStores_Force {
    
    $TestStoreList = ResetDocsList -PassThru

    $local  = "." | Resolve-Path
    $storeFolder = $local | Join-Path -ChildPath "fakefolder"

    Assert-IsFalse -Condition ($storeFolder | Test-Path)

    Add-DocsStore -Owner "SampleOwner" -Path $storeFolder -IsRecursive -Force

    Assert-Count -Expected 1 -Presented $TestStoreList
    $o1 = $TestStoreList["SampleOwner_any".ToLower()]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected $storeFolder -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

}
function DocsTest_GetStores {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive
    Add-DocsStore -Owner "SampleOwner3" -Path $Home

    $result = Get-DocsStore

    Assert-Count -Expected 4 -Presented $result

    $o0 = $result[0]
    Assert-AreEqual -Expected "SampleOwner0" -Presented $o0.Owner
    Assert-IsFalse -Condition $o0.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder0 -Presented $o0.Path
    Assert-IsFalse -Condition $o0.Exist

    $o1 = $result[1]
    Assert-AreEqual -Expected "SampleOwner1" -Presented $o1.Owner
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $result[2]
    Assert-AreEqual -Expected "SampleOwner2" -Presented $o2.Owner
    Assert-IsTrue -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder2 -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist

    $o3 = $result[3]
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o3.Owner
    Assert-IsFalse -Condition $o3.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o3.Path
    Assert-IsTrue -Condition $o3.Exist

}

function DocsTest_GetStoresWithExist {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive
    Add-DocsStore -Owner "SampleOwner3" -Path $Home

    # Exist

    $result3 = Get-DocsStore -Exist

    Assert-Count -Expected 2 -Presented $result3

    $o = $result3[0]
    Assert-AreEqual -Expected "SampleOwner1" -Presented $o.Owner
    Assert-IsTrue -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o.Path
    Assert-IsTrue -Condition $o.Exist

    $o = $result3[1]
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o.Path
    Assert-IsTrue -Condition $o.Exist

}
function DocsTest_GetStoresWithOwner {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive
    Add-DocsStore -Owner "SampleOwner3" -Path $Home

    # Owner

    $result2 = Get-DocsStore -Owner "SampleOwner2"
    
    Assert-Count -Expected 1 -Presented $result2

    $o = $result2

    Assert-AreEqual -Expected "SampleOwner2" -Presented $o.Owner
    Assert-IsTrue -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder2 -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

}

function DocsTest_GetStoresWithTarget {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0 -Target "Target0"
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive -Target "Target1"
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive -Target "Target2"
    Add-DocsStore -Owner "SampleOwner3" -Path $Home -Target "Target0"

    # Target

    $result2 = Get-DocsStore -Target "Target2"
    
    Assert-Count -Expected 1 -Presented $result2

    $o = $result2

    Assert-AreEqual -Expected "SampleOwner2" -Presented $o.Owner
    Assert-AreEqual -Expected "Target2" -Presented $o.Target
    Assert-IsTrue -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder2 -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

    $result3 = Get-DocsStore -Target "Target0"

    Assert-Count -Expected 2 -Presented $result3

    $o = $result3[0]
    Assert-AreEqual -Expected "SampleOwner0" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder0 -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

    $o = $result3[1]
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o.Path
    Assert-IsTrue -Condition $o.Exist

}

function DocsTest_GetStoresWithOwnerAndTarget {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0 -Target "Target0"
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive -Target "Target1"
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive -Target "Target2"
    Add-DocsStore -Owner "SampleOwner3" -Path $Home -Target "Target0"
    Add-DocsStore -Owner "SampleOwner3" -Path $Home

    # Target

    $result2 = Get-DocsStore -Owner "SampleOwner1" -Target "Target0"
    
    Assert-IsNull -Object $result2
    
    $result2 = Get-DocsStore -Owner "SampleOwner0" -Target "Target0"

    Assert-Count -Expected 1 -Presented $result2

    $o = $result2

    Assert-AreEqual -Expected "SampleOwner0" -Presented $o.Owner
    Assert-AreEqual -Expected "Target0" -Presented $o.Target
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder0 -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

    $result3 = Get-DocsStore -Target "Target0"

    Assert-Count -Expected 2 -Presented $result3

    $o = $result3[0]
    Assert-AreEqual -Expected "SampleOwner0" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $fakefolder0 -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

    $o = $result3[1]
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o.Path
    Assert-IsTrue -Condition $o.Exist

}

function DocsTest_GetStoresWithTargetAndExist {
    
    $fakefolder0 = Join-Path -Path $Home -ChildPath "fackefolder0"
    $fakefolder2 = Join-Path -Path $Home -ChildPath "fackefolder2"

    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path $fakefolder0 -Target "Target0"
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive -Target "Target1"
    Add-DocsStore -Owner "SampleOwner2" -Path $fakefolder2 -IsRecursive -Target "Target2"
    Add-DocsStore -Owner "SampleOwner3" -Path $Home -Target "Target0"

    # Target

    $result3 = Get-DocsStore -Target "Target0" -Exist
    
    Assert-Count -Expected 1 -Presented $result3

    $o = $result3
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o.Owner
    Assert-IsFalse -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o.Path
    Assert-IsTrue -Condition $o.Exist

}

function DocsTest_SetLocation{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $converted1 = $storefolder1 | Convert-Path
    $converted2 = $storefolder2 | Convert-Path

    Set-DocsLocationToStore -Owner test1

    Assert-AreEqualPath -Expected $converted1  -Presented '.'
    
    "test2" | Set-DocsLocationToStore 

    Assert-AreEqualPath -Expected $converted2 -Presented '.'

    Set-DocsLocationToStore test1

    Assert-AreEqualPath -Expected $converted1  -Presented '.'
}

function DocsTest_GetOwners {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path (Join-Path -Path $Home -ChildPath "fackefolder")

    $result = Get-DocsOwners

    Assert-Count -Expected 2 -Presented $result

    Assert-AreEqual -Expected "SampleOwner" -Presented $result[0]
    Assert-AreEqual -Expected "SampleOwner2" -Presented $result[1]

    # $o1 = $result[0]
    # Assert-IsTrue -Condition $o1.IsRecursive
    # Assert-AreEqualPath -Expected "." -Presented $o1.Path
    # Assert-IsTrue -Condition $o1.Exist

    # $o2 = $result[1]
    # Assert-IsFalse -Condition $o2.IsRecursive
    # Assert-AreEqualPath -Expected "$Home/fackefolder" -Presented $o2.Path
    # Assert-IsFalse -Condition $o2.Exist
}

function DocsTest_GetOwnersWithTargets {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive 
    Add-DocsStore -Owner "SampleOwner2" -Path (Join-Path -Path $Home -ChildPath "fackefolder")
    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive -Target "t1"

    $result = Get-DocsOwners

    Assert-Count -Expected 2 -Presented $result

    Assert-AreEqual -Expected "SampleOwner" -Presented $result[0]
    Assert-AreEqual -Expected "SampleOwner2" -Presented $result[1]

}
function DocsTest_GetOwners_Filtered {
    
    ResetDocsList

    Add-DocsStore -Owner "kk2k2" -Path (Join-Path -Path $Home -ChildPath "fackefolder") -IsRecursive
    Add-DocsStore -Owner "kk3k2" -Path (Join-Path -Path $Home -ChildPath "fackefolder")
    Add-DocsStore -Owner "kt2k2" -Path . -IsRecursive
    Add-DocsStore -Owner "kk2k2" -Path . -IsRecursive -Target "t2"

    $result = Get-DocsOwners

    Assert-Count -Expected 3 -Presented $result

    $result = Get-DocsOwners kk*

    Assert-Count -Expected 2 -Presented $result

    Assert-AreEqual -Expected "kk2k2" -Presented $result[0]
    Assert-AreEqual -Expected "kk3k2" -Presented $result[1]

    $result = Get-DocsOwners *3*

    Assert-Count -Expected 1 -Presented $result

    Assert-AreEqual -Expected "kk3k2" -Presented $result

    $result = Get-DocsOwners *k2

    Assert-Count -Expected 3 -Presented $result

    Assert-AreEqual -Expected "kk2k2" -Presented $result[0]
    Assert-AreEqual -Expected "kk3k2" -Presented $result[1]
    Assert-AreEqual -Expected "kt2k2" -Presented $result[2]

}

function DocsTest_FileName {
    $date = "121212"
    $owner = "sampleOwner"
    $target = "SampleTarget"
    $what = "sampleWhat"
    $amount = "99#99"
    $desc = "SampleDescription"
    $type = "SampleType"
    

    # Mandatory fields
    $defaultOwner = "rulasg"
    $defaultExt = "pdf"
    $fn = Get-DocsFileName -Target $target -Description $desc -Verbose
    Assert-AreEqual -Presented $fn  -Expected ("{0}-{1}-{2}-{3}.{4}" -f (Get-TodayDateReverse) , $defaultOwner, $target, $desc, $defaultExt)

    # Full seeded name
    $fn = Get-DocsFileName  `
        -Date $date         `
        -Owner $owner       `
        -Target $target     `
        -Amount $amount     `
        -What $what         `
        -Description $desc  `
        -Type $type         `
        
    Assert-AreEqual -Presented $fn  -Expected ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f $date, $owner, $target, $what, $amount, $desc, $type)

}

function DocsTest_Find_Simple{
    $storefolder = "." | Join-Path -ChildPath "Fakefolder" -AdditionalChildPath "FakeStoreFolder"
    
    $filename  = Get-DocsFileName -Owner Test -Target Testing -Description "Test File"
    $filename2 = Get-DocsFileName -Owner kk   -Target kking   -Description "Test File"
    
    $FileFullName  = $storefolder | Join-Path -ChildPath $filename 
    $FileFullName2 = $storefolder | Join-Path -ChildPath $filename2 
    
    ResetDocsList
    Add-DocsStore -Owner test -Path $storefolder -Force
    
    "This content is fake" | Out-File -FilePath $FileFullName
    "This content is fake" | Out-File -FilePath $FileFullName2

    Assert-Count -Expected 1 -Presented ($FileFullName | Get-ChildItem )

    $result = Find-DocsFile -Owner Test

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName -Presented $result

    $result = Find-DocsFile kking

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result

    $result = Find-DocsFile -Owner Test -JustName
    
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $filename -Presented $result

}

function DocsTest_Find_MultiFolder {

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13 
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2 
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23 

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $FileFullName2
    "This content is fake" | Out-File -FilePath $FileFullName23

    # Pattern 0

    $result = Find-DocsFile 02

    Assert-Count -Expected 2 -Presented $result
    
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result
    Assert-ContainsPath -Expected $FileFullName2 -Presented $result

    # Owner 1

    Assert-Count -Expected 4 -Presented (Get-ChildItem -File -Recurse)

    $result = Find-DocsFile -Owner Test1 

    Assert-Count -Expected 2 -Presented $result

    $result = Find-DocsFile -Owner Test2

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName23 -Presented $result

    # Target

    $result = Find-DocsFile -Target Testing3

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result
    Assert-ContainsPath -Expected $FileFullName23 -Presented $result

    # Descriptionm

    $result = Find-DocsFile -Description Test0

    Assert-IsNull -Object $result

    $result = Find-DocsFile -Description Test0*

    Assert-Count -Expected 3 -Presented $result

    $result = Find-DocsFile -Description *File2

    Assert-Count -Expected 1 -Presented $result

    $result = Find-DocsFile -Description *File2*

    Assert-Count -Expected 2 -Presented $result

    $result = Find-DocsFile -Description Test0_File2

    Assert-Count -Expected 1 -Presented $result

    $result = Find-DocsFile -Type Test1

    Assert-Count -Expected 3 -Presented $result

    $result = Find-DocsFile -Target Testing* -Description Test0*

    Assert-Count -Expected 3 -Presented $result

    $result = Find-DocsFile -Target Testing2 -Description *0*

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result

    # Date 

    $result = Find-DocsFile -Date 11

    Assert-IsNull -Object $result

    $result = Find-DocsFile -Date 11*

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result
    Assert-ContainsPath -Expected $FileFullName23 -Presented $result

    # Date 

    $result = Find-DocsFile -Date 1102*

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result

    # Object

    $result = $filename2 | Find-DocsFile
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result

}

function DocsTest_Find_MultiFolder_IsRecurse {

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    $storefolder11 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1","FakeStoreFolder11" # Recursive

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force -IsRecursive
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    New-Item -ItemType Directory -Path $storefolder11 # Recursive

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323
    $filename113 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File113 recurse" -Type test1  -Date 110214 # Recursive

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $fileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $fileName13 
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $fileName2 
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $fileName23 
    $FileFullName113 = Join-Path -Path $storefolder11 -ChildPath $filename113 # Recursive

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $FileFullName2
    "This content is fake" | Out-File -FilePath $FileFullName23
    
    "This content is fake" | Out-File -FilePath $FileFullName113 # Recursive

    # Pattern 0

    $result = Find-DocsFile 02 

    Assert-Count -Expected 3 -Presented $result

    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Owner 1

    Assert-Count -Expected 5 -Presented (Get-ChildItem -File -Recurse)

    $result = Find-DocsFile -Owner Test1 

    Assert-Count -Expected 3 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Target

    $result = Find-DocsFile -Target Testing3

    Assert-Count -Expected 3 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Descriptionm

    $result = Find-DocsFile -Description "*113*"

    Assert-Count -Expected 1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Date 

    $result = Find-DocsFile -Date *14

    Assert-Count -Expected 1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Date 

    $result = Find-DocsFile -Date 1102*

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

    # Object

    $result = $filename113 | Find-DocsFile
    Assert-Count -Expected 1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName113 -Presented $result

}

function DocsTest_TestFile{

    # Not exist
    $result = Test-DocsFile -Path "fakefile.txt"
    Assert-IsFalse -Condition $result

    # Is a directory
    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $null = New-Item -ItemType Directory -Name $filename1 
    
    $result = Test-DocsFile -Path $filename1 
    Assert-IsFalse -Condition $result
    
    # File
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test2 -Date 100102
    "This content is fake" | Out-File -FilePath $FileName2 

    $result = Test-DocsFile -Path $filename2 

    Assert-IsTrue -Condition $result
}

function DocsTest_TestFileName_FileFormats {
    
    Assert-IsTrue -Condition  ("12-owner-descr.txt"                                            | Test-DocsFileName) -Comment "121212-owner-descr"                                           
    Assert-IsTrue -Condition  ("1212-owner-descr"                                            | Test-DocsFileName) -Comment "121212-owner-descr"                                           
    Assert-IsTrue -Condition  ("121212-owner-descr"                                            | Test-DocsFileName) -Comment "121212-owner-descr"                                           
    Assert-IsTrue -Condition  ("121212-owner-Desc.txt"                                         | Test-DocsFileName) -Comment "121212-owner-Desc.txt"                                        
    Assert-IsTrue -Condition  ("121212-owner-target-Desc.txt"                                  | Test-DocsFileName) -Comment "121212-owner-target-Desc.txt"                                 
    Assert-IsTrue -Condition  ("121212-owner-target-What-Desc.txt"                             | Test-DocsFileName) -Comment "121212-owner-target-What-Desc.txt"                            
    Assert-IsTrue -Condition  ("121212-owner-target-What-32#32-Desc.txt"                       | Test-DocsFileName) -Comment "121212-owner-target-What-32#32-Desc.txt"                      
    Assert-IsTrue -Condition  ("121212-owner-target-What-32#32-Desc-dasd-asdasd-asddas.txt"    | Test-DocsFileName) -Comment "121212-owner-target-What-32#32-Desc-dasd-asdasd-asddas.txt"   
    Assert-IsTrue -Condition  ("121212-owner-target-What-Desc-dasd-asdasd-asddas.txt"           | Test-DocsFileName) -Comment "121212-owner-target-Ammount-What-Desc-dasd-asdasd-asddas.txt" 
    Assert-IsTrue -Condition  ("121212-owner-target-32#32-Desc.txt"                            | Test-DocsFileName) -Comment "121212-owner-target-32#32-Desc.txt"                           
    Assert-IsTrue -Condition  ("121212-owner-target-32#32-What-Desc.txt"                       | Test-DocsFileName) -Comment "121212-owner-target-32#32-What-Desc.txt"                      
    
    Assert-IsFalse -Condition ("121212"                                                     | Test-DocsFileName) -Comment "something"                                                    
    Assert-IsFalse -Condition (".txt"                                                     | Test-DocsFileName) -Comment "something"                                                    
    Assert-IsFalse -Condition ("something"                                                     | Test-DocsFileName) -Comment "something"                                                    
    Assert-IsFalse -Condition ("121212-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
    Assert-IsFalse -Condition ("121212-NoOwner"                                                | Test-DocsFileName) -Comment "121212-NoOwner"                                               
    Assert-IsFalse -Condition ("Owner-Descdescr.txt"                                           | Test-DocsFileName) -Comment "Owner-Descdescr.txt"                                          
    Assert-IsFalse -Condition ("12121a-owner-descr.txt"                                        | Test-DocsFileName) -Comment "12121a-owner-descr.txt"                                       
    Assert-IsFalse -Condition ("121212-owner-target-32.32-Desc.txt"                            | Test-DocsFileName) -Comment "121212-owner-target-32#32-Desc.txt"                           
    Assert-IsFalse -Condition ("1-owner-descr.txt"                                            | Test-DocsFileName) -Comment "121212-owner-descr"                                           
    Assert-IsFalse -Condition ("1212122-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
    Assert-IsFalse -Condition ("1213-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
    Assert-IsFalse -Condition ("121232-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
    Assert-IsFalse -Condition ("00-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
    Assert-IsFalse -Condition ("001212-NoOwner.txt"                                            | Test-DocsFileName) -Comment "121212-NoOwner.txt"                                           
}

function DocsTest_GetFile_All{

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    "This content is fake" | Out-File -FilePath $FileName1 
    "This content is fake" | Out-File -FilePath $FileName13 
    "This content is fake" | Out-File -FilePath $FileName2 
    "This content is fake" | Out-File -FilePath $FileName23 
    
    "This content is fake" | Out-File -FilePath "Test1-Target-Description.txt"
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Target-Description.txt"
    "This content is fake" | Out-File -FilePath "122012-NearlyCorrect.txt"
    "This content is fake" | Out-File -FilePath "122012-Test1.txt"
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Description.txt"

    $result = Get-DocsFile

    Assert-Count -Expected 6 -Presented $result
    $resultName = $result.Name
    Assert-Contains -Expected $FileName1  -Presented $resultName
    Assert-Contains -Expected $FileName2  -Presented $resultName
    Assert-Contains -Expected $FileName13  -Presented $resultName
    Assert-Contains -Expected $FileName23  -Presented $resultName
    Assert-Contains -Expected "122012-OtherOwner-Description.txt" -Presented $resultName
    Assert-Contains -Expected "122012-OtherOwner-Target-Description.txt" -Presented $resultName
    
    $result = Get-DocsFile -Target Testing3
    
    Assert-Count -Expected 2 -Presented $result
    $resultName = $result.Name
    Assert-Contains -Expected $FileName13  -Presented $resultName
    Assert-Contains -Expected $FileName23  -Presented $resultName
}

function DocsTest_GetFile_Recursive{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13 
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2 
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23 
    $fake1 = Join-Path -Path $storefolder1 -ChildPath "Test1-andnomore.txt"
    $fake2 = Join-Path -Path $storefolder2 -ChildPath "121212-fakename.txt"

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $FileFullName2
    "This content is fake" | Out-File -FilePath $FileFullName23

    "This content is fake" | Out-File -FilePath $fake1
    "This content is fake" | Out-File -FilePath $fake2

    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Description.txt" 
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Target-Description.txt" 

    Assert-Count -Expected 8 -Presented (Get-ChildItem -File -Recurse)

    $result = Get-DocsFile
    
    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected "122012-OtherOwner-Description.txt" -Presented $result
    Assert-ContainsPath -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result
    
    $result = Get-DocsFile -Recurse

    Assert-Count -Expected 6 -Presented $result
    Assert-ContainsPath -Expected "122012-OtherOwner-Description.txt" -Presented $result
    Assert-ContainsPath -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result
    Assert-ContainsPath -Expected $FileFullName1  -Presented $result
    Assert-ContainsPath -Expected $FileFullName13  -Presented $result
    Assert-ContainsPath -Expected $FileFullName2  -Presented $result
    Assert-ContainsPath -Expected $FileFullName23  -Presented $result

    Assert-Contains -Expected $FileName1  -Presented $result.Name
}


function DocsTest_GetFile_SpecificPath{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"

    $null = New-Item -ItemType Directory -Path $storefolder1 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $localfile  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13 

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $localfile 

    Assert-Count -Expected 3 -Presented (Get-ChildItem -File -Recurse)

    $result = Get-DocsFile -Path $FileFullName1
    
    Assert-Count -Expected 1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName1 -Presented $result
    
    $result = Get-DocsFile -Path $storefolder1

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result

    $result =  $storefolder1 | Get-DocsFile

    Assert-Count -Expected 2 -Presented $result
    Assert-ContainsPath -Expected $FileFullName1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result

    $result =  ($storefolder1,$localfile ) | Get-DocsFile 

    Assert-Count -Expected 3 -Presented $result
    Assert-ContainsPath -Expected $FileFullName1 -Presented $result
    Assert-ContainsPath -Expected $FileFullName13 -Presented $result
    Assert-ContainsPath -Expected $localfile  -Presented $result
}

function DocsTest_GetFile_StoresWithSamePath{
    $e = SetupScenario1

    Add-DocsStore -Owner Test22 -Path $e["storefolder2"]

    $result = Find-DocsFile -Owner Test2

    Assert-Count -Expected 2 -Presented $result
    Assert-Contains -Expected ($e["FileFullName2"] | Convert-Path) -Presented $result
    Assert-Contains -Expected ($e["FileFullName23"] | Convert-Path) -Presented $result
}

function DocsTest_MoveFile {
    
    $e = SetupScenario2

    $otherStoreFolder = ("." | Join-Path -ChildPath "FolderNotExist" )
    Add-DocsStore -Owner "LocalOwner" -Path $otherStoreFolder
    $filename  = Get-DocsFileName -Owner "LocalOwner" -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    "This content is fake" | Out-File -FilePath $FileName

    Assert-ItemExist     -Path     $e["filename1"]
    Assert-ItemExist     -Path     $e["filename2"]
    Assert-ItemExist     -Path     $e["filename13"]
    Assert-ItemExist     -Path     $e["filename23"]
    Assert-ItemExist     -Path     $filename

    $result = Move-DocsFile 

    Assert-Count -Expected 7 -Presented $result

    Assert-ItemNotExist     -Path     $e["filename1"]
    Assert-ItemNotExist     -Path     $e["filename2"]
    Assert-ItemNotExist     -Path     $e["filename13"]
    Assert-ItemNotExist     -Path     $e["filename23"]
    Assert-ItemNotExist     -Path     $otherStoreFolder

    $r0 = $result | Where-Object {$_.Name -eq $filename}

    Assert-AreEqual      -Expected "LocalOwner"         -Presented $r0.Owner; 
    Assert-AreEqualPath  -Expected $filename            -Presented $r0.Name;
    Assert-AreEqualPath  -Expected "FOLDER_NOT_FOUND"   -Presented $r0.Status 
    Assert-AreEqualPath  -Expected ""                   -Presented $r0.Destination; 
    Assert-ItemExist     -Path $filename

    $r1 = $result | Where-Object {$_.Name -eq $e["filename1"]}

    Assert-AreEqual      -Expected "Test1"              -Presented $r1.Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $r1.Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $r1.Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $r1.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
    $r2 = $result | Where-Object {$_.Name -eq $e["filename2"]}

    Assert-AreEqual      -Expected "Test2"              -Presented $r2.Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]      -Presented $r2.Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $r2.Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $r2.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName2"]
    
    $r3 = $result | Where-Object {$_.Name -eq $e["filename13"]}

    Assert-AreEqual      -Expected "Test1"              -Presented $r3.Owner; 
    Assert-AreEqualPath  -Expected $e["filename13"]     -Presented $r3.Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $r3.Status 
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $r3.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName13"]
    
    $r4 = $result | Where-Object {$_.Name -eq $e["filename23"]}

    Assert-AreEqual      -Expected "Test2"              -Presented $r4.Owner; 
    Assert-AreEqualPath  -Expected $e["filename23"]     -Presented $r4.Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $r4.Status 
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $r4.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName23"]

    $r5 = $result | Where-Object {$_.Name -eq $e["FileNameLocal_OtherOWner1"]}

    Assert-AreEqual      -Expected "OtherOwner"                    -Presented $r5.Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner1"] -Presented $r5.Name;
    Assert-AreEqualPath  -Expected "Unknown"                       -Presented $r5.Status 
    Assert-AreEqualPath  -Expected ""                              -Presented $r5.Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner1"]

    $r6 = $result | Where-Object {$_.Name -eq $e["FileNameLocal_OtherOWner2"]}

    Assert-AreEqual      -Expected "OtherOwner"                    -Presented $r6.Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner2"] -Presented $r6.Name;
    Assert-AreEqualPath  -Expected "Unknown"                       -Presented $r6.Status 
    Assert-AreEqualPath  -Expected ""                              -Presented $r6.Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner2"]

} 

function AddFileToRoot ($Owner, $Target){

    # $key = "FileName-{0}-{1}" -f $Owner,$Target

    $filename = "100101-{0}-{1}-Any_Description.test1" -f $Owner, $Target

    # $Env[$key] = $filename
    # "This content is fake" | Out-File -FilePath $Env[$key]
    
    "This content is fake" | Out-File -FilePath $filename

    return $filename
}
function DocsTest_MoveFile_WithTarget_MultiTargets {

    $e = SetupScenario3

    ResetDocsList

    Add-DocsStore -Owner $e["O1"]                  -Path $e["StoreFolder-1-1"] -Force   
    Add-DocsStore -Owner $e["O1"] -Target $e["T1"] -Path $e["StoreFolder-1-1"] -Force
    Add-DocsStore -Owner $e["O1"] -Target $e["T3"] -Path $e["StoreFolder-2-3"] 
    Add-DocsStore -Owner $e["O1"] -Target $e["T2"] -Path $e["StoreFolder-4-4"] -Force
    Add-DocsStore -Owner $e["O2"] -Target $e["T2"] -Path $e["StoreFolder-4-4"] -Force

    # Create files
    $FN_1_Any = AddFileToRoot -Owner $e["O1"] -Target $e["TF4"]
    $FN_O1_T1 = AddFileToRoot -Owner $e["O1"] -Target $e["T1"]
    $FN_O1_T2 = AddFileToRoot -Owner $e["O1"] -Target $e["T2"]
    $FN_O1_T3 = AddFileToRoot -Owner $e["O1"] -Target $e["T3"]
    $FN_O2_T2 = AddFileToRoot -Owner $e["O2"] -Target $e["T2"]
    
    # Act
    $result = Move-DocsFile
    
    Assert-Count -Expected 5 -Presented $result

    #Assest
    Assert-FileMove  -StatusExpected "MOVED" -ResultObject $result -FileName $FN_1_Any -StoreFolder $e["StoreFolder-1-1"] -Owner $e["O1"] -Target "any"  
    Assert-FileMove  -StatusExpected "MOVED" -ResultObject $result -FileName $FN_O1_T1 -StoreFolder $e["StoreFolder-1-1"] -Owner $e["O1"] -Target $e["T1"]
    Assert-FileMove  -StatusExpected "MOVED" -ResultObject $result -FileName $FN_O1_T2 -StoreFolder $e["StoreFolder-4-4"] -Owner $e["O1"] -Target $e["T2"]
    Assert-FileMove  -StatusExpected "MOVED" -ResultObject $result -FileName $FN_O2_T2 -StoreFolder $e["StoreFolder-4-4"] -Owner $e["O2"] -Target $e["T2"]
    
    Assert-FileMove -StatusExpected "FOLDER_NOT_FOUND" -ResultObject $result -FileName $FN_O1_T3  -StoreFolder $e["StoreFolder-4-4"] -Owner $e["O1"] -Target $e["T3"]
}

function Assert-FileItemMove {
    param(
        $FileName, $StoreFolder, $StatusExpected, $StatusPresented,
        [Switch] $ExistFrom,[Switch] $ExistTo, [Switch] $NotExistFrom,[Switch] $NotExistTo, [Switch] $AreTheSame,
        [Switch] $AreEqual, [Switch] $AreNotEqual
    )
    
    "Assert-FileItemMove [{0}]" -f $FileName | Trace-Message

    #Status
    Assert-AreEqual -Expected $StatusExpected -presented $StatusPresented -Comment "Move Status"

    $from = $FileName
    $to = Join-Path -Path $StoreFolder -ChildPath $FileName

    #Existance
    if ($ExistFrom)    { Assert-ItemExist    -Path $from      -Comment "ExistFrom" }
    if ($NotExistFrom) { Assert-ItemNotExist -Path $from      -Comment "NotExistFrom" }
    if ($ExistTo)      { Assert-ItemExist    -Path $to -Comment "ExistTo" }
    if ($NotExistTo)   { Assert-ItemNotExist -Path $to -Comment "NotExistTo" }

    if ($AreTheSame)   { Assert-AreEqualPath -Expected $to -Presented $FileName -Comment "AreTheSame" }
    if ($AreNotTheSame){ Assert-AreNotEqualPath -Expected $to -Presented $FileName -Comment "AreNotTheSame" }

    if ($AreEqual)     { Assert-AreEqualContent -Expected $from -Presented $to }
    if ($AreNotEqual)  { Assert-AreNotEqualContent -Expected $from -Presented $to }

    Write-AssertionSectionEnd
}


function Assert-FileMove ($FileName, $StoreFolder, $Owner, $Target, $ResultObject, $StatusExpected){

    $moveObject = $ResultObject | Where-Object{$_.Name -eq $FileName}
    
    switch ($StatusExpected) {
        "UNKNOWN"                    { Assert-FileItemMove -ExistFrom                                          -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "MOVED"                      { Assert-FileItemMove -ExistNotFrom -ExistTo                              -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "FOLDER_NOT_FOUND"           { Assert-FileItemMove -ExistFrom    -ExistNotTo                           -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "ARE_THE_SAME"               { Assert-FileItemMove -ExistFrom    -ExistTo    -AreTheSame               -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "ARE_EQUAL"                  { Assert-FileItemMove -ExistFrom    -ExistTo    -AreEqual  -AreNotTheSame -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "ARE_EQUAL_REMOVED_SOURCE"   { Assert-FileItemMove -ExistNotFrom -ExistTo                              -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "ARE_NOT_EQUAL"              { Assert-FileItemMove -ExistFrom    -ExistTo    -AreNotEqual              -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status }
        "ARE_NOT_EQUAL_RENAME_SOURCE"{ Assert-FileItemMove -ExistNotFrom -ExistTo    -AreNotEqual              -FileName $FileName -StoreFolder $StoreFolder -StatusExpected $StatusExpected -StatusPresented $moveObject.Status  
            $toFile = Join-Path -Path $StoreFolder -ChildPath $FileName | Get-Item
            $newToFile = Join-Path -Path $StoreFolder -ChildPath ($toFile.BaseName + "(1)" + $toFile.Extension) | Get-Item
            Assert-ItemExist -Path 
            Assert-AreNotEqualContent -Expected $toFile.FullName -Presented $newToFile.FullName
        }

        Default {
            throw -Message "Unknown Status"
        }
    }
}

function DocsTest_MoveFileItem{
    
    $filename1 = "filename1.txt"
    $filename2 = "filename2.txt"
    $destinationFolder1 = Join-Path -Path '.' -ChildPath "childfolder1" -AdditionalChildPath "childfolder12"
    $destinationFolder2 = Join-Path -Path '.' -ChildPath "childfolder1" -AdditionalChildPath "childfolder12"

    "some content" | Out-File -FilePath $filename1
    "some content" | Out-File -FilePath $filename2

    # Not store folder
    $status = Move-DocsFileItem -Path $filename1 -Destination $destinationFolder1

    Assert-FileItemMove  -StatusExpected "FOLDER_NOT_FOUND" -StatusPresented $status -FileName $filename1 -StoreFolder $destinationFolder1  -ExistFrom -NotExistTo
    
    # With store folder
    $null = New-Item -Path $destinationFolder1 -ItemType Directory
    
    $status = Move-DocsFileItem -Path $filename1 -Destination $destinationFolder1
    
    Assert-FileItemMove  -StatusExpected "MOVED" -StatusPresented $status -FileName $filename1 -StoreFolder $destinationFolder1  -NotExistFrom -ExistTo
    
    # Not Store folder with force
    $status = Move-DocsFileItem -Path $filename2 -Destination $destinationFolder2 -Force
    
    Assert-FileItemMove  -StatusExpected "MOVED" -StatusPresented $status -FileName $filename2 -StoreFolder $destinationFolder2  -NotExistFrom -ExistTo

}

function DocsTest_MoveFile_Path {
    
    $e = SetupScenario2

    Assert-ItemExist     -Path     $e["filename1"]

    $result = Move-DocsFile -Path $e["filename1"]

    Assert-ItemNotExist  -Path     $e["filename1"]
    
    Assert-Count         -Expected 1                    -Presented $result
    Assert-AreEqual      -Expected "Test1"              -Presented $result[0].Owner; 
    Assert-AreEqual      -Expected $e["filename1"]      -Presented $result[0].Name; 
    Assert-AreEqual      -Expected "MOVED"              -Presented $result[0].Status
    Assert-AreEqualPath      -Expected $e["storefolder1"]   -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
}

function DocsTest_MoveFile_Path_Recurse {
    
    $e = SetupScenario1
    
    $wrongFullName = Join-Path -Path $e["storefolder2"] -ChildPath $e["filename1"]
    $e["FileFullName1"] | Move-Item -Destination $e["storefolder2"]
    Assert-ItemExist     -Path     $wrongFullName
    
    $result = Move-DocsFile -Owner Test1 -Recurse
    
    Assert-Count         -Expected 2                    -Presented $result

    Assert-ItemNotExist  -Path     $wrongFullName 
    Assert-ItemExist     -Path     $e["FileFullName1"] 
    
    # Assert-ContainsPath -Expected $e["FileFullName13"] -Presented $result

    $r0 = $result | Where-Object {$_.Name -eq $e["filename13"]}
    
    Assert-AreEqual      -Expected "Test1"              -Presented $r0.Owner; 
    Assert-AreEqualPath  -Expected $e["filename13"]     -Presented $r0.Name; 
    Assert-AreEqualPath  -Expected "ARE_THE_SAME"       -Presented $r0.Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $r0.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName13"]
    
    $r1 = $result | Where-Object {$_.Name -eq $e["filename1"]}

    Assert-AreEqual      -Expected "Test1"              -Presented $r1.Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $r1.Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $r1.Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $r1.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
}

function DocsTest_MoveFile_Path_WhatIf {
    
    $e = SetupScenario2

    Assert-ItemExist     -Path     $e["filename1"]

    $result = Move-DocsFile -Path $e["filename1"] -WhatIf

    
    Assert-ItemExist     -Path     $e["filename1"]
    
    Assert-Count         -Expected 1                    -Presented $result
    Assert-AreEqual      -Expected "Test1"              -Presented $result.Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result.Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result.Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result.Destination; 
    Assert-ItemNotExist  -Path     $e["FileFullName1"]
    
}

function DocsTest_MoveFile_Path_Exists {
    
    $e = SetupScenario2

    Copy-Item -Path $e["filename1"] -Destination $e["FileFullName1"]
    Assert-FilesAreEqual -Expected  $e["filename1"] -Presented $e["FileFullName1"]

    "Some diferent text" | Out-File -FilePath $e["FileFullName2"]
    Assert-FilesAreNotEqual -Expected  $e["filename2"] -Presented $e["FileFullName2"]

    $result = ($e["filename1"] ,$e["filename2"]) | Move-DocsFile  
    
    Assert-Count         -Expected 2                     -Presented $result

    $r0 = $result | Where-Object {$_.Name -eq $e["filename1"]}

    Assert-AreEqual      -Expected "Test1"               -Presented $r0.Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]       -Presented $r0.Name; 
    Assert-AreEqualPath  -Expected "ARE_EQUAL"           -Presented $r0.Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]    -Presented $r0.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]

    $r1 = $result | Where-Object {$_.Name -eq $e["filename2"]}
    
    Assert-AreEqual      -Expected "Test2"               -Presented $r1.Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]       -Presented $r1.Name; 
    Assert-AreEqualPath  -Expected "ARE_NOT_EQUAL"       -Presented $r1.Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]    -Presented $r1.Destination; 
    Assert-ItemExist     -Path     $e["FileFullName2"]

}

function DocsTest_MoveFile_Path_Exists_TheSame {
    
    $e = SetupScenario1

    $result =  $e["FileFullName1"] | Move-DocsFile

    Assert-AreEqual      -Expected "Test1"               -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]       -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "ARE_THE_SAME" -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]    -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]

}

function DocsTest_MoveFile_Path_Exists_ARE_EQUAL_Force {
    
    $e = SetupScenario2

    Copy-Item -Path $e["filename1"] -Destination $e["FileFullName1"]
    Assert-FilesAreEqual -Expected  $e["filename1"] -Presented $e["FileFullName1"]

    $result =  $e["filename1"] | Move-DocsFile  -Force
    
    Assert-Count         -Expected 1                     -Presented $result
    
    Assert-AreEqual      -Expected "Test1"               -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]       -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "ARE_EQUAL_REMOVED_SOURCE"     -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]    -Presented $result[0].Destination; 
    Assert-ItemExist     -Path $e["FileFullName1"]
    Assert-ItemNotExist  -Path $e["filename1"]

}

function DocsTest_MoveFile_Path_Exists_ARE_NOT_EQUAL_Force {
    
    $e = SetupScenario2

    
    "Some diferent text" | Out-File -FilePath $e["FileFullName2"]
    Assert-FilesAreNotEqual -Expected  $e["filename2"] -Presented $e["FileFullName2"]

    $result = $e["filename2"] | Move-DocsFile  -Force

    Assert-Count         -Expected 1                     -Presented $result

    Assert-AreEqual      -Expected "Test2"               -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]       -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "ARE_NOT_EQUAL_RENAME_SOURCE" -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]    -Presented $result[0].Destination; 
    Assert-ItemExist     -Path $e["FileFullName2"]
    Assert-ItemExist     -Path ($e["FileFullName2"] -replace ".test1", "(1).test1")
    Assert-ItemNotExist  -Path $e["filename2"]
}

function DocsTest_DocName_Name_Transformations_Defaults{
    
    $dn = New-DocsDocName

    $result = $dn.Name() | ConvertTo-DocsDocName

    # Date
    Assert-StringIsNullOrEmpty -Presented $dn.Date
    Assert-AreEqualPath -Expected (Get-TodayDateReverse) -Presented $result.Date
    
    # Owner
    Assert-StringIsNullOrEmpty -Presented  $dn.Owner
    Assert-AreEqualPath -Expected "rulasg" -Presented $result.Owner
    
    # Type
    Assert-StringIsNullOrEmpty -Presented  $dn.Type
    Assert-AreEqualPath -Expected "pdf" -Presented $result.Type
    
    # Description
    #   Default
    Assert-AreEqualPath -Expected "DESCRIPTION" -Presented $result.Description
}

function DocsTest_DocName_Transformations_Description_Replacements{
        # We wil use ConverTo.DocsDocName to check the format of the name

        #   Replace " ", - , [ , ]

        #Spaces
        $dn = New-DocsDocName -Description "something space"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something space" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space" -Presented $result.Description
        # Spaces multi
        $dn = New-DocsDocName -Description "something   space"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something   space" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space" -Presented $result.Description

        # -
        $dn = New-DocsDocName -Description "something-space"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something-space" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space" -Presented $result.Description

        $dn = New-DocsDocName -Description "something[space]"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something[space]" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space_" -Presented $result.Description
}

function DocsTest_DocName_Transformations_Description_Replacements{

        #'[\s/\[\]-]'

        $dn = New-DocsDocName

        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one-two"   )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one--two"  )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("-one--two-")) 

        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one two"   )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one  two"  )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr(" one  two ")) 

        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one/two"   )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one//two"  )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("//one//two")) 

        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("[one_two]" )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("[one]two"  )) 

        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one.two"   )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr("one..two"  )) 
        Assert-AreEqual -Expected "one_two" -Presented ($dn.TestTransformStr(".one..two.")) 
}

function DocsTest_ConvertToDocName{

    "12-owner-descr.txt"                                        | ConvertTo-DocsDocName `
    | CheckDocName -Date "12" -Owner "owner" -Description "descr" -Type "txt"
    
    "1212-owner-descr"                                          | ConvertTo-DocsDocName `
    | CheckDocName -Date "1212" -Owner "owner" -Description "descr" 
    
    "121212-owner-descr"                                        | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Description "descr" 
    
    "121212-owner-Desc.txt"                                     | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Description "Desc" -Type "txt"
    
    "121212-owner-target-Desc.txt"                              | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -Description "Desc" -Type "txt"
    
    "121212-owner-target-What-Desc.txt"                         | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "What" -Description "Desc" -Type "txt"
    
    "121212-owner-target-What-32#32-Desc.txt"                   | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "What" -Amount "32#32" -Description "Desc" -Type "txt"
    
    "121212-owner-target-What-32#32-Desc-dasd-asdasd-asds.txt"  | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "What" -Amount "32#32" -Description "Desc-dasd-asdasd-asds" -Type "txt"

    "121212"                                                    | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" 
    
    ".txt"                                                      | ConvertTo-DocsDocName `
    | CheckDocName -Type "txt"

    "something"                                                 | ConvertTo-DocsDocName `
    | CheckDocName -Description "something"
    
    "121212-NoOwner.txt"                                        | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Description "NoOwner" -Type "txt"

    "121212-NoOwner"                                            | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Description "NoOwner" 

    "Owner-Descdescr.txt"                                       | ConvertTo-DocsDocName `
    | CheckDocName -Owner "Owner" -Description "Descdescr" -Type "txt"

    "12121a-target-descr.txt"                                    | ConvertTo-DocsDocName `
    | CheckDocName -Owner "12121a" -Target "target" -Description "descr" -Type "txt"

    "121212-owner-target-what-Desc-rasf-dasd-asdasd-asd.txt" | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "what"  -Description "Desc-rasf-dasd-asdasd-asd" -Type "txt"

    "121212-owner-target-what-234-Desc-rasf-dasd-asdasd-asd.txt" | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "what" -Amount "234" -Description "Desc-rasf-dasd-asdasd-asd" -Type "txt"

    "121212-owner-target-32.32-Desc.txt"                        | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "32.32" -Description "Desc" -Type "txt"
    
    "121212-owner-target-32#32-Desc.txt"                        | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -Amount "32#32" -Description "Desc" -Type "txt"
    
    "121212-owner-target-32#32-What-Desc.txt"                   | ConvertTo-DocsDocName `
    | CheckDocName -Date "121212" -Owner "owner" -Target "target" -What "what" -Amount "32#32" -Description "Desc" -Type "txt"

    # "121212-32#32-What-Desc.txt"                                | ConvertTo-DocsDocName `
    # | CheckDocName -Date "121212" -Amount "32#32" -Description "Desc" -Type "txt"

    
}

function DocsTest_RenameFile_WrongFile{

    $oldName = "desc3.txt"
    $newName = "{0}-kk-desc3.txt" -f (Get-TodayDateReverse)

    "This content is fake" | Out-File -FilePath $oldName

    # Single file 
    Assert-ItemExist    -Path $oldName
    Rename-DocsFile -Path $oldName -Owner kk -WhatIf
    Assert-ItemExist    -Path $oldName
    
    Rename-DocsFile -Path $oldName -Owner kk

    Assert-ItemNotExist    -Path $oldName
    Assert-ItemExist    -Path $newName
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
}
function DocsTest_RenameFile_SingleFile{

    $oldName = "122012-OtherOwner-Target-Description.txt"
    $newName = "122012-kk-Target-Description.txt"
    "This content is fake" | Out-File -FilePath $oldName

    # Single file 
    Assert-ItemExist    -Path $oldName
    Rename-DocsFile -Path $oldName -Owner kk -WhatIf
    Assert-ItemNotExist    -Path $newName
    
    Rename-DocsFile -Path $oldName -Owner kk
    Assert-ItemExist    -Path $newName
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
}

# function DocsTest_RenameFile_SingleFile_WithOutOwner_WithAmount{

#     $oldName = "122012-32#32-Description.txt"
#     $newName = "122012-kk-32#32-TargetName-Description.txt"
    
#     "This content is fake" | Out-File -FilePath $oldName
#     Assert-ItemExist    -Path $oldName

#     # Single file 
    
#     Rename-DocsFile -Path $oldName -Owner kk -Target "TargetName"

#     Assert-ItemExist    -Path $newName
#     Assert-Count -Expected 1 -Presented (Get-ChildItem)
# }

function DocsTest_RenameFile_SingleFile_Withowner_WithAmount{

    $oldName = "122012-owner-32#32-Description.txt"
    $newName = "122012-kk-32#32-Description.txt"
    
    "This content is fake" | Out-File -FilePath $oldName
    Assert-ItemExist    -Path $oldName

    # Single file 
    
    Rename-DocsFile -Path $oldName -Owner kk

    Assert-ItemExist    -Path $newName
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
}

function DocsTest_RenameFile_SingleFile_TheSame{

    $oldName = "122012-OtherOwner-Target-Description.txt"
    "This content is fake" | Out-File -FilePath $oldName

    # Single file 
    Assert-ItemExist    -Path $oldName
    Rename-DocsFile -Path $oldName
    Assert-ItemExist    -Path $oldName
}

function DocsTest_RenameFile_SingleFile_PreDescription{

    $oldName = "122012-OtherOwner-Target-Desc1.txt"
    $newName = "122012-kk-Target-PreDesc_Desc1.txt"

    "This content is fake" | Out-File -FilePath $oldName

    # Single file 
    Assert-ItemExist    -Path $oldName
    Rename-DocsFile -Path $oldName -Owner kk -PreDescription "PreDesc" -WhatIf
    Assert-ItemNotExist    -Path $newName
    
    Rename-DocsFile -Path $oldName -Owner kk -PreDescription "PreDesc"
    Assert-ItemExist    -Path $newName
    Assert-Count -Expected 1 -Presented (Get-ChildItem)

}

function DocsTest_RenameFile_WildChar{

    $oldName1 = "122012-OtherOwner-Target-Description.txt"
    $oldName2 = "122012-OtherOwner-Description.txt"
    $oldName3 = "132012-OtherOwner-Description.txt"
    $newName1 = "122012-kk-Target-Description.txt"
    $newName2 = "122012-kk-Description.txt"
    $newName3 = "132012-kk-Description.txt"
    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    # Single file 
    Rename-DocsFile -Path "12*OtherOwner*" -Owner kk
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemNotExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)

}

function DocsTest_RenameFile_Pipe_Files{

    $oldName1 = "122012-OtherOwner-Target-Description.txt"
    $oldName2 = "122012-OtherOwner-Description.txt"
    $oldName3 = "132012-OtherOwner-Description.txt"
    $newName1 = "122012-kk-Target-Description.txt"
    $newName2 = "122012-kk-Description.txt"
    $newName3 = "132012-kk-Description.txt"
    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    $files = Get-ChildItem -Path 12*

    # Single file 
    $files | Rename-DocsFile -Owner kk
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemNotExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)

}

function DocsTest_RenameFile_Pipe_String{

    $oldName1 = "122012-OtherOwner-Target-Description.txt"
    $oldName2 = "122012-OtherOwner-Description.txt"
    $oldName3 = "132012-OtherOwner-Description.txt"
    $newName1 = "122012-kk-Target-Description.txt"
    $newName2 = "122012-kk-Description.txt"
    $newName3 = "132012-kk-Description.txt"
    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    # Single file 
    @($oldName1,$oldName3) | Rename-DocsFile -Owner kk
    Assert-ItemExist    -Path $newName1
    Assert-ItemNotExist    -Path $newName2
    Assert-ItemExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)
}

function DocsTest_RenameFile_Pipe_String_MultipleParameters{

    $oldName1 = "122011-OtherOwner-Target-Description1.txt"
    $oldName2 = "122012-OtherOwner-Target2-Description2.txt"
    $oldName3 = "132013-OtherOwner-Target3-Description3.txt"
    $newName1 = "122011-kk-Target-Factura-Description1.txt"
    $newName2 = "122012-kk-Target-Factura-Description2.txt"
    $newName3 = "132013-kk-Target-Factura-Description3.txt"

    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    $docname = $oldName1 | ConvertTo-DocsDocName

    $docname.Date = ""
    $docname.Description = ""

    $docname | Rename-DocsFile -Owner kk -What "Factura" -Path (Get-ChildItem)

    Assert-Count -Expected 3 -Presented (Get-ChildItem)
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemExist    -Path $newName3
}

function DocsTest_ConvertToFile_SingleFile {
    
    $fileName = "filename1.txt"
    $newName = "121212-kk-SomeDescription_filename1.txt"

    "This content is fake" | Out-File -FilePath $fileName 

    # Single file 
    Assert-ItemExist    -Path $fileName
    Assert-ItemNotExist    -Path $newName

    Rename-DocsFile -Path $fileName -Owner kk -Date "121212" -PreDescription "SomeDescription" -WhatIf 
   
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
    Assert-ItemNotExist    -Path $newName
    Assert-ItemExist    -Path $fileName
  
    Rename-DocsFile -Path $fileName -Owner kk -Date "121212" -PreDescription "SomeDescription" 
   
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
    Assert-ItemNotExist    -Path $fileName
    Assert-ItemExist -Path $newName
}

function DocsTest_ConvertToFile_SingleFile_WithDescription {
    
    $fileName = "filename1.txt"
    $newName = "121212-kk-SomeDescription.txt"

    "This content is fake" | Out-File -FilePath $fileName 

    # Single file 
    Assert-ItemExist    -Path $fileName
    Assert-ItemNotExist    -Path $newName

    Rename-DocsFile -Path $fileName -Owner kk -Date "121212" -Description "SomeDescription" -WhatIf 
   
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
    Assert-ItemNotExist    -Path $newName
    Assert-ItemExist    -Path $fileName
  
    Rename-DocsFile -Path $fileName -Owner kk -Date "121212" -Description "SomeDescription" 
   
    Assert-Count -Expected 1 -Presented (Get-ChildItem)
    Assert-ItemNotExist    -Path $fileName
    Assert-ItemExist -Path $newName
}

function DocsTest_ConvertToFile_WildChar{

    $oldName1 = "Desc112.txt"
    $oldName2 = "Desc122.pdf"
    $oldName3 = "Desc132.txt"
    $newName1 = "121212-kk-Desc112.txt"
    $newName2 = "121212-kk-Desc122.pdf"
    $newName3 = "121212-kk-Desc132.txt"
    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    # Single file 
    Rename-DocsFile -Path "Desc1*" -Owner kk -Date "121212"
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)
}

function DocsTest_ConvertToFile_WildChar_WithDescription{
    $Today = Get-TodayDateReverse
    $oldName1 = "Desc112.txt"
    $oldName2 = "Desc122.pdf"
    $oldName3 = "Desc132.txt"
    $newName1 = $Today + "-kk-PreToAd_Desc112.txt"
    $newName2 = $Today + "-kk-PreToAd_Desc122.pdf"
    $newName3 = $Today + "-kk-PreToAd_Desc132.txt"
    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    # Single file 
    Rename-DocsFile -Path "Desc1*" -Owner kk -Date $Today -PreDescription "PreToAd"
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)

}
function DocsTest_ConvertToFile_Pipe_Files{


    $oldName1 = "12Desk1.txt"
    $oldName2 = "12Desk2.pdf"
    $oldName3 = "132012-OtherOwner-Description.txt"

    $newName1 = "121212-kk-rename-12Desk1.txt"
    $newName2 = "121212-kk-rename-12Desk2.pdf"
    $newName3 = "132012-kk-Description.txt"

    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    $files = Get-ChildItem -Path 12*

    # Single file 
    $files | Rename-DocsFile -Owner kk -Target rename -Date 121212
    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $newName2
    Assert-ItemNotExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)

}

function DocsTest_ConvertToFile_Pipe_String{

    $oldName1 = "12Desk1.txt"
    $oldName2 = "132012-OtherOwner-Description.txt"
    $oldName3 = "12Desk2.pdf"

    $newName1 = "121212-kk-rename-12Desk1.txt"
    $newName3 = "121212-kk-rename-12Desk2.pdf"

    "This content is fake" | Out-File -FilePath $oldName1
    "This content is fake" | Out-File -FilePath $oldName2
    "This content is fake" | Out-File -FilePath $oldName3

    # Single file 
    @($oldName1,$oldName3) |  Rename-DocsFile -Owner kk -Target rename -Date 121212

    Assert-ItemExist    -Path $newName1
    Assert-ItemExist    -Path $oldName2
    Assert-ItemExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)
}

function DocsTest_GetDocsName_Simple{

    Assert-NotImplemented
}

Export-ModuleMember -Function DocsTest_*

function SetupScenario1 () {
    
    $Evidence = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"
    $Evidence["storefolder1"] = $storefolder1
    $Evidence["storefolder2"] = $storefolder2

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323
    $Evidence["filename1"] = $filename1 
    $Evidence["filename13"] = $filename13 
    $Evidence["filename2"] = $filename2 
    $Evidence["filename23"] = $filename23 

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13 
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2 
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23 
    $FileFullName_fake1 = Join-Path -Path $storefolder1 -ChildPath "Test1-andnomore.txt"
    $FileFullName_fake2 = Join-Path -Path $storefolder2 -ChildPath "121212-fakename.txt"
    $Evidence["FileFullName1"] = $FileFullName1
    $Evidence["FileFullName13"] = $FileFullName13
    $Evidence["FileFullName2"] = $FileFullName2
    $Evidence["FileFullName23"] = $FileFullName23
    $Evidence["FileFullName_fake1"] = $FileFullName_fake1
    $Evidence["FileFullName_fake2"] = $FileFullName_fake2

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $FileFullName2
    "This content is fake" | Out-File -FilePath $FileFullName23
    "This content is fake" | Out-File -FilePath $FileFullName_fake1
    "This content is fake" | Out-File -FilePath $FileFullName_fake2

    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Description.txt" 
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Target-Description.txt" 

    $Evidence["FileNameLocal_OtherOWner1"] = "122012-OtherOwner-Description.txt" 
    $Evidence["FileNameLocal_OtherOWner2"] = "122012-OtherOwner-Target-Description.txt" 

    Assert-Count -Expected 8 -Presented (Get-ChildItem -File -Recurse)
    
    Write-AssertionSectionEnd

    $Evidence
}

function SetupScenario2 () {
    
    $Evidence = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"
    $Evidence["storefolder1"] = $storefolder1
    $Evidence["storefolder2"] = $storefolder2

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323
    $Evidence["filename1"] = $filename1 
    $Evidence["filename13"] = $filename13 
    $Evidence["filename2"] = $filename2 
    $Evidence["filename23"] = $filename23 

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1 
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13 
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2 
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23 
    $FileFullName_fake1 = Join-Path -Path $storefolder1 -ChildPath "Test1-andnomore.txt"
    $FileFullName_fake2 = Join-Path -Path $storefolder2 -ChildPath "121212-fakename.txt"
    $Evidence["FileFullName1"] = $FileFullName1
    $Evidence["FileFullName13"] = $FileFullName13
    $Evidence["FileFullName2"] = $FileFullName2
    $Evidence["FileFullName23"] = $FileFullName23
    $Evidence["FileFullName_fake1"] = $FileFullName_fake1
    $Evidence["FileFullName_fake2"] = $FileFullName_fake2

    "This content is fake" | Out-File -FilePath $FileName1 
    "This content is fake" | Out-File -FilePath $FileName13 
    "This content is fake" | Out-File -FilePath $FileName2 
    "This content is fake" | Out-File -FilePath $FileName23 

    "This content is fake" | Out-File -FilePath $FileFullName_fake1
    "This content is fake" | Out-File -FilePath $FileFullName_fake2

    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Description.txt" 
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Target-Description.txt" 

    $Evidence["FileNameLocal_OtherOWner1"] = "122012-OtherOwner-Description.txt" 
    $Evidence["FileNameLocal_OtherOWner2"] = "122012-OtherOwner-Target-Description.txt" 

    Assert-Count -Expected 8 -Presented (Get-ChildItem -File -Recurse)
    
    Write-AssertionSectionEnd

    return $Evidence
}

function SetupScenario3 () {
    
    $e = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    
    $e["O1"] = "Owner1"
    $e["O2"] = "Owner2"

    $e["T1"]  = "T1"
    $e["T2"]  = "T2"
    $e["T3"]  = "T3"
    $e["TF4"] = "TF4"
    $e["TF5"] = "TF5"

    # StoresFolder
    $e["StoreFolder-1-1"] = "." | Join-Path -ChildPath "FP1" -AdditionalChildPath "FC1"
    $e["StoreFolder-2-2"] = "." | Join-Path -ChildPath "FP2" -AdditionalChildPath "FC2"
    $e["StoreFolder-2-3"] = "." | Join-Path -ChildPath "FP2" -AdditionalChildPath "FC3"
    $e["StoreFolder-4-4"] = "." | Join-Path -ChildPath "FP4" -AdditionalChildPath "FC4"

    # Stores
    # ResetDocsList
    # Add-DocsStore -Owner $e["O1"]                  -Path $e["StoreFolder-1-1"] -force
    # Add-DocsStore -Owner $e["O1"] -Target $e["T1"] -Path $e["StoreFolder-1-1"] -force
    # Add-DocsStore -Owner $e["O1"] -Target $e["T3"] -Path $e["StoreFolder-2-3"] -force
    # Add-DocsStore -Owner $e["O1"] -Target $e["T2"] -Path $e["StoreFolder-4-4"]
    # Add-DocsStore -Owner $e["O2"]                  -Path $e["StoreFolder-2-2"] -Force

    #Files
    # $e["FileName-O1-TF4"] = "100101-{0}-{1}-Any_Description.test1" -f $e["O1"], $e["TF4"]
    # $e["FileName-O1-T1"]  = "110213-{0}-{1}-Any_Description.test1" -f $e["O1"], $e["T1"]    
    # $e["FileName-O1-T2"]  = "100201-{0}-{1}-Any_Description.test1" -f $e["O1"], $e["T2"]    
    # $e["FileName-O2-TF5"] = "110323-{0}-{1}-Any_Description.test"  -f $e["O2"], $e["TF5"]
    # $e["FileName-O2-T2"]  = "110323-{0}-{1}-Any_Description.test"  -f $e["O2"], $e["T2"]
    # $e["FileName-O1-T3"]  = "100201-{0}-{1}-Any_Description.test1" -f $e["O1"], $e["T3"]    
    # $e["FileName-NoDate"] = "Test1-andnomore.txt"
    # $e["FileName-D-D"]    = "121212-fakename.txt"
    # $e["FileName-OW"]     = "122012-OtherOwner-Description.txt" 
    # $e["FileName-OW-TW"]  = "122012-OtherOwner-Target-Description.txt" 


    # Create files
    #"This content is fake" | Out-File -FilePath $e["FileName-O1-TF4"]
    #"This content is fake" | Out-File -FilePath $e["FileName-O1-T1"] 
    #"This content is fake" | Out-File -FilePath $e["FileName-O1-T2"] 
    #"This content is fake" | Out-File -FilePath $e["FileName-O1-T3"] 
    #"This content is fake" | Out-File -FilePath $e["FileName-O2-TF5"] 
    #"This content is fake" | Out-File -FilePath $e["FileName-NoDate"]
    #"This content is fake" | Out-File -FilePath $e["FileName-D-D"]
    #"This content is fake" | Out-File -FilePath $e["FileName-OW"]
    #"This content is fake" | Out-File -FilePath $e["FileName-OW-TW"]

    #Assert-Count -Expected 9 -Presented (Get-ChildItem -File -Recurse)
    
    Write-AssertionSectionEnd

    return $e
}

function Get-TodayDateReverse() {
    (Get-Date -Format 'yyMMdd')
}

function CheckDocName{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline)] $DocName,
        [string]$Date,
        [string]$Owner,
        [string]$Target,
        [string]$What,
        [string]$Amount,
        [string]$Description,
        [string]$Type
    )
    Assert-AreEqual -Expected $Date        -Presented $DocName.Date        -Comment "Date"
    Assert-AreEqual -Expected $Owner       -Presented $DocName.Owner       -Comment "Owner"
    Assert-AreEqual -Expected $Target      -Presented $DocName.Target      -Comment "Target"
    Assert-AreEqual -Expected $What        -Presented $DocName.What        -Comment "What"
    Assert-AreEqual -Expected $Amount      -Presented $DocName.Amount      -Comment "Amount"
    Assert-AreEqual -Expected $Description -Presented $DocName.Description -Comment "Description"
    Assert-AreEqual -Expected $Type        -Presented $DocName.Type        -Comment "Type"

    Write-AssertionDot -Color Yellow
}
