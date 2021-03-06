# Picassio2

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Fudge/master/LICENSE.txt)

Picassio2 is a redesigned [Picassio](https://github.com/Badgerati/Picassio) that is `code-over-config`.
Instead of writing a JSON file with steps to run, you can now import the Picassio2 module and write your deployment/automation steps in pure PowerShell. Giving you all the flexibility you could want - you can even run steps in parallel and on remote servers.

* [Installing Picassio2](#installing-picassio2)
* [Features](#features)
* [Description](#description)
* [Example Scripts](#example-scripts)
* [Extensions](#extensions)
* [Bugs and Feature Requests](#bugs-and-feature-requests)

## Installing Picassio2

Coming soon via `Install-Module` and `Chocolatey`.

## Features

Picassio2 allows you to write deployment and automation steps completely in PowerShell, meaning you could just use the `Step` option and then do whatever you want.
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

Picassio2 is a PowerShell module that helps with automating deployment tasks on local or remote servers.

With Picassio2 there are no JSON, YAML, or any other configuration files - everything is written purely in PowerShell.
Unlike with the first Picassio where you needed a JSON file with defined steps, you can now import Picassio2 as a module and then just run the script as you would any other PowerShell script.

## Example Scripts

* Example of running single steps

```powershell
Import-Module Picassio2

Step 'Archive' {
    # archive a directory
    Invoke-PicassioArchive -Path 'C:\path\to\some\folder' -ZipPath 'C:\path\to\some\folder.7z'
}

Write-Host 'Random PowerShell between steps!'

Step 'Build Solution' {
    # run a cake build script
    Invoke-PicassioCake -Path 'C:\path\to\your\repo'
}

Step 'Name' {
    # plus any other powershell you want
}
```

* Example of running a single step on a remote machine

> Picassio2 *will* need to be installed on the remote machine

```powershell
Import-Module Picassio2

Step 'Install Features' -ComputerName 'Name' -Credentials (Get-Credential) {
    # install iis on remote machine
    Install-PicassioWindowsFeature -Name 'Web-Server' -IncludeAllSubFeatures
}
```

* Example of running steps in parallel

```powershell
Import-Module Picassio2

ParallelStep 'Multiple Cake Builds' @(
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

## Extensions

This is a feature pulled over from the original Picassio: Extension scripts. If you have scripts you want to use via Picassio2, and want their functions to be loaded with Picassio2 then place them at:

```plain
C:\Picassio2\Extensions
```

Any PowerShell (`*.ps1`) scripts here will be loaded with the Picassio2 module. If you use remoting any of your steps, then these extensions *will* have to exist on the remote machines as well.

## Bugs and Feature Requests

For any bugs you may find or features you wish to request, please create an [issue](https://github.com/Badgerati/Picassio2/issues "Issues") in GitHub.