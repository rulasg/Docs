[CmdletBinding()]
param ()

$ModuleName = "BaseSdk"

Import-Module -Name TestingHelper -Force

Test-Module -Name Docs 
