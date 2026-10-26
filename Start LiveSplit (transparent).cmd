@echo off
rem Starts LiveSplit (if it isn't running) with a see-through background.
rem Change the color here if you use a different background color in LiveSplit.
set "COLOR=#010101"

rem Where LiveSplit.exe is: next to this file, or the path written in livesplit-path.txt
set "LIVESPLIT=%~dp0LiveSplit.exe"
if exist "%~dp0livesplit-path.txt" set /p LIVESPLIT=<"%~dp0livesplit-path.txt"

start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0livesplit-transparent.ps1" -Color "%COLOR%" -LiveSplitPath "%LIVESPLIT%"
