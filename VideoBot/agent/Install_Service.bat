@echo off
title VideoAgent Ultimate - Service Installation
echo ╔══════════════════════════════════════════════════════════════╗
echo ║            VideoAgent Ultimate Service Installer            ║
echo ║                                                              ║
echo ║  ⚠️  This script must be run as Administrator!               ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ❌ ERROR: This script requires Administrator privileges!
    echo.
    echo Please right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo ✅ Administrator privileges confirmed
echo.

echo 🔧 Installing VideoAgent Ultimate as Windows Service...
echo.

cd /d "C:\VideoBot\agent"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\VideoAgent_Ultimate.ps1' -InstallService"

echo.
echo Installation complete!
echo.
echo To start the service:
echo   Start-Service -Name VideoAgentUltimate
echo.
echo To stop the service:
echo   Stop-Service -Name VideoAgentUltimate
echo.
pause