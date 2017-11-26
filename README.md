# posh-dotnet [![Build status](https://ci.appveyor.com/api/projects/status/2gempqlml4wp9u4w/branch/master?svg=true)](https://ci.appveyor.com/project/bergmeister/posh-dotnet/branch/master) [![AppVeyor tests](http://flauschig.ch/batch.php?type=tests&account=bergmeister&slug=posh-dotnet)](https://ci.appveyor.com/project/bergmeister/posh-dotnet/build/tests) [![codecov](https://codecov.io/gh/bergmeister/posh-dotnet/branch/master/graph/badge.svg)](https://codecov.io/gh/bergmeister/posh-dotnet) [![PSScriptAnalyzer](https://img.shields.io/badge/Linter-PSScriptAnalyzer-blue.svg)](http://google.com) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

`PowerShell` tab completion for the [dotnet CLI](https://github.com/dotnet/cli).

![Tab completion demo](demo.gif)

## Installation

You can install it via the [PSGallery](https://www.powershellgallery.com/packages/posh-dotnet/)

````powershell
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Install-Module posh-dotnet -Force
}
else {
    Install-Module TabExpansionPlusPlus -Force
    Install-Module posh-dotnet -Force
}
````

Alternatively you can also use it directly from this repo

````powershell
git clone https://github.com/bergmeister/posh-dotnet.git
cd .\posh-dotnet
Import-Module .\posh-dotnet.psd1
````

## Usage

````powershell
Import-Module posh-dotnet
````

It has been tested using the dotnet CLI version 1.0.3 and 2.0.3 on `Windows PowerShell 5.1` and `PowerShell Core 6.0 RC` but it should also work down to version 3.0 of `PowerShell`.
