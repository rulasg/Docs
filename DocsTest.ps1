[CmdletBinding()]
param ()

$ModuleName = "Docs"

Import-Module -Name TestingHelper -Force

# Test-Module -Name $ModuleName -TestName DocsTest_GetFile_Recursive
Test-Module -Name $ModuleName -TestName DocsTest_Find*
