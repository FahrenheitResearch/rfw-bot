@echo off
title Fire Alert Bot Installer
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0installer.ps1"
