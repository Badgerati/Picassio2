
<#
#>
function Update-PicassioAssemblyInfo
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,
        
        [string]
        $VersionInfo = $null
    )

    # ensure the path exists
    Test-PicassioPath $Path -ThrowIfNotExists | Out-Null

    # if no informational version passed, set as version
    if (Test-PicassioEmpty $VersionInfo)
    {
        $VersionInfo = $Version
    }

    # general variables
    $assmVersionRegex = 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $fileVersionRegex = 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)'
    $infoVersionRegex = 'AssemblyInformationalVersion\("[0-9a-zA-Z]+(\.([0-9a-zA-Z]+|\*)){1,3}"\)'

    $assmVersion = "AssemblyVersion(`"$($Version)`")"
    $fileVersion = "AssemblyFileVersion(`"$($Version)`")"
    $infoVersion = "AssemblyInformationalVersion(`"$($VersionInfo)`")"

    Write-PicassioInfo "Updating AssemblyInfo.cs files with passed version"
    Write-PicassioMessage "> File Version: $($Version)"
    Write-PicassioMessage "> Info Version: $($VersionInfo)`n"

    # update all AssemblyInfo.cs files at the path
    Get-ChildItem -Path $Path -Recurse -Force | 
        Where-Object { $_.Name -ieq 'AssemblyInfo.cs' } |
        ForEach-Object {
            $file = $_.FullName

            Write-PicassioInfo "> Updating: $($file)"
            
            (Get-Content -Path $file) | ForEach-Object {
                ForEach-Object {
                    (($_ -ireplace $assmVersionRegex, $assmVersion) -ireplace $fileVersionRegex, $fileVersion) -ireplace $infoVersionRegex, $infoVersion
                }
            } | Out-File -FilePath $file -Encoding utf8 -Force
        }
    
    Write-PicassioSuccess "`nAssemblyInfo files updated"
}