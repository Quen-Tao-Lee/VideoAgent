@echo off
setlocal
chcp 65001 >nul
title Start VideoAgent

REM 1) 进入目录
cd /d C:\VideoBot

REM 2) 运行环境体检与修复
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\VideoBot\agent\AgentDoctor.ps1'"
if errorlevel 1 (
  echo [X] 体检/修复失败，请查看 C:\VideoBot\logs\doctor_*.log
  pause
  exit /b 1
)

REM 3) 启动主Agent（调试版本）
powershell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\VideoBot\agent\VideoAgent_Debug.ps1'"
pause