# Removes the RSCP install directory from the user PATH.
# Used by the NSIS uninstaller.
param([Parameter(Mandatory = $true)][string]$Dir)

$p = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($p -split ';' | Where-Object { $_ -ne '' -and $_ -ne $Dir })
[Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
Write-Output "PATH updated: $Dir removed."
