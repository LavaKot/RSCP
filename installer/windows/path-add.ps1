# Appends the RSCP install directory to the user PATH (idempotent,
# case-insensitive). Used by the NSIS installer.
param([Parameter(Mandatory = $true)][string]$Dir)

$p = [Environment]::GetEnvironmentVariable('Path', 'User')
$parts = @($p -split ';' | Where-Object { $_ -ne '' })
if ($parts -notcontains $Dir) {
    $parts += $Dir
    [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
    Write-Output "PATH updated: $Dir added."
} else {
    Write-Output "PATH already contains $Dir."
}
