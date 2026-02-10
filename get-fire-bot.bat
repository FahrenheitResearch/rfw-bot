@echo off
setlocal
title Fire Alert Bot - Downloading...
color 0F

echo.
echo  ============================================
echo   Fire Alert Bot - One-Click Setup
echo  ============================================
echo.
echo  Downloading the bot files from GitHub...
echo.

:: Set install folder
set "DEST=%USERPROFILE%\rfw-bot"

:: Download the repo as a zip using PowerShell
powershell -Command ^
    "$ProgressPreference = 'SilentlyContinue'; " ^
    "try { " ^
    "  Invoke-WebRequest -Uri 'https://github.com/FahrenheitResearch/rfw-bot/archive/refs/heads/main.zip' -OutFile '%TEMP%\rfw-bot.zip' -UseBasicParsing; " ^
    "  if (Test-Path '%DEST%') { " ^
    "    Write-Host '  Updating existing installation...'; " ^
    "    Expand-Archive -Path '%TEMP%\rfw-bot.zip' -DestinationPath '%TEMP%\rfw-bot-extract' -Force; " ^
    "    Get-ChildItem '%TEMP%\rfw-bot-extract\rfw-bot-main\*' | ForEach-Object { " ^
    "      $destFile = Join-Path '%DEST%' $_.Name; " ^
    "      if ($_.Name -notin @('.env','config.json','seen_alerts.json') -or -not (Test-Path $destFile)) { " ^
    "        Copy-Item $_.FullName -Destination '%DEST%' -Force -Recurse " ^
    "      } " ^
    "    }; " ^
    "    Remove-Item '%TEMP%\rfw-bot-extract' -Recurse -Force; " ^
    "  } else { " ^
    "    Write-Host '  Installing fresh copy...'; " ^
    "    Expand-Archive -Path '%TEMP%\rfw-bot.zip' -DestinationPath '%TEMP%\rfw-bot-extract' -Force; " ^
    "    Move-Item '%TEMP%\rfw-bot-extract\rfw-bot-main' '%DEST%'; " ^
    "    Remove-Item '%TEMP%\rfw-bot-extract' -Recurse -Force -ErrorAction SilentlyContinue; " ^
    "  }; " ^
    "  Remove-Item '%TEMP%\rfw-bot.zip' -Force; " ^
    "  Write-Host '  [OK] Download complete!'; " ^
    "  exit 0 " ^
    "} catch { " ^
    "  Write-Host '  [ERROR] Download failed:' $_.Exception.Message; " ^
    "  exit 1 " ^
    "}"

if %errorlevel% neq 0 (
    echo.
    echo  Download failed. Check your internet connection
    echo  and try again.
    echo.
    pause
    exit /b 1
)

echo.
echo  Files downloaded to: %DEST%
echo.
echo  Launching the installer...
echo.

:: Launch the GUI installer
start "" powershell -ExecutionPolicy Bypass -File "%DEST%\installer.ps1"
exit
