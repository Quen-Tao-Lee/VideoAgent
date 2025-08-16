@echo off
setlocal EnableExtensions

rem ========== 目录设置 ==========
set "BASE=C:\VideoBot"
set "IN=%BASE%\in"
set "OUT=%BASE%\out"
set "DONE=%BASE%\done"
set "LOGS=%BASE%\logs"
set "TMP=%BASE%\temp"

if not exist "%IN%"  md "%IN%"
if not exist "%OUT%" md "%OUT%"
if not exist "%DONE%" md "%DONE%"
if not exist "%LOGS%" md "%LOGS%"
if not exist "%TMP%" md "%TMP%"

rem ========== 生成安全的时间戳（无/无:）==========
for /f %%A in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd_HHmmss')"') do set "TS=%%A"
set "LOG=%LOGS%\run_%TS%.txt"

echo ==== Start %DATE% %TIME% ====>>"%LOG%"

rem ========== 依赖检查 ==========
where ffmpeg >nul 2>&1 || (echo [ERR] 未找到 ffmpeg，请检查环境变量或路径>>"%LOG%" & echo 未找到 ffmpeg & pause & exit /b 1)

rem ========== 处理参数（可改）==========
rem 目标竖屏分辨率（宽x高）
set "TARGET_W=1080"
set "TARGET_H=1920"

rem 画质（CRF越小越清晰，体积越大；18~24 建议）
set "CRF=22"

rem 可选水印文字；留空表示不加
set "WM_TEXT="

rem 完成后是否把源文件移动到 done（1=是 0=否）
set "MOVE_DONE=1"

rem ========== 开始处理 ==========
set "COUNT=0"

rem 支持 mp4 mov m4v；可自行加上 *.avi 等
for %%F in ("%IN%\*.mp4") do call :PROCESS "%%~fF"
for %%F in ("%IN%\*.mov") do call :PROCESS "%%~fF"
for %%F in ("%IN%\*.m4v") do call :PROCESS "%%~fF"

echo 处理完成，共处理 %COUNT% 个文件>>"%LOG%"
echo ==== End %DATE% %TIME% ====>>"%LOG%"
echo 全部完成，日志：%LOG%
pause
exit /b 0

:PROCESS
set "SRC=%~1"
set "NAME=%~n1"
set "EXT=%~x1"
set "DST=%OUT%\%NAME%_1080x1920.mp4"

echo.>>"%LOG%"
echo [INFO] %TS% 处理：%SRC%>>"%LOG%"

rem 构建滤镜：先等比缩放适配竖屏高，再用 boxblur+复制铺底
set "VF=scale=-2:%TARGET_H%:flags=lanczos,setsar=1:1"
set "BG=split[a][b],[a]scale=%TARGET_W%:%TARGET_H%:force_original_aspect_ratio=increase,boxblur=20:1[bg];[b]scale=-2:%TARGET_H%:flags=lanczos,setsar=1:1[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2"

if not "%WM_TEXT%"=="" (
    rem 左下角加半透明白底文字水印
    set "WF=drawbox=x=20:y=H-100:w=text_w('^%WM_TEXT^%')+40:h=60:color=white@0.35:t=fill,drawtext=fontfile=C\\:/Windows/Fonts/msyh.ttc:text='%WM_TEXT%':fontcolor=black:fontsize=28:x=40:y=H-80"
    set "ALLVF=%BG%,%WF%"
) else (
    set "ALLVF=%BG%"
)

echo [CMD] ffmpeg 开始转码 >>"%LOG%"
ffmpeg -y -hide_banner -loglevel error ^
 -i "%SRC%" ^
 -filter_complex "%ALLVF%" ^
 -c:v libx264 -preset veryfast -crf %CRF% -pix_fmt yuv420p ^
 -c:a aac -b:a 128k -ac 2 -ar 44100 ^
 "%DST%" >>"%LOG%" 2>&1

if errorlevel 1 (
   echo [ERR] 转码失败：%SRC% >>"%LOG%"
   echo 失败：%SRC%
   goto :EOF
) else (
   echo [OK] 输出：%DST% >>"%LOG%"
   echo 成功：%DST%
)

if "%MOVE_DONE%"=="1" (
   move /y "%SRC%" "%DONE%" >nul
   echo [MOVE] 已移动源文件到 done >>"%LOG%"
)

set /a COUNT+=1
goto :EOF