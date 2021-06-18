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

    $o1 = $TestStoreList["SampleOwner".ToLower()]
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $TestStoreList["SampleOwner2".ToLower()]
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
    $o1 = $TestStoreList["SampleOwner".ToLower()]
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

function DocsTest_SetStoreLocation{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"
    $storefolder2 = "." | Join-Path -ChildPath "Fakefolder2" -AdditionalChildPath "FakeStoreFolder2"

    ResetDocsList
    Add-DocsStore -Owner test1 -Path $storefolder1 -Force
    Add-DocsStore -Owner test2 -Path $storefolder2 -Force

    $converted1 = $storefolder1 | Convert-Path
    $converted2 = $storefolder2 | Convert-Path

    Set-DocsStoreLocation -Owner test1

    Assert-AreEqualPath -Expected $converted1  -Presented '.'
    
    "test2" | Set-DocsStoreLocation 

    Assert-AreEqualPath -Expected $converted2 -Presented '.'

    Set-DocsStoreLocation test1

    Assert-AreEqualPath -Expected $converted1  -Presented '.'
}
function DocsTest_GetOwners {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path "$Home/fackefolder"

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

    Assert-Count -Expected 4 -Presented (Get-ChildItem -File -Recurse)

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

    # Object

    $result = $filename2 | Find-DocsFile
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName2 -Presented $result[0]

}

function DocsTest_TestFile{

    # Not exist
    $result = Test-DocsFile -Path "fakefile.txt"
    Assert-IsFalse -Condition $result

    # Is a directory
    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $null = New-Item -ItemType Directory -Name $filename1.Name()
    
    $result = Test-DocsFile -Path $filename1.Name()
    Assert-IsFalse -Condition $result
    
    # File
    $filename2  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test2 -Date 100102
    "This content is fake" | Out-File -FilePath $FileName2.Name()

    $result = Test-DocsFile -Path $filename2.Name()

    Assert-IsTrue -Condition $result
}

function DocsTest_TestFileName_FileFormats {
    
    Assert-IsTrue -Condition ("121212-owner-descr"    | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-Desc.txt" | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-target-Desc.txt" | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-target-32#32-Desc.txt" | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-target-What-Desc.txt" | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-target-32#32-What-Desc.txt" | Test-DocsFileName)
    Assert-IsTrue -Condition ("121212-owner-target-32#32-What-Desc-dasd-asdasd-asddas.txt" | Test-DocsFileName)
    
    Assert-IsFalse -Condition ("something"    | Test-DocsFileName)
    Assert-IsFalse -Condition ("121212-NoOwner.txt"    | Test-DocsFileName)
    Assert-IsFalse -Condition ("121212-NoOwner"    | Test-DocsFileName)
    Assert-IsFalse -Condition ("Owner-Descdescr.txt"    | Test-DocsFileName)
    Assert-IsFalse -Condition ("12121a-owner-descr.txt"    | Test-DocsFileName)
    Assert-IsFalse -Condition ("121212-owner-target-Ammount-What-Desc-dasd-asdasd-asddas.txt" | Test-DocsFileName)
    
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

    $result = Get-DocsFileToMove -Target Testing3

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqual -Expected $FileName13.Name() -Presented $result[0].Name
    Assert-AreEqual -Expected $FileName23.Name() -Presented $result[1].Name
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
    
    $result = Get-DocsFileToMove -Recurse

    Assert-Count -Expected 6 -Presented $result
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[0].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[1].Name
    Assert-AreEqual -Expected $FileName2.Name() -Presented $result[2].Name
    Assert-AreEqual -Expected $FileName23.Name() -Presented $result[3].Name
    Assert-AreEqual -Expected $FileName1.Name() -Presented $result[4].Name
    Assert-AreEqual -Expected $FileName13.Name() -Presented $result[5].Name
}

function DocsTest_GetFileToMove_SpecificPath{

    $storefolder1 = "." | Join-Path -ChildPath "Fakefolder1" -AdditionalChildPath "FakeStoreFolder1"

    $null = New-Item -ItemType Directory -Path $storefolder1 -Force

    $filename1  = Get-DocsFileName -Owner Test1 -Target Testing1 -Description "Test0 File1"  -Type test1 -Date 100101
    $filename13 = Get-DocsFileName -Owner Test1 -Target Testing3 -Description "Test File13" -Type test1  -Date 110213
    $localfile  = Get-DocsFileName -Owner Test2 -Target Testing2 -Description "Test0 File2"  -Type test1 -Date 100201

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1.Name()
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13.Name()

    "This content is fake" | Out-File -FilePath $FileFullName1
    "This content is fake" | Out-File -FilePath $FileFullName13
    "This content is fake" | Out-File -FilePath $localfile.Name()

    Assert-Count -Expected 3 -Presented (Get-ChildItem -File -Recurse)

    $result = Get-DocsFileToMove -Path $FileFullName1
    
    Assert-Count -Expected 1 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    
    $result = Get-DocsFileToMove -Path $storefolder1

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName

    $result =  $storefolder1 | Get-DocsFileToMove 

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName

    $result =  ($storefolder1,$localfile.Name()) | Get-DocsFileToMove 

    Assert-Count -Expected 3 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName
    Assert-AreEqualPath -Expected $localfile.Name() -Presented $result[2].FullName
}



function DocsTest_MoveFile {
    
    $e = SetupScenario2

    Assert-ItemExist     -Path     $e["filename1"]
    Assert-ItemExist     -Path     $e["filename2"]
    Assert-ItemExist     -Path     $e["filename13"]
    Assert-ItemExist     -Path     $e["filename23"]

    $result = Move-DocsFile 

    Assert-Count -Expected 6 -Presented $result

    Assert-ItemNotExist     -Path     $e["filename1"]
    Assert-ItemNotExist     -Path     $e["filename2"]
    Assert-ItemNotExist     -Path     $e["filename13"]
    Assert-ItemNotExist     -Path     $e["filename23"]

    Assert-AreEqual      -Expected "Test1"              -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
    Assert-AreEqual      -Expected "Test2"              -Presented $result[1].Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]      -Presented $result[1].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[1].Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $result[1].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName2"]
    
    Assert-AreEqual      -Expected "Test1"              -Presented $result[2].Owner; 
    Assert-AreEqualPath  -Expected $e["filename13"]     -Presented $result[2].Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[2].Status 
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[2].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName13"]
    
    Assert-AreEqual      -Expected "Test2"              -Presented $result[3].Owner; 
    Assert-AreEqualPath  -Expected $e["filename23"]     -Presented $result[3].Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[3].Status 
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $result[3].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName23"]

    Assert-AreEqual      -Expected "OtherOwner"         -Presented $result[4].Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner1"] -Presented $result[4].Name;
    Assert-AreEqualPath  -Expected "Unknown"            -Presented $result[4].Status 
    Assert-AreEqualPath  -Expected ""                   -Presented $result[4].Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner1"]

    Assert-AreEqual      -Expected "OtherOwner"         -Presented $result[5].Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner2"] -Presented $result[5].Name;
    Assert-AreEqualPath  -Expected "Unknown"            -Presented $result[5].Status 
    Assert-AreEqualPath  -Expected ""                   -Presented $result[5].Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner2"]

} 

