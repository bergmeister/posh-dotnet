[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]Param()


Describe 'TabExpansion2' {
    
    $poshdotnet_moduleName = 'posh-dotnet'
    Import-Module (Join-Path $PSScriptRoot "$poshdotnet_moduleName.psd1")
    
    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet b" -cursorColumn 8
        $commandCompletion.CompletionMatches.CompletionText | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet build --c" -cursorColumn 16
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--configuration'
    }

}

Describe 'PSScriptAnalyzer' {
    It 'There are no PScriptAnalyzer warnings' {
        $results = Invoke-ScriptAnalyzer . -Recurse
        $results | Should Be $null
    }
}