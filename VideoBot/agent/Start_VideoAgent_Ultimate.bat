@echo off
title VideoAgent Ultimate v3.0 - Quen-Tao-Lee
color 0A
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                VideoAgent Ultimate v3.0                     ║
echo ║              Enterprise Video Processing                     ║
echo ║                                                              ║
echo ║  👤 User: Quen-Tao-Lee                                       ║
echo ║  📅 Date: %date% %time%                          ║
echo ║  🌐 Web: http://localhost:8080                               ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

cd /d "C:\VideoBot\agent"

echo 🚀 Starting VideoAgent Ultimate...
echo 📁 Input: C:\VideoBot\in
echo 📁 Output: C:\VideoBot\out  
echo 🌐 Web Interface: http://localhost:8080
echo.
echo Press Ctrl+C to stop
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\VideoAgent_Ultimate.ps1' -WebInterface"

echo.
echo VideoAgent stopped.
pause