function DocsTest_MoveFile_Path {
    
    $e = SetupScenario2

    Assert-ItemExist     -Path     $e["filename1"]

    $result = Move-DocsFile -Path $e["filename1"]

    Assert-ItemNotExist  -Path     $e["filename1"]
    
    Assert-Count         -Expected 1                    -Presented $result
    Assert-AreEqual      -Expected "Test1"              -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
}

function DocsTest_MoveFile_Path_WhatIf {
    
    $e = SetupScenario2

    Assert-ItemExist     -Path     $e["filename1"]

    $result = Move-DocsFile -Path $e["filename1"] -WhatIf

    
    Assert-ItemExist     -Path     $e["filename1"]
    
    Assert-Count         -Expected 1                    -Presented $result
    Assert-AreEqual      -Expected "Test1"              -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[0].Destination; 
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

    Assert-AreEqual      -Expected "Test1"               -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]       -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "ARE_EQUAL" -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]    -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
    Assert-AreEqual      -Expected "Test2"               -Presented $result[1].Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]       -Presented $result[1].Name; 
    Assert-AreEqualPath  -Expected "ARE_NOT_EQUAL" -Presented $result[1].Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]    -Presented $result[1].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName2"]

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

function DocsTest_ConvertToDocName{

    #SetupScenario2
    #Get-DocNamePattern -Owner test2 | Get-Item | Convertto-docsdocName

    $result = ConvertTo-DocsDocName -Path "121212-owner-target-32#32-What-Desc-dasd-asdasd-asddas.txt"  
    Assert-AreEqual -Expected "121212" -Presented $result.Date
    Assert-AreEqual -Expected "owner" -Presented $result.Owner
    Assert-AreEqual -Expected "target" -Presented $result.Target
    Assert-AreEqual -Expected "32#32" -Presented $result.Amount
    Assert-AreEqual -Expected "What" -Presented $result.What
    Assert-AreEqual -Expected "Desc-dasd-asdasd-asddas" -Presented $result.Description

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

    $files = Get-ChildItem -Path 12*

    # Single file 
    @($oldName1,$oldName3) | Rename-DocsFile -Owner kk
    Assert-ItemExist    -Path $newName1
    Assert-ItemNotExist    -Path $newName2
    Assert-ItemExist    -Path $newName3
    Assert-Count -Expected 3 -Presented (Get-ChildItem)
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

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1.Name()
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13.Name()
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2.Name()
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23.Name()
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
    $Evidence["filename1"] = $filename1.Name()
    $Evidence["filename13"] = $filename13.Name()
    $Evidence["filename2"] = $filename2.Name()
    $Evidence["filename23"] = $filename23.Name()

    $FileFullName1 = Join-Path -Path $storefolder1 -ChildPath $FileName1.Name()
    $FileFullName13 = Join-Path -Path $storefolder1 -ChildPath $FileName13.Name()
    $FileFullName2 = Join-Path -Path $storefolder2 -ChildPath $FileName2.Name()
    $FileFullName23 = Join-Path -Path $storefolder2 -ChildPath $FileName23.Name()
    $FileFullName_fake1 = Join-Path -Path $storefolder1 -ChildPath "Test1-andnomore.txt"
    $FileFullName_fake2 = Join-Path -Path $storefolder2 -ChildPath "121212-fakename.txt"
    $Evidence["FileFullName1"] = $FileFullName1
    $Evidence["FileFullName13"] = $FileFullName13
    $Evidence["FileFullName2"] = $FileFullName2
    $Evidence["FileFullName23"] = $FileFullName23
    $Evidence["FileFullName_fake1"] = $FileFullName_fake1
    $Evidence["FileFullName_fake2"] = $FileFullName_fake2

    "This content is fake" | Out-File -FilePath $FileName1.Name()
    "This content is fake" | Out-File -FilePath $FileName13.Name()
    "This content is fake" | Out-File -FilePath $FileName2.Name()
    "This content is fake" | Out-File -FilePath $FileName23.Name()

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