
<#
#>
function Add-PicassioIISHosts
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPAddress,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $HostName
    )

    # check hosts file exists
    $hostsFile = "$($env:windir)\System32\drivers\etc\hosts"
    Test-PicassioPath $hostsFile -ThrowIfNotExists | Out-Null

    Write-PicassioInfo "Adding the following entry to the hosts file: '$($IPAddress) - $($HostName)'"

    # get regex for finding existing entries
    $rgxEntry = "^.*?$($IPAddress).*?$($Hostname).*?$"

    # check to see if the entry already exists
    $entryExists = (Get-Content $hostsFile | Where-Object { $_ -imatch $rgxEntry } | Measure-Object).Count

    # if it doesn't exist, add it
    if ($entryExists -eq 0)
    {
        ("`n$($IPAddress)`t`t$($Hostname)") | Out-File -FilePath $hostsFile -Encoding ASCII -Append
    }

    Write-PicassioSuccess 'Hosts entry added'
}


<#
#>
function Remove-PicassioIISHosts
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPAddress,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $HostName
    )

    # check hosts file exists
    $hostsFile = "$($env:windir)\System32\drivers\etc\hosts"
    Test-PicassioPath $hostsFile -ThrowIfNotExists | Out-Null

    Write-PicassioInfo "Removing the following entry from the hosts file: '$($IPAddress) - $($HostName)'"

    # get regex for finding existing entries
    $rgxEntry = "^.*?$($IPAddress).*?$($Hostname).*?$"

    # add lines back into the hosts file where they don't match the regex
    Get-Content $hostsFile | Where-Object { $_ -inotmatch $rgxEntry } | Out-File -FilePath $hostsFile -Encoding ASCII

    Write-PicassioSuccess 'Hosts entry removed'
}


<#
#>
function Get-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check the site exists
    if (!(Test-PicassioPath "IIS:\Sites\$($SiteName)"))
    {
        return $null
    }

    # return the application pool's name for the site
    return (Get-Item "IIS:\Sites\$($SiteName)" | Select-Object -ExpandProperty applicationPool)
}


<#
#>
function Test-PicassioIISAppPool
{
    param (
        [string]
        $SiteName,

        [string]
        $AppPoolName,
        
        [switch]
        $ThrowIfNotExists
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure at least one of site/app name was passed
    if ((Test-PicassioEmpty $SiteName) -and (Test-PicassioEmpty $AppPoolName))
    {
        throw 'At least one of SiteName or AppPoolName must be passed for testing application pools'
    }

    $exists = $false

    # check the app pool exists by website
    if (!(Test-PicassioEmpty $SiteName))
    {
        $appPool = (Get-PicassioIISAppPool -SiteName $SiteName)
        $exists = (![string]::IsNullOrWhiteSpace($appPool))
        
        if (!$exists -and $ThrowIfNotExists)
        {
            throw "No Application Pool in IIS found for website: $($SiteName)"
        }
    }

    # check the app pool exists by app pool
    elseif (!(Test-PicassioEmpty $AppPoolName))
    {
        $exists = (Test-PicassioPath "IIS:\AppPools\$($AppPoolName)")

        if (!$exists -and $ThrowIfNotExists)
        {
            throw "No Application Pool in IIS found: $($AppPoolName)"
        }
    }

    return $exists
}


<#
#>
function Restart-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the app pool exists
    Test-PicassioIISAppPool -AppPoolName $Name -ThrowIfNotExists | Out-Null

    # restart the app pool
    Write-PicassioInfo "Recycling application pool: $($Name)"
    Restart-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application pool recycled"
}


<#
#>
function Start-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $Restart
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the app pool exists
    Test-PicassioIISAppPool -AppPoolName $Name -ThrowIfNotExists | Out-Null
    
    # are we restarting?
    if ($Restart)
    {
        Stop-PicassioIISAppPool -Name $Name
    }

    # start the app pool
    Write-PicassioInfo "Starting application pool: $($Name)"
    Start-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application pool started"
}


<#
#>
function Stop-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the app pool exists
    Test-PicassioIISAppPool -AppPoolName $Name -ThrowIfNotExists | Out-Null

    # stop the app pool
    Write-PicassioInfo "Stopping application pool: $($Name)"
    Stop-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application pool stopped"
}


