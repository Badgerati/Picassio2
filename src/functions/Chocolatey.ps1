
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


<#
#>
function Install-PicassioChocoPackage
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [ValidateNotNullOrEmpty()]
        [string]
        $Version = 'latest',

        [string]
        $Source = $null,

        [string]
        $Arguments = $null,

        [switch]
        $Force
    )

    # check if shell is elevated
    if (!(Test-PicassioAdminUser))
    {
        throw 'Chocolatey needs to be run using elevated permissions'
    }

    # check if chocolatey is installed
    if (!(Test-PicassioSoftware -Check 'choco -v'))
    {
        Install-PicassioChoco
    }

    # get list of already installed software
    $list = Get-PicassioChocoList

    Write-PicassioInfo "Installing Chocolatey package: $($Name) [$Version]"

    # check if the software and it's version are already installed
    if ($list.ContainsKey($Name) -and $list[$Name] -ieq $Version -and !$Force)
    {
        Write-PicassioSuccess "Package for $($Name) [$($Version)] already installed"
        return
    }

    # build arguments
    if ($Version -ine 'latest')
    {
        $versionArg = "--version $($Version)"
    }

    if (!(Test-PicassioEmpty $Source))
    {
        $sourceArg = "-s '$($Source)'"
    }

    if ($Force)
    {
        $forceArg = '-f'
    }

    # if it's not installed or we have a specific version, just install it normally
    if (!$list.ContainsKey($Name) -or $Version -ine 'latest')
    {
        $output = choco install $Name -y $versionArg $sourceArg $forceArg $Arguments
    }

    # else it is installed, and version is latest then upgrade
    elseif ($list.ContainsKey($Name) -and $Version -ieq 'latest')
    {
        $output = choco upgrade $Name -y $versionArg $sourceArg $forceArg $Arguments
    }

    # check if the install failed
    if (!$?)
    {
        $fail = !($output -ilike '*has been successfully installed*')

        if ($fail)
        {
            Write-PicassioWarning "`n`n$($output)`n"
            throw "Failed to install package: $($Name) [$Version]"
        }
    }

    # check if a reboot could be required
    if ($output -ilike '*exit code 3010*')
    {
        Write-PicassioWarning "A reboot is required for $($Name)"
    }
    
    Write-PicassioSuccess "Package installed"
}


<#
#>
function Uninstall-PicassioChocoPackage
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [string]
        $Arguments = $null,

        [switch]
        $Dependencies
    )

    # check if shell is elevated
    if (!(Test-PicassioAdminUser))
    {
        throw 'Chocolatey needs to be run using elevated permissions'
    }

    # check if chocolatey is installed
    if (!(Test-PicassioSoftware -Check 'choco -v'))
    {
        Install-PicassioChoco
    }

    # get list of already installed software
    $list = Get-PicassioChocoList

    Write-PicassioInfo "Uninstalling Chocolatey package: $($Name)"

    # check if the software is already uninstalled
    if (!$list.ContainsKey($Name))
    {
        Write-PicassioSuccess "Package for $($Name) is already uninstalled"
        return
    }

    # build arguments
    if ($Dependencies)
    {
        $dependArg = '-x'
    }

    # uninstall the package
    $output = choco uninstall $Name -y $dependArg $Arguments

    # check if the uninstall failed
    if (!$?)
    {
        $fail = !($output -ilike '*has been successfully uninstalled*' -or $output -ilike '*Cannot uninstall a non-existent package*')

        if ($fail)
        {
            Write-PicassioWarning "`n`n$($output)`n"
            throw "Failed to uninstall package: $($Name)"
        }
    }

    # check if a reboot could be required
    if ($output -ilike '*exit code 3010*')
    {
        Write-PicassioWarning "A reboot is required for $($Name)"
    }
    
    Write-PicassioSuccess "Package uninstalled"
}


<#
#>
function Get-PicassioChocoList
{
    # check if chocolatey is installed
    if (!(Test-PicassioSoftware -Check 'choco -v'))
    {
        Install-PicassioChoco
    }

    $map = @{}
    
    (choco list -lo) | ForEach-Object {
        $row = $_ -ireplace ' Downloads cached for licensed users', ''
        if ($row -imatch '^(?<name>.*?)\s+((?<version>[\d\.]+)(\s+\[Approved\]){0,1}(\s+-\s+Possibly broken){0,1}).*?$')
        {
            $map[$Matches['name']] = $Matches['version']
        }
    }

    return $map
}