; RSCP Windows installer (NSIS 3.x; cross-builds on Linux).
;
;   makensis -DVER_FULL=2026.5.1.0 -DSRC=<staging dir> -DOUT=<output dir> \
;             rscp-setup.nsi
;
; The staging dir is the content of rscp-<ver>-windows-x64.zip plus the two
; PowerShell helpers (path-add.ps1, path-remove.ps1):
;   rscp.exe, examples\*.rscp, rscp-<ver>.vsix, INSTALL.txt, assoc-rscp.bat.
;
; The installer is user-level (no admin): files go to a writable directory
; (default C:\rscp) and PATH is extended in the *user* environment via
; PowerShell, which is preinstalled on every Windows 10/11.

!include "MUI2.nsh"

!ifndef VER_FULL
  !error "VER_FULL is not set (e.g. -DVER_FULL=2026.5.1.0)"
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

  DetailPrint "Добавление $INSTDIR в PATH пользователя..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\path-add.ps1" -Dir "$INSTDIR"'
  Delete "$INSTDIR\path-add.ps1"
SectionEnd

Section "Uninstall"
  DetailPrint "Удаление $INSTDIR из PATH пользователя..."
  nsExec::ExecToLog 'powershell -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\path-remove.ps1" -Dir "$INSTDIR"'
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
SectionEnd