<#
#>
function Remove-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check if the app pool exists, if not just return
    if (!(Test-PicassioIISAppPool -AppPoolName $Name))
    {
        Write-PicassioInfo "Application Pool already removed: $($Name)"
        return
    }

    # remove the app pool
    Write-PicassioInfo "Removing application pool: $($Name)"
    Remove-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application pool removed"
}


<#
#>
function New-PicassioIISAppPool
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [ValidateSet('v1.1', 'v2.0', 'v4.0')]
        [string]
        $RuntimeVersion = 'v4.0',

        [ValidateSet('LocalSystem', 'LocalService', 'NetworkService', 'SpecificUser', 'ApplicationPoolIdentity')]
        [string]
        $Identity = 'LocalSystem',
        
        [pscredential]
        $Credentials = $null
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 -ThrowError | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check that the app pool doesn't already exist
    if (Test-PicassioIISAppPool -AppPoolName $Name)
    {
        Write-PicassioInfo "Application Pool already exists: $($Name)"
        return
    }

    # attempt to create the app pool
    Write-PicassioInfo "Creating new App Pool: $($Name)"
    $pool = New-WebAppPool -Name $Name -Force -ErrorAction Stop
    
    # set the runtime version
    Write-PicassioInfo "Setting runtime version: $($RuntimeVersion)"
    $pool.managedRuntimeVersion = $RuntimeVersion

    # set the identity
    $identityMap = @{
        'LocalSystem' = 0;
        'LocalService' = 1;
        'NetworkService' = 2;
        'SpecificUser' = 3;
        'ApplicationPoolIdentity' = 4;
    }

    Write-PicassioInfo "Setting identity type: $($Identity)"
    $pool.processmodel.identityType = ($identityMap.$Identity)

    if ($Identity -ieq 'SpecificUser')
    {
        if ($Credentials -eq $null)
        {
            throw "No credentials supplied when setting up application pool: $($Name)"
        }

        $pool.processmodel.username = $Credentials.GetNetworkCredential().UserName
        $pool.processmodel.password = $Credentials.GetNetworkCredential().Password
    }

    # update the app pool
    $pool | Set-Item -Force -ErrorAction Stop
    Write-PicassioSuccess "Application pool created"

    # return the app pool
    return $pool
}


<#
#>
function Test-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $ThrowIfNotExists
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check the site exists
    $exists = (Test-PicassioPath "IIS:\Sites\$($Name)")

    if (!$exists -and $ThrowIfNotExists)
    {
        throw "No Website in IIS found for: $($Name)"
    }

    return $exists
}


<#
#>
function Get-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # if it doesn't exist return null
    if (!(Test-PicassioIISWebsite -Name $Name))
    {
        return $null
    }

    # return the site
    return (Get-Item "IIS:\Sites\$($Name)" -ErrorAction Stop)
}


<#
#>
function Start-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [switch]
        $Restart
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check the site exists
    Test-PicassioIISWebsite -Name $Name -ThrowIfNotExists | Out-Null

    # check the app pool exists
    Test-PicassioIISAppPool -SiteName $Name -ThrowIfNotExists | Out-Null

    # first recycle the application pool for the site
    $appPool = Get-PicassioIISAppPool -SiteName $Name
    Restart-PicassioIISAppPool -Name $appPool

    # are we restarting?
    if ($Restart)
    {
        Stop-PicassioIISWebsite -Name $Name
    }

    # then start the site itself
    Write-PicassioInfo "Starting website: $($Name)"
    Start-Website -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess 'Website started'
}


<#
#>
function Stop-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check the site exists
    Test-PicassioIISWebsite $Name -ThrowIfNotExists | Out-Null

    # stop the site
    Write-PicassioInfo "Stopping website: $($Name)"
    Stop-Website -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess 'Website stopped'
}


