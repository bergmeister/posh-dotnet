# posh-dotnet [![Build status](https://ci.appveyor.com/api/projects/status/2gempqlml4wp9u4w/branch/master?svg=true)](https://ci.appveyor.com/project/bergmeister/posh-dotnet/branch/master) [![AppVeyor tests](http://flauschig.ch/batch.php?type=tests&account=bergmeister&slug=posh-dotnet)](https://ci.appveyor.com/project/bergmeister/posh-dotnet/build/tests) [![codecov](https://codecov.io/gh/bergmeister/posh-dotnet/branch/master/graph/badge.svg)](https://codecov.io/gh/bergmeister/posh-dotnet) [![PSScriptAnalyzer](https://img.shields.io/badge/Linter-PSScriptAnalyzer-blue.svg)](http://google.com) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

`Windows PowerShell` tab completion for the dotnet CLI

## Usage

Just import the self containted `posh-dotnet.psm1` module of this repo, e.g.:

````powershell
git clone https://github.com/bergmeister/posh-dotnet.git
cd posh-dotnet
Import-Module .\posh-dotnet.psm1
````

The first time you use it in a new shell you have to press tab twice but afterwards it works as expected.

It has been tested on `Windows PowerShell 5.1` using the dotnet CLI version 2.0.