# VideoAgent - 智能视频处理工具
param([switch]$SkipDoctor = $false)

$ErrorActionPreference = "Stop"

# 配置 - 使用单引号避免路径解析问题
$CFG = @{
    IN       = 'C:\VideoBot\in'
    OUT      = 'C:\VideoBot\out'
    DONE     = 'C:\VideoBot\done'
    TMP      = 'C:\VideoBot\temp'
    LOG      = 'C:\VideoBot\logs'
    TargetW  = 1080
    TargetH  = 1920
    CRF      = 22
    AddSub   = $true
    FontName = 'Microsoft YaHei'
    Model    = 'whisper-1'
}

# 日志函数
function Write-Log {
    param($Message, $Level = "INFO")
    
    $LogFile = Join-Path $CFG.LOG ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogLine = "[$Timestamp] [$Level] $Message"
    
    switch($Level) {
        "ERROR" { Write-Host $LogLine -ForegroundColor Red }
        "WARN"  { Write-Host $LogLine -ForegroundColor Yellow }
        "INFO"  { Write-Host $LogLine -ForegroundColor White }
        default { Write-Host $LogLine }
    }
    
    try {
        Add-Content -Path $LogFile -Value $LogLine -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # 忽略日志写入错误
    }
}

# 环境检查
function Test-Environment {
    Write-Log "Starting environment check..." "INFO"
    
    $Directories = @($CFG.IN, $CFG.OUT, $CFG.DONE, $CFG.TMP, $CFG.LOG)
    foreach($Directory in $Directories) {
        if(-not (Test-Path $Directory)) {
            Write-Log "Creating directory: $Directory" "INFO"
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
    }
    
    $Tools = @("ffmpeg", "ffprobe")
    foreach($Tool in $Tools) {
        $ToolPath = (Get-Command $Tool -ErrorAction SilentlyContinue).Source
        if(-not $ToolPath) {
            throw "Missing tool: $Tool not found in PATH"
        }
        Write-Log "Found tool: $Tool" "INFO"
    }
    
    if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        Write-Log "OPENAI_API_KEY not found" "WARN"
        $ApiKey = Read-Host "Please enter your OpenAI API Key"
        if([string]::IsNullOrWhiteSpace($ApiKey)) {
            throw "OPENAI_API_KEY is required"
        }
        [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $ApiKey, "User")
        $env:OPENAI_API_KEY = $ApiKey
        Write-Log "OPENAI_API_KEY set successfully" "INFO"
    }
    
    Write-Log "Environment check completed" "INFO"
}

# 文件稳定性检查
function Test-FileStable {
    param($FilePath)
    
    $InitialSize = (Get-Item $FilePath).Length
    Start-Sleep -Seconds 5
    $FinalSize = (Get-Item $FilePath).Length
    return $InitialSize -eq $FinalSize
}

# 获取视频信息
function Get-VideoInfo {
    param($FilePath)
    
    try {
        $ProbeJson = & ffprobe -v quiet -print_format json -show_format -show_streams $FilePath 2>$null
        $ProbeData = $ProbeJson | ConvertFrom-Json
        
        $VideoStream = $ProbeData.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        if(-not $VideoStream) {
            throw "No video stream found"
        }
        
        return @{
            Duration = [double]$ProbeData.format.duration
            Width    = [int]$VideoStream.width
            Height   = [int]$VideoStream.height
            Size     = [long]$ProbeData.format.size
        }
    } catch {
        throw "Failed to get video info: $($_.Exception.Message)"
    }
}

