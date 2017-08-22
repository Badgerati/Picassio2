
<#
#>
function Install-PicassioChoco
{
    Write-PicassioInfo 'Installing Chocolatey'
    
    # check to see if choco is already installed
    if (Test-PicassioSoftware -Check 'choco -v')
    {
        Write-PicassioSuccess 'Chocolatey already installed'
        return
    }

    # check the current policy and set it appropriately
    $policies = @('Unrestricted', 'ByPass', 'AllSigned')
    $current = Get-ExecutionPolicy
    if ($policies -inotcontains $current)
    {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    }

    # install choco
    Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop | Out-Null

    # reset the policy
    Set-ExecutionPolicy -ExecutionPolicy $current -Force
    Write-PicassioSuccess 'Chocolatey installed'
}


<#
#>
function Disable-PicassioChocoShimming
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    # ensure the path exists
    Test-PicassioPath $Path -ThrowIfNotExists | Out-Null

    Write-PicassioInfo 'Create .ignore files of executables'
    Write-PicassioMessage "> Path: $($Path)"

    (Get-ChildItem "$($Path)\**\*.exe" -Recurse).FullName | ForEach-Object {
        Write-PicassioMessage "> $($_).ignore"
        New-Item -Path "$($_).ignore" -ItemType File -Force | Out-Null
    } | Out-Null
    
    Write-PicassioSuccess 'Ignore files created'
}