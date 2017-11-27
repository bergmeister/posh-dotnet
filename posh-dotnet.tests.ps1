Import-Module (Join-Path $PSScriptRoot "posh-dotnet.psd1") 

Function Invoke-TabExpansion([string]$InputScript) {
    TabExpansion2 -inputScript $InputScript -cursorColumn $InputScript.Length
}

Describe 'TabExpansion2 using latest CLI' {

    It "dotnet gets expanded to dotnet add" {
        $commandCompletion = Invoke-TabExpansion "dotnet "
        $commandCompletion.CompletionMatches.CompletionText[0] | Should Be 'add'
    }

    It "dotnet b gets expanded to dotnet build" {
        $commandCompletion = Invoke-TabExpansion "dotnet b"
        $commandCompletion.CompletionMatches.CompletionText | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration" {
        $commandCompletion = Invoke-TabExpansion "dotnet build --c"
        $commandCompletion.CompletionMatches.CompletionText | Should Be '--configuration'
    }

    It "Commands cannot be injected" {
        $harmFulCommand = {mkdir injected}
        Invoke-TabExpansion "dotnet $harmFulCommand"
        Invoke-TabExpansion "dotnet $harmFulCommand"
        Invoke-TabExpansion "dotnet --help; $harmFulCommand;"
        Invoke-TabExpansion "dotnet build; $harmFulCommand;"
        Invoke-TabExpansion "dotnet build --help; $harmFulCommand;"
        Test-Path injected | Should Be $false
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
        $commandCompletion = Invoke-TabExpansion "dotnet b"
        $commandCompletion.CompletionMatches.CompletionText | Should Be 'build'
    }

    It "dotnet build --c gets expanded to dotnet build --configuration " {
        $commandCompletion = Invoke-TabExpansion "dotnet build --c"
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