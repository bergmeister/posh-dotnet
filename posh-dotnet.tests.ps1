[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]Param()


Describe 'TabExpansion2' {
    
    $poshdotnet_moduleName = 'posh-dotnet'
    # Note that the module does not get re-imported because removing the module would also remove the TabExpansion2 function
    Import-Module (Join-Path $PSScriptRoot "$poshdotnet_moduleName.psd1") 
    
    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet b" -cursorColumn 8
        $commandCompletion.CompletionMatches.CompletionText[0] | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet build --c" -cursorColumn 16
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--configuration'
    }

}

Describe 'PSScriptAnalyzer' {

    if ($null -eq (Get-Module PSScriptAnalyzer -ListAvailable)) {
        throw "PSScriptAnalyzer is not installed. Install it using 'Install-Module PSScriptAnalyzer' to be able to run this test"
    }

    It 'There are no PScriptAnalyzer warnings' {
        $results = Invoke-ScriptAnalyzer $PSScriptRoot -Recurse
        $results | Should Be $null
    }
}