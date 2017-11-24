# posh-dotnet

`Windows PowerShell` tab completion for the dotnet CLI

## Usage

Just import the self containted `posh-dotnet.psm1` module of this repo, e.g.:

````powershell
git clone https://github.com/bergmeister/posh-dotnet.git
cd posh-dotnet
Import-Module .\posh-dotnet.psm1
````

The first time you use it in a new shell you have to press tab twice but afterwards it works as expected.

It has been tested on `Windows PowerShell 5.1`.