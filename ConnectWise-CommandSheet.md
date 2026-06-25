# ConnectWise Command Reference

A reference sheet for ConnectWise remote commands used in day-to-day endpoint management at VSCHSD.

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
reg add "HKLM\SOFTWARE\Policies\GoGuardian" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v LicenseTag /t REG_SZ /d "lnlhobhgeiihnkmkpkdagbijljeggalb" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v MinimizeToSystemTray /t REG_SZ /d "true" /f & reg add "HKLM\SOFTWARE\Policies\GoGuardian" /v StartMinimizedToSystemTray /t REG_SZ /d "true" /f & shutdown /r /f /t 0
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

$IPAddress   = "10.31.4.23"
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

$OldIP = "10.35.1.178"
$NewIP = "10.31.4.41"

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
ISCCX725                            Local  Lexmark Universal v2 XL       172.16.47.1       False   False
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

$CredentialProviders = "{01A30791-40AE-4653-AB2E-FD210019AE88},{1b283861-754f-4022-ad47-a5eaaa618894},{1ee7337f-85ac-45e2-a23c-37c753209769},{2135f72a-90b5-4ed3-a7f1-8bb705ac276a},{25CBB996-92ED-457e-B28C-4774084BD562},{27FBDB57-B613-4AF2-9D7E-4FA7A66C21AD},{3dd6bec0-8193-4ffe-ae25-e08e39ea4063},{48B4E58D-2791-456C-9091-D524C6C706F2},{600e7adb-da3e-41a4-9225-3c0399e88c0c},{60b78e88-ead8-445c-9cfd-0b87f74ea6cd},{8841d728-1a76-4682-bb6f-a9ea53b4b3ba},{8AF662BF-65A0-4D0A-A540-A338A999D36F},{8FD7E19C-3BF7-489B-A72C-846AB3678C96},{94596c7e-3744-41ce-893e-bbf09122f76a},{BEC09223-B018-416D-A0AC-523971B639F5},{C5D7540A-CD51-453B-B22B-05305BA03F07},{C885AA15-1764-4293-B82A-0586ADD46B35},{cb82ea12-9f71-446d-89e1-8d0924e1256e},{D6886603-9D2F-4EB2-B667-1971041FA96B},{e74e57b0-6c6d-44d5-9cda-fb2df5ed7435},{F8A0B131-5F68-486c-8040-7E8FC3C85BB6},{F8A1793B-7873-4046-B2A7-1F318747F427}"

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

Rename-Computer "DADM09WS01"
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

## SET-AUDIO DEVICE

> Sets a specific audio device as the active output by index number.
> Run [GET-AUDIO DEVICE](#get-audio-device) first to see available devices and their index numbers.

```cmd
Powershell -command "Set-AudioDevice -Index 1"
```

---

## SET-AUTOLOGON REGKEYS

> Configures auto-logon via registry keys for the `iiqlaptops` loaner account.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon"   -Value "1"          -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultUsername"  -Value "iiqlaptops" -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultPassword"  -Value "vslaptops"  -Type String -Force
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName"-Value "vschsd.org" -Type String -Force
```

---

## SET-AUTOLOGON SYSINTERNALS

> Configures auto-logon using Sysinternals AutoLogon64 for the `iiqloaners@vschsd.org` account.

```powershell
#!ps
#MaxLength=100000
#timeout=10000000

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

$Username     = "iiqloaners@vschsd.org"
$Domain       = "AzureAD"
$Password     = "vslaptops"
$AutologonPath = "C:\Users\mrteach\Desktop\AutoLogon\Autologon64.exe"

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
Connection-specific DNS Suffix  . : vshs.local
IPv4 Address. . . . . . . . . . . : 172.16.44.4
Subnet Mask . . . . . . . . . . . : 255.255.252.0
Default Gateway . . . . . . . . . : 172.16.44.254
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