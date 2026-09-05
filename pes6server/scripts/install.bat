@echo off
setlocal EnableExtensions

title Pro Evolution Soccer 6 - Portable Installer

if /i "%~1"=="/nopause" set "NOPAUSE=1"

echo ==========================================
echo Pro Evolution Soccer 6
echo Portable Registry Installer
echo ==========================================
echo.

rem ------------------------------------------------------------
rem Get directory of this BAT file
rem ------------------------------------------------------------

set "GAME_DIR=%~dp0..\.."
for %%i in ("%GAME_DIR%") do set "GAME_DIR=%%~fi"

echo Game directory:
echo %GAME_DIR%
echo.

rem ------------------------------------------------------------
rem Check required files
rem ------------------------------------------------------------

if not exist "%GAME_DIR%\PES6.exe" (
    echo [ERROR] PES6.exe not found.
    echo.
    pause
    exit /b 1
)

if not exist "%GAME_DIR%\settings.exe" (
    echo [ERROR] settings.exe not found.
    echo.
    pause
    exit /b 1
)

if not exist "%GAME_DIR%\dat" (
    echo [ERROR] dat folder not found.
    echo.
    pause
    exit /b 1
)

rem ------------------------------------------------------------
rem Request administrator privileges
rem ------------------------------------------------------------

net session >nul 2>&1

if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    echo.

    powershell.exe -NoProfile -ExecutionPolicy Bypass ^
        -Command "Start-Process -FilePath '%~f0' -Verb RunAs"

    exit /b
)

rem ------------------------------------------------------------
rem Remove old PES6 registry
rem ------------------------------------------------------------

echo [1/3] Removing old PES6 registry...

reg delete "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /f >nul 2>&1

echo Done.
echo.

rem ------------------------------------------------------------
rem Create PES6 registry
rem ------------------------------------------------------------

echo [2/3] Creating PES6 registry...

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /f >nul

rem Original code
reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "code" ^
    /t REG_SZ ^
    /d "A6V9D5HXPT62H4PFWA45" ^
    /f >nul

rem Game directory
reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "installdir" ^
    /t REG_SZ ^
    /d "%GAME_DIR%" ^
    /f >nul

rem Install source directory
reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "installfrom" ^
    /t REG_SZ ^
    /d "%GAME_DIR%" ^
    /f >nul

rem Languages
reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_e" /t REG_SZ /d "1" /f >nul

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_f" /t REG_SZ /d "" /f >nul

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_g" /t REG_SZ /d "" /f >nul

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_i" /t REG_SZ /d "" /f >nul

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_s" /t REG_SZ /d "" /f >nul

reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" ^
    /v "lang_p" /t REG_SZ /d "" /f >nul

rem Version subkey
reg add "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6\1.0" /f >nul

echo Done.
echo.

rem ------------------------------------------------------------
rem Verify
rem ------------------------------------------------------------

echo [3/3] Verifying registry...
echo.

reg query "HKLM\SOFTWARE\WOW6432Node\KONAMIPES6\PES6" /s

echo.
echo ==========================================
echo Installation completed.
echo ==========================================
echo.
if not defined NOPAUSE pause
