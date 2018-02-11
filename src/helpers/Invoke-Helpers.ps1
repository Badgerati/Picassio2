
<#
    invokes a command/application using powershell or command prompt
#>
function Invoke-PicassioCommand
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Command,

        [string]
        $Path,

        [switch]
        $ShowFullOutput
    )

    Write-PicassioInfo "Running: $($Command)"

    if (!(Test-PicassioEmpty $Path))
    {
        Write-PicassioMessage "> Path: $($Path)"
    }

    try
    {
        if (!(Test-PicassioEmpty $Path))
        {
            Test-PicassioPath $Path -ThrowIfNotExists | Out-Null
            Push-Location $Path
        }

        $output = Invoke-Expression "$($Command)"

        $code = $LASTEXITCODE
        if (!$? -or $lastcode -ne 0)
        {
            if (!(Test-PicassioEmpty $output))
            {
                if (!$ShowFullOutput)
                {
                    $output = ($output | Select-Object -Last 200)
                }

                $output | ForEach-Object { Write-PicassioError $_ }
            }

            throw "Command failed to complete. Exit code: $code"
        }
    }
    finally
    {
        if (!(Test-PicassioEmpty $Path))
        {
            Pop-Location
        }
    }
}


<#
#>
function Invoke-PicassioWhich
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Command
    )

    return (Get-Command -Name $Command -ErrorAction SilentlyContinue).Definition
}


<#
#>
function Invoke-PicassioRestEndpoint
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Delete', 'Get', 'Head', 'Merge', 'Options', 'Patch', 'Post', 'Put', 'Trace')]
        [string]
        $Method,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [object]
        $Body = $null,

        [hashtable]
        $Headers = $null,

        [object]
        $ContentType = 'application/json'
    )

    $response = Invoke-WebRequest -Method $Method -Uri $Uri -Body $Body -Headers $Headers -ContentType $ContentType -UseBasicParsing -ErrorAction Stop
    return (ConvertFrom-PicassioJson -Value $response.Content)
}