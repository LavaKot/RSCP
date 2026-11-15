# RSCP self-update: download the latest Windows build from the (private)
# GitHub repository LavaKot/rscp and swap it in place. Launched by `rscp update`;
# the exe path and the running version are passed as parameters.
param(
    [string]$ExePath = "",
    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # ~10x faster Invoke-WebRequest on PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$repo = 'LavaKot/rscp'

function Fail([string]$msg) {
    Write-Host "ОШИБКА: $msg" -ForegroundColor Red
    exit 1
}

# ---- token: the repository is private, downloads need a GitHub PAT --------
$token = $env:RSCP_GITHUB_TOKEN
if (-not $token) {
    $tokenFile = Join-Path $env:USERPROFILE '.rscp\token'
    if (Test-Path $tokenFile) { $token = (Get-Content $tokenFile -Raw).Trim() }
}
if (-not $token) {
    Write-Host "Репозиторий RSCP закрытый, поэтому для скачивания обновлений"
    Write-Host "нужен персональный токен GitHub (Classic, право repo)."
    Write-Host "Сохраните его ОДИН раз - и 'rscp update' будет работать всегда:"
    Write-Host ""
    Write-Host '    New-Item -ItemType Directory -Force "$env:USERPROFILE\.rscp" | Out-Null'
    Write-Host '    "ghp_ВАШ_ТОКЕН" | Set-Content "$env:USERPROFILE\.rscp\token"'
    Write-Host ""
    Write-Host "Вместо файла можно задать переменную окружения RSCP_GITHUB_TOKEN."
    exit 1
}

$headers = @{
    Authorization          = "Bearer $token"
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent'           = 'rscp-update'
}

# ---- what is the latest release? -------------------------------------------
try {
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $headers
} catch {
    Fail "не удалось узнать последний релиз (проверьте интернет и токен): $($_.Exception.Message)"
}

$latest = ($rel.tag_name -replace '^v', '').Trim()
if ($Version -ne '' -and $latest -eq $Version) {
    Write-Host "RSCP $Version - уже последняя версия, обновление не требуется."
    exit 0
}
Write-Host "Установлена: $Version"
Write-Host "Доступна:    $latest"

# ---- find the Windows zip asset --------------------------------------------
$asset = $rel.assets | Where-Object { $_.name -like '*-windows-x64.zip' } | Select-Object -First 1
if (-not $asset) { Fail "в релизе $latest нет файла *-windows-x64.zip" }

# ---- where is rscp installed? ----------------------------------------------
if (-not $ExePath -or -not (Test-Path $ExePath)) { Fail "не удалось определить, где лежит rscp.exe" }
$dir = Split-Path -Parent $ExePath
Write-Host "Папка установки: $dir"

# leftovers of a previous update + versioned files replaced by newer names
Remove-Item (Join-Path $dir 'rscp.old.exe') -Force -ErrorAction SilentlyContinue
Remove-Item "$dir\rscp-*.vsix" -Force -ErrorAction SilentlyContinue

# ---- download + unpack ------------------------------------------------------
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("rscp-update-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp $asset.name
try {
    Invoke-WebRequest -UseBasicParsing `
        -Uri $asset.url `
        -Headers @{ Authorization = "Bearer $token"; Accept = 'application/octet-stream' } `
        -OutFile $zip
} catch {
    Fail "не удалось скачать $($asset.name): $($_.Exception.Message)"
}
Expand-Archive -Path $zip -DestinationPath $tmp -Force

$newExe = Get-ChildItem -Path $tmp -Recurse -Filter 'rscp.exe' | Select-Object -First 1
if (-not $newExe) { Fail "в архиве $($asset.name) нет rscp.exe" }
$src = Split-Path -Parent $newExe.FullName

# ---- swap the files ---------------------------------------------------------
# rscp.exe is running right now; Windows allows RENAMING a running exe,
# so: rename the old one, copy the new files in, then try to delete the old
# (deletion may be blocked while it runs - the leftover is cleaned on the
# next update).
Move-Item -LiteralPath $ExePath -Destination (Join-Path $dir 'rscp.old.exe') -Force
try {
    Get-ChildItem -LiteralPath $src | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $dir -Recurse -Force
    }
} catch {
    Move-Item -LiteralPath (Join-Path $dir 'rscp.old.exe') -Destination $ExePath -Force
    Fail "не удалось заменить файлы (нет прав на запись в $dir ?): $($_.Exception.Message)"
}
Remove-Item -LiteralPath (Join-Path $dir 'rscp.old.exe') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

# ---- refresh the VS Code extension if an editor CLI is present --------------
$vsix = Get-ChildItem -LiteralPath $dir -Filter 'rscp-*.vsix' | Select-Object -First 1
if ($vsix) {
    foreach ($cli in @('code', 'codium', 'cursor')) {
        if (Get-Command $cli -ErrorAction SilentlyContinue) {
            try {
                & $cli --install-extension $vsix.FullName | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Host "Плагин $cli обновлён." }
            } catch { }
        }
    }
}

Write-Host ""
Write-Host "Готово: RSCP обновлён  $Version  ->  $latest"
Write-Host "Проверка:  rscp version"
