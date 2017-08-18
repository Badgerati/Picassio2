
<#
#>
function Get-PicassioRandomName
{
    param (
        [int]
        $Length = 5
    )

    $value = (65..90) | Get-Random -Count $Length | ForEach-Object { [char]$_ }
    return [String]::Concat($value)
}


<#
#>
function Format-PicassioJsonString
{
    param (
        [string]
        $Value
    )

    if (Test-PicassioEmpty $Value)
    {
        return $Value
    }

    $Value = $Value -ireplace '\\', '/'
    $Value = $Value -ireplace '"', "'"
    $Value = $Value -ireplace '&', ' and '
    $Value = $Value -ireplace '#', ''

    return $Value
}