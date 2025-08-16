# VideoAgent - 智能视频处理工具 v2.0
# 功能：自动监控、转录、翻译、格式转换
param(
    [switch]$SkipDoctor = $false
)

$ErrorActionPreference = "Stop"

# ========== 配置区域 ==========
$CFG = @{
    # 目录配置
    IN       = "C:\VideoBot\in"        # 输入目录
    OUT      = "C:\VideoBot\out"       # 输出目录  
    DONE     = "C:\VideoBot\done"      # 完成目录
    TMP      = "C:\VideoBot\temp"      # 临时目录
    LOG      = "C:\VideoBot\logs"      # 日志目录
    
    # 视频配置
    TargetW  = 1080                    # 目标宽度
    TargetH  = 1920                    # 目标高度（竖屏）
    CRF      = 22                      # 质量控制(18-28，越小质量越高)
    
    # 字幕配置
    AddSub   = $true                   # 是否添加字幕
    FontName = "Microsoft YaHei"       # 字体名称
    FontSize = 24                      # 字体大小
    
    # AI配置
    Model    = "whisper-1"             # Whisper模型
    MaxRetry = 3                       # 最大重试次数
    
    # 处理配置
    ScanInterval = 3                   # 扫描间隔(秒)
    StableWait   = 5                   # 文件稳定等待时间(秒)
}

# ========== 日志系统 ==========
function Log($msg, $level = "INFO") {
    $logFile = Join-Path $CFG.LOG ("agent_" + (Get-Date -Format "yyyyMMdd") + ".log")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$level] $msg"
    
    # 控制台输出
    switch($level) {
        "ERROR" { Write-Host $logLine -ForegroundColor Red }
        "WARN"  { Write-Host $logLine -ForegroundColor Yellow }
        "INFO"  { Write-Host $logLine -ForegroundColor White }
        "DEBUG" { Write-Host $logLine -ForegroundColor Gray }
        default { Write-Host $logLine }
    }
    
    # 写入日志文件
    try {
        $logLine | Add-Content -Path $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # 忽略日志写入错误
    }
}

# ========== 环境检查 ==========
function Test-Environment {
    Log "开始环境检查..." "INFO"
    
    # 检查目录
    $dirs = @($CFG.IN, $CFG.OUT, $CFG.DONE, $CFG.TMP, $CFG.LOG)
    foreach($dir in $dirs) {
        if(-not (Test-Path $dir)) {
            Log "创建目录: $dir" "INFO"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
    }
    
    # 检查依赖工具
    $tools = @("ffmpeg", "ffprobe", "curl.exe")
    foreach($tool in $tools) {
        $path = (Get-Command $tool -ErrorAction SilentlyContinue).Source
        if(-not $path) {
            throw "缺少依赖工具: $tool 不在 PATH 中"
        }
        Log "找到 $tool -> $path" "DEBUG"
    }
    
    # 检查OpenAI API Key
    if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        Log "未找到 OPENAI_API_KEY 环境变量" "WARN"
        $key = Read-Host "请输入你的 OpenAI API Key"
        if([string]::IsNullOrWhiteSpace($key)) {
            throw "必须设置 OPENAI_API_KEY"
        }
        [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $key, "User")
        $env:OPENAI_API_KEY = $key
        Log "已设置 OPENAI_API_KEY 到用户环境变量" "INFO"
    }
    
    Log "环境检查完成" "INFO"
}

# ========== 文件稳定性检查 ==========
function Test-FileStable($filePath) {
    $initialSize = (Get-Item $filePath).Length
    Start-Sleep -Seconds $CFG.StableWait
    $finalSize = (Get-Item $filePath).Length
    return $initialSize -eq $finalSize
}

# ========== 视频信息获取 ==========
function Get-VideoInfo($filePath) {
    try {
        $probe = & ffprobe -v quiet -print_format json -show_format -show_streams $filePath 2>$null | ConvertFrom-Json
        
        $videoStream = $probe.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        if(-not $videoStream) {
            throw "未找到视频流"
        }
        
        return @{
            Duration = [double]$probe.format.duration
            Width    = [int]$videoStream.width
            Height   = [int]$videoStream.height
            FPS      = [double]($videoStream.r_frame_rate -split '/')[0] / [double]($videoStream.r_frame_rate -split '/')[1]
            Size     = [long]$probe.format.size
        }
    } catch {
        throw "获取视频信息失败: $($_.Exception.Message)"
    }
}

# ========== 音频转录 ==========
function Invoke-Transcribe($videoPath) {
    Log "开始音频转录: $(Split-Path $videoPath -Leaf)" "INFO"
    
    # 提取音频
    $audioFile = Join-Path $CFG.TMP "audio_$(Get-Date -Format 'HHmmss').wav"
    $extractCmd = "ffmpeg -i `"$videoPath`" -vn -acodec pcm_s16le -ar 16000 -ac 1 `"$audioFile`" -y"
    
    try {
        Log "提取音频: $extractCmd" "DEBUG"
        Invoke-Expression $extractCmd 2>$null
        
        if(-not (Test-Path $audioFile)) {
            throw "音频提取失败"
        }
        
        # 调用OpenAI Whisper API
        $headers = @{
            "Authorization" = "Bearer $env:OPENAI_API_KEY"
        }
        
        $boundary = [System.Guid]::NewGuid().ToString()
        $bodyTemplate = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="audio.wav"
Content-Type: audio/wav

{0}
--$boundary
Content-Disposition: form-data; name="model"

$($CFG.Model)
--$boundary
Content-Disposition: form-data; name="response_format"

srt
--$boundary--
"@

        $audioBytes = [System.IO.File]::ReadAllBytes($audioFile)
        $audioContent = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($audioBytes)
        $body = $bodyTemplate -f $audioContent
        
        $headers["Content-Type"] = "multipart/form-data; boundary=$boundary"
        
        Log "调用 OpenAI Whisper API..." "INFO"
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/audio/transcriptions" -Method Post -Headers $headers -Body ([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($body))
        
        # 清理临时音频文件
        Remove-Item $audioFile -Force -ErrorAction SilentlyContinue
        
        Log "转录完成" "INFO"
        return $response
        
    } catch {
        Remove-Item $audioFile -Force -ErrorAction SilentlyContinue
        throw "转录失败: $($_.Exception.Message)"
    }
}

