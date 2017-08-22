
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

    # if the IP Address is a *, then don't do anything
    if ($IPAddress -ieq '*')
    {
        Write-PicassioWarning "Skipping adding hosts entry, as IP address is everything: *"
        return
    }

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
        ("`n$($IPAddress)`t`t$($Hostname)") | Out-File -FilePath $hostsFile -Encoding ASCII -Append -ErrorAction Stop
    }
    else
    {
        Write-PicassioMessage 'Hosts entry already exists'
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
    
    # if the IP Address is a *, then don't do anything
    if ($IPAddress -ieq '*')
    {
        Write-PicassioWarning "Skipping removing hosts entry, as IP address is everything: *"
        return
    }

    # check hosts file exists
    $hostsFile = "$($env:windir)\System32\drivers\etc\hosts"
    Test-PicassioPath $hostsFile -ThrowIfNotExists | Out-Null

    Write-PicassioInfo "Removing the following entry from the hosts file: '$($IPAddress) - $($HostName)'"

    # get regex for finding existing entries
    $rgxEntry = "^.*?$($IPAddress).*?$($Hostname).*?$"

    # add lines back into the hosts file where they don't match the regex
    Get-Content $hostsFile | Where-Object { $_ -inotmatch $rgxEntry } | Out-File -FilePath $hostsFile -Encoding ASCII -ErrorAction Stop

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

    # return the Application Pool's name for the site
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
        throw 'At least one of SiteName or AppPoolName must be passed for testing Application Pools'
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
    Write-PicassioInfo "Recycling Application Pool: $($Name)"
    Restart-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application Pool recycled"
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

    Write-PicassioInfo "Starting Application Pool: $($Name)"
    
    # check the app pool's state
    $state = (Get-WebAppPoolState -Name $Name).Value
    if ($state -ieq 'started')
    {
        Write-PicassioSuccess 'Application Pool already started'
        return
    }

    # start the app pool
    Start-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application Pool started"
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

    Write-PicassioInfo "Stopping Application Pool: $($Name)"
    
    # check the app pool's state
    $state = (Get-WebAppPoolState -Name $Name).Value
    if ((Test-PicassioEmpty $state) -or ($state -ieq 'stopped'))
    {
        Write-PicassioSuccess 'Application Pool already stopped'
        return
    }

    # stop the app pool
    Stop-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application Pool stopped"
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
    Write-PicassioInfo "Removing Application Pool: $($Name)"
    Remove-WebAppPool -Name $Name -ErrorAction Stop | Out-Null
    Write-PicassioSuccess "Application Pool removed"
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
            throw "No credentials supplied when setting up Application Pool: $($Name)"
        }

        $pool.processmodel.username = $Credentials.GetNetworkCredential().UserName
        $pool.processmodel.password = $Credentials.GetNetworkCredential().Password
    }

    # update the app pool
    $pool | Set-Item -Force -ErrorAction Stop
    Write-PicassioSuccess "Application Pool created"

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
function Get-PicassioIISWebsitePath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppName
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # if the website doesn't exist return null
    if (!(Test-PicassioIISWebsite -Name $SiteName))
    {
        Write-PicassioWarning "Website does not exist in IIS: $($SiteName)"
        return $null
    }

    # if the app name is passed, check it exists else return null
    if (!(Test-PicassioEmpty $AppName) -and !(Test-PicassioIISWebsiteApplication -Name $AppName -SiteName $SiteName))
    {
        Write-PicassioWarning "Website Application does not exist in IIS: $($AppName), under Website: $($SiteName)"
        return $null
    }

    # otherwise, return the path of the app if it was passed
    if (Test-PicassioEmpty $AppName)
    {
        return (Get-WebFilePath -PSPath "IIS:\Sites\$($SiteName)\$($AppName)" -ErrorAction Stop).FullName
    }
    
    # else return the path of the site
    return (Get-WebFilePath -PSPath "IIS:\Sites\$($SiteName)" -ErrorAction Stop).FullName
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

    # first recycle the Application Pool for the site
    $appPool = Get-PicassioIISAppPool -SiteName $Name
    Restart-PicassioIISAppPool -Name $appPool

    # are we restarting?
    if ($Restart)
    {
        Stop-PicassioIISWebsite -Name $Name
    }

    Write-PicassioInfo "Starting website: $($Name)"

    # check the site's state
    $state = (Get-Website -Name $Name).State
    if ($state -ieq 'started')
    {
        Write-PicassioSuccess 'Website already started'
        return
    }

    # then start the site itself
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

    Write-PicassioInfo "Stopping website: $($Name)"

    # check the site's state
    $state = (Get-Website -Name $Name).State
    if ((Test-PicassioEmpty $state) -or ($state -ieq 'stopped'))
    {
        Write-PicassioSuccess 'Website already stopped'
        return
    }

    # stop the site
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
            Get-Item "Cert:\LocalMachine\My\$($thumbprint)" -ErrorAction Stop | New-Item $IPAddress!$Port!$SiteName -Force -ErrorAction Stop | Out-Null
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
            Remove-Item $IPAddress!$Port!$SiteName -Force -ErrorAction Stop | Out-Null
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
    if (Test-PicassioIISWebsite -SiteName $Name)
    {
        Write-PicassioInfo "Removing Website: $($Name)"
        Remove-Website -Name $Name -ErrorAction Stop | Out-Null
    }
    else
    {
        Write-PicassioInfo "Website already removed: $($Name)"
    }

    Write-PicassioSuccess 'Website removed'

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
        Write-PicassioInfo "Creating Website: $($Name)"
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


