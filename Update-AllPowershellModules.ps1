#!ps
#MaxLength=100000
#timeout=10000000

#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Updates all installed PowerShell modules.

.DESCRIPTION
    Updates installed PowerShell modules from PowerShell Gallery.

    Features:
    - Updates all installed modules
    - Supports exclusions
    - Supports -WhatIf
    - Handles TLS 1.2
    - Logs execution
    - Removes older installed versions
    - Handles publisher certificate changes

.EXAMPLE
    .\Update-PowerShellModules.ps1

.EXAMPLE
    .\Update-PowerShellModules.ps1 -ExcludedModules PSReadLine

.EXAMPLE
    .\Update-PowerShellModules.ps1 -WhatIf

.NOTES
    Version: 1.0.0
#>

#!ps
#MaxLength=100000
#timeout=10000000


[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium'
)]

param
(
    [Parameter()]
    [string[]]
    $ExcludedModules,

    [Parameter()]
    [switch]
    $SkipPublisherCheck,

    [Parameter()]
    [string]
    $LogPath = "$env:TEMP\PowerShellModuleUpdate.log"
)

#region Initialization

$UpdatedCount = 0
$CurrentCount = 0
$FailedCount = 0
$SkippedCount = 0

Start-Transcript -Path $LogPath -Append | Out-Null

if (-not $ExcludedModules)
{
    $ExcludedModules = @()
}

if ($PSVersionTable.PSEdition -eq 'Desktop')
{
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor
        [Net.SecurityProtocolType]::Tls12
}

try
{
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue))
    {
        Register-PSRepository -Default
    }

    Set-PSRepository `
        -Name PSGallery `
        -InstallationPolicy Trusted `
        -ErrorAction SilentlyContinue
}
catch
{
    Write-Warning "Unable to configure PSGallery."
}

#endregion Initialization


#region Functions

function Remove-OldModuleVersions
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $ModuleName
    )

    try
    {
        $Versions = Get-InstalledModule `
            -Name $ModuleName `
            -AllVersions `
            -ErrorAction Stop |
            Sort-Object Version -Descending

        if ($Versions.Count -le 1)
        {
            return
        }

        foreach ($Version in ($Versions | Select-Object -Skip 1))
        {
            Write-Host "Removing old version $ModuleName $($Version.Version)" -ForegroundColor Yellow

            if ($PSCmdlet.ShouldProcess(
                "$ModuleName $($Version.Version)",
                "Remove old version"
            ))
            {
                Uninstall-Module `
                    -Name $ModuleName `
                    -RequiredVersion $Version.Version `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }
    }
    catch
    {
        Write-Warning "$ModuleName cleanup failed: $($_.Exception.Message)"
    }
}

#endregion Functions


#region Main

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " PowerShell Module Update" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$Modules = Get-InstalledModule |
    Sort-Object Name


foreach ($Module in $Modules)
{
    if ($ExcludedModules -contains $Module.Name)
    {
        Write-Host "[SKIPPED] $($Module.Name)" -ForegroundColor Yellow
        $SkippedCount++
        continue
    }


    try
    {
        $GalleryModule = Find-Module `
            -Name $Module.Name `
            -ErrorAction Stop


        $InstalledVersion = [version]$Module.Version
        $LatestVersion = [version]$GalleryModule.Version


        if ($LatestVersion -gt $InstalledVersion)
        {
            Write-Host ""
            Write-Host "[UPDATE] $($Module.Name)" -ForegroundColor Cyan
            Write-Host "$InstalledVersion -> $LatestVersion"


            if ($PSCmdlet.ShouldProcess(
                $Module.Name,
                "Update Module"
            ))
            {

                $Params = @{
                    Name = $Module.Name
                    Force = $true
                    ErrorAction = "Stop"
                }


                if ($SkipPublisherCheck)
                {
                    $Params.SkipPublisherCheck = $true
                }


                Update-Module @Params


                Remove-OldModuleVersions `
                    -ModuleName $Module.Name


                Write-Host "[SUCCESS] $($Module.Name)" -ForegroundColor Green

                $UpdatedCount++
            }
        }
        else
        {
            Write-Host "[CURRENT] $($Module.Name) $InstalledVersion" -ForegroundColor Green

            $CurrentCount++
        }
    }
    catch
    {
        Write-Warning "$($Module.Name): $($_.Exception.Message)"

        $FailedCount++
    }
}

#endregion Main


#region Summary

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host " Summary" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

Write-Host "Updated : $UpdatedCount" -ForegroundColor Green
Write-Host "Current : $CurrentCount" -ForegroundColor Green
Write-Host "Skipped : $SkippedCount" -ForegroundColor Yellow
Write-Host "Failed  : $FailedCount" -ForegroundColor Red

Write-Host ""
Write-Host "Log File: $LogPath" -ForegroundColor Cyan

Stop-Transcript | Out-Null

#endregion Summary