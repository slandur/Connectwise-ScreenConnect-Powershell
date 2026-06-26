# ConnectWise Command Reference

A reference sheet for ConnectWise remote commands used in day-to-day endpoint management at work.

---

## Table of Contents

- [ADD-GOGUARDIAN LICENSE](#add-goguardian-license)
- [ADD-PRINTER](#add-printer)
- [CHANGE-PRINTER IP](#change-printer-ip)
- [CLOSE-EDGE](#close-edge)
- [ENABLE-TOUCHSCREEN](#enable-touchscreen)
- [FIX-HOVERCAM SHORTCUT](#fix-hovercam-shortcut)
- [GET-AUDIO DEVICE](#get-audio-device)
- [GET-PRINTER LIST](#get-printer-list)
- [GET-SERIAL NUMBER](#get-serial-number)
- [OPEN-EDGE](#open-edge)
- [REBOOT-TASKBAR](#reboot-taskbar)
- [REMOTE LOCK-DEVICE](#remote-lock-device)
- [REMOTE UNLOCK-DEVICE](#remote-unlock-device)
- [REMOVE-PRINTER](#remove-printer)
- [RENAME-COMPUTER](#rename-computer)
- [RESTART-DEVICE](#restart-device)
- [RESTART-PRINT SPOOLER](#restart-print-spooler)
- [RUN-DELL COMMAND UPDATE](#run-dell-command-update)
- [RUN-HP IMAGE ASSIST UPDATE](#run-hp-image-assistant-update)
- [SET-AUDIO DEVICE](#set-audio-device)
- [SET-AUTOLOGON REGKEYS](#set-autologon-regkeys)
- [SET-AUTOLOGON SYSINTERNALS](#set-autologon-sysinternals)
- [SHOW-IP](#show-ip)
- [SWITCH-USER](#switch-user)
- [SYNC-COMPANY PORTAL](#sync-company-portal)
- [SYNC-TIME](#sync-time)
- [UPDATE-WINDOWS](#update-windows)

---

## ADD-GOGUARDIAN LICENSE

> Adds the GoGuardian license registry key via ConnectWise command line. Forces an immediate reboot.

```cmd
reg add "HKLM\SOFTWARE\Policies\GoGuardian" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v LicenseTag /t REG_SZ /d "<LICENSE NUMBER>" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v MinimizeToSystemTray /t REG_SZ /d "true" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v StartMinimizedToSystemTray /t REG_SZ /d "true" /f & shutdown /r /f /t 0
```

---

## ADD-PRINTER

> Adds a printer by IP address and name using the Lexmark Universal v2 XL driver.
> ⚠️ **Change `$IPAddress` and `$PrinterName` before running.**
> Check existing printers first with [GET-PRINTER LIST](#get-printer-list).

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$IPAddress   = "10.x.x.x"
$PrinterName = "Lexmark CX735"
$Driver      = "Lexmark Universal v2 XL"

Add-PrinterPort -Name "$IPAddress" -PrinterHostAddress "$IPAddress"
Add-Printer -Name "$PrinterName" -PortName "$IPAddress" -DriverName "$Driver"
```

---

## CHANGE-PRINTER IP

> Updates the port/IP address of an existing printer.
> ⚠️ **Set `$OldIP` and `$NewIP` to the correct values before running.**

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$OldIP = "10.x.x.x"
$NewIP = "10.x.x.x"

# Get printers using the old IP port
$Printers = Get-Printer | Where-Object { $_.PortName -like "*$OldIP*" }

# Check if any printer already uses the new IP port
$ExistingNewIPPrinter = Get-Printer | Where-Object { $_.PortName -eq $NewIP }
if ($ExistingNewIPPrinter) {
    Write-Host "A printer already exists using port $NewIP. No changes made."
    return
}

# Add new port only if it doesn't already exist
if (-not (Get-PrinterPort | Where-Object { $_.Name -eq $NewIP })) {
    Add-PrinterPort -Name $NewIP -PrinterHostAddress $NewIP
}

if ($Printers) {
    foreach ($Printer in $Printers) {
        Write-Host "Updating printer '$($Printer.Name)' to use port $NewIP"
        Set-Printer -Name $Printer.Name -PortName $NewIP
    }
}
```

---

## CLOSE-EDGE

> Force-kills Microsoft Edge. To reopen it, use [OPEN-EDGE](#open-edge).

```cmd
taskkill /IM msedge.exe /F
```

---

## OPEN-EDGE

> Launches Microsoft Edge.

```cmd
start "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
```

---

## ENABLE-TOUCHSCREEN

> Re-enables a disabled touchscreen HID driver.

```powershell
powershell -command "Get-PnpDevice -Class 'HIDClass' | Where-Object {$_.FriendlyName -like '*touch screen*'} | Enable-PnpDevice -Confirm:$false"
```

---

## FIX-HOVERCAM SHORTCUT

> Removes the broken Hovercam Flex11 desktop shortcut and recreates it pointing to the correct executable.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$DesktopPath  = "C:\Users\Public\Desktop"
$OldShortcut  = Join-Path $DesktopPath "Hovercam Flex11.lnk"

if (Test-Path $OldShortcut) {
    Remove-Item $OldShortcut -Force
    Write-Output "Old shortcut removed: $OldShortcut"
} else {
    Write-Output "Old shortcut not found, nothing to remove."
}

$ShortcutPath = Join-Path $DesktopPath "Hovercam Flex11.lnk"
$TargetPath   = "C:\Program Files (x86)\Hovercam Flex11_v4\Flex11App.exe"

Write-Output "Creating new shortcut: $ShortcutPath"
Write-Output " → Target: $TargetPath"

$WScriptShell = New-Object -ComObject WScript.Shell

try {
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.WorkingDirectory = Split-Path $TargetPath
    $Shortcut.Save()
    Write-Output "Shortcut successfully created."
} catch {
    Write-Output "ERROR: Failed to create shortcut. $($_.Exception.Message)"
}
```

---

## GET-AUDIO DEVICE

> Lists all audio devices on the target machine.

```powershell
#!ps
Get-AudioDevice -list
```

---

## GET-PRINTER LIST

> Lists all printers currently installed on the target computer.

```cmd
Powershell -command "Get-Printer"
```

**Sample Output:**

```
Name                  ComputerName  Type   DriverName                    PortName          Shared  Published
----                  ------------  ----   ----------                    --------          ------  ---------
Send to SMART Notebook              Local  SMART Notebook Documen...     SMRTPort2:        False   False
Send to SMART Cloud                 Local  SMART Notebook Documen...     SMRTPort:         False   False
OneNote (Desktop)                   Local  Send to Microsoft OneN...     nul:              False   False
Microsoft Print to PDF              Local  Microsoft Print To PDF        PORTPROMPT:       False   False
Lexmark Secure Print                Local  Lexmark Universal v2 XL       LPM Server Port   False   False
Lexmark X725                        Local  Lexmark Universal v2 XL       172.16.x.x       False   False
Adobe PDF                           Local  Adobe PDF Converter           Documents\*.pdf   False   False
```

---

## GET-SERIAL NUMBER

> Outputs the serial number of the target device instantly.

```cmd
wmic bios get serialnumber
```

---

## REBOOT-TASKBAR

> Kills and restarts `explorer.exe` — a "soft reboot" of the desktop, Start menu, Taskbar, and file manager. Explorer always restarts itself automatically after being killed.

```cmd
taskkill /IM explorer.exe /F
```

---

## REMOTE LOCK-DEVICE

> Locks the device so no one can log in. Sets a legal notice on the login screen and excludes all credential providers. Forces a logoff if a user is currently signed in.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$LegalNoticeTitle   = "Computer Locked"
$LegalNoticeMessage = "This computer has been locked. Please bring this laptop to the tech office."

$RegistryCredentialProviders = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers').PSChildName

$CredentialProviders = "<CREDENTIALS NUMBERS>"

$RegistryPath   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryNames  = @("LegalNoticeCaption","LegalNoticeText","ExcludedCredentialProviders")
$RegistryValues = @("$LegalNoticeTitle","$LegalNoticeMessage","$CredentialProviders")

$i = 0
While ($i -lt $RegistryNames.Count) {
    $Value = Get-ItemProperty -Path $RegistryPath -Name $RegistryNames[$i] -ErrorAction SilentlyContinue
    if ($Value.($RegistryNames[$i]) -ne $($RegistryValues[$i])) {
        Write-Output "$($RegistryNames[$i]) Not Set. Setting registry value for $($RegistryNames[$i])."
        Set-ItemProperty -Path $RegistryPath -Name $($RegistryNames[$i]) -Value $($RegistryValues[$i])
    } else {
        Write-Output "$($RegistryNames[$i]) Already Set."
    }
    $i++
}

# Force log off if user is signed in
If ((Get-CimInstance -ClassName Win32_ComputerSystem).Username -ne $null) {
    Invoke-CimMethod -Query 'SELECT * FROM Win32_OperatingSystem' -MethodName 'Win32ShutdownTracker' -Arguments @{ Flags = 4; Comment = 'Computer Locked' }
} Else {
    # Restart sign-in screen if user is not signed in
    Stop-Process -Name LogonUI
}
```

---

## REMOTE UNLOCK-DEVICE

> Clears the legal notice and credential provider exclusions set by [REMOTE LOCK-DEVICE](#remote-lock-device), then restarts the login screen.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$LegalNoticeTitle   = ""
$LegalNoticeMessage = ""
$CredentialProviders = ""

$RegistryPath   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$RegistryNames  = @("LegalNoticeCaption","LegalNoticeText","ExcludedCredentialProviders")
$RegistryValues = @("$LegalNoticeTitle","$LegalNoticeMessage","$CredentialProviders")

$i = 0
While ($i -lt $RegistryNames.Count) {
    $Value = Get-ItemProperty -Path $RegistryPath -Name $RegistryNames[$i] -ErrorAction SilentlyContinue
    if ($Value.($RegistryNames[$i]) -ne $($RegistryValues[$i])) {
        Write-Output "$($RegistryNames[$i]) Not Set. Setting registry value for $($RegistryNames[$i])."
        Set-ItemProperty -Path $RegistryPath -Name $($RegistryNames[$i]) -Value $($RegistryValues[$i])
    } else {
        Write-Output "$($RegistryNames[$i]) Already Set."
    }
    $i++
}

# Restart sign-in screen
Stop-Process -Name LogonUI
```

---

## REMOVE-PRINTER

> Removes a printer by exact name.
> ⚠️ **Change the printer name to match exactly — spelling is case-sensitive.**
> Use [GET-PRINTER LIST](#get-printer-list) to confirm the name first.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Remove-Printer -Name "Lexmark CS410n - Rm 235"
```

---

## RENAME-COMPUTER

> Renames the computer. **Requires a restart to take effect.**

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Rename-Computer "<COMPUTER NAME>"
```

To restart after renaming:

```cmd
shutdown -r
```

---

## RESTART-DEVICE

> Forces an immediate restart. Change `0` to a number of seconds to delay the restart.

```cmd
shutdown /f /r /t 0
```

---

## RESTART-PRINT SPOOLER

> Stops the print spooler, clears the print queue, and restarts the spooler. Useful for stuck print jobs.

```cmd
net stop spooler

echo y|del C:\Windows\System32\spool\PRINTERS\*.*

net start spooler
```

---

## RUN-DELL COMMAND UPDATE

> Runs Dell Command Center to update Dell computer.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$dcuCli = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
$updateArgs = "-updateType=bios,firmware,driver -updateSeverity=security,critical,recommended"
$rebootMessage = "This computer will restart in two minutes. Please save and close your work."

function Invoke-Reboot {
    Write-Output "DCU requires reboot before continuing. Initiating restart in 2 minutes."
    Start-Process -FilePath "shutdown.exe" -ArgumentList "/f /r /t 120 /c `"$rebootMessage`"" -NoNewWindow -Wait
}

$dcuScan = Start-Process -NoNewWindow -Wait -PassThru -FilePath $dcuCli -ArgumentList "/scan $updateArgs"

switch ($dcuScan.ExitCode) {
    0   { Write-Output "DCU scan completed successfully. Proceeding with updates." }
    500 { Write-Output "DCU skipped: System is up to date."; exit 0 }
    default {
        Write-Output "DCU scan failed with exit code: $($dcuScan.ExitCode)"
        exit $dcuScan.ExitCode
    }
}

$dcuResult = Start-Process -NoNewWindow -Wait -PassThru -FilePath $dcuCli -ArgumentList "/applyUpdates $updateArgs -reboot=enable -silent -autoSuspendBitLocker=enable"

switch ($dcuResult.ExitCode) {
    0    { Write-Output "DCU applyUpdates completed successfully." }
    1    { Invoke-Reboot }
    5    { Invoke-Reboot }
    500  { Write-Output "DCU skipped: System is up to date." }
    3006 { Write-Output "DCU skipped: System is in OOBE state. Please log in to finish the feature update, then run this script again." }
    default {
        Write-Output "DCU applyUpdates failed with exit code: $($dcuResult.ExitCode)"
        exit $dcuResult.ExitCode
    }
}
```

---

## RUN-HP IMAGE ASSIST UPDATE

> Runs HP Image Assistant to update HP computer.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

<#
Intune Proactive Remediation -- Remediation Script

Installs HPIA, runs List then Install.
Reboots on exit 3010 unless ESP/Autopilot is in progress.
#>

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
$BIOSPwdData       = 'X0hQUFcxMl8gALaGb6FgBbUuJxWXwexIBDddH4AGPEV1SJh1I3d+M78S'

# Softpaqs excluded from installation (wildcard name patterns)
$ExcludedSoftpaqs = @(
    '*Wacom*'
    # '*Realtek Audio*'
    # '*Intel Wireless*'
)
$HPIAStagingFolder = "$env:ProgramData\HP\HPIAUpdateService"
$HPIAStagingLogs   = "$HPIAStagingFolder\LogFiles"
$HPIAStagingReports= "$HPIAStagingFolder\Reports"
$HPIAStagingProgram= "$env:ProgramFiles\HPIA"

try {
    [void][System.IO.Directory]::CreateDirectory($HPIAStagingFolder)
    [void][System.IO.Directory]::CreateDirectory($HPIAStagingLogs)
    [void][System.IO.Directory]::CreateDirectory($HPIAStagingReports)
    [void][System.IO.Directory]::CreateDirectory($HPIAStagingProgram)
}
catch { throw }

# ---------------------------------------------------------
# Manufacturer check
# ---------------------------------------------------------
$manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
if ($manufacturer -notlike '*HP*' -and $manufacturer -notlike '*Hewlett*') {
    Write-Output 'Not an HP device. Skipping.'
    exit 0
}

# ---------------------------------------------------------
# ESP / Autopilot detection
# HasProvisioningCompleted: 0 = active ESP, 1 = complete, 4294967295 = stale
# ---------------------------------------------------------
$espKey   = 'HKLM:\SOFTWARE\Microsoft\Windows\Autopilot\EnrollmentStatusTracking\Device\Setup'
$espProps = Get-ItemProperty -Path $espKey -ErrorAction SilentlyContinue
$inESP    = ($null -ne $espProps) -and ($espProps.HasProvisioningCompleted -eq 0)
if ($inESP) { Write-Output 'Autopilot/ESP in progress. Reboot will be suppressed if updates are installed.' }

#region Functions

Function Install-HPIA {
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        $HPIAInstallPath = "$env:ProgramFiles\HP\HPIA\bin"
        )
    $script:TempWorkFolder = "$env:windir\Temp\HPIA"
    $ProgressPreference = 'SilentlyContinue'
    $HPIACABUrl = "https://hpia.hpcloud.hp.com/HPIAMsg.cab"

    try {
        [void][System.IO.Directory]::CreateDirectory($HPIAInstallPath)
        [void][System.IO.Directory]::CreateDirectory($TempWorkFolder)
    }
    catch { throw }

    $OutFile = "$TempWorkFolder\HPIAMsg.cab"
    Invoke-WebRequest -Uri $HPIACABUrl -UseBasicParsing -OutFile $OutFile
    if (Test-Path "$env:windir\System32\expand.exe") {
        try { Start-Process cmd.exe -ArgumentList "/c C:\Windows\System32\expand.exe -F:* $OutFile $TempWorkFolder\HPIAMsg.xml" -Wait }
        catch { Write-Output "Could not expand CAB." }
    }
    if (Test-Path -Path "$TempWorkFolder\HPIAMsg.xml") {
        [XML]$HPIAXML = Get-Content -Path "$TempWorkFolder\HPIAMsg.xml"
        $HPIADownloadURL = $HPIAXML.ImagePal.HPIALatest.SoftpaqURL
        $HPIAVersion     = $HPIAXML.ImagePal.HPIALatest.Version
        $HPIAFileName    = $HPIADownloadURL.Split('/')[-1]
    }
    else {
        $HPIAWebUrl = "https://ftp.hp.com/pub/caps-softpaq/cmit/HPIA.html"
        try { $HTML = Invoke-WebRequest -Uri $HPIAWebUrl -ErrorAction Stop }
        catch { Write-Output "Failed to download the HPIA web page. $($_.Exception.Message)"; throw }
        $HPIADownloadURL = ($HTML.Links | Where-Object { $_.href -match "hp-hpia-" }).href
        $HPIAFileName    = $HPIADownloadURL.Split('/')[-1]
        $HPIAVersion     = ($HPIAFileName.Split("-") | Select-Object -Last 1).Replace(".exe","")
    }

    Write-Output "Latest HPIA version: $HPIAVersion ($HPIAFileName)"

    $HPIAIsCurrent = $false
    If (Test-Path "$HPIAInstallPath\HPImageAssistant.exe") {
        $HPIAExtractedVersion = (Get-Item "$HPIAInstallPath\HPImageAssistant.exe").VersionInfo.FileVersion
        if ($HPIAExtractedVersion -match $HPIAVersion) {
            Write-Output "HPIA $HPIAVersion already installed. Skipping download."
            $HPIAIsCurrent = $true
        }
        else {
            Write-Output "Installed version ($HPIAExtractedVersion) differs from latest ($HPIAVersion). Updating."
        }
    }

    if ($HPIAIsCurrent -eq $false) {
        Write-Output "Downloading HPIA..."
        if (!(Test-Path -Path "$TempWorkFolder\$HPIAFileName")) {
            try {
                $ExistingBitsJob = Get-BitsTransfer -Name "$HPIAFileName" -AllUsers -ErrorAction SilentlyContinue
                If ($ExistingBitsJob) { Remove-BitsTransfer -BitsJob $ExistingBitsJob }
                $BitsJob = Start-BitsTransfer -Source $HPIADownloadURL -Destination "$TempWorkFolder\$HPIAFileName" -Asynchronous -DisplayName "$HPIAFileName" -Description "HPIA download" -RetryInterval 60 -ErrorAction Stop
                do {
                    Start-Sleep -Seconds 5
                    $Progress = [Math]::Round((100 * ($BitsJob.BytesTransferred / $BitsJob.BytesTotal)), 2)
                    Write-Output "Downloaded $Progress%"
                } until ($BitsJob.JobState -in ("Transferred","Error"))
                If ($BitsJob.JobState -eq "Error") { Write-Output "BITS transfer failed: $($BitsJob.ErrorDescription)"; throw }
                Complete-BitsTransfer -BitsJob $BitsJob
                Write-Output "BITS transfer complete."
            }
            catch { Write-Output "Failed to start BITS transfer: $($_.Exception.Message)"; throw }
        }
        else { Write-Output "$HPIAFileName already downloaded. Skipping." }

        Write-Output "Extracting HPIA..."
        try {
            Start-Process -FilePath "$TempWorkFolder\$HPIAFileName" -WorkingDirectory $HPIAInstallPath -ArgumentList "/s /f .\ /e" -NoNewWindow -PassThru -Wait -ErrorAction Stop | Out-Null
            Start-Sleep -Seconds 5
            If (Test-Path "$HPIAInstallPath\HPImageAssistant.exe") { Write-Output "Extraction complete." }
            Else { Write-Output "HPImageAssistant.exe not found after extraction."; throw }
        }
        catch { Write-Output "Failed to extract HPIA: $($_.Exception.Message)"; throw }
    }
}

Function Run-HPIA {
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet("Analyze","DownloadSoftPaqs")]
        $Operation = "Analyze",
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","BIOS","Drivers","Software","Firmware","Accessories","BIOS,Drivers,Firmware")]
        $Category = "BIOS,Drivers,Firmware",
        [Parameter(Mandatory=$false)]
        [ValidateSet("All","Critical","Recommended","Routine")]
        $Selection = "All",
        [Parameter(Mandatory=$false)]
        [ValidateSet("List","Download","Extract","Install","UpdateCVA")]
        $Action = "List",
        [Parameter(Mandatory=$false)]
        $LogFolder = "$env:systemdrive\ProgramData\HP\Logs",
        [Parameter(Mandatory=$false)]
        $ReportsFolder = "$env:systemdrive\ProgramData\HP\HPIA",
        [Parameter(Mandatory=$false)]
        $HPIAInstallPath = "$env:ProgramFiles\HP\HPIA\bin",
        [Parameter(Mandatory=$false)]
        $ReferenceFile,
        [Parameter(Mandatory=$false)]
        $BIOSPwdData,
        [Parameter(Mandatory=$false)]
        [switch]$AutoCleanup
        )

    $DateTime = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:CurrentReportsFolder = "$ReportsFolder\$DateTime"
    $script:TempWorkFolder = "$env:temp\HPIA"
    try {
        [void][System.IO.Directory]::CreateDirectory($LogFolder)
        [void][System.IO.Directory]::CreateDirectory($TempWorkFolder)
        [void][System.IO.Directory]::CreateDirectory($script:CurrentReportsFolder)
        [void][System.IO.Directory]::CreateDirectory($HPIAInstallPath)
    }
    catch { throw }

    Install-HPIA -HPIAInstallPath $HPIAInstallPath

    $HPIAArgs = "/Operation:$Operation /Category:$Category /Selection:$Selection /Action:$Action /Silent /Debug /IgnoreGenericOsError /NoReboot /ReportFolder:$script:CurrentReportsFolder"
    if ($AutoCleanup)   { $HPIAArgs += " /AutoCleanup" }
    if ($BIOSPwdData)   { $HPIAArgs += " /BIOSPwdData:$BIOSPwdData" }
    if ($ReferenceFile) { $HPIAArgs += " /ReferenceFile:$ReferenceFile" }

    Write-Output "Running HPIA with args: $HPIAArgs"

    try {
        $Process = Start-Process -FilePath "$HPIAInstallPath\HPImageAssistant.exe" -WorkingDirectory $TempWorkFolder -ArgumentList $HPIAArgs -NoNewWindow -PassThru -Wait -ErrorAction Stop

        switch ($Process.ExitCode) {
            0    { Write-Output "Exit 0 -- HPIA complete." }
            256  { Write-Output "Exit 256 -- No recommendations found." }
            257  { Write-Output "Exit 257 -- No recommendations selected." }
            3010 { Write-Output "Exit 3010 -- Updates installed. Reboot required."; $script:RebootRequired = $true }
            3020 { Write-Output "Exit 3020 -- One or more installs failed." }
            4096 { Write-Output "Exit 4096 -- Platform not supported." }
            default { Write-Output "Exit $($Process.ExitCode)." }
        }

        return $Process.ExitCode
    }
    catch {
        Write-Output "Failed to run HPImageAssistant.exe: $($_.Exception.Message)"
        throw
    }
}

Function Get-HPIARecommendations {
    param([string]$ReportFolder)

    $reportJson = Get-ChildItem -Path $ReportFolder -Filter '*.json' -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $reportJson) { Write-Output 'No JSON report found.'; return @() }

    try { $json = Get-Content -Path $reportJson.FullName -ErrorAction Stop | ConvertFrom-Json }
    catch { Write-Output "Could not parse report JSON: $_"; return @() }

    if (-not $json.HPIA.Recommendations) { return @() }

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($rec in $json.HPIA.Recommendations) {
        $results.Add([PSCustomObject]@{
            SoftpaqName  = $rec.Name
            SoftpaqId    = $rec.SoftPaqID
            AvailableVer = $rec.RecommendationValue
            Comments     = $rec.Comments
            SSMCompliant = $rec.SSMCompliant
            DPBCompliant = $rec.DPBCompliant
            Severity     = $rec.Severity
        })
    }
    return $results
}

#endregion

# Disable IE First Run Wizard
$IEMainPath = "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main"
if (-not (Test-Path $IEMainPath)) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer" -Name "Main" -Force | Out-Null
}
if ((Get-ItemProperty -Path $IEMainPath -ErrorAction SilentlyContinue).DisableFirstRunCustomize -ne 1) {
    New-ItemProperty -Path $IEMainPath -Name "DisableFirstRunCustomize" -PropertyType DWORD -Value 1 -Force | Out-Null
}

# ---------------------------------------------------------
# List phase
# ---------------------------------------------------------
$listExitCode = Run-HPIA -Operation Analyze -Category 'BIOS,Drivers,Firmware' -Selection All -Action List `
    -LogFolder $HPIAStagingLogs -ReportsFolder $HPIAStagingReports -HPIAInstallPath $HPIAStagingProgram `
    -BIOSPwdData $BIOSPwdData

if ($listExitCode -eq 256 -or $listExitCode -eq 257) {
    Write-Output 'Summary: No updates found. Remediation complete.'
    exit 0
}

# Parse JSON for detail output -- capture folder before Install phase overwrites $script:CurrentReportsFolder
$listReportFolder = $script:CurrentReportsFolder
$allRecs = @(Get-HPIARecommendations -ReportFolder $listReportFolder)

Write-Output ''
Write-Output "Recommendations ($($allRecs.Count) total):"
Write-Output ('-' * 60)
foreach ($rec in $allRecs) {
    Write-Output "  $($rec.SoftpaqName) ($($rec.SoftpaqId))"
    Write-Output "    Available : $($rec.AvailableVer)"
    Write-Output "    Severity  : $($rec.Severity)"
    Write-Output "    Comments  : $($rec.Comments)"
    Write-Output "    SSM       : $($rec.SSMCompliant)   DPB: $($rec.DPBCompliant)"
    Write-Output ''
}
Write-Output ('-' * 60)

$filteredRecs = $allRecs | Where-Object {
    $name = $_.SoftpaqName
    -not ($ExcludedSoftpaqs | Where-Object { $name -like $_ })
}

if ($filteredRecs.Count -gt 0 -and $filteredRecs.Count -lt $allRecs.Count) {
    $excludedNames = ($allRecs | Where-Object {
        $name = $_.SoftpaqName
        ($ExcludedSoftpaqs | Where-Object { $name -like $_ })
    } | ForEach-Object { $_.SoftpaqName }) -join ', '
    Write-Output "Excluded from installation: $excludedNames"
}

if ($filteredRecs.Count -eq 0) {
    Write-Output 'Summary: No applicable updates after exclusions. Remediation complete.'
    exit 0
}

# ---------------------------------------------------------
# Install phase
# ---------------------------------------------------------
$installExitCode = Run-HPIA -Operation Analyze -Category 'BIOS,Drivers,Firmware' -Selection All -Action Install `
    -LogFolder $HPIAStagingLogs -ReportsFolder $HPIAStagingReports -HPIAInstallPath $HPIAStagingProgram `
    -BIOSPwdData $BIOSPwdData -AutoCleanup

$rebootStatus = if ($installExitCode -eq 3010) { 'Reboot required' } else { 'No reboot required' }

if ($installExitCode -eq 3010) {
    if ($inESP) {
        Write-Output 'ESP/Autopilot in progress. Skipping shutdown -- Intune will handle the restart.'
    }
    else {
        Write-Output 'Initiating shutdown in 120 seconds...'
        Manage-bde -protectors -Disable C: -RebootCount 1
        shutdown /f /r /t 120 /c "This computer will restart in two minutes. Please save and close your work."
    }
}

$pendingNames = $filteredRecs | ForEach-Object { $_.SoftpaqName }
Write-Output "Summary: Remediation complete. Processed ($($filteredRecs.Count)): $($pendingNames -join ', '). $rebootStatus."
```

---

## SET-AUDIO DEVICE

> Sets a specific audio device as the active output by index number.
> Run [GET-AUDIO DEVICE](#get-audio-device) first to see available devices and their index numbers.

```cmd
Powershell -command "Set-AudioDevice -Index 1"
```

---

## SET-AUTOLOGON REGKEYS

> Configures auto-logon via registry keys for the `USERNAME` user account.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon"   -Value "1"          -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultUsername"  -Value "<USERNAME>" -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultPassword"  -Value "<PASSWORD>"  -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName"-Value "<DOMAIN NAME>" -Type String -Force
```

---

## SET-AUTOLOGON SYSINTERNALS

> Configures auto-logon using Sysinternals AutoLogon64 for the `USERNAME@DOMAINNAME.COM` account.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

$Username     = "USERNAME@DOMAINNAME.COM"
$Domain       = "AzureAD"
$Password     = "<PASSWORD>"
$AutologonPath = "C:\Users\<USERNAME>\Desktop\AutoLogon\Autologon64.exe"

Start-Process -FilePath $AutologonPath -ArgumentList "/accepteula $Username $Domain $Password" -Wait
```

---

## SHOW-IP

> Displays full IP configuration including subnet mask and default gateway.

```cmd
ipconfig /all
```

**Sample Output:**

```
Connection-specific DNS Suffix  . : domain.local
IPv4 Address. . . . . . . . . . . : 172.16.x.x
Subnet Mask . . . . . . . . . . . : 255.255.255.0
Default Gateway . . . . . . . . . : 172.16.x.254
```

---

## SWITCH-USER

> Re-enables the Switch User button (Fast User Switching).
> ⚠️ If the computer name contains `LAB` or `CART`, the Intune policy will re-apply and disable it again. Rename the computer first if needed.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

$regPath   = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$valueName = 'HideFastUserSwitching'

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

$currentValue = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction SilentlyContinue).$valueName

if ($currentValue -eq 1) {
    Set-ItemProperty -Path $regPath -Name $valueName -Value 0 -Type DWord
    Write-Output "Fast User Switching was disabled. It has now been enabled."
} elseif ($currentValue -eq $null) {
    New-ItemProperty -Path $regPath -Name $valueName -Value 0 -PropertyType DWord -Force
    Write-Output "Fast User Switching value was missing. It has now been created and enabled."
} else {
    Write-Output "Fast User Switching is already enabled."
}
```

---

## SYNC-COMPANY PORTAL

> Forces a sync of the Company Portal by triggering the `PushLaunch` scheduled task.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Get-ScheduledTask | ? {$_.TaskName -eq 'PushLaunch'} | Start-ScheduledTask
```

---

## SYNC-TIME

> Forces a time sync on the device.

```cmd
W32tm /resync /force
```

---

## UPDATE-WINDOWS

> Installs all available Windows Updates and automatically reboots.
> To suppress the reboot, remove `-AutoReboot` from the last line.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}

if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
    Write-Host "Installing module: PSWindowsUpdate"
    Install-Module PSWindowsUpdate -Force
}

Import-Module PSWindowsUpdate
Get-WindowsUpdate -Install -AcceptAll -AutoReboot
```