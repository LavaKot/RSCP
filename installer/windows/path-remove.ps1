# Removes the RSCP install directory from the user PATH (preserving the RAW
# value and its type), deletes the WindowsApps "instant alias" and the
# Software\RSCP registry key. Used by the NSIS uninstaller and by
# remove-from-path.cmd (the zip distribution).
param([Parameter(Mandatory = $true)][string]$Dir)

$ErrorActionPreference = 'Stop'

function Broadcast-EnvChange {
    Add-Type -Namespace Rscp -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);
'@
    [IntPtr]$res = [IntPtr]::Zero
    [Rscp.NativeMethods]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [IntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null
}

# ---- PATH entry -------------------------------------------------------------
$envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
if ($envKey) {
    $kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
    $raw = ''
    try { $raw = [string]$envKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } catch { $raw = '' }
    try { if ($envKey.GetValueKind('Path') -eq [Microsoft.Win32.RegistryValueKind]::String) { $kind = [Microsoft.Win32.RegistryValueKind]::String } } catch { }

    $kept = @()
    foreach ($p in ($raw -split ';')) {
        if ($p -ne '' -and $p -eq $Dir) { continue }
        $kept += $p
    }
    $new = ($kept -join ';')
    $envKey.SetValue('Path', $new, $kind)
    $envKey.Close()
    Write-Output "PATH updated: $Dir removed."
}

# ---- instant alias + the install-dir key ------------------------------------
$alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\rscp.exe'
try {
    if (Test-Path $alias) {
        Remove-Item $alias -Force
        Remove-Item (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\rscp.old.exe') -Force -ErrorAction SilentlyContinue
        Write-Output "Alias removed: $alias"
    }
} catch {
    Write-Output "Alias not removed: $($_.Exception.Message)"
}

Remove-Item 'HKCU:\Software\RSCP' -Recurse -ErrorAction SilentlyContinue
Broadcast-EnvChange
Write-Output "Done."
