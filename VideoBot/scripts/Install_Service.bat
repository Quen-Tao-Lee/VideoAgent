@echo off
echo Installing VideoAgent Ultimate as Windows Service...
echo Please run as Administrator!
echo.

cd /d "C:\VideoBot\agent"
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\VideoAgent_Ultimate.ps1' -InstallService"

pause