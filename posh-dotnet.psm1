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

# extracts help for dotnet cli v2
function Get-HelpTextV2HashTable
{
    # since commandElements is a strongly typed ast (that has already been parsed), the command injection risk has been mitigated
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    Param
    (
        [System.Management.Automation.Language.StringConstantExpressionAst[]]$commandElements,
        $completionList
    )

    $help = Invoke-Expression "$([string]::Join(" ", $CommandElements)) --help"
    $commandHelp = @{}
    foreach ($command in $completionList)
    {
        $help | ForEach-Object {
            # a command help ends with ',' or ' '
            if ($_.Length -gt 2 -and $_.StartsWith("  ") -and ( $_.Remove(0, 2).StartsWith("$command ") -or $_.Remove(0, 2).StartsWith("$command,")))
            {
                $helpText =  $_.TrimStart().Remove(0, $Command.Length).TrimStart()
                $commandHelp.Add($command, $helpText)
            }
            elseif ($_.Length -gt 2 -and -not $_.StartsWith("  ") -and  $_.Contains(" $command ")) # dotnet new
            {
                $helpText =  ($_ -split "  ")[0]
                $commandHelp.Add($command, $helpText)
            }
        }
    }
    return $commandHelp
}

$completion_Dotnet = {
    param($commandName, $commandAst, $cursorPosition)

    [int]$dotnetMajorVersion = [int]::Parse(((dotnet --version)[0]))
    if ($dotnetMajorVersion -ge 2)
    {
        # Starting from version 2, the dotnet CLI offers a dedicated complete command. See https://github.com/dotnet/cli/blob/master/Documentation/general/tab-completion.md
        $completionList = dotnet complete --position $cursorPosition "$commandAst"
        # the user has not given any details about the next command to be tab completed
        if ([string]::IsNullOrWhiteSpace($commandName))
        {
            [hashtable]$helpList = Get-HelpTextV2HashTable $commandAst.CommandElements $completionList
            $completionList | ForEach-Object { if ($null -eq $helpList[$_]){ $helpList.Add($_,$_)} }
            $completionList | Sort-Object | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $helpList[$_])  }
        }
        else
        {
            $completionList = $completionList | Where-Object {
                $_.StartsWith($commandAst.CommandElements[$commandAst.CommandElements.Count-1])
            }
            # do not use last incomplete command
            $commandElementsExceptLastOne = $commandAst.CommandElements | Select-Object -First ($commandAst.CommandElements.Count-1)
            $helpList = Get-HelpTextV2HashTable $commandElementsExceptLastOne $completionList
        }
        $completionList | ForEach-Object { if ($null -eq $helpList[$_]){ $helpList.Add($_,$_)} } # add missing help entries that could not get parsed
        $completionList | Sort-Object | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $helpList[$_])  }   
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
                                $options += $Matches[1].Split('|') 
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
