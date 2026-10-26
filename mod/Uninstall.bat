@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0K1FeatTrees.ps1" -Uninstall %*
pause
