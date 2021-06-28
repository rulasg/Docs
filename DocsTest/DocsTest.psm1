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

function DocsTest_ResetStores {

    $TestStoreList = ResetDocsList -PassThru
    Add-DocsStore -Owner "SampleOwner" -Path "." -IsRecursive
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

    $result = Get-DocsStore

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

    $result2 = Get-DocsStore -Owner "SampleOwner2"
    
    Assert-Count -Expected 1 -Presented $result2

    $o = $result2

    Assert-AreEqual -Expected "SampleOwner2" -Presented $o.Owner
    Assert-IsTrue -Condition $o.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder2" -Presented $o.Path
    Assert-IsFalse -Condition $o.Exist

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

function DocsTest_GetOwners_Filtered {
    
    ResetDocsList

    Add-DocsStore -Owner "kk2k2" -Path . -IsRecursive
    Add-DocsStore -Owner "kk3k2" -Path "$Home/fackefolder"
    Add-DocsStore -Owner "kt2k2" -Path . -IsRecursive

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
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[0]
    Assert-AreEqualPath -Expected $FileFullName2  -Presented $result[1]

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
    Assert-AreEqual -Expected $FileName1  -Presented $result[0].Name
    Assert-AreEqual -Expected $FileName2  -Presented $result[1].Name
    Assert-AreEqual -Expected $FileName13  -Presented $result[2].Name
    Assert-AreEqual -Expected $FileName23  -Presented $result[3].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[4].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[5].Name

    $result = Get-DocsFile -Target Testing3

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqual -Expected $FileName13  -Presented $result[0].Name
    Assert-AreEqual -Expected $FileName23  -Presented $result[1].Name
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
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[0].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[1].Name
    
    $result = Get-DocsFile -Recurse

    Assert-Count -Expected 6 -Presented $result
    Assert-AreEqual -Expected "122012-OtherOwner-Description.txt" -Presented $result[0].Name
    Assert-AreEqual -Expected "122012-OtherOwner-Target-Description.txt" -Presented $result[1].Name
    Assert-AreEqual -Expected $FileName2  -Presented $result[2].Name
    Assert-AreEqual -Expected $FileName23  -Presented $result[3].Name
    Assert-AreEqual -Expected $FileName1  -Presented $result[4].Name
    Assert-AreEqual -Expected $FileName13  -Presented $result[5].Name
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
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    
    $result = Get-DocsFile -Path $storefolder1

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName

    $result =  $storefolder1 | Get-DocsFile

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName

    $result =  ($storefolder1,$localfile ) | Get-DocsFile 

    Assert-Count -Expected 3 -Presented $result
    Assert-AreEqualPath -Expected $FileFullName1 -Presented $result[0].FullName
    Assert-AreEqualPath -Expected $FileFullName13 -Presented $result[1].FullName
    Assert-AreEqualPath -Expected $localfile  -Presented $result[2].FullName
}

function DocsTest_GetFile_StoresWithSamePath{
    $e = SetupScenario1

    Add-DocsStore -Owner Test22 -Path $e["storefolder2"]

    $result = Find-DocsFile -Owner Test2

    Assert-Count -Expected 2 -Presented $result
    Assert-AreEqual -Expected $e["filename2"] -Presented $result[0].Name
    Assert-AreEqual -Expected $e["filename23"] -Presented $result[1].Name
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

    Assert-AreEqual      -Expected "LocalOwner"         -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $filename            -Presented $result[0].Name;
    Assert-AreEqualPath  -Expected "FOLDER_NOT_FOUND" -Presented $result[0].Status 
    Assert-AreEqualPath  -Expected ""                   -Presented $result[0].Destination; 
    Assert-ItemExist     -Path $filename

    Assert-AreEqual      -Expected "Test1"              -Presented $result[1].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result[1].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[1].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[1].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
    Assert-AreEqual      -Expected "Test2"              -Presented $result[2].Owner; 
    Assert-AreEqualPath  -Expected $e["filename2"]      -Presented $result[2].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[2].Status
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $result[2].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName2"]
    
    Assert-AreEqual      -Expected "Test1"              -Presented $result[3].Owner; 
    Assert-AreEqualPath  -Expected $e["filename13"]     -Presented $result[3].Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[3].Status 
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[3].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName13"]
    
    Assert-AreEqual      -Expected "Test2"              -Presented $result[4].Owner; 
    Assert-AreEqualPath  -Expected $e["filename23"]     -Presented $result[4].Name;
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[4].Status 
    Assert-AreEqualPath  -Expected $e["storefolder2"]   -Presented $result[4].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName23"]

    Assert-AreEqual      -Expected "OtherOwner"                    -Presented $result[5].Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner1"] -Presented $result[5].Name;
    Assert-AreEqualPath  -Expected "Unknown"                       -Presented $result[5].Status 
    Assert-AreEqualPath  -Expected ""                              -Presented $result[5].Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner1"]

    Assert-AreEqual      -Expected "OtherOwner"                    -Presented $result[6].Owner; 
    Assert-AreEqualPath  -Expected $e["FileNameLocal_OtherOWner2"] -Presented $result[6].Name;
    Assert-AreEqualPath  -Expected "Unknown"                       -Presented $result[6].Status 
    Assert-AreEqualPath  -Expected ""                              -Presented $result[6].Destination; 
    Assert-ItemExist     -Path     $e["FileNameLocal_OtherOWner2"]

} 

function DocsTest_MoveFileItem{
    
    $filename1 = "filename1.txt"
    $filename2 = "filename2.txt"
    $destinationFolder1 = Join-Path -Path '.' -ChildPath "childfolder1" -AdditionalChildPath "childfolder12"
    $destinationFolder2 = Join-Path -Path '.' -ChildPath "childfolder1" -AdditionalChildPath "childfolder12"


    "some content" | Out-File -FilePath $filename1
    "some content" | Out-File -FilePath $filename2

    Assert-ItemExist -Path $filename1    
    Assert-ItemNotExist -Path $destinationFolder1

    $result = Move-DocsFileItem -Path $filename1 -Destination $destinationFolder1

    Assert-AreEqual -Expected FOLDER_NOT_FOUND -Presented $result
    Assert-ItemExist -Path $filename1    
    Assert-ItemNotExist -Path $destinationFolder1

    $null = New-Item -Path $destinationFolder1 -ItemType Directory
    $result = Move-DocsFileItem -Path $filename1 -Destination $destinationFolder1

    Assert-AreEqual -Expected MOVED -Presented $result
    Assert-ItemNotExist -Path $filename1    
    Assert-ItemExist -Path $destinationFolder1
    Assert-ItemExist -Path (Join-Path -Path $destinationFolder1 -ChildPath $filename1)

    $result = Move-DocsFileItem -Path $filename2 -Destination $destinationFolder2 -Force

    Assert-AreEqual -Expected MOVED -Presented $result
    Assert-ItemNotExist -Path $filename2    
    Assert-ItemExist -Path $destinationFolder2
    Assert-ItemExist -Path (Join-Path -Path $destinationFolder2 -ChildPath $filename2)
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

function DocsTest_MoveFile_Path_Recurse {
    
    $e = SetupScenario1
    
    $wrongFullName = Join-Path -Path $e["storefolder2"] -ChildPath $e["filename1"]
    $e["FileFullName1"] | Move-Item -Destination $e["storefolder2"]
    Assert-ItemExist     -Path     $wrongFullName
    
    $result = Move-DocsFile -Owner Test1 -Recurse
    
    Assert-Count         -Expected 2                    -Presented $result

    Assert-ItemNotExist  -Path     $wrongFullName 
    Assert-ItemExist     -Path     $e["FileFullName1"] 
    
    Assert-AreEqual      -Expected "Test1"              -Presented $result[0].Owner; 
    Assert-AreEqualPath  -Expected $e["filename1"]      -Presented $result[0].Name; 
    Assert-AreEqualPath  -Expected "MOVED"              -Presented $result[0].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[0].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName1"]
    
    Assert-AreEqual      -Expected "Test1"              -Presented $result[1].Owner; 
    Assert-AreEqualPath  -Expected $e["filename13"]      -Presented $result[1].Name; 
    Assert-AreEqualPath  -Expected "ARE_THE_SAME"              -Presented $result[1].Status
    Assert-AreEqualPath  -Expected $e["storefolder1"]   -Presented $result[1].Destination; 
    Assert-ItemExist     -Path     $e["FileFullName13"]
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
    Assert-IsNull -Object $dn.Date
    Assert-AreEqualPath -Expected (Get-TodayDateReverse) -Presented $result.Date
    
    # Owner
    Assert-IsNull -Object $dn.Owner
    Assert-AreEqualPath -Expected "rulasg" -Presented $result.Owner
    
    # Type
    Assert-IsNull -Object $dn.Type
    Assert-AreEqualPath -Expected "pdf" -Presented $result.Type
    
    # Description
    #   Default
    Assert-AreEqualPath -Expected "DESCRIPTION" -Presented $result.Description
}

function DocsTest_DocName_Name_Transformations_Description_Replacements{
        #   Replace " ", - , [ , ]

        $dn = New-DocsDocName -Description "something space"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something space" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space" -Presented $result.Description

        $dn = New-DocsDocName -Description "something-space"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something-space" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space" -Presented $result.Description

        $dn = New-DocsDocName -Description "something[space]"
        $result = $dn.Name() | ConvertTo-DocsDocName 
        Assert-AreEqualPath -Expected "something[space]" -Presented $dn.Description
        Assert-AreEqualPath -Expected "something_space_" -Presented $result.Description
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