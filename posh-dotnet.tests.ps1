Import-Module (Join-Path $PSScriptRoot "posh-dotnet.psd1") 

Describe 'TabExpansion2 using latest CLI' {

    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet b" -cursorColumn 8
        $commandCompletion.CompletionMatches.CompletionText[0] | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet build --c" -cursorColumn 16
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--configuration'
    }

}

Describe 'TabExpansion2 using v1.0 CLI' {
    
    BeforeEach {
        $globalDotJson = @"
{
    "sdk": {
        "version": "1.0.0"
    }
}
"@
        $globalDotJson | Set-Content global.json
    }

    AfterEach {
        Remove-Item .\global.json
    }
    
    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet b" -cursorColumn 8
        $commandCompletion.CompletionMatches.CompletionText | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = TabExpansion2 -inputScript "dotnet build --b" -cursorColumn 16
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--build-profile'
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