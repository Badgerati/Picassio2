
<#
    Writes a general message to the console (colour: white)
#>
function Write-PicassioMessage
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -ForegroundColor White -NoNewline:$NoNewLine
}


<#
    Writes a success message to the console (colour: green)
#>
function Write-PicassioSuccess
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -ForegroundColor Green -NoNewline:$NoNewLine
}


<#
    Writes an error message to the console (colour: red)
#>
function Write-PicassioError
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine,

        [switch]
        $ThrowError
    )

    Write-Host $Message -ForegroundColor Red -NoNewline:$NoNewLine

    if ($ThrowError)
    {
        throw "$($Message)"
    }
}


<#
    Writes a warning message to the console (colour: yellow)
#>
function Write-PicassioWarning
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -ForegroundColor Yellow -NoNewline:$NoNewLine
}


<#
    Writes an informational message to the console (colour: cyan)
#>
function Write-PicassioInfo
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [switch]
        $NoNewLine
    )

    Write-Host $Message -ForegroundColor Cyan -NoNewline:$NoNewLine
}


<#
    Writes a passed exception type and message to the console (colour: red)
#>
function Write-PicassioException
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [exception]
        $Exception
    )

    Write-PicassioError $Exception.GetType().FullName
    Write-PicassioError $Exception.Message
}


<#
    Writes a header to the console (colour: magenta)
#>
function Write-PicassioHeader
{
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message
    )

    $count = (65 - $Message.Length)
    $output = "$($Message)>"
    
    if ($count -gt 0)
    {
        $padding = ('=' * $count)
        $output = "=$($Message)$($padding)>"
    }

    Write-Host ($output.ToUpperInvariant()) -ForegroundColor Magenta
}