
if ((Get-Module -Name Picassio2 | Measure-Object).Count -ne 0)
{
    Remove-Module -Name Picassio2
}

$path = (Split-Path -Parent -Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path))
Import-Module "$($path)/src/Picassio2.psm1" -ErrorAction Stop


Step 'Single' {
    Write-PicassioWarning 'Ooh, its a warning!'
}

Step 'File Hash' {
    $hash = Get-PicassioPathHash -Path $path
    Write-PicassioSuccess "Hash: $($hash)"
}

ParallelStep 'ParallelTest' @(
    {
        Write-PicassioInfo 'PARA1'
    },
    {
        Write-PicassioInfo 'PARA2'
    },
    {
        Start-Sleep -Milliseconds 20
        Write-PicassioInfo 'PARA3'
    }
)

Step 'Windows Feature' {
    $exists = Test-PicassioWindowsFeatureInstalled -Name 'Web-Server' -Optional
    Write-Host "Installed: $($exists)"
}

Send-PicassioSlackMessage -Channel '<CHANNEL>' -Message 'It works!' -APIToken '<TOKEN>' -Colour 'danger'

$fields = @(
    @{
        'title' = 'Status';
        'value' = 'Success';
        'short' = $true
    },
    @{
        'title' = 'Date';
        'value' = [datetime]::Now.ToShortDateString();
        'short' = $true
    },
    @{
        'title' = 'Reason';
        'value' = 'Hey look, this works!';
        'short' = $false
    }
)

Step 'Slack Message' {
    Send-PicassioSlackAttachments -Channel '<CHANNEL>' -APIToken '<TOKEN>' -Colour 'good' -Fallback 'eek' -Fields $fields -Title 'Example Message'
}