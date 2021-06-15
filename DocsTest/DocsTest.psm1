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


function ResetDocsList([switch]$PassThru) {

    $TestStoreList = New-DocsStoresList
    Initialize-DocsStoresList -StoreList $TestStoreList 

    if ($PassThru) {
        return $TestStoreList
    } 
}

function DocsTest_Sample() {
    Assert-IsTrue -Condition $true
}

function DocsTest_AddStores {
    
    $TestStoreList = ResetDocsList -PassThru
    Add-DocsStore -Owner "SampleOwner" -Path "." -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path "$Home/fackefolder"

    Assert-Count -Expected 2 -Presented $TestStoreList

    $o1 = $TestStoreList["SampleOwner"]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $TestStoreList["SampleOwner2"]
    Assert-IsFalse -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder" -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist
}

function DocsTest_AddStores_Force {
    
    $TestStoreList = ResetDocsList -PassThru

    $local  = "." | Resolve-Path
    $storeFolder = $local | Join-Path -ChildPath "fakefolder"

    Assert-IsFalse -Condition ($storeFolder | Test-Path)

    Add-DocsStore -Owner "SampleOwner" -Path $storeFolder -IsRecursive -Force

    Assert-Count -Expected 1 -Presented $TestStoreList
    $o1 = $TestStoreList["SampleOwner"]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected $storeFolder -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

}
function DocsTest_GetStores {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner0" -Path "$Home/fackefolder0"
    Add-DocsStore -Owner "SampleOwner1" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path "$Home/fackefolder2" -IsRecursive
    Add-DocsStore -Owner "SampleOwner3" -Path $Home

    $result = Get-DocsStores

    Assert-Count -Expected 4 -Presented $result

    $o0 = $result[0]
    Assert-AreEqual -Expected "SampleOwner0" -Presented $o0.Owner
    Assert-IsFalse -Condition $o0.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder0" -Presented $o0.Path
    Assert-IsFalse -Condition $o0.Exist

    $o1 = $result[1]
    Assert-AreEqual -Expected "SampleOwner1" -Presented $o1.Owner
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $result[2]
    Assert-AreEqual -Expected "SampleOwner2" -Presented $o2.Owner
    Assert-IsTrue -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder2" -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist

    $o3 = $result[3]
    Assert-AreEqual -Expected "SampleOwner3" -Presented $o3.Owner
    Assert-IsFalse -Condition $o3.IsRecursive
    Assert-AreEqualPath -Expected $Home -Presented $o3.Path
    Assert-IsTrue -Condition $o3.Exist

    # Owner

    $result2 = Get-DocsStores -Owner "SampleOwner2"
    
    Assert-Count -Expected 1 -Presented $result2

    $o = $result2

    Assert-AreEqual -Expected "SampleOwner2" -Presented $o.Owner
    Assert-IsTrue -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder2" -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

    # Exist

    $result3 = Get-DocsStores -Exist

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

function DocsTest_GetOwners {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path "$Home/fackefolder"

    $result = Get-DocsOwners

    Assert-Count -Expected 2 -Presented $result

    $o1 = $result[0]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $result[1]
    Assert-IsFalse -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder" -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist

}

function DocsTest_GetFileNamePattern{

        # Base Pattern
        $fnp = Get-DocsFileNamePattern
        Assert-AreEqual -Expected "*-*-*.*" -Presented $fnp
        
        # Ammount
        $fnp = Get-DocsFileNamePattern -Amount "99#99"
        Assert-AreEqual -Expected "*-*-*99#99*-*.*" -Presented $fnp
}

function DocsTest_FileName {
    $date = "121212"
    $owner = "sampleOwner"
    $target = "SampleTarget"
    $amount = "99#99"
    $what = "sampleWhat"
    $desc = "SampleDescription"
    $type = "SampleType"
    

    # Mandatory fields
    $defaultOwner = "rulasg"
    $defaultExt = "pdf"
    $fn = Get-DocsFileName -Target $target -Description $desc
    Assert-AreEqual -Presented $fn.Name() -Expected ("{0}-{1}-{2}-{3}.{4}" -f (Get-Date -Format 'yyMMdd'), $defaultOwner, $target, $desc, $defaultExt)
    Assert-AreEqual -Presented $fn.Pattern() -Expected ("*-*-*{0}*-*{1}*.*" -f $target, $desc)

    # Full seeded name
    $fn = Get-DocsFileName  `
        -Date $date         `
        -Owner $owner       `
        -Target $target     `
        -Amount $amount     `
        -What $what         `
        -Description $desc  `
        -Type $type         `
        
    Assert-AreEqual -Presented $fn.Name() -Expected ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f $date, $owner, $target, $amount, $what, $desc, $type)
    Assert-AreEqual -Presented $fn.Pattern() -Expected ("*{0}*-*{1}*-*{2}*-*{3}*-*{4}*-*{5}*.*{6}*" -f $date, $owner, $target, $amount, $what, $desc, $type)

    # Name Pattern

    # Assert-AreEqual -Presented $fn.Sample() -Expected ("{0}-{1}-{2}-{3}-{4}-{5}.{6}" -f "date", "owner", "target", "amount", "what", "desc", "type")

}

