
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
        $Arguments,

        [switch]
        $ShowFullOutput,

        [switch]
        $UseCommandPrompt
    )

    Write-PicassioInfo "Running: $($Command) $($Arguments)"

    if ($UseCommandPrompt)
    {
        $output = cmd.exe /C "`"$($Command)`" $($Arguments)"
        $code = $LASTEXITCODE

        if ($code -ne 0)
        {
            if (!(Test-PicassioEmpty $output))
            {
                if (!$ShowFullOutput)
                {
                    $output = ($output | Select-Object -Last 200)
                }

                $output | ForEach-Object { Write-PicassioError $_ }
            }

            throw "Command '$($Command)' failed to complete. Exit code: $code"
        }
    }
    else
    {
        $output = powershell.exe /C "`"$($Command)`" $($Arguments)"

        if (!$?)
        {
            if (!(Test-PicassioEmpty $output))
            {
                if (!$ShowFullOutput)
                {
                    $output = ($output | Select-Object -Last 200)
                }

                $output | ForEach-Object { Write-PicassioError $_ }
            }

            throw "Command '$($Command)' failed to complete"
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

    return (Get-Command -Name $Command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition)
}


<#
#>
function Invoke-PicassioRestEndpoint
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Post', 'Get', 'Put', 'Patch', 'Delete')]
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