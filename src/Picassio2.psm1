
# get existing system functions from memory for later comparison
$systemFuncs = Get-ChildItem Function:


# load functions and helpers
$root = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
Get-ChildItem "$($root)\helpers\*.ps1" | Resolve-Path | ForEach-Object { . $_ }
Get-ChildItem "$($root)\functions\*.ps1" | Resolve-Path | ForEach-Object { . $_ }


# check if there are any extensions and load them
$ext = 'C:\Picassio2\Extensions'
if (Test-Path $ext)
{
    Get-ChildItem "$($ext)\*.ps1" | Resolve-Path | ForEach-Object { . $_ }
}


# get functions from memory and compare to existing to find new functions added
$picassioFuncs = Get-ChildItem Function: | Where-Object { $systemFuncs -notcontains $_ }


# export the module
Export-ModuleMember -Function ($picassioFuncs.Name)