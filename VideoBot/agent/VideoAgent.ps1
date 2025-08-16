# VideoAgent - 智能视频处理工具
# 功能：自动监控、转录、翻译、格式转换

param(
    [switch]$SkipDoctor = $false
)

$ErrorActionPreference = "Stop"

# 配置
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

# 日志函数
function Log($msg, $level = "INFO") {
    $logFile = Join-Path $CFG.LOG ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$level] $msg"
    
    switch($level) {
        "ERROR" { Write-Host $logLine -ForegroundColor Red }
        "WARN"  { Write-Host $logLine -ForegroundColor Yellow }
        "INFO"  { Write-Host $logLine -ForegroundColor White }
        default { Write-Host $logLine }
    }
    
    try {
        $logLine | Add-Content -Path $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

# 环境检查
function Test-Environment {
    Log "Starting environment check..." "INFO"
    
    $dirs = @($CFG.IN, $CFG.OUT, $CFG.DONE, $CFG.TMP, $CFG.LOG)
    foreach($dir in $dirs) {
        if(-not (Test-Path $dir)) {
            Log "Creating directory: $dir" "INFO"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    $tools = @("ffmpeg", "ffprobe", "curl.exe")
    foreach($tool in $tools) {
        $path = (Get-Command $tool -ErrorAction SilentlyContinue).Source
        if(-not $path) {
            throw "Missing tool: $tool not found in PATH"
        }
        Log "Found tool: $tool" "INFO"
    }
    
    if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        Log "OPENAI_API_KEY not found" "WARN"
        $key = Read-Host "Please enter your OpenAI API Key"
        if([string]::IsNullOrWhiteSpace($key)) {
            throw "OPENAI_API_KEY is required"
        }
        [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $key, "User")
        $env:OPENAI_API_KEY = $key
        Log "OPENAI_API_KEY set successfully" "INFO"
    }
    
    Log "Environment check completed" "INFO"
}

# 文件稳定性检查
function Test-FileStable($filePath) {
    $initialSize = (Get-Item $filePath).Length
    Start-Sleep -Seconds 5
    $finalSize = (Get-Item $filePath).Length
    return $initialSize -eq $finalSize
}

# 获取视频信息
function Get-VideoInfo($filePath) {
    try {
        $probe = & ffprobe -v quiet -print_format json -show_format -show_streams $filePath 2>$null | ConvertFrom-Json
        
        $videoStream = $probe.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        if(-not $videoStream) {
            throw "No video stream found"
        }
        
        return @{
            Duration = [double]$probe.format.duration
            Width    = [int]$videoStream.width
            Height   = [int]$videoStream.height
            Size     = [long]$probe.format.size
        }
    } catch {
        throw "Failed to get video info: $($_.Exception.Message)"
    }
}

# 音频转录
function Invoke-Transcribe($videoPath) {
    Log "Starting audio transcription for: $(Split-Path $videoPath -Leaf)" "INFO"
    
    $audioFile = Join-Path $CFG.TMP "audio_$(Get-Date -Format 'HHmmss').wav"
    
    try {
        # 提取音频
        $extractCmd = "ffmpeg -i `"$videoPath`" -vn -acodec pcm_s16le -ar 16000 -ac 1 `"$audioFile`" -y"
        Log "Extracting audio..." "INFO"
        cmd /c $extractCmd 2>$null
        
        if(-not (Test-Path $audioFile)) {
            throw "Audio extraction failed"
        }
        
        # 调用OpenAI API
        Log "Calling OpenAI Whisper API..." "INFO"
        
        $audioBytes = [System.IO.File]::ReadAllBytes($audioFile)
        $boundary = [System.Guid]::NewGuid().ToString()
        
        $headers = @{
            "Authorization" = "Bearer $env:OPENAI_API_KEY"
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        
        # 构建multipart body
        $bodyParts = @()
        $bodyParts += "--$boundary"
        $bodyParts += 'Content-Disposition: form-data; name="file"; filename="audio.wav"'
        $bodyParts += 'Content-Type: audio/wav'
        $bodyParts += ''
        
        $bodyText = ($bodyParts -join "`r`n") + "`r`n"
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyText)
        
        $endBoundary = "`r`n--$boundary`r`nContent-Disposition: form-data; name=`"model`"`r`n`r`n$($CFG.Model)`r`n--$boundary`r`nContent-Disposition: form-data; name=`"response_format`"`r`n`r`nsrt`r`n--$boundary--`r`n"
        $endBytes = [System.Text.Encoding]::UTF8.GetBytes($endBoundary)
        
        # 合并所有字节
        $fullBody = New-Object byte[] ($bodyBytes.Length + $audioBytes.Length + $endBytes.Length)
        [Array]::Copy($bodyBytes, 0, $fullBody, 0, $bodyBytes.Length)
        [Array]::Copy($audioBytes, 0, $fullBody, $bodyBytes.Length, $audioBytes.Length)
        [Array]::Copy($endBytes, 0, $fullBody, $bodyBytes.Length + $audioBytes.Length, $endBytes.Length)
        
        # 发送请求
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/audio/transcriptions" -Method Post -Headers $headers -Body $fullBody
        
        Remove-Item $audioFile -Force -ErrorAction SilentlyContinue
        
        Log "Transcription completed" "INFO"
        return $response
        
    } catch {
        Remove-Item $audioFile -Force -ErrorAction SilentlyContinue
        throw "Transcription failed: $($_.Exception.Message)"
    }
}

# 视频处理
function Process-Video($inputPath) {
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($inputPath)
    $outputPath = Join-Path $CFG.OUT "$fileName.mp4"
    $donePath = Join-Path $CFG.DONE ([System.IO.Path]::GetFileName($inputPath))
    
    Log "Processing video: $([System.IO.Path]::GetFileName($inputPath))" "INFO"
    
    try {
        # 获取视频信息
        $videoInfo = Get-VideoInfo $inputPath
        $durationMin = [math]::Round($videoInfo.Duration / 60, 2)
        Log "Video info: $($videoInfo.Width)x$($videoInfo.Height), Duration: $durationMin minutes" "INFO"
        
        # 构建ffmpeg命令
        $filters = @()
        
        # 分辨率调整
        if($videoInfo.Width -ne $CFG.TargetW -or $videoInfo.Height -ne $CFG.TargetH) {
            $filters += "scale=$($CFG.TargetW):$($CFG.TargetH):force_original_aspect_ratio=decrease"
            $filters += "pad=$($CFG.TargetW):$($CFG.TargetH):(ow-iw)/2:(oh-ih)/2:black"
        }
        
        $filterStr = if($filters.Count -gt 0) { "-vf `"$($filters -join ',')`"" } else { "" }
        
        # 基础转换命令
        $cmd = "ffmpeg -i `"$inputPath`" $filterStr -c:v libx264 -crf $($CFG.CRF) -c:a aac -b:a 128k `"$outputPath`" -y"
        
        Log "Converting video..." "INFO"
        cmd /c $cmd 2>$null
        
        if(-not (Test-Path $outputPath)) {
            throw "Video conversion failed"
        }
        
        # 添加字幕
        if($CFG.AddSub) {
            try {
                $srtContent = Invoke-Transcribe $inputPath
                $srtFile = Join-Path $CFG.TMP "$fileName.srt"
                $srtContent | Out-File -FilePath $srtFile -Encoding UTF8
                
                # 生成带字幕的最终版本
                $finalOutput = Join-Path $CFG.OUT "$fileName`_with_subs.mp4"
                $fontPath = "C:\\Windows\\Fonts\\msyh.ttc"
                
                $subCmd = "ffmpeg -i `"$outputPath`" -vf `"subtitles='$srtFile':force_style='FontName=$($CFG.FontName),FontSize=24'`" -c:a copy `"$finalOutput`" -y"
                
                Log "Adding subtitles..." "INFO"
                cmd /c $subCmd 2>$null
                
                if(Test-Path $finalOutput) {
                    Remove-Item $outputPath -Force
                    $outputPath = $finalOutput
                    Log "Subtitles added successfully" "INFO"
                }
                
                Remove-Item $srtFile -Force -ErrorAction SilentlyContinue
                
            } catch {
                Log "Subtitle processing failed, keeping version without subtitles: $($_.Exception.Message)" "WARN"
            }
        }
        
        # 移动原文件到完成目录
        Move-Item $inputPath $donePath -Force
        
        $outputSize = (Get-Item $outputPath).Length
        $sizeMB = [math]::Round($outputSize/1MB, 2)
        Log "Processing completed: $([System.IO.Path]::GetFileName($outputPath)) ($sizeMB MB)" "INFO"
        
        return $outputPath
        
    } catch {
        Log "Video processing failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# 主监控循环
function Start-Agent {
    Log "VideoAgent started, monitoring: $($CFG.IN)" "INFO"
    
    while($true) {
        try {
            # 调试输出
            Write-Host "DEBUG: Scanning $($CFG.IN)" -ForegroundColor Yellow
            $allFiles = Get-ChildItem $CFG.IN -ErrorAction SilentlyContinue
            Write-Host "DEBUG: Found $($allFiles.Count) total files" -ForegroundColor Yellow
            
            # 修复后的视频文件检测 - 这是关键修复！
            $files = Get-ChildItem $CFG.IN -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\.(mp4|mov|mkv|m4v)$' }
            Write-Host "DEBUG: Found $($files.Count) video files" -ForegroundColor Yellow
            
            foreach($file in $files) {
                Log "Found video file: $($file.Name)" "INFO"
                
                # 检查文件稳定性
                if(-not (Test-FileStable $file.FullName)) {
                    Log "File still being transferred, skipping: $($file.Name)" "WARN"
                    continue
                }
                
                # 处理视频
                try {
                    Write-Host "PROCESSING: $($file.Name)" -ForegroundColor Green
                    $result = Process-Video $file.FullName
                    Write-Host "SUCCESS: Processing completed for $($file.Name)" -ForegroundColor Green
                    Log "Successfully processed: $($file.Name)" "INFO"
                } catch {
                    Write-Host "FAILED: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
                    Log "Processing failed: $($file.Name) - $($_.Exception.Message)" "ERROR"
                }
            }
            
        } catch {
            Log "Monitor loop error: $($_.Exception.Message)" "ERROR"
        }
        
        Start-Sleep -Seconds 3
    }
}

# 主程序入口
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         VideoAgent v2.0" -ForegroundColor Cyan  
    Write-Host "========================================" -ForegroundColor Cyan
    
    if(-not $SkipDoctor) {
        Test-Environment
    }
    
    Start-Agent
    
} catch {
    Log "Fatal error: $($_.Exception.Message)" "ERROR"
    Write-Host "Press any key to exit..." -ForegroundColor Red
    Read-Host
    exit 1
}