# 音频转录
function Invoke-Transcribe {
    param($VideoPath)
    
    Write-Log "Starting audio transcription for: $(Split-Path $VideoPath -Leaf)" "INFO"
    
    $AudioFile = Join-Path $CFG.TMP "audio_$(Get-Date -Format 'HHmmss').wav"
    
    try {
        # 提取音频
        $ExtractArgs = @(
            "-i", $VideoPath,
            "-vn",
            "-acodec", "pcm_s16le", 
            "-ar", "16000",
            "-ac", "1",
            $AudioFile,
            "-y"
        )
        
        Write-Log "Extracting audio..." "INFO"
        & ffmpeg @ExtractArgs 2>$null
        
        if(-not (Test-Path $AudioFile)) {
            throw "Audio extraction failed"
        }
        
        # 调用OpenAI API
        Write-Log "Calling OpenAI Whisper API..." "INFO"
        
        $AudioBytes = [System.IO.File]::ReadAllBytes($AudioFile)
        $Boundary = [System.Guid]::NewGuid().ToString()
        
        $Headers = @{
            "Authorization" = "Bearer $env:OPENAI_API_KEY"
            "Content-Type" = "multipart/form-data; boundary=$Boundary"
        }
        
        # 构建multipart body
        $BodyStart = "--$Boundary`r`n" +
                    "Content-Disposition: form-data; name=`"file`"; filename=`"audio.wav`"`r`n" +
                    "Content-Type: audio/wav`r`n`r`n"
        
        $BodyEnd = "`r`n--$Boundary`r`n" +
                  "Content-Disposition: form-data; name=`"model`"`r`n`r`n" +
                  "$($CFG.Model)`r`n" +
                  "--$Boundary`r`n" +
                  "Content-Disposition: form-data; name=`"response_format`"`r`n`r`n" +
                  "srt`r`n" +
                  "--$Boundary--`r`n"
        
        $BodyStartBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyStart)
        $BodyEndBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyEnd)
        
        # 合并所有字节
        $FullBodyLength = $BodyStartBytes.Length + $AudioBytes.Length + $BodyEndBytes.Length
        $FullBody = New-Object byte[] $FullBodyLength
        
        [Array]::Copy($BodyStartBytes, 0, $FullBody, 0, $BodyStartBytes.Length)
        [Array]::Copy($AudioBytes, 0, $FullBody, $BodyStartBytes.Length, $AudioBytes.Length)
        [Array]::Copy($BodyEndBytes, 0, $FullBody, $BodyStartBytes.Length + $AudioBytes.Length, $BodyEndBytes.Length)
        
        # 发送请求
        $Response = Invoke-RestMethod -Uri "https://api.openai.com/v1/audio/transcriptions" -Method Post -Headers $Headers -Body $FullBody
        
        Remove-Item $AudioFile -Force -ErrorAction SilentlyContinue
        
        Write-Log "Transcription completed" "INFO"
        return $Response
        
    } catch {
        Remove-Item $AudioFile -Force -ErrorAction SilentlyContinue
        throw "Transcription failed: $($_.Exception.Message)"
    }
}

