@echo off
setlocal EnableDelayedExpansion
cd /d C:\VideoBot\out

for %%F in (*.mp4) do (
  set "N=%%~nF"
  set "SRT1=%%~nF.srt"
  set "N2=!N:,=!"
  set "SRT2=!N2!.srt"

  if exist "!SRT1!" (
    echo [INFO] Burn "!SRT1!" -> "%%~nF_sub.mp4"
    ffmpeg -hide_banner -loglevel error -y -i "%%F" -vf "subtitles=!SRT1!:charenc=UTF-8:force_style='FontName=Microsoft YaHei,FontSize=44,Outline=2,Shadow=1'" -c:a copy "%%~nF_sub.mp4"
  ) else if exist "!SRT2!" (
    echo [INFO] Burn fallback "!SRT2!" -> "%%~nF_sub.mp4"
    ffmpeg -hide_banner -loglevel error -y -i "%%F" -vf "subtitles=!SRT2!:charenc=UTF-8:force_style='FontName=Microsoft YaHei,FontSize=44,Outline=2,Shadow=1'" -c:a copy "%%~nF_sub.mp4"
  ) else (
    echo [WARN] No SRT for "%%F"
  )
)

echo Done. Press any key to exit.
pause >nul