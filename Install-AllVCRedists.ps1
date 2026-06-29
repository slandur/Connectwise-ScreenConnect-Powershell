#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy Bypass -Scope Process -Force

# =========================================================
# Install-AllVCRedists.ps1
#
# Downloads and installs official Microsoft
# Visual C++ Redistributables silently.
#
# Safe for:
# - ScreenConnect
# - Intune
# - RMM deployment
# - Windows 10/11
# =========================================================

$downloadRoot = "C:\ProgramData\VCRedists"

if (-not (Test-Path $downloadRoot)) {
    New-Item -Path $downloadRoot -ItemType Directory -Force | Out-Null
}

# ---------------------------------------------------------
# Check Installed VC++ Redistributables
# ---------------------------------------------------------

function Test-VCRedistInstalled {

    param (
        [string]$DisplayNameMatch
    )

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths) {

        $items = Get-ItemProperty $path -ErrorAction SilentlyContinue

        foreach ($item in $items) {

            if ($item.DisplayName -like "*$DisplayNameMatch*") {
                return $true
            }
        }
    }

    return $false
}

# ---------------------------------------------------------
# Package Definitions
# ---------------------------------------------------------

$packages = @(

    # -----------------------------------------------------
    # VC++ 2008 SP1
    # -----------------------------------------------------

    @{
        Name = "VC2008_x86.exe"
        Url  = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"
        Args = "/q"
        Detect = "Microsoft Visual C++ 2008 x86 Redistributable"
    },

    @{
        Name = "VC2008_x64.exe"
        Url  = "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"
        Args = "/q"
        Detect = "Microsoft Visual C++ 2008 x64 Redistributable"
    },

    # -----------------------------------------------------
    # VC++ 2010 SP1
    # -----------------------------------------------------

    @{
        Name = "VC2010_x86.exe"
        Url  = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"
        Args = "/passive /norestart"
        Detect = "Microsoft Visual C++ 2010 x86 Redistributable"
    },

    @{
        Name = "VC2010_x64.exe"
        Url  = "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"
        Args = "/passive /norestart"
        Detect = "Microsoft Visual C++ 2010 x64 Redistributable"
    },

    # -----------------------------------------------------
    # VC++ 2012 Update 4
    # -----------------------------------------------------

    @{
        Name = "VC2012_x86.exe"
        Url  = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"
        Args = "/passive /norestart"
        Detect = "Microsoft Visual C++ 2012 x86 Redistributable"
    },

    @{
        Name = "VC2012_x64.exe"
        Url  = "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
        Args = "/passive /norestart"
        Detect = "Microsoft Visual C++ 2012 x64 Redistributable"
    },

    # -----------------------------------------------------
    # VC++ 2013
    # -----------------------------------------------------

    @{
        Name = "VC2013_x86.exe"
        Url  = "https://aka.ms/highdpimfc2013x86enu"
        Args = "/install /passive /norestart"
        Detect = "Microsoft Visual C++ 2013 x86 Redistributable"
    },

    @{
        Name = "VC2013_x64.exe"
        Url  = "https://aka.ms/highdpimfc2013x64enu"
        Args = "/install /passive /norestart"
        Detect = "Microsoft Visual C++ 2013 x64 Redistributable"
    },

    # -----------------------------------------------------
    # VC++ 2015-2022
    # -----------------------------------------------------

    @{
        Name = "VC2015_2022_x86.exe"
        Url  = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        Args = "/install /quiet /norestart"
        Detect = "Microsoft Visual C++ 2015-2022 x86 Redistributable"
    },

    @{
        Name = "VC2015_2022_x64.exe"
        Url  = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        Args = "/install /quiet /norestart"
        Detect = "Microsoft Visual C++ 2015-2022 x64 Redistributable"
    }
)

# ---------------------------------------------------------
# Process Packages
# ---------------------------------------------------------

foreach ($pkg in $packages) {
    Write-Output ""
    Write-Output "================================================="
    Write-Output "Processing: $($pkg.Name)"
    Write-Output "================================================="

    # -------------------------------------------------
    # Detection Check
    # -------------------------------------------------

    if (Test-VCRedistInstalled -DisplayNameMatch $pkg.Detect) {
        Write-Output "Already installed. Skipping download/install."
        continue
    }


    $filePath = Join-Path $downloadRoot $pkg.Name
    try {

        # -------------------------------------------------
        # Download
        # -------------------------------------------------

        Write-Output "Downloading..."

        Invoke-WebRequest `
            -Uri $pkg.Url `
            -OutFile $filePath `
            -UseBasicParsing `
            -ErrorAction Stop

        Write-Output "Download complete."

        # -------------------------------------------------
        # Unblock
        # -------------------------------------------------

        try {
            Unblock-File $filePath -ErrorAction SilentlyContinue
        }
        catch {}

        # -------------------------------------------------
        # Verify Signature
        # -------------------------------------------------

        $sig = Get-AuthenticodeSignature $filePath

        Write-Output "Signature status: $($sig.Status)"
        if ($sig.Status -ne "Valid") {
            Write-Warning "Invalid signature. Skipping."
            continue
        }

        # -------------------------------------------------
        # Install
        # -------------------------------------------------

        Write-Output "Installing silently..."

        $proc = Start-Process `
            -FilePath $filePath `
            -ArgumentList $pkg.Args `
            -WindowStyle Hidden `
            -Wait `
            -PassThru `
            -ErrorAction Stop

        Write-Output "Exit code: $($proc.ExitCode)"

        switch ($proc.ExitCode) {
            0 {
                Write-Output "Install successful."
            }
            1638 {
                Write-Output "Newer version already installed."
            }
            3010 {
                Write-Output "Install successful. Reboot required."
            }
            default {
                Write-Warning "Installer returned exit code $($proc.ExitCode)"
            }
        }
    }
    catch {
        Write-Warning "Failed: $_"
    }
}

# ---------------------------------------------------------
# Cleanup
# ---------------------------------------------------------

Write-Output ""
Write-Output "Cleaning up..."

Remove-Item `
    -Path $downloadRoot `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

Write-Output ""
Write-Output "All Visual C++ Redistributables processed."