# 视频处理
function Invoke-ProcessVideo {
    param($InputPath)
    
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $OutputPath = Join-Path $CFG.OUT "$FileName.mp4"
    $DonePath = Join-Path $CFG.DONE ([System.IO.Path]::GetFileName($InputPath))
    
    Write-Log "Processing video: $([System.IO.Path]::GetFileName($InputPath))" "INFO"
    
    try {
        # 获取视频信息
        $VideoInfo = Get-VideoInfo $InputPath
        $DurationMin = [math]::Round($VideoInfo.Duration / 60, 2)
        Write-Log "Video info: $($VideoInfo.Width)x$($VideoInfo.Height), Duration: $DurationMin minutes" "INFO"
        
        # 构建ffmpeg命令参数
        $ConvertArgs = @(
            "-i", $InputPath
        )
        
        # 分辨率调整
        if($VideoInfo.Width -ne $CFG.TargetW -or $VideoInfo.Height -ne $CFG.TargetH) {
            $FilterString = "scale=$($CFG.TargetW):$($CFG.TargetH):force_original_aspect_ratio=decrease,pad=$($CFG.TargetW):$($CFG.TargetH):(ow-iw)/2:(oh-ih)/2:black"
            $ConvertArgs += @("-vf", $FilterString)
        }
        
        $ConvertArgs += @(
            "-c:v", "libx264",
            "-crf", $CFG.CRF.ToString(),
            "-c:a", "aac", 
            "-b:a", "128k",
            $OutputPath,
            "-y"
        )
        
        Write-Log "Converting video..." "INFO"
        & ffmpeg @ConvertArgs 2>$null
        
        if(-not (Test-Path $OutputPath)) {
            throw "Video conversion failed"
        }
        
        # 添加字幕
        if($CFG.AddSub) {
            try {
                $SrtContent = Invoke-Transcribe $InputPath
                $SrtFile = Join-Path $CFG.TMP "$FileName.srt"
                $SrtContent | Out-File -FilePath $SrtFile -Encoding UTF8
                
                # 生成带字幕的最终版本
                $FinalOutput = Join-Path $CFG.OUT "$FileName`_with_subs.mp4"
                
                $SubArgs = @(
                    "-i", $OutputPath,
                    "-vf", "subtitles='$SrtFile':force_style='FontName=$($CFG.FontName),FontSize=24'",
                    "-c:a", "copy",
                    $FinalOutput,
                    "-y"
                )
                
                Write-Log "Adding subtitles..." "INFO"
                & ffmpeg @SubArgs 2>$null
                
                if(Test-Path $FinalOutput) {
                    Remove-Item $OutputPath -Force
                    $OutputPath = $FinalOutput
                    Write-Log "Subtitles added successfully" "INFO"
                }
                
                Remove-Item $SrtFile -Force -ErrorAction SilentlyContinue
                
            } catch {
                Write-Log "Subtitle processing failed, keeping version without subtitles: $($_.Exception.Message)" "WARN"
            }
        }
        
        # 移动原文件到完成目录
        Move-Item $InputPath $DonePath -Force
        
        $OutputSize = (Get-Item $OutputPath).Length
        $SizeMB = [math]::Round($OutputSize/1MB, 2)
        Write-Log "Processing completed: $([System.IO.Path]::GetFileName($OutputPath)) ($SizeMB MB)" "INFO"
        
        return $OutputPath
        
    } catch {
        Write-Log "Video processing failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# 主监控循环
function Start-Agent {
    Write-Log "VideoAgent started, monitoring: $($CFG.IN)" "INFO"
    
    while($true) {
        try {
            # 调试输出
            Write-Host "DEBUG: Scanning $($CFG.IN)" -ForegroundColor Yellow
            $AllFiles = Get-ChildItem $CFG.IN -ErrorAction SilentlyContinue
            Write-Host "DEBUG: Found $($AllFiles.Count) total files" -ForegroundColor Yellow
            
            # 修复后的视频文件检测
            $VideoFiles = Get-ChildItem $CFG.IN -File -ErrorAction SilentlyContinue | Where-Object { 
                $_.Extension -match '\.(mp4|mov|mkv|m4v)$' 
            }
            Write-Host "DEBUG: Found $($VideoFiles.Count) video files" -ForegroundColor Yellow
            
            foreach($VideoFile in $VideoFiles) {
                Write-Log "Found video file: $($VideoFile.Name)" "INFO"
                
                # 检查文件稳定性
                if(-not (Test-FileStable $VideoFile.FullName)) {
                    Write-Log "File still being transferred, skipping: $($VideoFile.Name)" "WARN"
                    continue
                }
                
                # 处理视频
                try {
                    Write-Host "PROCESSING: $($VideoFile.Name)" -ForegroundColor Green
                    $Result = Invoke-ProcessVideo $VideoFile.FullName
                    Write-Host "SUCCESS: Processing completed for $($VideoFile.Name)" -ForegroundColor Green
                    Write-Log "Successfully processed: $($VideoFile.Name)" "INFO"
                } catch {
                    Write-Host "FAILED: $($VideoFile.Name) - $($_.Exception.Message)" -ForegroundColor Red
                    Write-Log "Processing failed: $($VideoFile.Name) - $($_.Exception.Message)" "ERROR"
                }
            }
            
        } catch {
            Write-Log "Monitor loop error: $($_.Exception.Message)" "ERROR"
        }
        
        Start-Sleep -Seconds 3
    }
}

# 主程序入口
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         VideoAgent v2.1 Fixed" -ForegroundColor Cyan  
    Write-Host "========================================" -ForegroundColor Cyan
    
    if(-not $SkipDoctor) {
        Test-Environment
    }
    
    Start-Agent
    
} catch {
    Write-Log "Fatal error: $($_.Exception.Message)" "ERROR"
    Write-Host "Press any key to exit..." -ForegroundColor Red
    Read-Host
    exit 1
}