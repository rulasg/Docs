[CmdletBinding()]
param ()

function Import-TestingHelper($Version){

    if (-not (import-Module TestingHelper -RequiredVersion $Version -PassThru -ErrorAction SilentlyContinue )) {
        Install-Module -Name TestingHelper -Force -RequiredVersion $Version
        Import-Module -Name TestingHelper -Force -RequiredVersion $Version
    }
}

Import-TestingHelper -Version $Version

$psd = get-childitem -Path $PSScriptRoot -Filter *.psd1

Import-Module -Name $psd.FullName -Force

Test-Module -Name $psd.BaseName -TestName DocsTest_Find_MultiFolder_IsRecurse