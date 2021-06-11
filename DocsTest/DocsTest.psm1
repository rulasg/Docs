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

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive
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

function DocsTest_GetStores {
    
    ResetDocsList

    Add-DocsStore -Owner "SampleOwner" -Path . -IsRecursive
    Add-DocsStore -Owner "SampleOwner2" -Path "$Home/fackefolder"

    $result = Get-DocsStores

    Assert-Count -Expected 2 -Presented $result

    $o1 = $result[0]
    Assert-AreEqual -Expected "SampleOwner" -Presented $o1.Owner
    Assert-IsTrue -Condition $o1.IsRecursive
    Assert-AreEqualPath -Expected "." -Presented $o1.Path
    Assert-IsTrue -Condition $o1.Exist

    $o2 = $result[1]
    Assert-AreEqual -Expected "SampleOwner2" -Presented $o2.Owner
    Assert-IsFalse -Condition $o2.IsRecursive
    Assert-AreEqualPath -Expected "$Home/fackefolder" -Presented $o2.Path
    Assert-IsFalse -Condition $o2.Exist

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


Export-ModuleMember -Function DocsTest_*