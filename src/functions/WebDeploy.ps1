
<#
#>
function Get-PicassioWebDeployDefaultToolPath
{
    return 'C:\Program Files\IIS\Microsoft Web Deploy V3\msdeploy.exe'
}


<#
#>
function Sync-PicassioWebDeployPaths
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName,

        [string[]]
        $Exclude = @(),

        [string]
        $WebDeployPath = $null,
        
        [pscredential]
        $Credentials = $null,

        [switch]
        $Quiet
    )

    # check that webdeploy tool is installed
    if (Test-PicassioEmpty $WebDeployPath)
    {
        $WebDeployPath = Get-PicassioWebDeployDefaultToolPath
    }

    Test-PicassioPath $WebDeployPath -ThrowIfNotExists | Out-Null

    # check that the source path exists
    Test-PicassioPath $Source -ThrowIfNotExists | Out-Null

    # build the credentials string
    $creds_str = [string]::Empty
    if ($Credentials -ne $null)
    {
        $creds_str = ",username='$($Credentials.GetNetworkCredential().UserName)',password='$($Credentials.GetNetworkCredential().Password)'"
    }

    # build the arguments to use
    [string[]] $_args = @(
        '-verb:sync',
        "-source:dirPath='$($Source)'",
        "-dest:dirPath='$($Destination)',computerName='$($ComputerName)'$($creds_str)"
    )

    # append any paths that need to be excluded
    if (!(Test-PicassioEmpty $Exclude))
    {
        $Exclude | ForEach-Object {
            $_args += "-skip:objectName=filePath,absolutePath='$($_)'"
        }
    }

    # run web deploy with arguments
    Write-PicassioInfo "Syncing paths via WebDeploy on $($ComputerName)"
    Write-PicassioMessage "> Source: $($Source)"
    Write-PicassioMessage "> Destination: $($Destination)"

    if ($Quiet)
    {
        & $WebDeployPath $_args | Out-Null
    }
    else
    {
        & $WebDeployPath $_args
    }

    # check for errors
    if (!$?)
    {
        throw 'WebDeploy failed to sync files'
    }

    Write-PicassioSuccess 'WebDeploy complete'
}


<#
#>
function Sync-PicassioWebDeployServers
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Destination,

        [string]
        $WebDeployPath = $null,
        
        [pscredential]
        $Credentials = $null,

        [switch]
        $Quiet
    )

    # check that webdeploy is installed
    if (Test-PicassioEmpty $WebDeployPath)
    {
        $WebDeployPath = Get-PicassioWebDeployDefaultToolPath
    }

    Test-PicassioPath $WebDeployPath -ThrowIfNotExists | Out-Null

    # build the credentials string
    $creds_str = [string]::Empty
    if ($Credentials -ne $null)
    {
        $creds_str = ",username='$($Credentials.GetNetworkCredential().UserName)',password='$($Credentials.GetNetworkCredential().Password)'"
    }

    # build the arguments to use
    [string[]] $_args = @(
        '-verb:sync',
        "-source:webserver,computername='$($Source)'$($creds_str)",
        "-dest:webserver,computername='$($Destination)'$($creds_str)"
    )

    # run web deploy with arguments
    Write-PicassioInfo "Syncing servers via WebDeploy"
    Write-PicassioMessage "> Source: $($Source)"
    Write-PicassioMessage "> Destination: $($Destination)"

    if ($Quiet)
    {
        & $WebDeployPath $_args | Out-Null
    }
    else
    {
        & $WebDeployPath $_args
    }

    # check for errors
    if (!$?)
    {
        throw 'WebDeploy failed to sync servers'
    }

    Write-PicassioSuccess 'WebDeploy complete'
}