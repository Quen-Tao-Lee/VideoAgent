@echo off
setlocal EnableDelayedExpansion

rem ===== 路径 =====
set "BASE=C:\VideoBot"
set "IN=%BASE%\in"
set "OUT=%BASE%\out"
set "LOGDIR=%BASE%\logs"
set "TMP=%BASE%\temp"
set "DONE=%BASE%\done"

if not exist "%IN%"  md "%IN%"
if not exist "%OUT%" md "%OUT%"
if not exist "%LOGDIR%" md "%LOGDIR%"
if not exist "%TMP%" md "%TMP%"
if not exist "%DONE%" md "%DONE%"

rem ===== 安全时间戳做日志文件名（避免斜杠/中文星期）=====
for /f "tokens=2 delims==." %%I in ('wmic os get LocalDateTime /value ^| find "="') do set LDT=%%I
set "TS=%LDT:~0,4%-%LDT:~4,2%-%LDT:~6,2%_%LDT:~8,2%-%LDT:~10,2%-%LDT:~12,2%"
set "LOG=%LOGDIR%\transcode_%TS%.txt"

where ffmpeg >nul 2>&1 || (echo [ERR] 没找到 ffmpeg，请检查 PATH>>"%LOG%" & echo 未找到 ffmpeg，按任意键退出 & pause & exit /b)

set /a COUNT=0
for %%F in ("%IN%\*.mp4" "%IN%\*.mov" "%IN%\*.mkv") do (
  if exist "%%~fF" (
    set /a COUNT+=1
    echo 处理: %%~nxF>>"%LOG%"
    ffmpeg -y -hwaccel auto -i "%%~fF" -vf "scale=w=1080:h=-2:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1" -r 30 -c:v libx264 -preset veryfast -crf 20 -c:a aac -b:a 128k "%OUT%\%%~nF_1080x1920.mp4" >>"%LOG%" 2>&1
    if errorlevel 1 (echo [ERR] 转码失败: %%~nxF>>"%LOG%") else (
      move /y "%%~fF" "%DONE%\" >nul
      echo 成功: %%~nxF>>"%LOG%"
    )
  )
)

if %COUNT%==0 (echo [INFO] in 文件夹没有可处理的视频>>"%LOG%" & echo in 里没视频，按任意键退出 & pause & exit /b)

echo 完成。日志：%LOG%
pause