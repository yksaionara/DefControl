@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DefControl - Windows Defender Control

:: ===================================================================
::  DefControl  -  a console Windows Defender on/off switch
::  Does what Sordum's Defender Control does, but it's yours.
::
::  Uses only official mechanisms:
::    - HKLM Defender policy keys  (reg.exe)
::    - Set-MpPreference           (PowerShell / Defender module)
::  Requires Administrator rights. Self-elevates on launch.
:: ===================================================================

:: ---- color (0A = black bg / green text) ----------------------------
color 0A

:: ---- self-elevate to Administrator ---------------------------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting Administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
    exit /b
)

:menu
cls
echo.
echo   ===============================================================
echo                D E F C O N T R O L   v1.0
echo            Windows Defender on/off  -  console edition
echo   ===============================================================
echo.
call :status
echo.
echo   ---------------------------------------------------------------
echo     [1]  Disable Windows Defender
echo     [2]  Enable  Windows Defender
echo     [3]  Refresh status
echo     [4]  Open Windows Security (Tamper Protection toggle)
echo     [0]  Exit
echo   ---------------------------------------------------------------
echo.
set "choice="
set /p "choice=   Select an option: "

if "%choice%"=="1" goto disable
if "%choice%"=="2" goto enable
if "%choice%"=="3" goto menu
if "%choice%"=="4" goto opensec
if "%choice%"=="0" exit /b
goto menu

:: ===================================================================
::  STATUS
:: ===================================================================
:status
set "RTP=unknown"
for /f "usebackq delims=" %%R in (`powershell -NoProfile -Command "try { (Get-MpComputerStatus).RealTimeProtectionEnabled } catch { 'ERR' }" 2^>nul`) do set "RTP=%%R"

set "TAMPER=unknown"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "try { (Get-MpComputerStatus).IsTamperProtected } catch { 'ERR' }" 2^>nul`) do set "TAMPER=%%T"

:: policy key state
set "POL=not set"
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware >nul 2>&1
if "%errorlevel%"=="0" (
    for /f "tokens=3" %%P in ('reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware ^| find "DisableAntiSpyware"') do (
        if "%%P"=="0x1" (set "POL=DISABLED by policy") else (set "POL=enabled")
    )
)

echo     Real-time protection : %RTP%
echo     Tamper Protection    : %TAMPER%
echo     Policy (AntiSpyware) : %POL%
goto :eof

:: ===================================================================
::  DISABLE
:: ===================================================================
:disable
cls
echo.
echo   Disabling Windows Defender...
echo.

:: 1) Try the live toggle first (works only if Tamper Protection is OFF)
powershell -NoProfile -Command "try { Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop; Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableScanOnRealtimeEnable $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

:: 2) Set policy keys (apply after reboot even if Tamper blocks the live toggle)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul 2>&1

echo   Done. Verifying...
echo.
call :status
echo.
call :tamper_note
pause >nul
goto menu

:: ===================================================================
::  ENABLE
:: ===================================================================
:enable
cls
echo.
echo   Enabling Windows Defender...
echo.

:: 1) Remove the policy keys
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1

:: 2) Re-enable the live toggle
powershell -NoProfile -Command "try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop; Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue; Set-MpPreference -DisableScanOnRealtimeEnable $false -ErrorAction SilentlyContinue; Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue } catch {}" >nul 2>&1

echo   Done. Verifying...
echo.
call :status
echo.
call :tamper_note
pause >nul
goto menu

:: ===================================================================
::  HELPERS
:: ===================================================================
:tamper_note
if /i "%TAMPER%"=="True" (
    echo   [!] Tamper Protection is ON. Windows blocks live changes to
    echo       real-time protection while it is on. The policy keys were
    echo       still written and take effect after you turn Tamper
    echo       Protection OFF  ^(option [4]^)  or after a reboot.
    echo.
    echo       Press any key to continue...
)
goto :eof

:opensec
start windowsdefender://threatsettings
goto menu
