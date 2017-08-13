
if ((Get-Module -Name Picassio2 | Measure-Object).Count -ne 0)
{
    Remove-Module -Name Picassio2
}

$path = (Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path))
Import-Module "$($path)/src/Picassio2.psm1" -ErrorAction Stop




Invoke-Step 'Single' {
    Write-PicassioWarning 'Ooh, its a warning!'
}

Invoke-Step 'File Hash' {
    $hash = Get-PicassioPathHash -Path $path
    Write-PicassioSuccess "Hash: $($hash)"
}

Invoke-ParallelStep 'ParallelTest' @(
    {
        Write-PicassioInfo 'PARA1'
    },
    {
        Write-PicassioInfo 'PARA2'
    },
    {
        Start-Sleep -Milliseconds 100
        Write-PicassioInfo 'PARA3'
    },
    {
        Write-PicassioInfo 'PARA4'
    },
    {
        Write-PicassioInfo 'PARA5'
    }
)

Invoke-Step 'Windows Feature' {
    $exists = Test-PicassioWindowsFeatureInstalled -Name 'Web-Server' -Optional
    Write-Host "Installed: $($exists)"
}