@echo off
title VideoAgent Ultimate Launcher
echo ========================================
echo      VideoAgent Ultimate v3.0
echo    Enterprise Video Processing
echo ========================================
echo.
echo Starting VideoAgent Ultimate...
echo Web Interface will be available at: http://localhost:8080
echo.

cd /d "C:\VideoBot\agent"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\VideoAgent_Ultimate.ps1' -WebInterface"

pause