<#
#>
function Test-PicassioIISWebsiteApplication
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,

        [switch]
        $ThrowIfNotExists
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # check the site exists
    $exists = (Test-PicassioPath "IIS:\Sites\$($SiteName)")

    if (!$exists -and $ThrowIfNotExists)
    {
        throw "No Website in IIS found for: $($SiteName)"
    }

    # check the app exists
    $exists = (Test-PicassioPath "IIS:\Sites\$($SiteName)\$($Name)")
    
    if (!$exists -and $ThrowIfNotExists)
    {
        throw "No Website Application in IIS found for: $($Name), under Website: $($SiteName)"
    }

    return $exists
}


<#
#>
function New-PicassioIISWebsiteApplication
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PhysicalPath
    )
    
    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the physical path exists
    Test-PicassioPath $PhysicalPath -ThrowIfNotExists | Out-Null

    # ensure the website exists
    Test-PicassioIISWebsite -Name $SiteName -ThrowIfNotExists | Out-Null

    # ensure the app pool exists
    Test-PicassioIISAppPool -SiteName $SiteName -ThrowIfNotExists | Out-Null

    # get the app pool name
    $appPoolName = Get-PicassioIISAppPool -SiteName $SiteName

    # create the web application
    if (Test-PicassioIISWebsiteApplication -Name $Name -SiteName $SiteName)
    {
        Write-PicassioInfo "Website Application already created: $($Name), under Website: $($SiteName)"
    }
    else
    {
        Write-PicassioInfo "Creating Website Application: $($Name), under Website: $($SiteName)"
        Write-PicassioMessage "> Path: $($PhysicalPath)"

        New-WebApplication -Site $SiteName -Name $Name -PhysicalPath $PhysicalPath -ApplicationPool $appPoolName -Force -ErrorAction Stop | Out-Null
    }

    # setup acl for site path
    Set-PicassioFileAccessRule -Path $PhysicalPath -User 'NT AUTHORITY\IUSR' -Permission 'ReadAndExecute' -Access 'Allow'
    Set-PicassioFileAccessRule -Path $PhysicalPath -User "IIS APPPOOL\$($appPoolName)" -Permission 'ReadAndExecute' -Access 'Allow'

    # start site and app pool
    Restart-PicassioIISAppPool -Name $appPoolName
    Start-PicassioIISWebsite -Name $SiteName -Restart

    # inform success
    Write-PicassioSuccess 'Website Application created'
}


