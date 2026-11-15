@echo off
rem ============================================================
rem  RSCP: remove this folder from the user PATH and delete the
rem  "rscp" alias. Run from the RSCP folder being removed.
rem ============================================================
setlocal
set "DIR=%~dp0"
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\path-remove.ps1" -Dir "%DIR%"

echo.
echo Done. Open a NEW terminal and `rscp` will be gone.
pause
