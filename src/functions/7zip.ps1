
<#
#>
function Invoke-PicassioArchive
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ZipPath
    )

    # ensure that 7zip is installed
    Test-PicassioSoftware -Check '7z' -Name '7zip' -ThrowIfNotExists | Out-Null

    # ensure that the path to archive exists
    Test-PicassioPath -Path $Path -ThrowIfNotExists | Out-Null

    # check if the zip path exists - otherwise create it
    $zipParentPath = Split-Path -Parent -Path $ZipPath
    if (!(Test-PicassioPath -Path $zipParentPath))
    {
        New-Item -ItemType Directory -Path $zipParentPath -Force | Out-Null
    }

    # attempt to archive the file/directory
    Write-PicassioInfo "Archiving path"
    Write-PicassioMessage "> From: $($Path)"
    Write-PicassioMessage ">   To: $($ZipPath)"

    Invoke-PicassioCommand -Command "7z a -t7z -y `"$($ZipPath)`" `"$($Path)`""

    Write-PicassioSuccess 'Archiving complete'
}


<#
#>
function Invoke-PicassioExtract
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ZipPath
    )

    # ensure that 7zip is installed
    Test-PicassioSoftware -Check '7z' -Name '7zip' -ThrowIfNotExists | Out-Null

    # ensure that the zip path to extract exists
    Test-PicassioPath -Path $ZipPath -ThrowIfNotExists | Out-Null

    # check if the path to archive exists - otherwise create it
    $parentPath = Split-Path -Parent -Path $Path
    if (!(Test-PicassioPath -Path $parentPath))
    {
        New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    # attempt to extrac the file/directory
    Write-PicassioInfo "Extracting archive"
    Write-PicassioMessage "> From: $($ZipPath)"
    Write-PicassioMessage ">   To: $($Path)"

    Invoke-PicassioCommand -Command "7z x -y `"$($ZipPath)`" -o`"$($Path)`""

    Write-PicassioSuccess 'Extraction complete'
}