<#
#>
function Remove-PicassioIISWebsiteApplication
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # remove the site
    if (Test-PicassioIISWebsiteApplication -Name $Name -SiteName $SiteName)
    {
        Write-PicassioInfo "Removing Website Application: $($Name), under Website: $($SiteName)"
        Remove-WebApplication -Site $SiteName -Name $Name -ErrorAction Stop | Out-Null
    }
    else
    {
        Write-PicassioInfo "Website Application already removed: $($Name), under Website: $($SiteName)"
    }

    Write-PicassioSuccess 'Website Application removed'
}


<#
#>
function Update-PicassioIISPhysicalPath
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppName,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PhysicalPath,

        [switch]
        $SyncPathToAll
    )

    # IIS alterations must be done in 64-bit shells
    Test-Win64 | Out-Null
    Import-Module WebAdministration -ErrorAction Stop

    # ensure the new physical path exists
    Test-PicassioPath $PhysicalPath -ThrowIfNotExists | Out-Null

    # ensure the website exists
    Test-PicassioIISWebsite -Name $SiteName -ThrowIfNotExists | Out-Null

    # ensure the web app exists (if passed)
    $haveApp = !(Test-PicassioEmpty $AppName)
    if ($haveApp)
    {
        Test-PicassioIISWebsiteApplication -Name $AppName -SiteName $SiteName -ThrowIfNotExists | Out-Null
    }

    # either update the one site/app, or sync to all that share old path
    if (!$SyncPathToAll)
    {
        if ($haveApp)
        {
            Write-PicassioInfo "Updating physical path for Website Application: $($AppName), under Website: $($SiteName)"
            Write-PicassioMessage "> Path: $($PhysicalPath)"
            Set-ItemProperty -Path "IIS:\Sites\$($SiteName)\$($AppName)" -Name physicalPath -Value $PhysicalPath -Force -ErrorAction Stop | Out-Null
        }
        else
        {
            Write-PicassioInfo "Updating physical path for Website: $($SiteName)"
            Write-PicassioMessage "> Path: $($PhysicalPath)"
            Set-ItemProperty -Path "IIS:\Sites\$($SiteName)" -Name physicalPath -Value $PhysicalPath -Force -ErrorAction Stop | Out-Null
        }

        Write-PicassioSuccess "Physical path updated"
    }
    else
    {
        # get the current path
        $currentPath = Get-PicassioIISWebsitePath -SiteName $SiteName -AppName $AppName

        Write-PicassioInfo "Updating physical path for all Websites and Website Applications"
        Write-PicassioMessage "> From: $($currentPath)"
        Write-PicassioMessage ">   To: $($PhysicalPath)"

        # get every website that references the current path
        $sites = Get-Website | Select-Object Name, PhysicalPath | Where-Object { $_.PhysicalPath -ieq $currentPath } | Select-Object -ExpandProperty Name

        if (($sites | Measure-Object).Count -gt 0)
        {
            foreach ($site in $sites)
            {
                if (Test-PicassioEmpty $site)
                {
                    continue
                }

                Write-PicassioMessage "Updating website: $($site)" -NoNewLine
                Set-ItemProperty  "IIS:\Sites\$($site)" -Name physicalPath -Value $PhysicalPath -Force -ErrorAction Stop | Out-Null
                Write-PicassioSuccess " > Updated"
            }
        }

        # get every app that references the current path
        $apps = Get-WebApplication | Where-Object { $_.PhysicalPath -ieq $currentPath }

        if (($apps | Measure-Object).Count -gt 0)
        {
            foreach ($app in $apps)
            {
                if (Test-PicassioEmpty $app)
                {
                    continue
                }
                
                $name = $app.path.Trim('/')
                $site = $app.GetParentElement()['name']

                Write-PicassioMessage "Updating app: $($name)" -NoNewLine
                Set-ItemProperty "IIS:\Sites\$($site)\$($name)" -Name physicalPath -Value $PhysicalPath -Force -ErrorAction Stop | Out-Null
                Write-PicassioSuccess " > Updated"
            }
        }
        
        Write-PicassioSuccess "Physical paths updated"
    }
}