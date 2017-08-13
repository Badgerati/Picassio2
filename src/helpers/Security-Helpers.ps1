
<#
#>
function Set-PicassioFileAccessRule
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $User,
        
        [string]
        $Permission = 'ReadAndExecute',
        
        [string]
        $Inheritance = 'ContainerInherit,ObjectInherit',
        
        [string]
        $Special = 'None',
        
        [ValidateSet('Allow', 'Deny')]
        [string]
        $Access = 'Allow'
    )

    # ensure the path exists
    Test-PicassioPath $Path -ThrowIfNotExists | Out-Null

    # get the ACL
    $acl = Get-Acl -Path $Path

    # check if the user already has access
    $exists = (($acl.Access | ForEach-Object { $_.identityReference.value | Where-Object { $_ -imatch [regex]::Escape($User) } } | Measure-Object).Count -gt 0)
    if ($exists)
    {
        Write-PicassioInfo "User already has permissions setup: $($User)"
        Write-PicassioMessage "> Path: $($Path)"
        return
    }

    # add the access rule
    Write-PicassioInfo "Setting up user with file permissions: $($User) [$($Access)]"
    Write-PicassioMessage "> Path: $($Path)"

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $Permission, $Inheritance, $Special, $Access)
    if (!$?)
    {
        throw 'Failed to create new access rule for user'
    }

    $acl.SetAccessRule($rule) | Out-Null
    if (!$?)
    {
        throw 'Failed to set the access rule to the path'
    }

    Set-Acl -Path $Path -AclObject $acl | Out-Null
    if (!$?)
    {
        throw 'Failed when saving the access rule'
    }

    Write-PicassioSuccess "Access permission setup"
}