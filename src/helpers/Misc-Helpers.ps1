
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


<#
#>
function ConvertFrom-PicassioJson
{
    param (
        [string]
        $Path,

        [string]
        $Value
    )

    if (!(Test-PicassioEmpty $Path) -and !(Test-PicassioPath $Path))
    {
        $Value = Get-Content $Path -Force -ErrorAction Stop
    }

    if (Test-PicassioEmpty $Value)
    {
        return $null
    }

    Add-Type -Assembly System.Web.Extensions
    $js = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $js.MaxJsonLength = [int]::MaxValue

    $json = $js.DeserializeObject($Value)
    if (!$?)
    {
        throw 'Failed to deserialise the JSON value supplied'
    }

    return $json
}


<#
#>
function Set-PicassioSafeguard
{
    param (
        [string]
        $Value,

        [string]
        $Default = $null
    )

    if ($Value -eq $null)
    {
        $Value = [string]::Empty
        if ($Default -ne $null)
        {
            $Value = $Default
        }
    }

    return $Value
}