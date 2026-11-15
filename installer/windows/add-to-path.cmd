@echo off
rem ============================================================
rem  RSCP: add this folder to the user PATH and install the
rem  instant "rscp" alias (WindowsApps). After this, `rscp`
rem  works in NEW and ALREADY OPEN terminals - close nothing.
rem  Run from the unpacked RSCP folder; double-click is fine.
rem ============================================================
setlocal
set "DIR=%~dp0"
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

if not exist "%DIR%\rscp.exe" (
    echo rscp.exe not found next to this script.
    echo Run add-to-path.cmd from the unpacked RSCP folder.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\path-add.ps1" -Dir "%DIR%"

echo.
echo Done. Check it in ANY terminal (new or already open):
echo     rscp version
pause
