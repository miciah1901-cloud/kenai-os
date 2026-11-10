@echo off
rem Removes Kenai Switch (asks for admin once).
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoExit -File \"%~dp0Uninstall-KenaiSwitch.ps1\"'"
