@echo off
title VideoAgent Ultimate - Complete Deployment
color 0B
echo ╔══════════════════════════════════════════════════════════════╗
echo ║            VideoAgent Ultimate 完整部署脚本                  ║
echo ║                     v3.0 - 2025-08-16                      ║
echo ║                   用户：Quen-Tao-Lee                        ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo 🚀 开始完整部署 VideoAgent Ultimate...
echo.

rem 创建目录结构
echo 📁 创建目录结构...
md "C:\VideoBot\agent" 2>nul
md "C:\VideoBot\config" 2>nul
md "C:\VideoBot\web" 2>nul
md "C:\VideoBot\in" 2>nul
md "C:\VideoBot\out" 2>nul
md "C:\VideoBot\done" 2>nul
md "C:\VideoBot\temp" 2>nul
md "C:\VideoBot\logs" 2>nul
md "C:\VideoBot\scripts" 2>nul
md "C:\VideoBot\scripts\management" 2>nul
md "C:\VideoBot\tools" 2>nul

echo ✅ 目录结构创建完成
echo.

rem 创建README文件
echo 📝 创建说明文件...
(
echo VideoAgent Ultimate v3.0
echo 用户: Quen-Tao-Lee
echo 部署时间: %DATE% %TIME%
echo.
echo 目录说明:
echo   in/     - 输入视频文件夹，将要处理的视频放在这里
echo   out/    - 输出视频文件夹，处理完成的视频在这里
echo   done/   - 完成视频文件夹，原始视频的备份
echo   logs/   - 日志文件夹，系统运行日志
echo   config/ - 配置文件夹，系统配置文件
echo   web/    - Web界面文件夹
echo   agent/  - 主程序文件夹
echo   scripts/ - 脚本工具文件夹
echo   tools/  - 专用工具文件夹
echo.
echo 使用说明:
echo 1. 运行 Start_VideoAgent.bat 启动服务
echo 2. 访问 http://localhost:8080 查看Web界面
echo 3. 将视频文件拖入 in/ 文件夹开始处理
echo.
echo 支持的视频格式: MP4, MOV, MKV, M4V, AVI, WMV, FLV, WEBM
) > "C:\VideoBot\README.txt"

(
echo 欢迎使用 VideoAgent Ultimate!
echo.
echo 请将您要处理的视频文件放入此文件夹。
echo 支持的格式: MP4, MOV, MKV, M4V, AVI, WMV, FLV, WEBM
echo.
echo 处理完成的视频将保存在 ../out/ 文件夹中。
echo 原始视频将移动到 ../done/ 文件夹作为备份。
echo.
echo 用户: Quen-Tao-Lee
echo 部署时间: %DATE% %TIME%
) > "C:\VideoBot\in\使用说明.txt"

echo ✅ 说明文件创建完成
echo.

rem 检查FFmpeg
echo 🔍 检查FFmpeg...
ffmpeg -version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ FFmpeg 已安装
) else (
    echo ⚠️  FFmpeg 未安装，请手动安装:
    echo    winget install FFmpeg
    echo    或下载: https://ffmpeg.org/download.html
)
echo.

rem 创建默认配置文件
echo ⚙️ 创建默认配置...

rem 简化的设置文件
(
echo {
echo   "user": "Quen-Tao-Lee",
echo   "version": "3.0-Ultimate",
echo   "created": "%DATE% %TIME%",
echo   "directories": {
echo     "input": "C:\\VideoBot\\in",
echo     "output": "C:\\VideoBot\\out",
echo     "done": "C:\\VideoBot\\done",
echo     "temp": "C:\\VideoBot\\temp",
echo     "logs": "C:\\VideoBot\\logs",
echo     "config": "C:\\VideoBot\\config",
echo     "web": "C:\\VideoBot\\web"
echo   },
echo   "processing": {
echo     "default_preset": "mobile",
echo     "auto_subtitles": true,
echo     "web_interface": true,
echo     "auto_cleanup": true
echo   },
echo   "web": {
echo     "port": 8080,
echo     "enabled": true
echo   }
echo }
) > "C:\VideoBot\config\basic_settings.json"

echo ✅ 基础配置创建完成
echo.

rem 创建快捷启动脚本
echo 🔗 创建启动脚本...

(
echo @echo off
echo title VideoAgent Ultimate - Quick Start
echo cd /d "C:\VideoBot\scripts"
echo if exist "Start_VideoAgent_Ultimate.bat" (
echo     call "Start_VideoAgent_Ultimate.bat"
echo ^) else (
echo     echo 启动脚本不存在，请先创建主程序文件
echo     echo 需要创建: C:\VideoBot\agent\VideoAgent_Ultimate.ps1
echo     pause
echo ^)
) > "C:\VideoBot\Start_VideoAgent.bat"

echo ✅ 启动脚本创建完成
echo.

rem 打开关键目录
echo 📂 打开关键目录供您创建必要文件...
start "" "C:\VideoBot\agent"
start "" "C:\VideoBot\in"

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                     部署完成！                              ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo ✅ VideoAgent Ultimate 基础结构部署完成
echo.
echo 📋 接下来需要您手动创建的文件：
echo.
echo 🔴 必需文件：
echo    1. C:\VideoBot\agent\VideoAgent_Ultimate.ps1 - 主程序
echo    2. C:\VideoBot\scripts\Start_VideoAgent_Ultimate.bat - 启动脚本
echo.
echo 🟡 可选文件：
echo    3. C:\VideoBot\web\index.html - Web界面（程序会自动生成）
echo    4. C:\VideoBot\config\settings.json - 详细配置（程序会自动生成）
echo.
echo 🚀 使用步骤：
echo    1. 创建上述必需文件
echo    2. 双击 Start_VideoAgent.bat 启动
echo    3. 访问 http://localhost:8080 查看Web界面
echo    4. 将视频拖入 in 文件夹开始处理
echo.
echo 📂 已打开的文件夹：
echo    - Agent文件夹（创建主程序）
echo    - 输入文件夹（放置视频文件）
echo.
pause