[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]Param()

$poshdotnet_moduleName = 'posh-dotnet'
Import-Module (Join-Path $PSScriptRoot "$poshdotnet_moduleName.psm1")
try {
    TabExpansion2 -inputScript "dotnet b" -cursorColumn 8 -ErrorAction Ignore # the first time it fails, this is a TODO item
}
catch {

}

Describe 'TabExpansion2' {

    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet b" -cursorColumn 8
        $commandCompletion.CompletionMatches.CompletionText | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet build --c" -cursorColumn 16
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--configuration'
    }

}