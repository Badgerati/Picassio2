<#
    invokes cake build at the passed path
#>
function Invoke-PicassioCake
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        
        [ValidateNotNullOrEmpty()]
        [string]
        $CakeFile = 'build.cake'
    )

    # ensure that cake is installed
    Test-PicassioSoftware -Check 'cake -version' -Name 'cake' -ThrowIfNotExists | Out-Null

    # ensure that the path to run cake exists
    Test-PicassioPath -Path $Path -ThrowIfNotExists | Out-Null

    # ensure that the cake script we're about to run exists
    Test-PicassioPath -Path (Join-Path $Path $CakeFile) -ThrowIfNotExists | Out-Null

    try
    {
        Push-Location $Path
        Write-PicassioInfo "Running cake script: $($CakeFile)"

        Invoke-PicassioCommand -Command "cake $($CakeFile)"

        Write-PicassioSuccess 'Cake build complete'
    }
    finally
    {
        Pop-Location
    }
}