function DocsTest_Find_Simple{
    $storefolder = "." | Join-Path -ChildPath "Fakefolder" -AdditionalChildPath "FakeStoreFolder"

    ResetDocsList
    Add-DocsStore -Owner test -Path $storefolder -Force

    $filename = Get-DocsFileName -Owner Test -Target Testing -Description "Test File"
    $FileFullName = $storefolder | Join-Path -ChildPath $filename.Name()
    "This content is fake" | Out-File -FilePath $FileFullName

    Assert-Count -Expected 1 -Presented ($FileFullName | Get-ChildItem )

    $result = Find-DocsFile -Owner Test

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName -Presented $result
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

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1.Name()
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13.Name()
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2.Name()
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23.Name()

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $FileFullName2
    "This content is fake" | Out-File -FilePath $FileFullName23

    # Owner 1

    Assert-Count -Expected 4 -Presented (Get-ChildItem -filter "*.test*" -Recurse)

    $result = Find-DocsFile -Owner Test1

    Assert-Count -Expected 2 -Presented $result
    $result = Find-DocsFile -Owner Test2

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result[0]
    Assert-AreEqualPath -Expected $FileFullName23 -Presented $result[1]

    # Target

    $result = Find-DocsFile -Target Testing3

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[0]
    Assert-AreEqualPath -Expected $FileFullName23 -Presented $result[1]

    # Descriptionm

    $result = Find-DocsFile -Description Test0

    Assert-Count -Expected 3 -Presented $result

    $result = Find-DocsFile -Type Test1

    Assert-Count -Expected 3 -Presented $result

    $result = Find-DocsFile -Target Testing2 -Description Test0

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result[0]

    # Date 

    $result = Find-DocsFile -Date 11

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[0]
    Assert-AreEqualPath -Expected $FileFullName23 -Presented $result[1]

    # Date 

    $result = Find-DocsFile -Date 1102

    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[0]

}



function DocsTest_TestFileName{

    # Not exist
    Assert-IsFalse -Condition (Test-DocsFileName -Path "fakefile.txt")

    # Is a directory
    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $null = New-Item -ItemType Directory -Name $filename1.Name()
    
    $result = Test-DocsFileName -Path $filename1.Name()
    Assert-IsFalse -Condition $result
    
    # File
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test2 -Date 100102
    "This content is fake" | Out-File -FilePath $FileName2.Name()

    $result = Test-DocsFileName -Path $filename2.Name()

    Assert-IsTrue -Condition $result
}

function DocsTest_GetFileToMove_All{

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    "This content is fake" | Out-File -FilePath $FileName1.Name()
    "This content is fake" | Out-File -FilePath $FileName13.Name()
    "This content is fake" | Out-File -FilePath $FileName2.Name()
    "This content is fake" | Out-File -FilePath $FileName23.Name()

    "This content is fake" | Out-File -FilePath "Test1-Target-Description.txt"
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Target-Description.txt"
    "This content is fake" | Out-File -FilePath "122012-NearlyCorrect.txt"
    "This content is fake" | Out-File -FilePath "122012-Test1.txt"
    "This content is fake" | Out-File -FilePath "122012-OtherOwner-Description.txt"

    $result = Get-DocsFileToMove

    Assert-Count -Expected 6 -Presented $result
    Assert-AreEqual -Expected $FileName1.Name() -Presented $result[0].Name
    Assert-AreEqual -Expected $FileName2.Name() -Presented $result[1].Name
    Assert-AreEqual -Expected $FileName13.Name() -Presented $result[2].Name
    Assert-AreEqual -Expected $FileName23.Name() -Presented $result[3].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[4].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[5].Name
}

function DocsTest_GetFileToMove_Recursive{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1.Name()
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13.Name()
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2.Name()
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23.Name()
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

    $result = Get-DocsFileToMove 
    
    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[0].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[1].Name
    
    $result = Get-DocsFileToMove -Recursive

    Assert-Count -Expected 6 -Presented $result
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[0].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[1].Name
    Assert-AreEqual -Expected $FileName2.Name() -Presented $result[2].Name
    Assert-AreEqual -Expected $FileName23.Name() -Presented $result[3].Name
    Assert-AreEqual -Expected $FileName1.Name() -Presented $result[4].Name
    Assert-AreEqual -Expected $FileName13.Name() -Presented $result[5].Name
}



function DocsTest_MoveFile {

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"
    
    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201
    $filename23 = Get-DocsFileName -Owner Test2 -Target Testing3 -Description "Test0 File23" -Type test  -Date 110323

    "This content is fake" | Out-File -FilePath $FileName1.Name()
    "This content is fake" | Out-File -FilePath $FileName13.Name()
    "This content is fake" | Out-File -FilePath $FileName2.Name()
    "This content is fake" | Out-File -FilePath $FileName23.Name()

    $local = Get-ChildItem -File

    Assert-Count -Expected 4 -Presented $local

    

    Assert-NotImplemented

} 

Export-ModuleMember -Function DocsTest_*