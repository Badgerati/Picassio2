
<#
#>
function Test-PicassioProcess
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    return ((tasklist /FI "IMAGENAME eq $($Name)" | Where-Object { $_ -ilike "*$($Name)*" } | Measure-Object).Count -gt 0)
}


<#
#>
function Remove-PicassioProcess
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    if (Test-PicassioProcess $Name)
    {
        taskkill /F /IM $Name | Out-Null
    }
}