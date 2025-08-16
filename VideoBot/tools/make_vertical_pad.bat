@echo off
setlocal EnableDelayedExpansion

REM —— 固定工作目录为脚本所在位置 ——
cd /d "%~dp0"

REM —— 如果你的 ffmpeg 已加入 PATH，这里就用 ffmpeg；否则改成 C:\ffmpeg\bin\ffmpeg.exe ——
set "FF=ffmpeg"

REM —— 目录（相对脚本） ——
set "IN=%cd%\in"
set "OUT=%cd%\out"
set "DONE=%cd%\done"
set "LOG=%cd%\logs\run_%date:~0,4%%date:~5,2%%date:~8,2%.log"

if not exist "%OUT%"  mkdir "%OUT%"
if not exist "%DONE%" mkdir "%DONE%"
if not exist "%cd%\logs" mkdir "%cd%\logs"

echo ==== Start %date% %time% ====>> "%LOG%"

REM —— 批量处理常见视频格式 ——
for %%F in ("%IN%\*.mp4" "%IN%\*.mov" "%IN%\*.mkv" "%IN%\*.avi") do (
  if exist "%%F" (
    set "NAME=%%~nF"
    echo Processing "%%~nxF" >> "%LOG%"

    if exist "%cd%\watermark.png" (
      "%FF%" -y -i "%%F" -i "%cd%\watermark.png" ^
        -filter_complex "scale=iw*min(1080/iw\,1920/ih):ih*min(1080/iw\,1920/ih),pad=1080:1920:(1080-iw*min(1080/iw\,1920/ih))/2:(1920-ih*min(1080/iw\,1920/ih))/2:black[bg];[bg][1:v]overlay=W-w-40:H-h-40" ^
        -c:v libx264 -preset medium -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart ^
        "%OUT%\!NAME!_1080x1920_pad.mp4" >> "%LOG%" 2>&1
    ) else (
      "%FF%" -y -i "%%F" ^
        -vf "scale=iw*min(1080/iw\,1920/ih):ih*min(1080/iw\,1920/ih),pad=1080:1920:(1080-iw*min(1080/iw\,1920/ih))/2:(1920-ih*min(1080/iw\,1920/ih))/2:black,format=yuv420p" ^
        -c:v libx264 -preset medium -crf 22 -c:a aac -b:a 128k -movflags +faststart ^
        "%OUT%\!NAME!_1080x1920_pad.mp4" >> "%LOG%" 2>&1
    )

    if !errorlevel! EQU 0 (
      move /y "%%F" "%DONE%" >nul
    ) else (
      echo Failed on "%%~nxF" >> "%LOG%"
    )
  )
)

echo ==== End %date% %time% ====>> "%LOG%"
pause