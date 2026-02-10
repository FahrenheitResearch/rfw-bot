@echo off
echo ============================================
echo   Fire Alert Bot - Auto-Start Setup
echo ============================================
echo.
echo This will make the bot start automatically
echo every time you log into Windows.
echo.

:: Create a shortcut in the Windows Startup folder
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SCRIPT=%~dp0start_bot.bat"

:: Use PowerShell to create a shortcut (minimized window)
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%STARTUP%\FireAlertBot.lnk'); $sc.TargetPath = '%SCRIPT%'; $sc.WorkingDirectory = '%~dp0'; $sc.WindowStyle = 7; $sc.Description = 'Fire Alert Discord Bot'; $sc.Save()"

if exist "%STARTUP%\FireAlertBot.lnk" (
    echo.
    echo  SUCCESS! The bot will now auto-start when
    echo  you log into Windows. It will run minimized
    echo  in your taskbar.
    echo.
    echo  To UNDO this later, just delete this file:
    echo  %STARTUP%\FireAlertBot.lnk
) else (
    echo.
    echo  Something went wrong. You can set this up
    echo  manually - see the SETUP.md file for steps.
)

echo.
echo Press any key to close...
pause >nul