<#
#>
function Remove-PicassioIISWebsiteSslBindings
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure that there are any bindings
    $sslPath = 'IIS:\SslBindings'
    if (!(Test-PicassioPath $sslPath))
    {
        Write-PicassioInfo 'There are no SSL Binding to be removed'
        return
    }

    # get the bindings for the site
    $site = (Get-ChildItem -Path $sslPath | Select-Object -ExpandProperty Sites | Where-Object { $_.Value -ieq $SiteName } | Select-Object -First 1)

    # if there is no site, just return
    if ($site -eq $null)
    {
        Write-PicassioInfo "There are no SSL Binding to be removed for website: $($SiteName)"
        return
    }

    # attempt to remove the bindings
    Write-PicassioInfo "Removing SSL Bindings for website: $($SiteName)"
    Get-ChildItem -Path $sslPath | Where-Object { $_.Sites -eq $site } | Remove-Item -Force -ErrorAction Stop
    Write-PicassioSuccess 'SSL Binding removed'
}


<#
#>
function Add-PicassioIISWebsiteBinding
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('http', 'https')]
        [string]
        $Protocol,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPAddress,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [int]
        $Port,

        [string]
        $Certificate
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check that the website does exist
    Test-PicassioIISWebsite -Name $SiteName -ThrowIfNotExists | Out-Null

    # if the port is 0 or less, error
    if ($Port -le 0)
    {
        throw "Port value must be greater than 0 when setting up website bindings"
    }

    # get the website
    $site = Get-PicassioIISWebsite -Name $SiteName

    # get the site's existing bindings
    $bindings = $site.Bindings.Collection | Where-Object { $_.protocol -ieq $Protocol }
    $bindingRegex = ("*$($IPAddress):$($Port)*")

    # check if the binding already exists, if so then return
    if (!(Test-PicassioEmpty $bindings) -and $bindings.bindingInformation -ilike $bindingRegex)
    {
        Write-PicassioInfo "Binding already exists for site '$($SiteName)': $($IPAddress):$($Port)"
        return
    }

    # if protocol is https, then validate the cert
    if ($Protocol -ieq 'https')
    {
        #if there's no cert, error
        if (Test-PicassioEmpty $Certificate)
        {
            throw "A certificate is required for HTTPS binding; ie: '*.domain.com'"
        }

        # if there is a cert, ensure it actually exists
        $certs = (Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.Subject -ilike $Certificate } | Select-Object -First 1)
        if (Test-PicassioEmpty $certs)
        {
            throw "The certificate passed cannot be found: $($Certificate)"
        }
    }

    # create the new binding
    Write-PicassioInfo "Creating binding for site '$($SiteName)': $($IPAddress):$($Port)"
    New-WebBinding -Name $SiteName -IPAddress $IPAddress -Port $Port -Protocol $Protocol -Force -ErrorAction Stop | Out-Null

    # if the protocol is for https, create the cert
    if ($Protocol -ieq 'https')
    {
        Write-PicassioInfo "Setting up binding with certificate: $($Certificate)"
        $certs = (Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object { $_.Subject -ilike $Certificate } | Select-Object -First 1)
        $thumbprint = $certs.Thumbprint.ToString()

        $sslBindingsPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\SslBindingInfo\'
        $registryItems = Get-ChildItem -Path $sslBindingsPath | Where-Object -FilterScript { $_.Property -eq 'DefaultSslCtlStoreName' }

        If (!(Test-PicassioEmpty $registryItems))
        {
            foreach ($item in $registryItems)
            {
                $item | Remove-ItemProperty -Name DefaultSslCtlStoreName -Force -ErrorAction Stop
                Write-PicassioMessage "Deleted DefaultSslCtlStoreName in $($item.Name)"
            }
        }

        try
        {
            Push-Location 'IIS:\SslBindings'
            Get-Item "Cert:\LocalMachine\My\$($thumbprint)" -ErrorAction Stop | New-Item $IPAddress!$Port -Force -ErrorAction Stop | Out-Null
        }
        finally
        {
            Pop-Location
        }
    }

    Write-PicassioSuccess 'Binding created'
}


