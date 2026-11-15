; RSCP Windows installer (NSIS 3.x; cross-builds on Linux).
;
;   makensis -DVER_FULL=26.0.8.0 -DSRC=<staging dir> -DOUT=<output dir> \
;             rscp-setup.nsi
;
; The staging dir is the content of rscp-<ver>-windows-x64.zip plus the two
; PowerShell helpers (path-add.ps1, path-remove.ps1):
;   rscp.exe, examples\*.rscp, rscp-<ver>.vsix, INSTALL.txt, assoc-rscp.bat.
;
; The installer is user-level (no admin): files go to a writable directory
; (default C:\rscp) and PATH is extended in the *user* environment.
;
; Making `rscp` work IMMEDIATELY (the Python experience, since 26.0.8.0):
;   1. a copy of rscp.exe goes into %LOCALAPPDATA%\Microsoft\WindowsApps -
;      that folder is on the user PATH of every process since account
;      creation, so `rscp` works even in terminals opened BEFORE the install;
;   2. the install dir is appended to the user PATH (PowerShell preserves
;      %VAR% entries and the REG_EXPAND_SZ type; a direct registry write is
;      the fallback when PowerShell is unavailable);
;   3. WM_SETTINGCHANGE is broadcast so terminals freshly opened from
;      Explorer/Start see the new PATH without logging off.

!include "MUI2.nsh"
!include "LogicLib.nsh"

!ifndef VER_FULL
  !error "VER_FULL is not set (e.g. -DVER_FULL=26.0.8.0)"
!endif
!ifndef SRC
  !error "SRC is not set (the staging directory with rscp.exe)"
!endif
!ifndef OUT
  !define OUT "."
!endif

Name "RSCP ${VER_FULL}"
OutFile "${OUT}/rscp-${VER_FULL}-windows-x64-setup.exe"
Unicode true
RequestExecutionLevel user
InstallDir "C:\rscp"
InstallDirRegKey HKCU "Software\RSCP" "InstallDir"
SetCompressor /SOLID lzma

VIProductVersion "${VER_FULL}"
VIAddVersionKey "ProductName" "RSCP"
VIAddVersionKey "FileDescription" "RSCP — язык программирования (установщик)"
VIAddVersionKey "FileVersion" "${VER_FULL}"
VIAddVersionKey "ProductVersion" "${VER_FULL}"

!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "English"

Section "RSCP"
  SetOutPath "$INSTDIR"
  File "${SRC}/rscp.exe"
  File "${SRC}/INSTALL.txt"
  File "${SRC}/assoc-rscp.bat"
  File "${SRC}/path-add.ps1"
  File "${SRC}/path-remove.ps1"
  File /nonfatal "${SRC}/rscp-${VER_FULL}.vsix"
  SetOutPath "$INSTDIR\examples"
  File "${SRC}/examples/*.rscp"

  WriteRegStr HKCU "Software\RSCP" "InstallDir" "$INSTDIR"
  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "DisplayName" "RSCP (язык программирования)"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "DisplayVersion" "${VER_FULL}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "Publisher" "RSCP project"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP" "DisplayIcon" "$INSTDIR\rscp.exe"

  ; ---- 1. instant alias: works even in terminals opened BEFORE the install
  DetailPrint "Установка мгновенного алиаса rscp в WindowsApps..."
  CreateDirectory "$LOCALAPPDATA\Microsoft\WindowsApps"
  ClearErrors
  CopyFiles /SILENT "$INSTDIR\rscp.exe" "$LOCALAPPDATA\Microsoft\WindowsApps"
  ${If} ${Errors}
    DetailPrint "  (нет доступа к WindowsApps — не критично, PATH всё равно настроится)"
  ${EndIf}
  ClearErrors

  ; ---- 2. PATH: PowerShell first (preserves %VAR% entries and the value type)
  DetailPrint "Добавление $INSTDIR в PATH пользователя..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\path-add.ps1" -Dir "$INSTDIR"'
  Pop $0
  ${If} $0 != "0"
    DetailPrint "PowerShell недоступен (код $0) — записываю PATH напрямую..."
    ReadRegStr $1 HKCU "Environment" "Path"
    ${If} $1 == ""
      StrCpy $1 "$INSTDIR"
    ${Else}
      StrCpy $1 "$1;$INSTDIR"
    ${EndIf}
    WriteRegExpandStr HKCU "Environment" "Path" $1
  ${EndIf}
  Delete "$INSTDIR\path-add.ps1"

  ; ---- 3. broadcast: freshly opened terminals see the new PATH right away
  System::Call 'user32::SendMessageTimeout(p 0xFFFF, i 0x1A, p 0, t "Environment", i 2, i 5000, *p .r2) i'
SectionEnd

Section "Uninstall"
  DetailPrint "Удаление мгновенного алиаса rscp (WindowsApps)..."
  Delete "$LOCALAPPDATA\Microsoft\WindowsApps\rscp.exe"
  Delete "$LOCALAPPDATA\Microsoft\WindowsApps\rscp.old.exe"

  DetailPrint "Удаление $INSTDIR из PATH пользователя..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\path-remove.ps1" -Dir "$INSTDIR"'
  Pop $0
  ${If} $0 != "0"
    DetailPrint "PowerShell недоступен — запись PATH остаётся (HKCU\Environment), удалите её вручную"
  ${EndIf}

  Delete "$INSTDIR\path-remove.ps1"
  Delete "$INSTDIR\rscp.exe"
  Delete "$INSTDIR\INSTALL.txt"
  Delete "$INSTDIR\assoc-rscp.bat"
  Delete "$INSTDIR\uninstall.exe"
  Delete "$INSTDIR\rscp-*.vsix"
  RMDir /r "$INSTDIR\examples"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\RSCP"
  DeleteRegKey HKCU "Software\RSCP"

  ; the environment changed again - let freshly opened terminals know
  System::Call 'user32::SendMessageTimeout(p 0xFFFF, i 0x1A, p 0, t "Environment", i 2, i 5000, *p .r2) i'
SectionEnd
