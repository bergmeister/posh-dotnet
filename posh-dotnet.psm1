[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")] # needed to override tab completion
Param()

$global:DotnetCompletion = @{}
if ($global:DotnetCompletion.Count -eq 0)
{
    $global:DotnetCompletion["commands"] = @{}
    $global:DotnetCompletion["options"] = @()
        
    dotnet --help | ForEach-Object { 
        if ($_ -match "^\s{2,3}(\w+)\s+(.+)")
        {
            # The help includes some documentation that are indented the same way -> do not include them by assuming that commans start with a lower case
            if ($null -ne $Matches[1] -and $Matches[1].Count -gt 0 -and !([Char]::IsUpper($Matches[1][0])))
            {
                $global:DotnetCompletion["commands"][$Matches[1]] = @{}
                
                $currentCommand = $global:DotnetCompletion["commands"][$Matches[1]]
                $currentCommand["options"] = @()
            }
        }
        elseif ($_ -match $flagRegex)
        {
            $global:DotnetCompletion["options"] += $Matches[1]
            if ($null -ne $Matches[2])
            {
                $global:DotnetCompletion["options"] += $Matches[2]
            }
        }
    }
}

$script:flagRegex = "^  (-[^, =]+),? ?(--[^= ]+)?"

function script:Get-AutoCompleteResult
{
    param([Parameter(ValueFromPipeline = $true)] $value)
    
    Process
    {
        New-Object System.Management.Automation.CompletionResult $value
    }
}

filter script:MatchingCommand($commandName)
{
    if ($_.StartsWith($commandName))
    {
        $_
    }
}

$completion_Dotnet = {
    param($commandName, $commandAst, $cursorPosition)

    [int]$dotnetMajorVersion = [int]::Parse(((dotnet --version)[0]))
    if ($dotnetMajorVersion -ge 2)
    {
        # Starting from version 2, the dotnet CLI offers a dedicated complete command. See https://github.com/dotnet/cli/blob/master/Documentation/general/tab-completion.md
        dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    else
    {
        $command = $null
        $commandParameters = @{}
        $state = "Unknown"
        $wordToComplete = $commandAst.CommandElements | Where-Object { $_.ToString() -eq $commandName } | Foreach-Object { $commandAst.CommandElements.IndexOf($_) }

        for ($i = 1; $i -lt $commandAst.CommandElements.Count; $i++)
        {
            $p = $commandAst.CommandElements[$i].ToString()

            if ($p.StartsWith("-"))
            {
                if ($state -eq "Unknown" -or $state -eq "Options")
                {
                    $commandParameters[$i] = "Option"
                    $state = "Options"
                }
                else
                {
                    $commandParameters[$i] = "CommandOption"
                    $state = "CommandOptions"
                }
            } 
            else 
            {
                $commandParameters[$i] = "Command"
                $command = $p
                $state = "CommandOptions"
            }
        }
        
        if ($wordToComplete -ne $null)
        {
            $commandToComplete = $commandParameters[$wordToComplete]
        }

        switch ($commandToComplete)
        {
            "Command" { $global:DotnetCompletion["commands"].Keys | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult }
            "Option" { $global:DotnetCompletion["options"] | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult }
            "CommandOption"
            { 
                $options = $global:DotnetCompletion["commands"][$command]["options"]
                if ($options.Count -eq 0)
                {
                    dotnet $command --help | ForEach-Object {
                        if ($_ -match $flagRegex)
                        {
                            if ($Matches[1].Contains('|'))
                            {
                                $Matches[1].Split('|') | ForEach-Object { $options += $_ }
                            }
                            else
                            {
                                $options += $Matches[1]
                                if ($Matches[2] -ne $null)
                                {
                                    $options += $Matches[2]
                                }
                            }
                        }
                        elseif ($_ -match "^  (-[^, =]+),? ?(-[^= ]+)?") # version 1.0 has -c|--configuration for some options like e.g. dotnet build --help
                        {
                            $options += $Matches[1]
                            if ($Matches[2] -ne $null)
                            {
                                $options += $Matches[2]
                            }
                        }
                    }
                }

                $global:DotnetCompletion["commands"][$command]["options"] = $options
                $options | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult
            }
            default { $global:DotnetCompletion["commands"].Keys | MatchingCommand -Command $commandName }
        }
    }
}


if (Get-Command Register-ArgumentCompleter -ea Ignore)
{
    Register-ArgumentCompleter -CommandName 'dotnet' -ScriptBlock $Completion_Dotnet -Native
}
else
{
    # in version 3 and 4 of PS, one needs to install TabExpansionPlusPlus for backcompat. No check for the psversion needed since the manifest does that already. 
    throw "Required module TabExpansionPlusPlus is not installed. Please install it using 'Install-Module TabExpansionPlusPlus'"    
}
