[CmdletBinding()]
param ()

function Import-TestingHelper($Version){
    
    if (-not (import-Module TestingHelper -RequiredVersion $Version -PassThru -ErrorAction SilentlyContinue )) {
        Install-Module -Name TestingHelper -Force -RequiredVersion $Version
    }
    
    Import-Module -Name TestingHelper -Force -RequiredVersion $Version
}

$ModuleName = "Docs"

Import-TestingHelper -Version $TestingHelperRequiredVersion

Import-Module ./Docs.psd1 -Force

# Test-Module -Name $ModuleName -TestName DocsTest_GetFile_Recursive
Test-Module -Name $ModuleName -Verbose
