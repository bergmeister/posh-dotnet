[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")] # needed to override tab completion
Param()

$global:DotnetCompletion = @{}

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
            if ($state -ne "CommandOptions")
            {
                $commandParameters[$i] = "Command"
                $command = $p
                $state = "CommandOptions"
            } 
            else 
            {
                $commandParameters[$i] = "CommandOther"
            }
        }
    }

    if ($global:DotnetCompletion.Count -eq 0)
    {
        $global:DotnetCompletion["commands"] = @{}
        $global:DotnetCompletion["options"] = @()
        
        dotnet --help | ForEach-Object {
            Write-Output $_
            if ($_ -match "^\s{2,3}(\w+)\s+(.+)")
            {
                $global:DotnetCompletion["commands"][$Matches[1]] = @{}
                
                $currentCommand = $global:DotnetCompletion["commands"][$Matches[1]]
                $currentCommand["options"] = @()
            }
            elseif ($_ -match $flagRegex)
            {
                $global:DotnetCompletion["options"] += $Matches[1]
                if ($Matches[2] -ne $null)
                {
                    $global:DotnetCompletion["options"] += $Matches[2]
                }
            }
        }

    }
    
    if ($wordToComplete -eq $null)
    {
        $commandToComplete = "Command"
        if ($commandParameters.Count -gt 0)
        {
            if ($commandParameters[$commandParameters.Count] -eq "Command")
            {
                $commandToComplete = "CommandOther"
            }
        } 
    }
    else
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
        "CommandOther"
        {
            # $filter = $null
            switch ($command)
            {
                "start" { FilterContainers $commandName "status=created", "status=exited" }
                "stop" { FilterContainers $commandName "status=running" }
                { @("run", "rmi", "history", "push", "save", "tag") -contains $_ } { CompleteImages $commandName }
                default { FilterContainers $commandName }
            }
            
        }
        default { $global:DotnetCompletion["commands"].Keys | MatchingCommand -Command $commandName }
    }
}

function script:FilterContainers($commandName, $filter)
{
    Get-Containers $filter | MatchingCommand -Command $commandName | Sort-Object | Get-AutoCompleteResult
}

function script:CompleteImages($commandName)
{
    if ($commandName.Contains(":"))
    {
        Get-Images | ForEach-Object { $_.Repository + ":" + $_.Tag } | MatchingCommand -Command $commandName | Sort-Object -Unique | Get-AutoCompleteResult
    } 
    else 
    {
        Get-Images | Select-Object -ExpandProperty Repository | MatchingCommand -Command $commandName |  Sort-Object -Unique | Get-AutoCompleteResult
    }
}

# Register the TabExpension2 function
if (-not $global:options) { $global:options = @{CustomArgumentCompleters = @{}; NativeArgumentCompleters = @{}}
}
$global:options['NativeArgumentCompleters']['dotnet'] = $Completion_Dotnet

$function:tabexpansion2 = $function:tabexpansion2 -replace 'End\r\n{', 'End { if ($null -ne $options) { $options += $global:options} else {$options = $global:options}'
