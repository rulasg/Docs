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

function DocsTest_Sample(){
    Assert-IsTrue -Condition $true
}