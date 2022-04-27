[CmdletBinding()]
param ()

$ModuleName = "Docs"

Import-Module -Name TestingHelper -Force

# Test-Module -Name $ModuleName 
Test-Module -Name $ModuleName 