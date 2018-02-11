
<#
#>
function Get-PicassioSSDTDefaultToolPath
{
    @('100', '110', '120', '130') | ForEach-Object {
        $path = "C:\Program Files (x86)\Microsoft SQL Server\$($_)\DAC\bin\SqlPackage.exe"
        if (Test-PicassioPath $path)
        {
            return $path
        }
    }
}


<#
#>
function Find-PicassioSSDTMissingSqlFiles
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    # ensure the path exists
    Test-PicassioPath $Path -ThrowIfNotExists
    $Path = Resolve-Path $Path

    # grab the sqlproj files
    Write-PicassioInfo "Finding files missing in SQL projects"
    Write-PicassioMessage "> Path: $($Path)"

    $sqlprojs = Get-ChildItem $Path -Include @('*.sqlproj') -Recurse
    $sqlprojs | ForEach-Object { Write-PicassioMessage "> Project: $($_.Name)" }

    # get a list of sql files in the projects
    $regex = '(Build|None|PostDeploy|PreDeploy)\s+Include="(.*?.sql)"'
    $files = @{}

    foreach ($proj in $sqlprojs)
    {
        $dir = Split-Path -Parent -Path $proj.FullName

        $lines = Get-Content $proj
        foreach ($line in $lines)
        {
            if ($line -imatch $regex)
            {
                $p = Join-Path $dir $Matches[2]
                if (!$files.ContainsKey($p))
                {
                    $files.Add($p, $true)
                }
            }
        }
    }

    # now find any sql files not in the projects
    $missing = (Get-ChildItem $Path -Include @('*.sql') -Recurse |
                    Where-Object { !$files.Contains($_.FullName) -and $_.FullName -inotmatch '.*\\(obj|bin)\\.*' })

    Write-PicassioInfo "Found $(($missing | Measure-Object).Count) missing SQL files"
    return $missing
}


<#
#>
function Publish-PicassioSSDT
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DacPac,

        [string]
        $Publish = $null,

        [ValidateNotNull()]
        [int]
        $Timeout = 60,

        [string]
        $Arguments = $null,

        [string]
        $ToolPath = $null,

        [switch]
        $BackupFirst,

        [switch]
        $DropFirst,

        [switch]
        $BlockOnLoss
    )

    # check that the ssdt sqlpackage tool is installed
    if (Test-PicassioEmpty $ToolPath)
    {
        $ToolPath =  Get-PicassioSSDTDefaultToolPath
    }

    Test-PicassioPath $ToolPath -ThrowIfNotExists | Out-Null

    # ensure that the dacpac path exist
    Test-PicassioPath $DacPac -ThrowIfNotExists | Out-Null

    # ensure that the publish profile path exists (if passed)
    if (!(Test-PicassioEmpty $Publish))
    {
        Test-PicassioPath $Publish -ThrowIfNotExists | Out-Null
    }

    # resolve the dacpac paths for the tool
    $DacPac =  Resolve-Path -Path $DacPac

    if (!(Test-PicassioEmpty $Publish))
    {
        $Publish =  Resolve-Path -Path $Publish
    }

    # ensure the timeout is positive
    if ($Timeout -le 0)
    {
        $Timeout = 60
    }

    # build up the arguments for running
    $dacpac_arg = "/sf:`"$($DacPac)`""
    $timeout_arg = "/p:CommandTimeout=$($Timeout)"

    if (!(Test-PicassioEmpty $Publish))
    {
        $publish_arg = "/pr:`"$($Publish)`""
    }

    $switch_args = "/p:BackupDatabaseBeforeChanges=$($BackupFirst) /p:CreateNewDatabase=$($DropFirst) /p:BlockOnPossibleDataLoss=$($BlockOnLoss)"

    # build the final arguments
    $_args = "/a:publish $($dacpac_arg) $($publish_arg) $($timeout_arg) $($switch_args) $($Arguments)"

    # run the tools
    Write-PicassioInfo "Running SSDT publish"
    Write-PicassioMessage "> DacPac: $($DacPac)"

    if (!(Test-PicassioEmpty $Publish))
    {
        Write-PicassioMessage "> Publish: $($Publish)"
    }

    $toolLocation = Split-Path -Parent -Path $ToolPath
    $toolName = ".\$(Split-Path -Leaf -Path $ToolPath)"

    Invoke-PicassioCommand -Command "$($toolName) $($_args)" -Path $toolLocation -ShowFullOutput

    Write-PicassioSuccess "SSDT published"
}


<#
#>
function Export-PicassioSSDT
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DacPac,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Output,

        [ValidateNotNull()]
        [int]
        $Timeout = 60,

        [string]
        $Arguments = $null,

        [string]
        $ToolPath = $null,

        [switch]
        $Force
    )

    # check that the ssdt sqlpackage tool is installed
    if (Test-PicassioEmpty $ToolPath)
    {
        $ToolPath =  Get-PicassioSSDTDefaultToolPath
    }

    Test-PicassioPath $ToolPath -ThrowIfNotExists | Out-Null

    # ensure that the dacpac path exist
    Test-PicassioPath $DacPac -ThrowIfNotExists | Out-Null

    # ensure that the output path does not exist (unless force is passed)
    if (Test-PicassioPath $Output)
    {
        if ($Force)
        {
            Write-PicassioWarning "Output path already exists, removing: $($Output)"
            Remove-Item -Path $Output -Force -ErrorAction Stop | Out-Null
        }
        else
        {
            throw "The output path already exists: $($Output)"
        }
    }
    else
    {
        New-Item -Path (Split-Path -Parent -Path $Output) -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }

    # resolve the dacpac and output paths for the tool
    $DacPac =  Resolve-Path -Path $DacPac
    $Output =  Resolve-Path -Path $Output

    # ensure the timeout is positive
    if ($Timeout -le 0)
    {
        $Timeout = 60
    }

    # build up the arguments for running
    $dacpac_arg = "/sf:`"$($DacPac)`""
    $timeout_arg = "/p:CommandTimeout=$($Timeout)"
    $output_arg = "/op:`"$($Output)`""

    # build the final arguments
    $_args = "/a:script $($dacpac_arg) $($output_arg) $($timeout_arg) $($Arguments)"

    # run the tools
    Write-PicassioInfo "Running SSDT to generate script"
    Write-PicassioMessage "> DacPac: $($DacPac)"
    Write-PicassioMessage "> Output: $($Output)"

    $toolLocation = Split-Path -Parent -Path $ToolPath
    $toolName = ".\$(Split-Path -Leaf -Path $ToolPath)"

    Invoke-PicassioCommand -Command "$($toolName) $($_args)" -Path $toolLocation -ShowFullOutput

    Write-PicassioSuccess "SSDT script generated"
}