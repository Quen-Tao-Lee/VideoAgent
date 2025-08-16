$ErrorActionPreference = "Stop"

# ===== 配置 =====
$CFG = @{
  IN       = "C:\VideoBot\in"
  OUT      = "C:\VideoBot\out"
  DONE     = "C:\VideoBot\done"
  TMP      = "C:\VideoBot\temp"
  LOG      = "C:\VideoBot\logs"
  TargetW  = 1080
  TargetH  = 1920
  CRF      = 22
  AddSub   = $true
  FontName = "Microsoft YaHei"
  Model    = "whisper-1"
}

# ===== 日志 =====
function Log($msg){
  $f = Join-Path $CFG.LOG ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "[$ts] $msg" | Tee-Object -FilePath $f -Append
}

# ===== 依赖校验 =====
function Must($tool){
  $p = (Get-Command $tool -ErrorAction SilentlyContinue).Source
  if(-not $p){ throw "Missing dependency: $tool not in PATH" }
}
Must "ffmpeg"
Must "ffprobe"
Must "curl.exe"
if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)){ throw "OPENAI_API_KEY not found" }

# ===== 工具函数 =====
function Stable($path){
  try{
    $s1 = (Get-Item $path).Length
    Start-Sleep -Milliseconds 1500
    $s2 = (Get-Item $path).Length
    return ($s1 -eq $s2)
  } catch { return $false }
}
function RunFF($args){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "ffmpeg"
  $psi.Arguments = $args
  $psi.RedirectStandardError = $true
  $psi.RedirectStandardOutput = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  $null = $p.Start()
  $e = $p.StandardError.ReadToEnd()
  $o = $p.StandardOutput.ReadToEnd()
  $p.WaitForExit()
  if($p.ExitCode -ne 0){
    Log "ffmpeg failed: $args"
    Log $e
    throw "ffmpeg exit $($p.ExitCode)"
  } else {
    Log "ffmpeg success: $args"
  }
}
function HaveAudio($file){
  $info = & ffprobe -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 "`"$file`""
  return -not [string]::IsNullOrWhiteSpace($info)
}

# ===== 启动 =====
Write-Host "== VideoAgent DEBUG Running, monitoring: $($CFG.IN) ==" -ForegroundColor Cyan
Log "Agent started (DEBUG MODE)"

# 检查目录是否存在
if(-not (Test-Path $CFG.IN)){
  Log "ERROR: IN directory does not exist: $($CFG.IN)"
  throw "IN directory missing"
}

$loopCount = 0
while($true){
  $loopCount++
  Log "=== Loop $loopCount: Scanning $($CFG.IN) ==="
  Write-Host "Loop $loopCount: Scanning..." -ForegroundColor Yellow
  
  # 列出目录中的所有文件（调试用）
  try{
    $allFiles = Get-ChildItem $CFG.IN -ErrorAction SilentlyContinue
    Log "All files in IN directory: $($allFiles.Count) files"
    foreach($af in $allFiles){
      Log "  Found: $($af.Name) (Size: $($af.Length) bytes, Type: $($af.Extension))"
    }
  } catch {
    Log "Error listing all files: $($_.Exception.Message)"
  }
  
  # 查找视频文件
  try{
    $files = Get-ChildItem $CFG.IN -File -Include *.mp4,*.mov,*.mkv,*.m4v -ErrorAction SilentlyContinue
    Log "Video files found: $($files.Count)"
    foreach($f in $files){
      Log "  Video: $($f.Name) (Size: $($f.Length) bytes)"
    }
  } catch {
    Log "Error finding video files: $($_.Exception.Message)"
  }
  
  foreach($f in $files){
    $src = $f.FullName
    Log "Checking stability of: $($f.Name)"
    
    if(-not (Stable $src)){ 
      Log "File transfer incomplete, skip: $($f.Name)"
      Write-Host "Skipping unstable file: $($f.Name)" -ForegroundColor Red
      continue 
    }

    $name = $f.BaseName
    $work = Join-Path $CFG.TMP ($name + "_" + [guid]::NewGuid().ToString("N").Substring(0,8))
    New-Item $work -ItemType Directory | Out-Null

    try{
      Log "Start processing: $($f.Name)"
      Write-Host "Processing: $($f.Name)" -ForegroundColor Green

      # 1) Extract audio
      if(-not (HaveAudio $src)){ throw "Source video has no audio track" }
      $wav = Join-Path $work "audio.wav"
      RunFF "-y -i `"$src`" -vn -ac 1 -ar 16000 `"$wav`""
      if((Get-Item $wav).Length -gt 25MB){ throw "Audio exceeds 25MB limit for Whisper" }

      # 2) Whisper -> SRT
      $srt = Join-Path $work "sub.srt"
      $resp = Join-Path $work "api.txt"
      $key  = $env:OPENAI_API_KEY
      $http = & curl.exe -s -w "%{http_code}" -o "$resp" -X POST "https://api.openai.com/v1/audio/transcriptions" `
        -H "Authorization: Bearer $key" -H "Content-Type: multipart/form-data" `
        -F "file=@$wav" -F "model=$($CFG.Model)" -F "response_format=srt" -F "temperature=0"
      if($http -ne "200"){ throw "API failed HTTP=$http -> $(Get-Content $resp -Raw)" }
      $txt = Get-Content $resp -Raw -Encoding UTF8
      if(-not ($txt -match "^\s*1\s*`r?`n")){ throw "Response not SRT format -> $txt" }
      Set-Content -Path $srt -Value $txt -Encoding UTF8
      Log "SRT generated successfully"

      # 3) Portrait + hardcoded subtitles
      $vfBase = "scale=$($CFG.TargetW):-2:flags=lanczos,pad=$($CFG.TargetW):$($CFG.TargetH):(ow-iw)/2:(oh-ih)/2:color=black,setsar=1"
      $outName = $name + "_1080x1920" + ($(if($CFG.AddSub){"_sub"}else{""})) + ".mp4"
      $outMp4  = Join-Path $CFG.OUT $outName

      if($CFG.AddSub){
        $sub = ($srt -replace '\\','/').Replace("'","\'")
        $style = "FontName=$($CFG.FontName),FontSize=42,Outline=2,Shadow=1,PrimaryColour=&H00FFFFFF,BackColour=&H64000000,BorderStyle=1,Alignment=2,MarginV=36"
        $vf = "$vfBase,subtitles='$sub':charenc=UTF-8:force_style='$style'"
      } else {
        $vf = $vfBase
      }

      RunFF "-y -i `"$src`" -vf `"$vf`" -c:v libx264 -preset medium -crf $($CFG.CRF) -c:a aac -b:a 128k `"$outMp4`""

      # 4) Output and archive
      Copy-Item $srt (Join-Path $CFG.OUT ($name + ".srt")) -Force
      Move-Item $src (Join-Path $CFG.DONE $f.Name) -Force

      Log "Completed: $($f.Name) -> $outName"
      Write-Host "✓ Completed: $outName" -ForegroundColor Green
    }
    catch{
      Log "ERROR: $($_.Exception.Message)"
      Write-Host "✗ Failed: $($f.Name) - $($_.Exception.Message)" -ForegroundColor Red
      Move-Item $src (Join-Path $CFG.DONE ("ERROR_" + $f.Name)) -Force
    }
    finally{
      if(Test-Path $work){ Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue; Log "Cleanup: $work" }
    }
  }

  Start-Sleep -Seconds 3
}