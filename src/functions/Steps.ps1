
<#
    Defines a named step of logic that needs to be run. This logic can either be run
    locally or remotely. When running remotely, if you haven't specified credentials
    then the step will request them.

    If you supply a ComputerName that is the local machine, no credentials will be
    requested.
#>
function Step
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [scriptblock]
        $ScriptBlock,

        [string]
        $ComputerName,

        [pscredential]
        $Credentials = $null,

        [switch]
        $UseSSL
    )

    # check if ComputerName is the local machine
    $localMachine = Test-PicassioLocalComputer $ComputerName

    # if it's not local, we need credentials to run remote commands if the Credentials weren't supplied
    if (!$localMachine -and $Credentials -eq $null)
    {
        $Credentials = (Get-Credential -Message "Picassio requires your credentials to run commands remotely on $($ComputerName)")
        if ($Credentials -eq $null)
        {
            throw "No credentials supplied to run commands remotely on $($ComputerName)"
        }
    }

    # if local, set ComputerName to actual $env:COMPUTERNAME
    if ($localMachine)
    {
        $ComputerName = $env:COMPUTERNAME
    }

    # attempt to run the step logic
    try
    {
        # output step headers
        Write-PicassioEmpty
        Write-PicassioHeader $Name
        Write-PicassioWarning "Computer: $ComputerName"

        # start time
        $start = [datetime]::UtcNow

        # run on the local machine
        if ($localMachine)
        {
            & $ScriptBlock
        }

        # else run script remotely
        else
        {
            Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ArgumentList $ScriptBlock -ScriptBlock {
                param(
                    [ValidateNotNull()]
                    [scriptblock]
                    $StepLogic
                )

                Import-Module -Name Picassio2 -ErrorAction Stop
                & $StepLogic
            } -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck) -UseSSL:$UseSSL
        }

        # display duration
        Write-PicassioMessage "Duration: $([datetime]::UtcNow - $start)"

        # blank line for neatness
        Write-PicassioEmpty
    }
    catch [exception]
    {
        Write-PicassioException $_.Exception
        throw
    }
}


<#
    invokes multiple 'Step' steps in parallel
#>
function ParallelStep
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [scriptblock[]]
        $ScriptBlocks,

        [string]
        $ComputerName,

        [pscredential]
        $Credentials = $null
    )

    $jobs=  @()
    $modulePath = (Get-Module -Name Picassio2).Path

    foreach ($block in $ScriptBlocks)
    {
        $code = {
            param (
                [string]
                $block
            )

            Import-Module $using:modulePath -ErrorAction Stop

            $sb = ([scriptblock]::Create($block))
            Step -Name $using:Name -ScriptBlock $sb -ComputerName $using:ComputerName -Credentials $using:Credentials
        }

        $jobs += Start-Job -ScriptBlock $code -ArgumentList $block
    }

    while (($jobs | Measure-Object).Count -gt 0)
    {
        $completed = Get-Job | Where-Object { $jobs.Name -icontains $_.Name -and $_.State -ieq 'completed' }

        if (($completed | Measure-Object).Count -eq 0)
        {
            Start-Sleep -Milliseconds 50
        }
        else
        {
            $completed | Receive-Job
            $jobs = ($jobs | Where-Object { $completed.Name -inotcontains $_.Name })
        }
    }
}