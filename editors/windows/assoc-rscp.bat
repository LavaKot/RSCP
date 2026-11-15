@echo off
rem ============================================================
rem  RSCP 2026.2.0.0 - file association helper for Windows
rem
rem  Registers the .rscp extension:
rem    * "rscpfile" type with a plain-text description
rem    * double-click runs the file with rscp.exe (if in PATH)
rem    * "Edit" verb opens the file in Notepad++ or Notepad
rem
rem  Run once, as administrator:
rem    right-click assoc-rscp.bat -> "Run as administrator"
rem ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run this script as administrator ^(right-click -^> "Run as administrator"^).
    pause
    exit /b 1
)

assoc .rscp=rscpfile
ftype rscpfile="%%1" %*

rem Double-click: run with rscp.exe if it is in PATH, else open in Notepad.
where rscp.exe >nul 2>&1
if %errorlevel% equ 0 (
    ftype rscpfile="rscp.exe" "%%1"
) else (
    echo NOTE: rscp.exe not found in PATH - double-click will open Notepad.
    echo       Put rscp.exe into PATH and run this script again to run files.
    ftype rscpfile=notepad.exe "%%1"
)

reg add "HKCR\rscpfile" /ve /d "RSCP source file" /f >nul
reg add "HKCR\rscpfile\DefaultIcon" /ve /d "imageres.dll,-69" /f >nul

echo.
echo Done: .rscp files are associated.
echo   - double-click: runs the file with rscp ^(or opens Notepad for now^)
echo   - right-click -^> "Open with" always lets you pick any editor:
echo     VS Code, Notepad++, Notepad - .rscp is plain UTF-8 text.
pause
