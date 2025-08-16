@echo off
set IN=C:\VideoBot\in
set OUT=C:\VideoBot\out
set DONE=C:\VideoBot\done
set LOG=C:\VideoBot\logs\ffmpeg_%date:~0,4%%date:~5,2%%date:~8,2%.log

echo ==== Start %date% %time% ====>> "%LOG%"
for %%F in ("%IN%\*.mp4") do (
  echo Processing "%%~nxF" >> "%LOG%"
  ffmpeg -y -i "%%F" -vf "scale=1280:-2,format=yuv420p" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k "%OUT%\%%~nF_720p.mp4" >> "%LOG%" 2>&1
  if %errorlevel%==0 move "%%F" "%DONE%" >nul
)
echo ==== End %date% %time% ====>> "%LOG%"