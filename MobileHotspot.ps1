<#
    MobileHotspot.ps1 - Toggle the built-in Windows Mobile Hotspot.

    Made by Dimitrios Dimopoulos, 2026 refresh of WifiHotspot.bat.
    comments and suggestions at mitselec.wordpress.com

    The old WifiHotspot.bat relies on the "Hosted Network" feature of
    Windows 7, which most Windows 10/11 Wi-Fi drivers no longer support.
    The built-in Mobile Hotspot uses Wi-Fi Direct instead and works on
    any Windows 10 (1607+) or Windows 11 machine - including sharing the
    Ethernet connection, with no manual ICS setup.

    Usage (run with Windows PowerShell, i.e. powershell.exe, not pwsh):

        powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Status
        powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action On
        powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Off
        powershell -ExecutionPolicy Bypass -File .\MobileHotspot.ps1 -Action Toggle

    The hotspot name and password can be changed once in
    Settings > Network & Internet > Mobile hotspot.
#>

[CmdletBinding()]
param(
    [ValidateSet('Status', 'On', 'Off', 'Toggle')]
    [string]$Action = 'Status'
)

# WinRT APIs need Windows PowerShell 5.1 (they are not available in pwsh 7)
if ($PSVersionTable.PSEdition -ne 'Desktop') {
    Write-Error 'Please run this with Windows PowerShell (powershell.exe), not PowerShell 7.'
    exit 1
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime | Out-Null

# Helper: await a WinRT IAsyncOperation<T> and return its result
function Await($WinRtTask, [Type]$ResultType) {
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
        })[0].MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

# Helper: await a WinRT IAsyncAction (no result)
function AwaitAction($WinRtAction) {
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() |
        Where-Object {
            $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
            -not $_.IsGenericMethod -and
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
        })[0]
    $netTask = $asTask.Invoke($null, @($WinRtAction))
    $netTask.Wait(-1) | Out-Null
}

function Get-AccessPointInfo($manager) {
    # Windows 10 exposes GetCurrentAccessPointSettings(); some newer
    # Windows 11 builds project it as GetCurrentAccessPointConfiguration().
    if ($manager | Get-Member -Name 'GetCurrentAccessPointSettings') {
        return $manager.GetCurrentAccessPointSettings()
    }
    return $manager.GetCurrentAccessPointConfiguration()
}

function Show-Status($manager) {
    $settings = Get-AccessPointInfo $manager
    Write-Host ('Hotspot name      : ' + $settings.Ssid)
    Write-Host ('Hotspot password  : ' + $settings.Passphrase)
    Write-Host ('Current state     : ' + $manager.TetheringOperationalState)
    Write-Host ('Connected clients : ' + $manager.ClientCount + ' / ' + $manager.MaxClientCount)
}

function Start-Hotspot($manager) {
    if ($manager.TetheringOperationalState.ToString() -eq 'On') {
        Write-Host 'Hotspot is already on.'
        return
    }
    $result = Await ($manager.StartTetheringAsync()) `
        ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    if ($result.Status.ToString() -ne 'Success') {
        Write-Error ('Could not start the hotspot: ' + $result.Status + ' ' + $result.AdditionalErrorMessage)
        exit 1
    }
    Write-Host 'Hotspot started.'
}

function Stop-Hotspot($manager) {
    if ($manager.TetheringOperationalState.ToString() -eq 'Off') {
        Write-Host 'Hotspot is already off.'
        return
    }
    $result = Await ($manager.StopTetheringAsync()) `
        ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    if ($result.Status.ToString() -ne 'Success') {
        Write-Error ('Could not stop the hotspot: ' + $result.Status + ' ' + $result.AdditionalErrorMessage)
        exit 1
    }
    Write-Host 'Hotspot stopped.'
}

# The connection profile whose internet connection gets shared
# (e.g. your Ethernet adapter)
$connectionProfile =
    [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::
        GetInternetConnectionProfile()
if (-not $connectionProfile) {
    Write-Error 'No internet connection profile found - is the laptop online?'
    exit 1
}

$manager =
    [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::
        CreateFromConnectionProfile($connectionProfile)

switch ($Action) {
    'Status' { Show-Status $manager }
    'On'     { Start-Hotspot $manager }
    'Off'    { Stop-Hotspot $manager }
    'Toggle' {
        if ($manager.TetheringOperationalState.ToString() -eq 'On') {
            Stop-Hotspot $manager
        } else {
            Start-Hotspot $manager
        }
    }
}
