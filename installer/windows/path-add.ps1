# Adds the RSCP install directory to the user PATH - idempotent,
# case-insensitive, preserving the RAW value (%VAR% references and the
# REG_EXPAND_SZ type survive). Also installs the "instant alias":
# a copy of rscp.exe in %LOCALAPPDATA%\Microsoft\WindowsApps, which sits on
# the user PATH of every process since account creation - so `rscp` starts
# working right away, even in terminals that were opened BEFORE the install
# (the same reason `python` works immediately after its installer runs).
# Used by the NSIS installer and by add-to-path.cmd (the zip distribution).
param([Parameter(Mandatory = $true)][string]$Dir)

$ErrorActionPreference = 'Stop'

function Broadcast-EnvChange {
    # Tell the system (Explorer, new processes) that the environment changed.
    # The old `[Environment]::SetEnvironmentVariable` did this implicitly;
    # writing the registry directly does not, so we send WM_SETTINGCHANGE
    # ourselves.
    Add-Type -Namespace Rscp -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam, int fuFlags, int uTimeout, out IntPtr lpdwResult);
'@
    [IntPtr]$res = [IntPtr]::Zero
    [Rscp.NativeMethods]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [IntPtr]::Zero, 'Environment', 2, 5000, [ref]$res) | Out-Null
}

$envKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)

# ---- read the RAW value: %VAR% entries and the value type survive ---------
$kind = [Microsoft.Win32.RegistryValueKind]::ExpandString
$raw = ''
try { $raw = [string]$envKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) } catch { $raw = '' }
try { if ($envKey.GetValueKind('Path') -eq [Microsoft.Win32.RegistryValueKind]::String) { $kind = [Microsoft.Win32.RegistryValueKind]::String } } catch { }

$haveIt = $false
foreach ($p in ($raw -split ';')) {
    if ($p -ne '' -and $p -eq $Dir) { $haveIt = $true; break }
}
if (-not $haveIt) {
    $new = if ($raw) { "$raw;$Dir" } else { $Dir }
    $envKey.SetValue('Path', $new, $kind)
    Write-Output "PATH updated: $Dir added."
} else {
    Write-Output "PATH already contains $Dir."
}
$envKey.Close()

# ---- remember where RSCP lives (rscp update needs this when it is launched
# ---- through the WindowsApps alias rather than the install dir) -----------
[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Software\RSCP').SetValue('InstallDir', $Dir)

Broadcast-EnvChange

# ---- instant alias into WindowsApps ----------------------------------------
$exe = Join-Path $Dir 'rscp.exe'
if (Test-Path $exe) {
    $aliasDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    try {
        if (-not (Test-Path $aliasDir)) { New-Item -ItemType Directory -Path $aliasDir -Force | Out-Null }
        Copy-Item $exe (Join-Path $aliasDir 'rscp.exe') -Force
        Write-Output "Instant alias: $aliasDir\rscp.exe"
        Write-Output "'rscp' works right now, even in already open terminals."
    } catch {
        Write-Output "Alias skipped (no write access to WindowsApps): $($_.Exception.Message)"
    }
} else {
    Write-Output "Note: rscp.exe not found in $Dir - alias not installed."
}
