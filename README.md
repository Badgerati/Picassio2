# Picassio2

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Fudge/master/LICENSE.txt)

Picassio2 is a redesigned [Picassio](https://github.com/Badgerati/Picassio) that is `code-over-config`.
Instead of writing a JSON file with steps to run, you can now import the Picassio2 module and write your steps in pure PowerShell. Giving you all the flexibility you could want!

* [Installing Picassio2](#installing-picassio2)
* [Features](#features)
* [Description](#description)
* [Example Scripts](#example-scripts)
* [Bugs and Feature Requests](#bugs-and-feature-requests)

## Installing Picassio2

Coming soon via `Install-Module` and `Chocolatey`.

## Features

Picassio2 allows you to write steps completely in PowerShell, meaning you could just use the `Invoke-Step` option and then do whatever you want.
Though to make your lives easier, Picassio2 comes with some inbuilt functions:

* Ability to use general PowerShell inside and outside of Picassio2's steps
* Archive and Extract files/directories with 7-zip
* Run Cake build scripts for your projects
* Copy files/directories, create temporary directories, and create temporary network drives to remote systems
* Create and remove websites, application pools and bindings in IIS
* Create and remove Windows Services
* Install and uninstall Windows Features and Optional Features
* Test if software is installed and fail if not installed
* Setup ACL permissions on files and directories
* Run steps on remote machines - requires Picassio2 to be installed on remote machine
* Install software using chocolatey (will self-install chocolatey)
* Manage databases using SSDT scripts
* Post messages to Slack channels!
* And many more...

## Description

With Picassio2 there are no JSON, YAML, or any other configuration files - everything is written purely in PowerShell.
Unlike with the first Picassio where you needed a JSON file with defined steps, you can now import Picassio2 as a module and then just run the script as you would any other PowerShell script.

## Example Scripts

* Example of running single steps

```powershell
Import-Module Picassio2

Invoke-Step 'Archive' {
    # archive a directory
    Invoke-PicassioArchive -Path 'C:\path\to\some\folder' -ZipPath 'C:\path\to\some\folder.7z'
}

Write-Host 'Random PowerShell between steps!'

Invoke-Step 'Build Solution' {
    # run a cake build script
    Invoke-PicassioCake -Path 'C:\path\to\your\repo'
}

Invoke-Step 'Name' {
    # plus any other powershell you want
}
```

* Example of running a single step on a remote machine

> Picassio2 *will* need to be installed on the remote machine

```powershell
Import-Module Picassio2

Invoke-Step 'Install Features' -ComputerName 'Name' -Credentials (Get-Credential) {
    # install iis on remote machine
    Install-PicassioWindowsFeature -Name 'Web-Server' -IncludeAllSubFeatures
}
```

* Example of running steps in parallel

```powershell
Import-Module Picassio2

Invoke-ParallelStep 'Multiple Cake Builds' @(
    {
        Invoke-PicassioCake -Path 'C:\path\to\your\repo1'
    },
    {
        Invoke-PicassioCake -Path 'C:\path\to\your\repo2'
    },
    {
        Invoke-PicassioCake -Path 'C:\path\to\your\repo3'
    }
)
```

How do you run these scripts? Well, if you save the last example as `build-cake.ps1`, then to run it just do:

```powershell
> .\build-cake.ps1
```

Yes, it's that simple!

## Bugs and Feature Requests

For any bugs you may find or features you wish to request, please create an [issue](https://github.com/Badgerati/Picassio2/issues "Issues") in GitHub.