<#
#>
function Remove-PicassioIISWebsiteBinding
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('http', 'https')]
        [string]
        $Protocol,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPAddress,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [int]
        $Port
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check if the site doesn't exist, if not just return
    if (!(Test-PicassioIISWebsite -Name $SiteName))
    {
        Write-PicassioInfo "Website does not exist to remove bindings: $($SiteName)"
        return
    }
    
    # if the port is 0 or less, error
    if ($Port -le 0)
    {
        throw "Port value must be greater than 0 when removing website bindings"
    }
    
    # get the website
    $site = Get-PicassioIISWebsite -Name $SiteName

    # get the site's existing bindings
    $bindings = $site.Bindings.Collection | Where-Object { $_.protocol -ieq $Protocol }
    $bindingRegex = ("*$($IPAddress):$($Port)*")

    # check to see if the binding exists, if not return
    if ((Test-PicassioEmpty $bindings) -or $bindings.bindingInformation -inotlike $bindingRegex)
    {
        Write-PicassioInfo "Binding already removed for site '$($SiteName)': $($IPAddress):$($Port)"
        return
    }

    # remove the binding
    Write-PicassioInfo "Removing binding for site '$($SiteName)': $($IPAddress):$($Port)"
    Remove-WebBinding -Name $SiteName -IPAddress $IPAddress -Port $Port -Protocol $Protocol -ErrorAction Stop | Out-Null

    # if protocol is https, remove cert binding
    if ($Protocol -ieq 'https')
    {
        try
        {
            Push-Location 'IIS:\SslBindings'
            Remove-Item $IPAddress!$Port -Force -ErrorAction Stop | Out-Null
        }
        finally
        {
            Pop-Location
        }
    }

    Write-PicassioSuccess 'Binding removed'
}


<#
#>
function Remove-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # remove the sites ssl bindings - if it has any
    Remove-PicassioIISWebsiteSslBindings -SiteName $Name

    # remove the site
    Write-PicassioInfo "Removing website: $($Name)"

    if (Test-PicassioIISWebsite -SiteName $Name)
    {
        Remove-Website -Name $Name -ErrorAction Stop | Out-Null
        Write-PicassioSuccess 'Website removed'
    }
    else
    {
        Write-PicassioInfo "Website already removed: $($Name)"
    }

    # remove the app pool
    if (Test-PicassioIISAppPool -SiteName $Name)
    {
        $appPool = Get-PicassioIISAppPool -SiteName $Name
        Remove-PicassioIISAppPool -Name $appPool
    }
}


<#
#>
function New-PicassioIISWebsite
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PhysicalPath,

        [string]
        $AppPoolName,
        
        [ValidateSet('v1.1', 'v2.0', 'v4.0')]
        [string]
        $RuntimeVersion = 'v4.0',

        [ValidateSet('LocalSystem', 'LocalService', 'NetworkService', 'SpecificUser', 'ApplicationPoolIdentity')]
        [string]
        $Identity = 'LocalSystem',

        [pscredential]
        $Credentials = $null
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the physical path exists
    Test-PicassioPath $PhysicalPath -ThrowIfNotExists | Out-Null

    # create the app pool
    if (Test-PicassioEmpty $AppPoolName)
    {
        $AppPoolName = $Name
    }

    $pool = New-PicassioIISAppPool -Name $AppPoolName -RuntimeVersion $RuntimeVersion -Identity $Identity -Credentials $Credentials

    # create the website
    if (Test-PicassioIISWebsite -Name $Name)
    {
        Write-PicassioInfo "Website already created: $($Name)"
    }
    else
    {
        Write-PicassioInfo "Creating website: $($Name)"
        Write-PicassioMessage "> Path: $($PhysicalPath)"

        New-Website -Name $Name -PhysicalPath $PhysicalPath -ApplicationPool $pool -Force -ErrorAction Stop | Out-Null
        Remove-WebBinding -Name $Name -IPAddress * -Port 80 -Protocol 'http' -ErrorAction Stop | Out-Null
    }

    # setup acl for site path
    Set-PicassioFileAccessRule -Path $PhysicalPath -User 'NT AUTHORITY\IUSR' -Permission 'ReadAndExecute' -Access 'Allow'
    Set-PicassioFileAccessRule -Path $PhysicalPath -User "IIS APPPOOL\$($AppPoolName)" -Permission 'ReadAndExecute' -Access 'Allow'

    # start site and app pool
    Restart-PicassioIISAppPool -Name $AppPoolName
    Start-PicassioIISWebsite -Name $Name -Restart

    # inform success
    Write-PicassioSuccess 'Website created'
}