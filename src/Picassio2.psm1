
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
# this will be used later to dynamically pass functions to "Invoke-Command"
# this is so you don't have to install Picassio2 on every machine
$picassioFuncs = Get-ChildItem Function: | Where-Object { $systemFuncs -notcontains $_ }


# returns a list of all Picassio functions' ScriptBlocks
#function Get-PicassioFunctions()
#{
#    $funcs = [string]::Empty
#
#    $picassioFuncs | ForEach-Object {
#        $funcs += ("function $($_.Name) {$($_.ScriptBlock)}`n")
#    }
#
#    return $funcs # $picassioFuncs.ScriptBlock -join "`n"
#}


# export the module
Export-ModuleMember -Function ($picassioFuncs.Name)