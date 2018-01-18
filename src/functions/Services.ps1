
<#
#>
function Get-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    return (Get-WmiObject -Class Win32_Service -Filter "Name='$($Name)'")
}


<#
#>
function Test-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $ThrowIfNotExists
    )

    $exists = ((Get-PicassioService -Name $Name) -ne $null)

    if (!$exists -and $ThrowIfNotExists)
    {
        throw "No service found for name: $($Name)"
    }

    return $exists
}


<#
#>
function New-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [string]
        $DisplayName = $null,

        [string]
        $Description = $null,

        [ValidateSet('Manual', 'Automatic')]
        [System.ServiceProcess.ServiceStartMode]
        $StartupType = 'Automatic',

        [pscredential]
        $Credentials = $null,

        [switch]
        $ThrowIfExists,

        [switch]
        $Start
    )

    # check if the service already exists
    $exists = Test-PicassioService -Name $Name

    # check if we need to throw an error when it already exists
    if ($exists -and $ThrowIfExists)
    {
        throw "A service with the following name already exists: $($Name)"
    }

    # if it already exists, just return
    if ($exists)
    {
        Write-PicassioInfo "Service already exists: $($Name)"

        if ($Start)
        {
            Start-PicassioService -Name $Name
        }

        return
    }

    # check that the service path exists
    Test-PicassioPath -Path $Path -ThrowIfNotExists | Out-Null

    # attempt to create the service
    Write-PicassioInfo "Creating new service: $($Name)"
    Write-PicassioMessage "> Path: $($Path)"

    if (Test-PicassioEmpty $DisplayName)
    {
        $DisplayName = $Name
    }

    if (Test-PicassioService $Description)
    {
        $Description = $Name
    }

    New-Service -Name $Name -DisplayName $DisplayName -BinaryPathName $Path -Description $Description `
        -StartupType $StartupType -Credential $Credentials -ErrorAction Stop | Out-Null
    
    if (!$?)
    {
        throw "Failed to create service: $($Name)"
    }

    # do we need to start the service?
    if ($Start)
    {
        Start-PicassioService -Name $Name
    }

    Write-PicassioSuccess 'Service created'
}


<#
#>
function Update-PicassioServicePath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [switch]
        $ThrowIfNotExists,

        [switch]
        $Start
    )

    # check if the service exists
    $exists = Test-PicassioService -Name $Name

    # check if we need to throw an error when it doesn't exists
    if (!$exists -and $ThrowIfNotExists)
    {
        throw "Service does not exist to have binary path updated: $($Name)"
    }

    # if it doesn't exist, just return
    if (!$exists)
    {
        Write-PicassioInfo "Service does not exist to have binary path updated: $($Name)"
        return
    }

    # check that the service path exists
    Test-PicassioPath -Path $Path -ThrowIfNotExists | Out-Null

    # first stop the servive
    Stop-PicassioService -Name $Name

    # attempt to update the service
    Write-PicassioInfo "Updating service: $($Name)"
    Write-PicassioMessage "> Path: $($Path)"

    sc.exe config "$($Name)" binPath= "$($Path)" | Out-Null

    if (!$?)
    {
        throw "Failed to update service: $($Name)"
    }

    # do we need to start the service?
    if ($Start)
    {
        Start-PicassioService -Name $Name
    }

    Write-PicassioSuccess 'Service path updated'
}


<#
#>
function Remove-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # check if the service already doesn't exist
    $service = Get-PicassioService -Name $Name
    
    # if it doesn't exist, just return
    if ($service -eq $null)
    {
        Write-PicassioInfo "Service already removed: $($Name)"
        return
    }

    # stop any instances of mmc - because windows is dumb
    Remove-PicassioProcess -Name 'mmc.exe'

    # stop the service
    Stop-PicassioService -Name $Name

    # remove the service
    Write-PicassioInfo "Removing service: $($Name)"
    $service.delete() | Out-Null
    if (!$?)
    {
        throw "Failed to remove service: $($Name)"
    }
    
    Write-PicassioSuccess 'Service removed'
}


<#
#>
function Start-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $Restart
    )

    # get the service
    $service = Get-PicassioService -Name $Name

    # if it doesn't exist, error
    if ($service -eq $null)
    {
        throw "Service does not exist to be started: $($Name)"
    }

    # if we're restarting, stop the service first
    if ($Restart -and $service.State -ine 'stopped`')
    {
        Stop-PicassioService -Name $Name
    }

    # start the service
    Write-PicassioInfo "Starting service: $($Name)"

    if ($service.State -ine 'running')
    {
        Start-Service -Name $Name -ErrorAction Stop | Out-Null
        if (!$?)
        {
            throw "Failed to start service: $($Name)"
        }
    }
    
    Write-PicassioSuccess "Service started"
}


<#
#>
function Stop-PicassioService
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $ThrowIfNotExists
    )

    # get the service
    $service = Get-PicassioService -Name $Name

    # if it doesn't exist, error
    if ($service -eq $null -and $ThrowIfNotExists)
    {
        throw "Service does not exist to be stopped: $($Name)"
    }

    if ($service -eq $null)
    {
        Write-PicassioInfo "Service does not exist to stop: $($Name)"
        return
    }

    # stop the service
    Write-PicassioInfo "Stopping service: $($Name)"

    if ($service.State -ine 'stopped')
    {
        Stop-Service -Name $Name -Force -ErrorAction Stop | Out-Null
        if (!$?)
        {
            throw "Failed to stop service: $($Name)"
        }
    }
    
    Write-PicassioSuccess "Service stopped"
}