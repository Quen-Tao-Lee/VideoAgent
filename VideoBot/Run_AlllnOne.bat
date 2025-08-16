@echo off
title VideoAgent One-Click (Hardened)
chcp 65001 >nul

:: 管理员检测
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo 请右键本文件，選擇“以管理员身份运行”。
  pause
  exit /b
)

set "ROOT=C:\VideoBot"
set "AGENT=%ROOT%\agent"
mkdir "%ROOT%\in" "%ROOT%\out" "%ROOT%\done" "%ROOT%\temp" "%ROOT%\logs" "%AGENT%" 2>nul

echo [自检] ffmpeg / ffprobe / curl ...
where ffmpeg  >nul 2>nul || (echo 缺少 ffmpeg：請把 ffmpeg\bin 加到 PATH 後重試 & pause & exit /b)
where ffprobe >nul 2>nul || (echo 缺少 ffprobe：請把 ffmpeg\bin 加到 PATH 後重試 & pause & exit /b)
where curl     >nul 2>nul || (echo 缺少 curl（Win10 自帶）：請檢查 %SystemRoot%\System32\curl.exe & pause & exit /b)

:: API Key
if "%OPENAI_API_KEY%"=="" (
  echo 未檢測到 OPENAI_API_KEY
  set /p OKEY=請粘貼你的 OpenAI API Key（粘貼後回車）： 
  if "%OKEY%"=="" (echo 未輸入，退出 & pause & exit /b)
  setx OPENAI_API_KEY "%OKEY%" /m >nul
  echo 已保存系統環境變量 OPENAI_API_KEY。
)

:: 寫入強化版 PowerShell 腳本
powershell -NoLogo -NoProfile -Command ^
 "$ps=@'
# ============ VideoAgent.ps1 (hardened) ============
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

$CFG = @{
  IN        = "C:\VideoBot\in"
  OUT       = "C:\VideoBot\out"
  DONE      = "C:\VideoBot\done"
  TMP       = "C:\VideoBot\temp"
  LOG       = "C:\VideoBot\logs"
  TargetW   = 1080
  TargetH   = 1920
  CRF       = 22
  AddHardSub = $true
  Model     = "whisper-1"
  MaxUpload = 24MB
}

foreach($d in @($CFG.IN,$CFG.OUT,$CFG.DONE,$CFG.TMP,$CFG.LOG)){ if(!(Test-Path $d)){ New-Item $d -ItemType Directory -Force | Out-Null } }

function Log($msg){
  $file = Join-Path $CFG.LOG ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
  $line = "[" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + "] " + $msg
  $line | Tee-Object -FilePath $file -Append
}

function Must($t){
  $p = (Get-Command $t -ErrorAction SilentlyContinue | Select-Object -First 1).Source
  if(-not $p){ throw ("MISSING: " + $t + " not in PATH") }
}
Must "ffmpeg"
Must "ffprobe"
Must "curl.exe"

if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)){ throw "OPENAI_API_KEY not found. Set it and rerun." }

function Stable($path){
  for($i=0;$i -lt 3;$i++){
    try{
      $a=(Get-Item $path).Length
      Start-Sleep -Seconds 2
      $b=(Get-Item $path).Length
      if($a -eq $b){ return $true }
    }catch{}
  }
  return $false
}

function EscapeAssPath($p){
  $q = $p -replace '\\','/'
  $q = $q -replace "'","\'"
  return $q
}

function IsLikelySrt($txt){
  return ($txt -match '^\s*1\s*\r?\n\d{2}:\d{2}:\d{2},\d{3}\s*-->\s*\d{2}:\d{2}:\d{2},\d{3}')
}

function RunFF($args){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "ffmpeg"
  $psi.Arguments = $args
  $psi.RedirectStandardError = $true
  $psi.RedirectStandardOutput = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  $err = $p.StandardError.ReadToEnd()
  $out = $p.StandardOutput.ReadToEnd()
  $p.WaitForExit()
  if($p.ExitCode -ne 0){ Log("ffmpeg fail: " + $args); Log($err); throw ("ffmpeg exit " + $p.ExitCode) } else { Log("ffmpeg ok: " + $args) }
}

function ProbeHasAudio($file){
  $json = ffprobe -v error -show_streams -of json -- "$file" | Out-String
  return ($json -match '"codec_type"\s*:\s*"audio"')
}
function ProbeDurationSec($file){
  $dur = ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -- "$file" 2>$null
  [double]::TryParse($dur,[ref]([double]$d)) | Out-Null
  if($d -lt 0.001){ return 0 } else { return [int][Math]::Round($d) }
}

Log "VideoAgent started. Watching: $($CFG.IN)"
Write-Host ("Watching: " + $CFG.IN)

