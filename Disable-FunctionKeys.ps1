<#
.SYNOPSIS
    Applies a custom Scancode Map registry entry on G4 HP devices to disable specific keyboard keys that turn off wireless radios.

.DESCRIPTION
    Retrieves the device's BIOS serial number via CIM and checks for the HP '5CG' serial prefix.
    If the device is identified as an HP machine, a Scancode Map binary value is written to the
    Windows registry under HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout.

    The following scan codes are disabled by this map:
        0x0076  -  Application/Menu key
        0xE001  -  HP-specific extended fn key

    A restart is required for the remapping to take effect.

.NOTES
    Author       : Scott Vazquez
    Version      : 1.0.0
    Requires     : PowerShell 5.1+; must be run as Administrator

    Registry key modified:
        HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout
        Value name: Scancode Map
        Value type: REG_BINARY

    Deployment:
        Compatible with ScreenConnect script deployment and Intune Remediations
        (Detection + Remediation pattern). Run under SYSTEM context.

.EXAMPLE
    PS> .\Set-HPKeyboardScancodeMap.ps1

    Queries the local machine's serial number. If the serial begins with '5CG',
    writes the Scancode Map registry value and outputs a success message.

.EXAMPLE
    PS> .\Set-HPKeyboardScancodeMap.ps1
    [SKIP] Serial number 'MXL1234567' does not match HP prefix '5CG'. No changes made.

    On a non-HP device, the script exits cleanly without making any changes.

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/hid/keyboard-and-mouse-class-drivers
#>

#!ps
#MaxLength=100000
#timeout=10000000

#Requires -RunAsAdministrator

#region Configuration

$RegPath    = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
$RegName    = 'Scancode Map'
$HPPrefix   = '5CG'

# Scancode Map binary payload
# Header    : 00 00 00 00  (version)
# Flags     : 00 00 00 00
# Entry cnt : 03 00 00 00  (2 remaps + null terminator)
# Remap 1   : 00 00 76 00  (disable Application/Menu key  -> 0x0076)
# Remap 2   : 00 00 01 E0  (disable HP extended fn key    -> 0xE001)
# Terminator: 00 00 00 00
$ScancodeMapValue = [byte[]](
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x76, 0x00,
    0x00, 0x00, 0x01, 0xE0,
    0x00, 0x00, 0x00, 0x00
)

#endregion

#region Main

try {
    $SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
}
catch {
    Write-Error "[ERROR] Failed to retrieve serial number. $_"
    exit 1
}

if ($SerialNumber.StartsWith($HPPrefix)) {
    Write-Output "[INFO] HP device detected. Serial: '$SerialNumber'"

    try {
        New-ItemProperty -Path $RegPath `
                         -Name $RegName `
                         -PropertyType Binary `
                         -Value $ScancodeMapValue `
                         -Force | Out-Null

        Write-Output "[SUCCESS] Scancode Map applied. A restart is required for changes to take effect."
    }
    catch {
        Write-Error "[ERROR] Failed to write registry value. $_"
        exit 1
    }
}
else {
    Write-Output "[SKIP] Serial number '$SerialNumber' does not match HP prefix '$HPPrefix'. No changes made."
    exit 0
}

#endregion