# ========== 视频处理 ==========
function Invoke-ProcessVideo($inputPath) {
    $fileName = Split-Path $inputPath -LeafBase
    $outputPath = Join-Path $CFG.OUT "$fileName.mp4"
    $donePath = Join-Path $CFG.DONE (Split-Path $inputPath -Leaf)
    
    Log "开始处理视频: $(Split-Path $inputPath -Leaf)" "INFO"
    
    try {
        # 获取视频信息
        $videoInfo = Get-VideoInfo $inputPath
        Log "视频信息: $($videoInfo.Width)x$($videoInfo.Height), 时长: $([math]::Round($videoInfo.Duration, 2))秒" "INFO"
        
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
        
        Log "执行转换: $cmd" "DEBUG"
        Invoke-Expression $cmd 2>$null
        
        if(-not (Test-Path $outputPath)) {
            throw "视频转换失败"
        }
        
        # 添加字幕（如果启用）
        if($CFG.AddSub) {
            try {
                $srtContent = Invoke-Transcribe $inputPath
                $srtFile = Join-Path $CFG.TMP "$fileName.srt"
                $srtContent | Out-File -FilePath $srtFile -Encoding UTF8
                
                # 生成带字幕的最终版本
                $finalOutput = Join-Path $CFG.OUT "$fileName`_with_subs.mp4"
                $subCmd = "ffmpeg -i `"$outputPath`" -vf `"subtitles='$srtFile':force_style='FontName=$($CFG.FontName),FontSize=$($CFG.FontSize)'`" -c:a copy `"$finalOutput`" -y"
                
                Log "添加字幕: $subCmd" "DEBUG"
                Invoke-Expression $subCmd 2>$null
                
                if(Test-Path $finalOutput) {
                    Remove-Item $outputPath -Force
                    $outputPath = $finalOutput
                    Log "字幕添加成功" "INFO"
                }
                
                Remove-Item $srtFile -Force -ErrorAction SilentlyContinue
                
            } catch {
                Log "字幕处理失败，保留无字幕版本: $($_.Exception.Message)" "WARN"
            }
        }
        
        # 移动原文件到完成目录
        Move-Item $inputPath $donePath -Force
        
        $outputSize = (Get-Item $outputPath).Length
        Log "处理完成: $(Split-Path $outputPath -Leaf) ($(([math]::Round($outputSize/1MB, 2))) MB)" "INFO"
        
        return $outputPath
        
    } catch {
        Log "视频处理失败: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ========== 主监控循环 ==========
function Start-Agent {
    Log "VideoAgent 启动，监控目录: $($CFG.IN)" "INFO"
    
    while($true) {
        try {
            # 调试输出
            Write-Host "DEBUG: Scanning $($CFG.IN)" -ForegroundColor Yellow
            $allFiles = Get-ChildItem $CFG.IN -ErrorAction SilentlyContinue
            Write-Host "DEBUG: Found $($allFiles.Count) total files" -ForegroundColor Yellow
            
            # 修复后的视频文件检测
            $videoFiles = Get-ChildItem $CFG.IN -File -ErrorAction SilentlyContinue | Where-Object { 
                $_.Extension -match '\.(mp4|mov|mkv|m4v|avi|wmv|flv)$' 
            }
            Write-Host "DEBUG: Found $($videoFiles.Count) video files" -ForegroundColor Yellow
            
            foreach($file in $videoFiles) {
                Write-Host "DEBUG: Video file detected: $($file.Name)" -ForegroundColor Green
                
                Log "发现视频文件: $($file.Name)" "INFO"
                
                # 检查文件稳定性
                if(-not (Test-FileStable $file.FullName)) {
                    Log "文件还在传输中，跳过: $($file.Name)" "WARN"
                    continue
                }
                
                # 处理视频
                try {
                    $result = Invoke-ProcessVideo $file.FullName
                    Log "成功处理: $($file.Name) -> $(Split-Path $result -Leaf)" "INFO"
                } catch {
                    Log "处理失败: $($file.Name) - $($_.Exception.Message)" "ERROR"
                    # 移动失败的文件到错误目录（可选）
                }
            }
            
        } catch {
            Log "监控循环出错: $($_.Exception.Message)" "ERROR"
        }
        
        Start-Sleep -Seconds $CFG.ScanInterval
    }
}

# ========== 主程序入口 ==========
try {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         VideoAgent v2.0 启动中..." -ForegroundColor Cyan  
    Write-Host "========================================" -ForegroundColor Cyan
    
    if(-not $SkipDoctor) {
        Test-Environment
    }
    
    Start-Agent
    
} catch {
    Log "致命错误: $($_.Exception.Message)" "ERROR"
    Write-Host "按任意键退出..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}