while($true){
  try{
    $files = Get-ChildItem $CFG.IN -File -Include *.mp4,*.mov,*.mkv,*.m4v -ErrorAction SilentlyContinue
    foreach($f in $files){
      $src = $f.FullName
      if(-not (Stable $src)){ Log("still copying: " + $f.Name); continue }

      if(-not (ProbeHasAudio $src)){ Log("no audio: " + $f.Name); Write-Host ("FAIL(no audio): " + $f.Name) -ForegroundColor Yellow; Move-Item $src (Join-Path $CFG.DONE ("NOAUDIO_" + $f.Name)) -Force; continue }
      $dur = ProbeDurationSec $src
      if($dur -eq 0){ Log("duration 0: " + $f.Name); Move-Item $src (Join-Path $CFG.DONE ("ZERODUR_" + $f.Name)) -Force; continue }

      $name = $f.BaseName
      $guid = [guid]::NewGuid().ToString().Substring(0,8)
      $work = Join-Path $CFG.TMP ($name + "_" + (Get-Date -Format "yyyyMMddHHmmss") + "_" + $guid)
      New-Item $work -ItemType Directory -Force | Out-Null
      Log("start: " + $f.Name); Write-Host ("Processing: " + $f.Name)

      try{
        # 1) 優先輸出 wav（Whisper 最穩），太大則轉 m4a 48kbps
        $wav = Join-Path $work "audio.wav"
        RunFF ('-y -i "' + $src + '" -vn -ac 1 -ar 16000 "' + $wav + '"')
        $upload = $wav
        if((Get-Item $wav).Length -gt $CFG.MaxUpload){
          $m4a = Join-Path $work "audio.m4a"
          RunFF ('-y -i "' + $src + '" -vn -ac 1 -ar 16000 -c:a aac -b:a 48k "' + $m4a + '"')
          if((Get-Item $m4a).Length -lt $CFG.MaxUpload){ $upload = $m4a } else { throw "Audio too large for Whisper after compress" }
        }

        # 2) 調 OpenAI，強化校驗
        $srt = Join-Path $work "sub.srt"
        $resp = Join-Path $work "api_response.txt"
        $key  = $env:OPENAI_API_KEY
        $cmd  = @('curl.exe','-s','-w','%{http_code}','-o',$resp,'-X','POST','https://api.openai.com/v1/audio/transcriptions','-H',('Authorization: Bearer ' + $key),'-H','Content-Type: multipart/form-data','-F',('file=@' + $upload),'-F',('model=' + $CFG.Model),'-F','response_format=srt','-F','temperature=0')
        $code = & $cmd 2>$null
        if($code -ne '200'){ $err = if(Test-Path $resp){ Get-Content $resp -Raw } else { "request failed" }; throw ("API HTTP " + $code + ": " + $err) }
        $txt = Get-Content $resp -Raw -Encoding UTF8
        if(-not (IsLikelySrt $txt)){ throw "API returned non-SRT content" }
        Set-Content -Path $srt -Value $txt -Encoding UTF8
        Log "srt ready"

        # 3) 轉 ASS（更穩）
        $ass = Join-Path $work "sub.ass"
        RunFF ('-y -i "' + $srt + '" "' + $ass + '"')

        # 4) 構建 VF，必要時燒字
        $W=[int]$CFG.TargetW; $H=[int]$CFG.TargetH
        $vf = "scale=" + $W + ":-2:flags=lanczos,pad=" + $W + ":" + $H + ":(ow-iw)/2:(oh-ih)/2:color=black,setsar=1"
        if($CFG.AddHardSub){ $assEsc = EscapeAssPath $ass; $vf = $vf + ",ass='" + $assEsc + "'" }

        $outName = $name + "_" + $W + "x" + $H + (if($CFG.AddHardSub){"_sub"}else{""}) + ".mp4"
        $outMp4  = Join-Path $CFG.OUT $outName
        if(Test-Path $outMp4){ Log("skip exists: " + $outName); Write-Host ("Skip exists: " + $outName) -ForegroundColor Yellow }
        else{
          RunFF ('-y -i "' + $src + '" -vf "' + $vf + '" -c:v libx264 -preset medium -crf ' + $CFG.CRF + ' -c:a aac -b:a 128k "' + $outMp4 + '"')
        }

        Copy-Item $srt (Join-Path $CFG.OUT ($name + ".srt")) -Force
        Move-Item $src (Join-Path $CFG.DONE $f.Name) -Force
        Log ("done: " + $outName); Write-Host ("OK: " + $outName) -ForegroundColor Green
      } catch {
        Log ("ERROR: " + $_.Exception.Message)
        Write-Host ("FAIL: " + $f.Name + " - " + $_.Exception.Message) -ForegroundColor Red
      } finally {
        if(Test-Path $work){ Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue; Log("clean: " + (Split-Path $work -Leaf)) }
      }
    }
  } catch {
    Log ("FATAL LOOP ERROR: " + $_.Exception.Message)
    Start-Sleep -Seconds 5
  }
  Start-Sleep -Seconds 3
}
# ============ /VideoAgent.ps1 ============
'@; Set-Content -Path '%AGENT%\VideoAgent.ps1' -Value $ps -Encoding UTF8"

if errorlevel 1 (
  echo 寫入主腳本失敗，請確認 C:\VideoBot\agent 可寫入。
  pause
  exit /b
)

echo 啟動監控...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%AGENT%\VideoAgent.ps1"