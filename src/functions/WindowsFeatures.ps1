
<#
#>
function Test-PicassioWindowsFeature
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $Optional,

        [switch]
        $ThrowIfNotExists
    )

    if ($Optional)
    {
        $exists = ((Get-WindowsOptionalFeature -Online -FeatureName $Name | Measure-Object).Count -gt 0)
    }
    else
    {
        $exists = ((Get-WindowsFeature -Name $Name | Measure-Object).Count -gt 0)
    }

    if (!$exists -and $ThrowIfNotExists)
    {
        throw "Windows $(if ($Optional) { 'Optional ' })Feature '$($Name)' does not exist"
    }
    
    return $exists
}


<#
#>
function Test-PicassioWindowsFeatureInstalled
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $Optional
    )

    if ($Optional)
    {
        return ((Get-WindowsOptionalFeature -Online -FeatureName $Name).State -ieq 'enabled')
    }
    else
    {
        return ((Get-WindowsFeature -Name $Name).Installed -eq $true)
    }
}


<#
#>
function Install-PicassioWindowsFeature
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $IncludeAllSubFeatures,

        [switch]
        $Optional
    )

    # ensure the feature actually exists
    Test-PicassioWindowsFeature -Name $Name -Optional:$Optional -ThrowIfNotExists | Out-Null

    # if it's already installed, just return
    if (Test-PicassioWindowsFeatureInstalled -Name $Name -Optional:$Optional)
    {
        Write-PicassioInfo "Windows $(if ($Optional) { 'Optional ' })Feature already installed: $($Name)"
        return
    }

    # uninstall the feature
    Write-PicassioInfo "Installing Windows $(if ($Optional) { 'Optional ' })Feature: $($Name)"

    if ($Optional)
    {
        Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName $Name `
            -All:$IncludeAllSubFeatures -ErrorAction Stop | Out-Null
    }
    else
    {
        Add-WindowsFeature -Name $Name -IncludeAllSubFeature:$IncludeAllSubFeatures `
            -IncludeManagementTools:$IncludeAllSubFeatures -ErrorAction Stop | Out-Null
    }

    Write-PicassioSuccess "$($Name) installed"
}


<#
#>
function Uninstall-PicassioWindowsFeature
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $IncludeAllSubFeatures,

        [switch]
        $Optional
    )

    # ensure the feature actually exists
    Test-PicassioWindowsFeature -Name $Name -Optional:$Optional -ThrowIfNotExists | Out-Null

    # if it's already uninstalled, just return
    if (!(Test-PicassioWindowsFeatureInstalled -Name $Name -Optional:$Optional))
    {
        Write-PicassioInfo "Windows $(if ($Optional) { 'Optional ' })Feature already uninstalled: $($Name)"
        return
    }

    # uninstall the feature
    Write-PicassioInfo "Uninstalling Windows $(if ($Optional) { 'Optional ' })Feature: $($Name)"
    
    if ($Optional)
    {
        Disable-WindowsOptionalFeature -Online -NoRestart -FeatureName $Name -ErrorAction Stop | Out-Null
    }
    else
    {
        Remove-WindowsFeature -Name $Name -IncludeManagementTools:$IncludeAllSubFeatures -ErrorAction Stop | Out-Null
    }

    Write-PicassioSuccess "$($Name) uninstalled"
}