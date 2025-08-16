@echo off
setlocal EnableExtensions
set "BASE=C:\VideoBot"
set "OUT=%BASE%\out"
set "TMP=%BASE%\temp"
set "LOGS=%BASE%\logs"
if not exist "%TMP%" md "%TMP%"
if not exist "%LOGS%" md "%LOGS%"

where ffmpeg >nul 2>&1 || (echo 未找到 ffmpeg & pause & exit /b 1)
where curl   >nul 2>&1 || (echo 未找到 curl & pause & exit /b 1)

if "%OPENAI_API_KEY%"=="" (
  echo 未检测到 OPENAI_API_KEY 环境变量
  echo 请先在 CMD 里设置：setx OPENAI_API_KEY "sk-xxxx" /m
  pause
  exit /b 1
)

for %%F in ("%OUT%\*.mp4") do call :ONE "%%~fF"
echo 全部完成
pause
exit /b 0

:ONE
set "SRC=%~1"
set "NAME=%~n1"
set "WAV=%TMP%\%NAME%.wav"
set "SRT=%OUT%\%NAME%.srt"
echo 处理：%SRC%

ffmpeg -y -hide_banner -loglevel error -i "%SRC%" -vn -ac 1 -ar 16000 "%WAV%" || (echo 提取音频失败 & goto :EOF)

curl -s -X POST "https://api.openai.com/v1/audio/transcriptions" ^
  -H "Authorization: Bearer %OPENAI_API_KEY%" ^
  -H "Content-Type: multipart/form-data" ^
  -F "file=@%WAV%" ^
  -F "model=whisper-1" ^
  -F "response_format=srt" ^
  -o "%SRT%"

if exist "%SRT%" (echo 已生成字幕：%SRT%) else (echo 生成字幕失败)
del /q "%WAV%" >nul 2>&1
goto :EOF