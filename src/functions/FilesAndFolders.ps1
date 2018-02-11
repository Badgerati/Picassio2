
<#
    Copys files and folders from one location to another, creating the destination
    directories if they don't exist. You can also specify files/folders to specifically
    include or exclude
#>
function Copy-PicassioFiles
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $From,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $To,

        [string[]]
        $ExcludeFiles = $null,

        [string[]]
        $ExcludeFolders = $null,

        [string[]]
        $IncludeFiles = $null,

        [string[]]
        $IncludeFolders = $null
    )

    # ensure the From path exists
    Test-PicassioPath $From -ThrowIfNotExists

    # build the regex for $ExcludeFolders
    if (!(Test-PicassioEmpty $ExcludeFolders))
    {
        [Regex]$rgxExcludeFolders = ($ExcludeFolders | ForEach-Object { [Regex]::Escape($_) }) -join '|'
    }

    # build the regex for $IncludeFolders
    if (!(Test-PicassioEmpty $IncludeFolders))
    {
        [Regex]$rgxIncludeFolders = ($IncludeFolders | ForEach-Object { [Regex]::Escape($_) }) -join '|'
    }

    Write-PicassioInfo "Copying files"
    Write-PicassioMessage "> From: $($From)"
    Write-PicassioMessage ">   To: $($To)"

    # do the copying of files/folders
    $fromLength = $From.Length

    Get-ChildItem -Path $From -Recurse -Force -Exclude $ExcludeFiles -Include $IncludeFiles |
        Where-Object { $rgxExcludeFolders -eq $null -or $_.FullName.Replace($From, [String]::Empty) -notmatch $rgxExcludeFolders } |
        Where-Object { $rgxIncludeFolders -eq $null -or $_.FullName.Replace($From, [String]::Empty) -match $rgxIncludeFolders } |
        Copy-Item -Destination {
            if ($_.PSIsContainer)
            {
                $path = Join-Path $To $_.Parent.FullName.Substring($fromLength)
                $temp = $path
            }
            else
            {
                $path = Join-Path $To $_.FullName.Substring($fromLength)
                $temp = Split-Path -Parent -Path $path
            }

            if (!(Test-PicassioPath $temp))
            {
                New-Item -ItemType Directory -Force -Path $temp | Out-Null
            }

            $path
        } -Force -Exclude $ExcludeFiles -Include $IncludeFiles
    
    # check to ensure copying didn't fail silently
    if (!$?)
    {
        Write-PicassioError 'Copying files failed' -ThrowError
    }

    Write-PicassioSuccess 'Files/Directories copied'
}


<#
#>
function Search-PicassioFiles
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Pattern,

        [string[]]
        $ExcludeFiles = $null,

        [string[]]
        $IncludeFiles = $null
    )

    # ensure the From path exists
    Test-PicassioPath $From -ThrowIfNotExists

    # search path for files containing pattern
    Write-PicassioInfo "Searching files for: $($Pattern)"
    Write-PicassioMessage "> Path: $($Path)"

    $files = (Get-ChildItem $Path -Recurse -Include $IncludeFiles -Exclude $ExcludeFiles |
                Select-String -Pattern $Pattern |
                Group-Object path |
                Select-Object -ExpandProperty Name)

    Write-PicassioInfo "Found $(($files | Measure-Object).Count) files"
    return $files
}


<#
#>
function Get-PicassioPathHash
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    # ensure the path exists
    Test-PicassioPath -Path $Path -ThrowIfNotExists | Out-Null
    $Path = Resolve-Path -Path $Path

    # is this path a directory or a file?
    $isDirectory = Test-PicassioPathDirectory -Path $Path

    # general variables
    $sha1 = New-Object -TypeName 'System.Security.Cryptography.SHA1CryptoServiceProvider'
    $bytes = $null

    # compute bytes of a directory
    if ($isDirectory)
    {
        Write-PicassioInfo "Computing directory hash for: $($Path)"
        $fullHash = [String]::Empty
        
        Get-ChildItem -Path $Path -Recurse |
            Where-Object { !$_.PSIsContainer } |
            ForEach-Object {
                $fullHash += ([System.BitConverter]::ToString($sha1.ComputeHash([System.IO.File]::ReadAllBytes($_.FullName))))
            }
        
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($fullHash)
    }
    
    # compute bytes of a file
    else
    {
        Write-PicassioInfo "Computing file hash for: $($Path)"
        $bytes = [System.IO.File]::ReadAllBytes($Path)
    }

    # return the MD5 hash for the path
    return ([System.BitConverter]::ToString($sha1.ComputeHash($bytes)))
}


<#
#>
function New-PicassioTempFolder
{
    param (
        [string]
        $Path = $null
    )

    if (Test-PicassioEmpty $Path)
    {
        $Path = $env:TEMP
    }

    $name = [System.IO.Path]::GetRandomFileName()
    $temp = Join-Path $Path $name

    if (!(Test-PicassioPath $temp))
    {
        New-Item -ItemType Directory -Path $temp -Force -ErrorAction Stop | Out-Null
    }

    return $temp
}


<#
#>
function New-PicassioNetworkDrive
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RemotePath,

        [string]
        $DriveName = $null,

        [pscredential]
        $Credentials
    )

    # if no name passed, generate a random one
    if (Test-PicassioEmpty $DriveName)
    {
        $DriveName = (Get-PicassioRandomName -Length 5)
    }

    # remove any colons or slashes
    $DriveName = $DriveName.TrimEnd(':', '\', '/')

    Write-PicassioInfo "Creating new network drive"
    Write-PicassioMessage "> From: $($RemotePath)"
    Write-PicassioMessage ">   To: $($DriveName):\"

    # create the drive
    if ($Credentials -eq $null)
    {
        New-PSDrive -Name $DriveName -PSProvider FileSystem -Root $RemotePath -Scope Script -ErrorAction Stop | Out-Null
    }
    else
    {
        New-PSDrive -Name $DriveName -PSProvider FileSystem -Root $RemotePath -Scope Script -Credential $Credentials -ErrorAction Stop | Out-Null
    }

    # return the base drive name just created
    Write-PicassioSuccess 'Network drive created'
    return "$($DriveName):"
}


<#
#>
function New-PicassioFileShare
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

        [ValidateNotNullOrEmpty()]
        [string]
        $Permissions = 'Everyone,FULL',

        [switch]
        $Force
    )

    # ensure the path exists
    Test-PicassioPath $Path -ThrowIfNotExists | Out-Null

    # if we're forcing, attempt to delete share first
    if ($Force)
    {
        Remove-PicassioFileShare -Name $Name
    }

    # attempt to create the share
    Write-PicassioInfo "Creating new file share: $($Name)"
    Write-PicassioMessage "> Path: $($Path)"

    net share $Name=$Path /grant:$Permissions 2>&1>null
    if (!$?)
    {
        throw "Failed to create share: $($Name)"
    }

    Write-PicassioSuccess "File share created"
}

<#
#>
function Remove-PicassioFileShare
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # if the share exists, remove it
    if ((net share | Where-Object { $_ -ilike "$($Name)*" } | Measure-Object).Count -gt 0)
    {
        Write-PicassioInfo "Removing file share: $($Name)"

        net share $Name /delete /y 2>&1>null
        if (!$?)
        {
            throw "Failed to remove file share: $($Name)"
        }

        Write-PicassioSuccess "File share removed"
    }
    else
    {
        Write-PicassioInfo "File share doesn't exist: $($Name)"
    }
}