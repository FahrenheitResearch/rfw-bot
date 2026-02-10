@echo off
title Fire Alert Bot
cd /d "%~dp0"
echo ============================================
echo   Fire Alert Bot - Starting...
echo   (Minimize this window - don't close it)
echo ============================================
echo.

:start
echo Checking for updates...
python updater.py
if %errorlevel% equ 1 (
    echo.
    echo Update applied, restarting...
    echo.
    goto :start
)

echo.
python run.py
echo.
echo Bot stopped. Press any key to close...
pause >nul
