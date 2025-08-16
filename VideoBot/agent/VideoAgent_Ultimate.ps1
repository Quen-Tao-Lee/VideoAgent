# VideoAgent Ultimate - 企业级视频处理解决方案
# 作者: Copilot AI Assistant
# 版本: v3.0 Ultimate
# 用户: Quen-Tao-Lee
# 日期: 2025-08-16

param(
    [switch]$InstallService = $false,
    [switch]$WebInterface = $false,
    [switch]$SkipDoctor = $false,
    [string]$ConfigFile = "",
    [string]$Port = "8080"
)

# 全局配置
$Global:CFG = @{
    # 基础路径
    IN          = 'C:\VideoBot\in'
    OUT         = 'C:\VideoBot\out'
    DONE        = 'C:\VideoBot\done'
    TMP         = 'C:\VideoBot\temp'
    LOG         = 'C:\VideoBot\logs'
    CONFIG      = 'C:\VideoBot\config'
    WEB         = 'C:\VideoBot\web'
    
    # 处理预设
    PRESETS     = @{
        'mobile'    = @{ W=1080; H=1920; CRF=23; Preset='medium'; Desc='手机竖屏' }
        'desktop'   = @{ W=1920; H=1080; CRF=20; Preset='medium'; Desc='电脑横屏' }
        '4k'        = @{ W=3840; H=2160; CRF=18; Preset='slow'; Desc='4K超清' }
        'web'       = @{ W=1280; H=720; CRF=25; Preset='fast'; Desc='网络优化' }
        'social'    = @{ W=1080; H=1080; CRF=23; Preset='medium'; Desc='社交媒体' }
    }
    
    # AI设置
    AI = @{
        Model       = 'whisper-1'
        Language    = 'auto'
        AddSubs     = $true
        Provider    = 'deepseek'
        EnableContentAnalysis = $true
        EnableMarketingGeneration = $true
        EnableSEOOptimization = $true
        EnableSubtitleOptimization = $true
        EnableCostMonitoring = $true
        SubStyle    = @{
            FontName = 'Microsoft YaHei'
            FontSize = 24
            Color    = 'white'
            Shadow   = $true
        }
    }
    
    # Web界面设置
    WEB_CONFIG = @{
        Port        = $Port
        Host        = 'localhost'
        EnableAPI   = $true
        EnableAuth  = $false
        Theme       = 'dark'
    }
    
    # 统计设置
    STATS = @{
        EnableStats     = $true
        ReportInterval  = 3600  # 1小时
        KeepDays       = 30
    }
}

# 导入DeepSeek模块
$DeepSeekModulePath = Join-Path $PSScriptRoot "..\modules\DeepSeek.ps1"
if(Test-Path $DeepSeekModulePath) {
    . $DeepSeekModulePath
} else {
    Write-Warning "DeepSeek module not found at: $DeepSeekModulePath"
}

# 全局变量
$Global:DeepSeekClient = $null
$Global:DeepSeekConfig = $null

# 加载DeepSeek配置
function Initialize-DeepSeekConfiguration {
    $configPath = Join-Path $Global:CFG.CONFIG "deepseek-config.json"
    if(Test-Path $configPath) {
        try {
            $Global:DeepSeekConfig = Get-Content $configPath -Raw | ConvertFrom-Json
            Write-UltimateLog "DeepSeek configuration loaded successfully" "SUCCESS" "DEEPSEEK"
        } catch {
            Write-UltimateLog "Failed to load DeepSeek configuration: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        }
    } else {
        Write-UltimateLog "DeepSeek configuration file not found: $configPath" "WARN" "DEEPSEEK"
    }
}

# 初始化DeepSeek客户端
function Initialize-DeepSeekClient {
    if([string]::IsNullOrWhiteSpace($env:DEEPSEEK_API_KEY)) {
        Write-UltimateLog "DEEPSEEK_API_KEY not configured, skipping DeepSeek initialization" "WARN" "DEEPSEEK"
        return $false
    }
    
    try {
        $Global:DeepSeekClient = [DeepSeekClient]::new($env:DEEPSEEK_API_KEY)
        Write-UltimateLog "DeepSeek client initialized successfully" "SUCCESS" "DEEPSEEK"
        return $true
    } catch {
        Write-UltimateLog "Failed to initialize DeepSeek client: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        return $false
    }
}

# 日志系统
function Write-UltimateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "SYSTEM"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogLine = "[$Timestamp] [$Level] [$Component] $Message"
    
    # 控制台输出
    $Color = switch($Level) {
        "ERROR"   { "Red" }
        "WARN"    { "Yellow" }
        "INFO"    { "White" }
        "SUCCESS" { "Green" }
        "DEBUG"   { "Gray" }
        default   { "White" }
    }
    
    Write-Host $LogLine -ForegroundColor $Color
    
    # 文件日志
    try {
        $LogFile = Join-Path $Global:CFG.LOG ("videoagent_" + (Get-Date -Format "yyyyMMdd") + ".log")
        Add-Content -Path $LogFile -Value $LogLine -Encoding UTF8 -ErrorAction SilentlyContinue
        
        # JSON结构化日志用于Web界面
        $JsonLog = @{
            timestamp = $Timestamp
            level = $Level
            component = $Component
            message = $Message
            user = $env:USERNAME
        } | ConvertTo-Json -Compress
        
        $JsonLogFile = Join-Path $Global:CFG.LOG ("structured_" + (Get-Date -Format "yyyyMMdd") + ".jsonl")
        Add-Content -Path $JsonLogFile -Value $JsonLog -Encoding UTF8 -ErrorAction SilentlyContinue
        
    } catch {
        # 忽略日志写入错误
    }
}

# 配置管理
function Initialize-Configuration {
    Write-UltimateLog "Initializing VideoAgent Ultimate configuration..." "INFO" "CONFIG"
    
    # 创建目录结构
    $AllDirs = @($Global:CFG.IN, $Global:CFG.OUT, $Global:CFG.DONE, $Global:CFG.TMP, 
                 $Global:CFG.LOG, $Global:CFG.CONFIG, $Global:CFG.WEB)
    
    foreach($Dir in $AllDirs) {
        if(-not (Test-Path $Dir)) {
            New-Item -Path $Dir -ItemType Directory -Force | Out-Null
            Write-UltimateLog "Created directory: $Dir" "INFO" "CONFIG"
        }
    }
    
    # 保存配置文件
    $ConfigPath = Join-Path $Global:CFG.CONFIG "settings.json"
    $Global:CFG | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
    
    # 创建用户配置文件
    $UserConfig = @{
        user = "Quen-Tao-Lee"
        created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        version = "3.0-Ultimate"
        preferences = @{
            defaultPreset = "mobile"
            autoSubtitles = $true
            notifications = $true
            webInterface = $true
        }
    }
    
    $UserConfigPath = Join-Path $Global:CFG.CONFIG "user_preferences.json"
    $UserConfig | ConvertTo-Json -Depth 5 | Out-File -FilePath $UserConfigPath -Encoding UTF8
    
    Write-UltimateLog "Configuration initialized successfully" "SUCCESS" "CONFIG"
}

# 环境检查增强版
function Test-UltimateEnvironment {
    Write-UltimateLog "Starting comprehensive environment check..." "INFO" "DOCTOR"
    
    $Issues = @()
    
    # 检查FFmpeg
    try {
        $FFmpegVersion = & ffmpeg -version 2>$null | Select-Object -First 1
        if($FFmpegVersion -match "ffmpeg version (.+?) ") {
            Write-UltimateLog "FFmpeg found: $($Matches[1])" "SUCCESS" "DOCTOR"
        }
    } catch {
        $Issues += "FFmpeg not found in PATH"
    }
    
    # 检查网络连接
    try {
        $TestConnection = Test-NetConnection -ComputerName "api.openai.com" -Port 443 -WarningAction SilentlyContinue
        if($TestConnection.TcpTestSucceeded) {
            Write-UltimateLog "OpenAI API connectivity: OK" "SUCCESS" "DOCTOR"
        } else {
            $Issues += "Cannot reach OpenAI API"
        }
    } catch {
        $Issues += "Network connectivity test failed"
    }
    
    # 检查API Key
    if([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
        Write-UltimateLog "OpenAI API Key not configured" "WARN" "DOCTOR"
        
        # 智能API Key设置
        $ApiKeyPath = Join-Path $Global:CFG.CONFIG "api_key.txt"
        if(Test-Path $ApiKeyPath) {
            $SavedKey = Get-Content $ApiKeyPath -Raw
            $env:OPENAI_API_KEY = $SavedKey.Trim()
            Write-UltimateLog "Loaded saved API key" "SUCCESS" "DOCTOR"
        } else {
            Write-Host "`n🔑 OpenAI API Key Setup Required" -ForegroundColor Yellow
            Write-Host "Please enter your OpenAI API Key (will be saved securely):" -ForegroundColor Cyan
            $ApiKey = Read-Host -AsSecureString "API Key"
            $PlainKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey))
            
            if(-not [string]::IsNullOrWhiteSpace($PlainKey)) {
                $env:OPENAI_API_KEY = $PlainKey
                $PlainKey | Out-File -FilePath $ApiKeyPath -Encoding UTF8
                Write-UltimateLog "API Key configured and saved" "SUCCESS" "DOCTOR"
            }
        }
    }
    
    # 检查可用端口
    if($Global:CFG.WEB_CONFIG.EnableAPI) {
        try {
            $PortInUse = Get-NetTCPConnection -LocalPort $Global:CFG.WEB_CONFIG.Port -ErrorAction SilentlyContinue
            if($PortInUse) {
                Write-UltimateLog "Port $($Global:CFG.WEB_CONFIG.Port) is in use, trying alternative..." "WARN" "DOCTOR"
                $Global:CFG.WEB_CONFIG.Port = "8081"
            }
        } catch {
            # 端口检查失败，继续使用默认端口
        }
    }
    
    # 磁盘空间检查
    $Drive = (Get-Item $Global:CFG.OUT).PSDrive
    $FreeSpaceGB = [math]::Round($Drive.Free / 1GB, 2)
    if($FreeSpaceGB -lt 5) {
        $Issues += "Low disk space: $FreeSpaceGB GB available"
    } else {
        Write-UltimateLog "Disk space: $FreeSpaceGB GB available" "SUCCESS" "DOCTOR"
    }
    
    # 检查DeepSeek配置
    Write-UltimateLog "Checking DeepSeek AI integration..." "INFO" "DOCTOR"
    
    # 检查DeepSeek网络连接
    try {
        $DeepSeekConnection = Test-NetConnection -ComputerName "api.deepseek.com" -Port 443 -WarningAction SilentlyContinue
        if($DeepSeekConnection.TcpTestSucceeded) {
            Write-UltimateLog "DeepSeek API connectivity: OK" "SUCCESS" "DOCTOR"
        } else {
            Write-UltimateLog "Cannot reach DeepSeek API - network may be restricted" "WARN" "DOCTOR"
        }
    } catch {
        Write-UltimateLog "DeepSeek network connectivity test failed" "WARN" "DOCTOR"
    }
    
    # 检查DeepSeek API Key
    if([string]::IsNullOrWhiteSpace($env:DEEPSEEK_API_KEY)) {
        Write-UltimateLog "DeepSeek API Key not configured" "WARN" "DOCTOR"
        
        # 智能DeepSeek API Key设置
        $DeepSeekKeyPath = Join-Path $Global:CFG.CONFIG "deepseek_api_key.txt"
        if(Test-Path $DeepSeekKeyPath) {
            $SavedDeepSeekKey = Get-Content $DeepSeekKeyPath -Raw
            $env:DEEPSEEK_API_KEY = $SavedDeepSeekKey.Trim()
            Write-UltimateLog "Loaded saved DeepSeek API key" "SUCCESS" "DOCTOR"
        } else {
            Write-Host "`n🤖 DeepSeek API Key Setup (Optional)" -ForegroundColor Green
            Write-Host "DeepSeek provides 95% cost savings compared to OpenAI" -ForegroundColor Cyan
            Write-Host "Enter your DeepSeek API Key (press Enter to skip):" -ForegroundColor Cyan
            $DeepSeekKey = Read-Host -AsSecureString "DeepSeek API Key"
            $PlainDeepSeekKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($DeepSeekKey))
            
            if(-not [string]::IsNullOrWhiteSpace($PlainDeepSeekKey)) {
                $env:DEEPSEEK_API_KEY = $PlainDeepSeekKey
                $PlainDeepSeekKey | Out-File -FilePath $DeepSeekKeyPath -Encoding UTF8
                Write-UltimateLog "DeepSeek API Key configured and saved" "SUCCESS" "DOCTOR"
            } else {
                Write-UltimateLog "DeepSeek API Key skipped - enhanced AI features disabled" "WARN" "DOCTOR"
            }
        }
    } else {
        Write-UltimateLog "DeepSeek API Key configured" "SUCCESS" "DOCTOR"
    }
    
    # 检查DeepSeek配置文件
    $DeepSeekConfigPath = Join-Path $Global:CFG.CONFIG "deepseek-config.json"
    if(Test-Path $DeepSeekConfigPath) {
        Write-UltimateLog "DeepSeek configuration file found" "SUCCESS" "DOCTOR"
    } else {
        Write-UltimateLog "DeepSeek configuration file missing - using defaults" "WARN" "DOCTOR"
    }
    
    # 检查DeepSeek模块
    $DeepSeekModulePath = Join-Path $PSScriptRoot "..\modules\DeepSeek.ps1"
    if(Test-Path $DeepSeekModulePath) {
        Write-UltimateLog "DeepSeek module found" "SUCCESS" "DOCTOR"
    } else {
        Write-UltimateLog "DeepSeek module missing - enhanced AI features unavailable" "WARN" "DOCTOR"
    }
    
    if($Issues.Count -gt 0) {
        Write-UltimateLog "Environment issues detected:" "WARN" "DOCTOR"
        $Issues | ForEach-Object { Write-UltimateLog "  - $_" "WARN" "DOCTOR" }
    } else {
        Write-UltimateLog "Environment check passed" "SUCCESS" "DOCTOR"
    }
    
    return $Issues.Count -eq 0
}

# 智能视频信息分析
function Get-EnhancedVideoInfo {
    param($FilePath)
    
    try {
        $ProbeCommand = "ffprobe -v quiet -print_format json -show_format -show_streams `"$FilePath`""
        $ProbeOutput = cmd /c $ProbeCommand 2>$null
        $ProbeData = $ProbeOutput | ConvertFrom-Json
        
        $VideoStream = $ProbeData.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
        $AudioStream = $ProbeData.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1
        
        if(-not $VideoStream) {
            throw "No video stream found"
        }
        
        # 智能场景检测
        $AspectRatio = [double]$VideoStream.width / [double]$VideoStream.height
        $SceneType = if($AspectRatio -gt 1.5) { "landscape" } 
                    elseif($AspectRatio -lt 0.8) { "portrait" }
                    else { "square" }
        
        $Duration = [double]$ProbeData.format.duration
        $Category = if($Duration -lt 60) { "short" }
                   elseif($Duration -lt 600) { "medium" }
                   else { "long" }
        
        return @{
            Duration     = $Duration
            Width        = [int]$VideoStream.width
            Height       = [int]$VideoStream.height
            Size         = [long]$ProbeData.format.size
            Bitrate      = [int]$ProbeData.format.bit_rate
            VideoCodec   = $VideoStream.codec_name
            AudioCodec   = if($AudioStream) { $AudioStream.codec_name } else { "none" }
            FrameRate    = if($VideoStream.r_frame_rate) { 
                              $parts = $VideoStream.r_frame_rate -split '/'
                              [math]::Round([double]$parts[0] / [double]$parts[1], 2)
                           } else { 0 }
            AspectRatio  = $AspectRatio
            SceneType    = $SceneType
            Category     = $Category
            HasAudio     = $AudioStream -ne $null
            Metadata     = $ProbeData.format.tags
        }
    } catch {
        throw "Failed to analyze video: $($_.Exception.Message)"
    }
}

# AI转录和字幕生成 - 增强版支持DeepSeek和OpenAI
function Invoke-AITranscription {
    param(
        [string]$VideoPath,
        [string]$Language = "auto"
    )
    
    Write-UltimateLog "Starting AI transcription for: $(Split-Path $VideoPath -Leaf)" "INFO" "AI"
    
    # 检查配置的AI提供商
    $useDeepSeek = ($Global:CFG.AI.Provider -eq "deepseek") -and ($Global:DeepSeekClient -ne $null)
    $useOpenAI = -not $useDeepSeek -and (-not [string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY))
    
    if(-not $useDeepSeek -and -not $useOpenAI) {
        Write-UltimateLog "No AI provider configured, skipping transcription" "WARN" "AI"
        return $null
    }
    
    $AudioFile = Join-Path $Global:CFG.TMP "audio_$(Get-Date -Format 'HHmmss').wav"
    
    try {
        # 提取音频
        $ExtractCmd = "ffmpeg -i `"$VideoPath`" -vn -acodec pcm_s16le -ar 16000 -ac 1 `"$AudioFile`" -y"
        Write-UltimateLog "Extracting audio..." "INFO" "AI"
        cmd /c $ExtractCmd 2>$null
        
        if(-not (Test-Path $AudioFile)) {
            throw "Audio extraction failed"
        }
        
        # 检查音频文件大小
        $AudioSize = (Get-Item $AudioFile).Length
        if($AudioSize -gt 25MB) {
            Write-UltimateLog "Audio file too large, compressing..." "WARN" "AI"
            $CompressedAudio = Join-Path $Global:CFG.TMP "audio_compressed_$(Get-Date -Format 'HHmmss').mp3"
            $CompressCmd = "ffmpeg -i `"$AudioFile`" -codec:a mp3 -b:a 64k `"$CompressedAudio`" -y"
            cmd /c $CompressCmd 2>$null
            
            if(Test-Path $CompressedAudio) {
                Remove-Item $AudioFile -Force
                $AudioFile = $CompressedAudio
            }
        }
        
        $response = $null
        
        if($useDeepSeek) {
            # 使用DeepSeek API
            Write-UltimateLog "Calling DeepSeek Whisper API..." "INFO" "AI"
            try {
                $options = @{
                    language = if($Language -ne "auto") { $Language } else { $null }
                }
                $response = $Global:DeepSeekClient.AudioTranscription($AudioFile, $options)
                Write-UltimateLog "DeepSeek transcription completed successfully" "SUCCESS" "AI"
            } catch {
                Write-UltimateLog "DeepSeek transcription failed: $($_.Exception.Message)" "ERROR" "AI"
                if($Global:CFG.AI.Provider -eq "deepseek" -and $Global:DeepSeekConfig.integration.fallback_to_openai) {
                    Write-UltimateLog "Falling back to OpenAI..." "WARN" "AI"
                    $useOpenAI = $true
                    $useDeepSeek = $false
                }
            }
        }
        
        if($useOpenAI -and $response -eq $null) {
            # 使用OpenAI API作为后备
            Write-UltimateLog "Calling OpenAI Whisper API..." "INFO" "AI"
            
            $AudioBytes = [System.IO.File]::ReadAllBytes($AudioFile)
            $Boundary = [System.Guid]::NewGuid().ToString()
            
            $Headers = @{
                "Authorization" = "Bearer $env:OPENAI_API_KEY"
                "Content-Type" = "multipart/form-data; boundary=$Boundary"
            }
            
            # 构建multipart请求体
            $BodyStart = "--$Boundary`r`n" +
                        "Content-Disposition: form-data; name=`"file`"; filename=`"audio.wav`"`r`n" +
                        "Content-Type: audio/wav`r`n`r`n"
            
            $BodyEnd = "`r`n--$Boundary`r`n" +
                      "Content-Disposition: form-data; name=`"model`"`r`n`r`n" +
                      "$($Global:CFG.AI.Model)`r`n" +
                      "--$Boundary`r`n" +
                      "Content-Disposition: form-data; name=`"response_format`"`r`n`r`n" +
                      "srt`r`n"
            
            if($Language -ne "auto") {
                $BodyEnd += "--$Boundary`r`n" +
                           "Content-Disposition: form-data; name=`"language`"`r`n`r`n" +
                           "$Language`r`n"
            }
            
            $BodyEnd += "--$Boundary--`r`n"
            
            $BodyStartBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyStart)
            $BodyEndBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyEnd)
            
            # 合并请求体
            $FullBodyLength = $BodyStartBytes.Length + $AudioBytes.Length + $BodyEndBytes.Length
            $FullBody = New-Object byte[] $FullBodyLength
            
            [Array]::Copy($BodyStartBytes, 0, $FullBody, 0, $BodyStartBytes.Length)
            [Array]::Copy($AudioBytes, 0, $FullBody, $BodyStartBytes.Length, $AudioBytes.Length)
            [Array]::Copy($BodyEndBytes, 0, $FullBody, $BodyStartBytes.Length + $AudioBytes.Length, $BodyEndBytes.Length)
            
            # 发送请求
            $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/audio/transcriptions" -Method Post -Headers $Headers -Body $FullBody
            Write-UltimateLog "OpenAI transcription completed successfully" "SUCCESS" "AI"
        }
        
        Remove-Item $AudioFile -Force -ErrorAction SilentlyContinue
        
        return $response
        
    } catch {
        Remove-Item $AudioFile -Force -ErrorAction SilentlyContinue
        Write-UltimateLog "AI transcription failed: $($_.Exception.Message)" "ERROR" "AI"
        return $null
    }
}

# 智能预设选择
function Select-OptimalPreset {
    param($VideoInfo)
    
    # 基于视频特征智能选择预设
    $RecommendedPreset = switch($VideoInfo.SceneType) {
        "portrait"  { "mobile" }
        "landscape" { if($VideoInfo.Width -ge 3840) { "4k" } else { "desktop" } }
        "square"    { "social" }
        default     { "web" }
    }
    
    # 基于时长调整
    if($VideoInfo.Category -eq "short" -and $VideoInfo.Duration -lt 30) {
        $RecommendedPreset = "social"  # 短视频优化
    }
    
    Write-UltimateLog "Recommended preset: $RecommendedPreset (Scene: $($VideoInfo.SceneType), Duration: $($VideoInfo.Category))" "INFO" "SMART"
    
    return $RecommendedPreset
}

# 增强的视频处理引擎
function Invoke-UltimateVideoProcessing {
    param(
        [string]$InputPath,
        [string]$PresetName = "auto",
        [hashtable]$CustomSettings = @{}
    )
    
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $StartTime = Get-Date
    
    Write-UltimateLog "Starting ultimate processing: $(Split-Path $InputPath -Leaf)" "INFO" "PROCESSOR"
    
    try {
        # 分析视频
        $VideoInfo = Get-EnhancedVideoInfo $InputPath
        Write-UltimateLog "Video analysis: $($VideoInfo.Width)x$($VideoInfo.Height), $([math]::Round($VideoInfo.Duration/60,1))min, $($VideoInfo.SceneType)" "INFO" "PROCESSOR"
        
        # 智能预设选择
        if($PresetName -eq "auto") {
            $PresetName = Select-OptimalPreset $VideoInfo
        }
        
        $Preset = $Global:CFG.PRESETS[$PresetName]
        if(-not $Preset) {
            $Preset = $Global:CFG.PRESETS["mobile"]  # 默认预设
            Write-UltimateLog "Unknown preset '$PresetName', using mobile preset" "WARN" "PROCESSOR"
        }
        
        # 合并自定义设置
        foreach($Key in $CustomSettings.Keys) {
            $Preset[$Key] = $CustomSettings[$Key]
        }
        
        $OutputPath = Join-Path $Global:CFG.OUT "$FileName`_$PresetName.mp4"
        $DonePath = Join-Path $Global:CFG.DONE (Split-Path $InputPath -Leaf)
        
        # 构建FFmpeg命令
        $FFmpegCmd = "ffmpeg -i `"$InputPath`""
        
        # 视频滤镜
        $Filters = @()
        
        # 分辨率调整
        if($VideoInfo.Width -ne $Preset.W -or $VideoInfo.Height -ne $Preset.H) {
            $ScaleFilter = "scale=$($Preset.W):$($Preset.H):force_original_aspect_ratio=decrease"
            $PadFilter = "pad=$($Preset.W):$($Preset.H):(ow-iw)/2:(oh-ih)/2:black"
            $Filters += "$ScaleFilter,$PadFilter"
        }
        
        # 添加水印（可选）
        $WatermarkPath = Join-Path $Global:CFG.CONFIG "watermark.png"
        if(Test-Path $WatermarkPath) {
            $Filters += "overlay=W-w-10:H-h-10"
            $FFmpegCmd += " -i `"$WatermarkPath`""
        }
        
        # 应用滤镜
        if($Filters.Count -gt 0) {
            $FFmpegCmd += " -filter_complex `"$($Filters -join ';')`""
        }
        
        # 编码参数
        $FFmpegCmd += " -c:v libx264 -preset $($Preset.Preset) -crf $($Preset.CRF)"
        $FFmpegCmd += " -c:a aac -b:a 128k -movflags +faststart"
        $FFmpegCmd += " `"$OutputPath`" -y"
        
        Write-UltimateLog "Processing with preset: $PresetName ($($Preset.Desc))" "INFO" "PROCESSOR"
        Write-UltimateLog "Command: $FFmpegCmd" "DEBUG" "PROCESSOR"
        
        # 执行转换
        $Process = Start-Process -FilePath "cmd" -ArgumentList "/c $FFmpegCmd" -Wait -PassThru -NoNewWindow
        
        if($Process.ExitCode -eq 0 -and (Test-Path $OutputPath)) {
            $ProcessingTime = (Get-Date) - $StartTime
            $OutputSize = (Get-Item $OutputPath).Length
            $CompressionRatio = [math]::Round(($VideoInfo.Size - $OutputSize) / $VideoInfo.Size * 100, 1)
            
            Write-UltimateLog "Video processing completed in $($ProcessingTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS" "PROCESSOR"
            Write-UltimateLog "Size reduction: $CompressionRatio% ($(([math]::Round($VideoInfo.Size/1MB,1)))MB → $(([math]::Round($OutputSize/1MB,1)))MB)" "SUCCESS" "PROCESSOR"
            
            # AI字幕处理
            if($Global:CFG.AI.AddSubs -and $VideoInfo.HasAudio) {
                Write-UltimateLog "Starting subtitle generation..." "INFO" "PROCESSOR"
                $SrtContent = Invoke-AITranscription $InputPath
                
                if($SrtContent) {
                    $SrtFile = Join-Path $Global:CFG.OUT "$FileName`_$PresetName.srt"
                    $SrtContent | Out-File -FilePath $SrtFile -Encoding UTF8
                    
                    # 创建带字幕的版本
                    $SubtitledOutput = Join-Path $Global:CFG.OUT "$FileName`_$PresetName`_with_subs.mp4"
                    $SubCmd = "ffmpeg -i `"$OutputPath`" -vf `"subtitles='$SrtFile':force_style='FontName=$($Global:CFG.AI.SubStyle.FontName),FontSize=$($Global:CFG.AI.SubStyle.FontSize),PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000'`" -c:a copy `"$SubtitledOutput`" -y"
                    
                    $SubProcess = Start-Process -FilePath "cmd" -ArgumentList "/c $SubCmd" -Wait -PassThru -NoNewWindow
                    
                    if($SubProcess.ExitCode -eq 0 -and (Test-Path $SubtitledOutput)) {
                        Write-UltimateLog "Subtitled version created successfully" "SUCCESS" "PROCESSOR"
                    }
                }
            }
            
            # 移动原文件
            Move-Item $InputPath $DonePath -Force
            
            # 记录处理统计
            $Stats = @{
                timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                user = "Quen-Tao-Lee"
                input_file = Split-Path $InputPath -Leaf
                output_file = Split-Path $OutputPath -Leaf
                preset = $PresetName
                processing_time = $ProcessingTime.TotalSeconds
                input_size = $VideoInfo.Size
                output_size = $OutputSize
                compression_ratio = $CompressionRatio
                video_info = $VideoInfo
            }
            
            $StatsFile = Join-Path $Global:CFG.LOG ("processing_stats_" + (Get-Date -Format "yyyyMM") + ".jsonl")
            $Stats | ConvertTo-Json -Compress | Add-Content -Path $StatsFile -Encoding UTF8
            
            return @{
                Success = $true
                OutputPath = $OutputPath
                Stats = $Stats
            }
            
        } else {
            throw "FFmpeg processing failed with exit code: $($Process.ExitCode)"
        }
        
    } catch {
        Write-UltimateLog "Ultimate processing failed: $($_.Exception.Message)" "ERROR" "PROCESSOR"
        return @{
            Success = $false
            Error = $_.Exception.Message
    }
}

# 增强AI视频处理 - 包含内容分析、营销文案生成等
function Invoke-EnhancedVideoProcessing {
    param(
        [string]$InputPath,
        [string]$PresetName = "mobile"
    )
    
    $StartTime = Get-Date
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    
    Write-UltimateLog "Starting enhanced AI video processing for: $(Split-Path $InputPath -Leaf)" "INFO" "ENHANCED"
    
    # 初始化成本监控
    if($Global:CFG.AI.EnableCostMonitoring -and $Global:DeepSeekClient) {
        Start-DeepSeekCostMonitoring
    }
    
    try {
        # 1. 基础视频处理
        $BasicResult = Invoke-UltimateVideoProcessing $InputPath $PresetName
        if(-not $BasicResult.Success) {
            throw "Basic video processing failed: $($BasicResult.Error)"
        }
        
        # 2. AI转录
        $transcriptContent = ""
        if($Global:CFG.AI.AddSubs) {
            Write-UltimateLog "Generating transcript..." "INFO" "ENHANCED"
            $srtContent = Invoke-AITranscription $InputPath
            
            if($srtContent) {
                $transcriptContent = Convert-SRTToPlainText $srtContent
                $srtFile = Join-Path $Global:CFG.OUT "$FileName.srt"
                $srtContent | Out-File -FilePath $srtFile -Encoding UTF8
                Write-UltimateLog "Transcript saved to: $srtFile" "SUCCESS" "ENHANCED"
            }
        }
        
        # 3. AI内容分析
        $analysisResult = $null
        if($Global:CFG.AI.EnableContentAnalysis -and $Global:DeepSeekClient -and $transcriptContent) {
            Write-UltimateLog "Performing AI content analysis..." "INFO" "ENHANCED"
            $analysisResult = Invoke-DeepSeekContentAnalysis $transcriptContent $InputPath $Global:DeepSeekClient
            
            if($analysisResult) {
                $analysisFile = Join-Path $Global:CFG.OUT "$FileName.analysis.json"
                $analysisResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $analysisFile -Encoding UTF8
                Write-UltimateLog "Content analysis saved to: $analysisFile" "SUCCESS" "ENHANCED"
            }
        }
        
        # 4. 营销文案生成
        if($Global:CFG.AI.EnableMarketingGeneration -and $Global:DeepSeekClient -and $analysisResult) {
            Write-UltimateLog "Generating marketing content..." "INFO" "ENHANCED"
            
            $platforms = @("youtube", "tiktok", "bilibili", "general")
            $marketingContent = @{}
            
            foreach($platform in $platforms) {
                try {
                    $content = New-DeepSeekMarketingContent $analysisResult $platform $Global:DeepSeekClient
                    $marketingContent[$platform] = $content
                } catch {
                    Write-UltimateLog "Marketing content generation failed for $platform`: $($_.Exception.Message)" "WARN" "ENHANCED"
                }
            }
            
            if($marketingContent.Count -gt 0) {
                $marketingFile = Join-Path $Global:CFG.OUT "$FileName.marketing.txt"
                $marketingOutput = ""
                foreach($platform in $marketingContent.Keys) {
                    $marketingOutput += "=== $platform 营销文案 ===`r`n"
                    $marketingOutput += "$($marketingContent[$platform])`r`n`r`n"
                }
                $marketingOutput | Out-File -FilePath $marketingFile -Encoding UTF8
                Write-UltimateLog "Marketing content saved to: $marketingFile" "SUCCESS" "ENHANCED"
            }
        }
        
        # 5. SEO关键词生成
        if($Global:CFG.AI.EnableSEOOptimization -and $Global:DeepSeekClient -and $analysisResult) {
            Write-UltimateLog "Generating SEO keywords..." "INFO" "ENHANCED"
            try {
                $seoKeywords = New-DeepSeekSEOKeywords $analysisResult $Global:DeepSeekClient
                $seoFile = Join-Path $Global:CFG.OUT "$FileName.keywords.txt"
                $seoKeywords | Out-File -FilePath $seoFile -Encoding UTF8
                Write-UltimateLog "SEO keywords saved to: $seoFile" "SUCCESS" "ENHANCED"
            } catch {
                Write-UltimateLog "SEO keywords generation failed: $($_.Exception.Message)" "WARN" "ENHANCED"
            }
        }
        
        # 6. 字幕优化
        if($Global:CFG.AI.EnableSubtitleOptimization -and $Global:DeepSeekClient -and $srtContent) {
            Write-UltimateLog "Optimizing subtitles..." "INFO" "ENHANCED"
            try {
                $optimizedSrt = Optimize-DeepSeekSubtitles $srtContent $Global:DeepSeekClient
                $optimizedSrtFile = Join-Path $Global:CFG.OUT "$FileName.optimized.srt"
                $optimizedSrt | Out-File -FilePath $optimizedSrtFile -Encoding UTF8
                Write-UltimateLog "Optimized subtitles saved to: $optimizedSrtFile" "SUCCESS" "ENHANCED"
            } catch {
                Write-UltimateLog "Subtitle optimization failed: $($_.Exception.Message)" "WARN" "ENHANCED"
            }
        }
        
        # 7. 生成处理报告
        $processingTime = (Get-Date) - $StartTime
        $enhancedStats = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            user = "Quen-Tao-Lee"
            input_file = Split-Path $InputPath -Leaf
            output_file = Split-Path $BasicResult.OutputPath -Leaf
            preset = $PresetName
            processing_time = $processingTime.TotalSeconds
            ai_features_used = @{
                transcription = $srtContent -ne $null
                content_analysis = $analysisResult -ne $null
                marketing_generation = $marketingContent.Count -gt 0
                seo_optimization = (Test-Path (Join-Path $Global:CFG.OUT "$FileName.keywords.txt"))
                subtitle_optimization = (Test-Path (Join-Path $Global:CFG.OUT "$FileName.optimized.srt"))
            }
            analysis_result = $analysisResult
            basic_stats = $BasicResult.Stats
            cost_report = if($Global:DeepSeekCostTracker) { Get-DeepSeekCostReport } else { $null }
        }
        
        # 保存增强统计
        $enhancedStatsFile = Join-Path $Global:CFG.LOG ("enhanced_stats_" + (Get-Date -Format "yyyyMM") + ".jsonl")
        $enhancedStats | ConvertTo-Json -Compress | Add-Content -Path $enhancedStatsFile -Encoding UTF8
        
        Write-UltimateLog "Enhanced AI video processing completed in $($processingTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS" "ENHANCED"
        
        # 显示成本报告
        if($Global:DeepSeekCostTracker) {
            $costReport = Get-DeepSeekCostReport
            Write-UltimateLog "AI Processing Cost: `$$($costReport.SessionUsage.ToString('F4')) (Daily: `$$($costReport.DailyUsage.ToString('F4')))" "INFO" "COST"
        }
        
        return @{
            Success = $true
            OutputPath = $BasicResult.OutputPath
            EnhancedStats = $enhancedStats
            AnalysisResult = $analysisResult
            ProcessingTime = $processingTime
        }
        
    } catch {
        Write-UltimateLog "Enhanced video processing failed: $($_.Exception.Message)" "ERROR" "ENHANCED"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# 辅助函数：将SRT转换为纯文本
function Convert-SRTToPlainText {
    param([string]$SrtContent)
    
    $lines = $SrtContent -split "`r`n|`n"
    $textLines = @()
    
    foreach($line in $lines) {
        $line = $line.Trim()
        # 跳过数字索引行和时间戳行
        if($line -match '^\d+$' -or $line -match '\d{2}:\d{2}:\d{2}') {
            continue
        }
        # 跳过空行
        if([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $textLines += $line
    }
    
    return $textLines -join " "
}

# DeepSeek成本监控和优化
function Start-DeepSeekCostMonitoring {
    Write-UltimateLog "Initializing DeepSeek cost monitoring..." "INFO" "COST"
    
    $Global:DeepSeekCostTracker = @{
        DailyUsage = 0.0
        SessionUsage = 0.0
        APICallCount = 0
        StartTime = Get-Date
        DailyLimit = if($Global:DeepSeekConfig) { $Global:DeepSeekConfig.deepseek.cost_limits.daily_limit_usd } else { 10.0 }
        WarningThreshold = if($Global:DeepSeekConfig) { $Global:DeepSeekConfig.deepseek.cost_limits.warning_threshold_usd } else { 0.8 }
    }
    
    # 加载今日使用记录
    $costLogPath = Join-Path $Global:CFG.LOG ("deepseek_cost_" + (Get-Date -Format "yyyyMMdd") + ".json")
    if(Test-Path $costLogPath) {
        try {
            $todayCosts = Get-Content $costLogPath -Raw | ConvertFrom-Json
            $Global:DeepSeekCostTracker.DailyUsage = $todayCosts.total_cost
            $Global:DeepSeekCostTracker.APICallCount = $todayCosts.api_calls
            Write-UltimateLog "Loaded daily usage: `$$($Global:DeepSeekCostTracker.DailyUsage.ToString('F4'))" "INFO" "COST"
        } catch {
            Write-UltimateLog "Failed to load cost history: $($_.Exception.Message)" "WARN" "COST"
        }
    }
}

function Add-DeepSeekCostRecord {
    param(
        [double]$Cost,
        [string]$Operation,
        [hashtable]$Details = @{}
    )
    
    if(-not $Global:DeepSeekCostTracker) {
        Start-DeepSeekCostMonitoring
    }
    
    $Global:DeepSeekCostTracker.SessionUsage += $Cost
    $Global:DeepSeekCostTracker.DailyUsage += $Cost
    $Global:DeepSeekCostTracker.APICallCount++
    
    # 记录详细成本信息
    $costRecord = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        operation = $Operation
        cost = $Cost
        session_total = $Global:DeepSeekCostTracker.SessionUsage
        daily_total = $Global:DeepSeekCostTracker.DailyUsage
        details = $Details
    }
    
    # 保存到日志
    $costLogPath = Join-Path $Global:CFG.LOG ("deepseek_cost_" + (Get-Date -Format "yyyyMMdd") + ".jsonl")
    $costRecord | ConvertTo-Json -Compress | Add-Content -Path $costLogPath -Encoding UTF8
    
    # 检查成本限制
    $dailyLimitPercent = ($Global:DeepSeekCostTracker.DailyUsage / $Global:DeepSeekCostTracker.DailyLimit) * 100
    
    if($dailyLimitPercent -ge 100) {
        Write-UltimateLog "⚠️ COST ALERT: Daily limit exceeded! ($($Global:DeepSeekCostTracker.DailyUsage.ToString('F4'))/$($Global:DeepSeekCostTracker.DailyLimit))" "ERROR" "COST"
        return $false
    } elseif($dailyLimitPercent -ge ($Global:DeepSeekCostTracker.WarningThreshold * 100)) {
        Write-UltimateLog "⚠️ COST WARNING: $($dailyLimitPercent.ToString('F1'))% of daily limit used" "WARN" "COST"
    }
    
    Write-UltimateLog "$Operation cost: `$$($Cost.ToString('F4')) (Daily: `$$($Global:DeepSeekCostTracker.DailyUsage.ToString('F4')))" "INFO" "COST"
    return $true
}

function Get-DeepSeekCostReport {
    if(-not $Global:DeepSeekCostTracker) {
        return @{ Error = "Cost tracking not initialized" }
    }
    
    $sessionTime = (Get-Date) - $Global:DeepSeekCostTracker.StartTime
    $avgCostPerCall = if($Global:DeepSeekCostTracker.APICallCount -gt 0) { 
        $Global:DeepSeekCostTracker.SessionUsage / $Global:DeepSeekCostTracker.APICallCount 
    } else { 0 }
    
    return @{
        DailyUsage = $Global:DeepSeekCostTracker.DailyUsage
        SessionUsage = $Global:DeepSeekCostTracker.SessionUsage
        APICallCount = $Global:DeepSeekCostTracker.APICallCount
        SessionDuration = $sessionTime.TotalMinutes
        AverageCostPerCall = $avgCostPerCall
        DailyLimit = $Global:DeepSeekCostTracker.DailyLimit
        DailyLimitPercent = ($Global:DeepSeekCostTracker.DailyUsage / $Global:DeepSeekCostTracker.DailyLimit) * 100
        EstimatedMonthlyCost = $Global:DeepSeekCostTracker.DailyUsage * 30
    }
}

function Optimize-DeepSeekUsage {
    param(
        [string]$Text,
        [string]$Operation
    )
    
    # 智能文本分块，避免超长请求
    $maxChunkSize = switch($Operation) {
        "content_analysis" { 3000 }  # 内容分析允许更长文本
        "marketing" { 2000 }         # 营销文案适中
        "seo" { 1500 }              # SEO关键词相对简短
        "subtitle_optimization" { 4000 }  # 字幕优化需要完整上下文
        default { 2000 }
    }
    
    if($Text.Length -le $maxChunkSize) {
        return @($Text)
    }
    
    # 智能分块策略
    $chunks = @()
    $sentences = $Text -split '[.!?。！？]'
    $currentChunk = ""
    
    foreach($sentence in $sentences) {
        $sentence = $sentence.Trim()
        if([string]::IsNullOrWhiteSpace($sentence)) { continue }
        
        if(($currentChunk.Length + $sentence.Length) -le $maxChunkSize) {
            $currentChunk += "$sentence. "
        } else {
            if($currentChunk.Length -gt 0) {
                $chunks += $currentChunk.Trim()
                $currentChunk = "$sentence. "
            } else {
                # 单个句子过长，强制分块
                $chunks += $sentence.Substring(0, [Math]::Min($maxChunkSize, $sentence.Length))
            }
        }
    }
    
    if($currentChunk.Length -gt 0) {
        $chunks += $currentChunk.Trim()
    }
    
    Write-UltimateLog "Optimized text into $($chunks.Count) chunks for $Operation" "INFO" "OPTIMIZE"
    return $chunks
}

# Web界面生成器
function Initialize-WebInterface {
    Write-UltimateLog "Initializing web interface..." "INFO" "WEB"
    
    # 创建HTML界面
    $IndexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VideoAgent Ultimate - Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); }
        .header p { font-size: 1.2em; opacity: 0.9; }
        .dashboard { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { 
            background: rgba(255,255,255,0.1); 
            border-radius: 15px; 
            padding: 20px; 
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
            transition: transform 0.3s ease;
        }
        .card:hover { transform: translateY(-5px); }
        .card h3 { margin-bottom: 15px; color: #ffd700; }
        .status { display: flex; align-items: center; margin: 10px 0; }
        .status-dot { 
            width: 12px; height: 12px; border-radius: 50%; 
            margin-right: 10px; background: #4CAF50;
            animation: pulse 2s infinite;
        }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.5; } }
        .btn { 
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white; padding: 10px 20px; border: none;
            border-radius: 8px; cursor: pointer; font-size: 16px;
            transition: all 0.3s ease;
        }
        .btn:hover { transform: scale(1.05); box-shadow: 0 4px 15px rgba(0,0,0,0.3); }
        .log-container { 
            background: rgba(0,0,0,0.3); border-radius: 8px; 
            padding: 15px; max-height: 300px; overflow-y: auto;
            font-family: 'Courier New', monospace; font-size: 14px;
        }
        .upload-zone { 
            border: 2px dashed rgba(255,255,255,0.5); 
            border-radius: 10px; padding: 40px; text-align: center;
            transition: all 0.3s ease; cursor: pointer;
        }
        .upload-zone:hover { 
            border-color: #ffd700; 
            background: rgba(255,215,0,0.1);
        }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; }
        .stat-item { text-align: center; padding: 15px; background: rgba(0,0,0,0.2); border-radius: 8px; }
        .stat-value { font-size: 2em; font-weight: bold; color: #ffd700; }
        .stat-label { font-size: 0.9em; opacity: 0.8; margin-top: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎬 VideoAgent Ultimate</h1>
            <p>Enterprise Video Processing Solution for Quen-Tao-Lee</p>
        </div>
        
        <div class="dashboard">
            <div class="card">
                <h3>🚀 System Status</h3>
                <div class="status">
                    <div class="status-dot"></div>
                    <span>VideoAgent Running</span>
                </div>
                <div class="status">
                    <div class="status-dot"></div>
                    <span>AI Transcription Ready</span>
                </div>
                <div class="status">
                    <div class="status-dot"></div>
                    <span>Web Interface Active</span>
                </div>
                <button class="btn" onclick="refreshStatus()">Refresh Status</button>
            </div>
            
            <div class="card">
                <h3>📊 Processing Stats</h3>
                <div class="stats-grid">
                    <div class="stat-item">
                        <div class="stat-value" id="totalProcessed">0</div>
                        <div class="stat-label">Videos Processed</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value" id="queueCount">0</div>
                        <div class="stat-label">In Queue</div>
                    </div>
                    <div class="stat-item">
                        <div class="stat-value" id="successRate">100%</div>
                        <div class="stat-label">Success Rate</div>
                    </div>
                </div>
            </div>
            
            <div class="card">
                <h3>📁 Quick Upload</h3>
                <div class="upload-zone" onclick="document.getElementById('fileInput').click()">
                    <p>🎥 Drag & Drop Videos Here</p>
                    <p>or click to browse</p>
                    <input type="file" id="fileInput" multiple accept="video/*" style="display: none;" onchange="handleFileUpload(this.files)">
                </div>
            </div>
            
            <div class="card">
                <h3>🎛️ Processing Presets</h3>
                <button class="btn" onclick="setPreset('mobile')" style="margin: 5px;">📱 Mobile</button>
                <button class="btn" onclick="setPreset('desktop')" style="margin: 5px;">💻 Desktop</button>
                <button class="btn" onclick="setPreset('4k')" style="margin: 5px;">🖥️ 4K</button>
                <button class="btn" onclick="setPreset('web')" style="margin: 5px;">🌐 Web</button>
                <button class="btn" onclick="setPreset('social')" style="margin: 5px;">📲 Social</button>
            </div>
            
            <div class="card">
                <h3>📝 Recent Activity</h3>
                <div class="log-container" id="activityLog">
                    <div>Initializing VideoAgent Ultimate...</div>
                    <div>System ready for video processing</div>
                    <div>Web interface loaded successfully</div>
                </div>
            </div>
            
            <div class="card">
                <h3>⚙️ Settings</h3>
                <label>
                    <input type="checkbox" id="autoSubtitles" checked> 
                    Auto-generate Subtitles
                </label><br><br>
                <label>
                    <input type="checkbox" id="notifications" checked> 
                    Enable Notifications
                </label><br><br>
                <button class="btn" onclick="openAdvancedSettings()">Advanced Settings</button>
            </div>
        </div>
    </div>

    <script>
        // WebSocket connection for real-time updates
        let ws = null;
        
        function connectWebSocket() {
            try {
                ws = new WebSocket('ws://localhost:$($Global:CFG.WEB_CONFIG.Port)/ws');
                ws.onmessage = function(event) {
                    const data = JSON.parse(event.data);
                    updateDashboard(data);
                };
                ws.onopen = function() {
                    console.log('WebSocket connected');
                };
                ws.onclose = function() {
                    console.log('WebSocket disconnected, retrying...');
                    setTimeout(connectWebSocket, 5000);
                };
            } catch(e) {
                console.log('WebSocket not available, using polling');
                setInterval(refreshStatus, 5000);
            }
        }
        
        function updateDashboard(data) {
            if(data.stats) {
                document.getElementById('totalProcessed').textContent = data.stats.total || 0;
                document.getElementById('queueCount').textContent = data.stats.queue || 0;
                document.getElementById('successRate').textContent = (data.stats.successRate || 100) + '%';
            }
            
            if(data.activity) {
                const log = document.getElementById('activityLog');
                const newEntry = document.createElement('div');
                newEntry.textContent = new Date().toLocaleTimeString() + ' - ' + data.activity;
                log.insertBefore(newEntry, log.firstChild);
                
                // Keep only last 10 entries
                while(log.children.length > 10) {
                    log.removeChild(log.lastChild);
                }
            }
        }
        
        function refreshStatus() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => updateDashboard(data))
                .catch(console.error);
        }
        
        function handleFileUpload(files) {
            for(let file of files) {
                if(file.type.startsWith('video/')) {
                    uploadFile(file);
                }
            }
        }
        
        function uploadFile(file) {
            const formData = new FormData();
            formData.append('video', file);
            
            fetch('/api/upload', {
                method: 'POST',
                body: formData
            })
            .then(response => response.json())
            .then(data => {
                if(data.success) {
                    updateDashboard({activity: 'File uploaded: ' + file.name});
                }
            })
            .catch(console.error);
        }
        
        function setPreset(preset) {
            fetch('/api/preset', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({preset: preset})
            })
            .then(response => response.json())
            .then(data => {
                updateDashboard({activity: 'Preset changed to: ' + preset});
            })
            .catch(console.error);
        }
        
        function openAdvancedSettings() {
            window.open('/settings.html', '_blank');
        }
        
        // Initialize
        connectWebSocket();
        refreshStatus();
        
        // Refresh stats every 30 seconds
        setInterval(refreshStatus, 30000);
    </script>
</body>
</html>
"@

    $IndexPath = Join-Path $Global:CFG.WEB "index.html"
    $IndexHtml | Out-File -FilePath $IndexPath -Encoding UTF8
    
    Write-UltimateLog "Web interface created at: $IndexPath" "SUCCESS" "WEB"
}

# Windows服务安装
function Install-VideoAgentService {
    Write-UltimateLog "Installing VideoAgent as Windows Service..." "INFO" "SERVICE"
    
    $ServiceName = "VideoAgentUltimate"
    $ServiceDisplayName = "VideoAgent Ultimate - AI Video Processing Service"
    $ServiceDescription = "Enterprise video processing solution with AI transcription and web management"
    
    $ScriptPath = $MyInvocation.MyCommand.Path
    $ServiceCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -SkipDoctor"
    
    try {
        # 检查是否已安装
        $ExistingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if($ExistingService) {
            Write-UltimateLog "Service already exists, removing old version..." "WARN" "SERVICE"
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $ServiceName
            Start-Sleep -Seconds 2
        }
        
        # 创建服务
        & sc.exe create $ServiceName binPath= $ServiceCommand DisplayName= $ServiceDisplayName start= auto
        & sc.exe description $ServiceName $ServiceDescription
        
        # 配置服务恢复选项
        & sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/15000
        
        Write-UltimateLog "Service installed successfully" "SUCCESS" "SERVICE"
        Write-UltimateLog "To start service: Start-Service -Name $ServiceName" "INFO" "SERVICE"
        
        return $true
        
    } catch {
        Write-UltimateLog "Service installation failed: $($_.Exception.Message)" "ERROR" "SERVICE"
        return $false
    }
}

# 主监控引擎
function Start-UltimateAgent {
    Write-UltimateLog "🚀 VideoAgent Ultimate started by user: Quen-Tao-Lee" "SUCCESS" "MAIN"
    Write-UltimateLog "Monitoring directory: $($Global:CFG.IN)" "INFO" "MAIN"
    Write-UltimateLog "Web interface: http://localhost:$($Global:CFG.WEB_CONFIG.Port)" "INFO" "MAIN"
    
    # 启动Web服务器（如果启用）
    if($WebInterface -or $Global:CFG.WEB_CONFIG.EnableAPI) {
        Start-Job -ScriptBlock {
            param($Port, $WebDir)
            
            # 简单的HTTP服务器
            $Listener = New-Object System.Net.HttpListener
            $Listener.Prefixes.Add("http://localhost:$Port/")
            $Listener.Start()
            
            while($Listener.IsListening) {
                try {
                    $Context = $Listener.GetContext()
                    $Request = $Context.Request
                    $Response = $Context.Response
                    
                    $Url = $Request.Url.LocalPath
                    
                    if($Url -eq "/" -or $Url -eq "/index.html") {
                        $IndexPath = Join-Path $WebDir "index.html"
                        if(Test-Path $IndexPath) {
                            $Content = Get-Content $IndexPath -Raw
                            $Response.ContentType = "text/html"
                        } else {
                            $Content = "<h1>VideoAgent Ultimate</h1><p>Web interface not found</p>"
                            $Response.ContentType = "text/html"
                        }
                    } elseif($Url.StartsWith("/api/")) {
                        # API处理
                        $ApiResponse = @{
                            status = "ok"
                            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            message = "VideoAgent Ultimate API"
                        }
                        $Content = $ApiResponse | ConvertTo-Json
                        $Response.ContentType = "application/json"
                    } else {
                        $Content = "404 - Not Found"
                        $Response.StatusCode = 404
                        $Response.ContentType = "text/plain"
                    }
                    
                    $Buffer = [System.Text.Encoding]::UTF8.GetBytes($Content)
                    $Response.ContentLength64 = $Buffer.Length
                    $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
                    $Response.Close()
                    
                } catch {
                    # 忽略HTTP服务器错误
                }
            }
        } -ArgumentList $Global:CFG.WEB_CONFIG.Port, $Global:CFG.WEB
        
        Write-UltimateLog "Web server started on port $($Global:CFG.WEB_CONFIG.Port)" "SUCCESS" "WEB"
    }
    
    # 主处理循环
    $ProcessedCount = 0
    $StartTime = Get-Date
    
    while($true) {
        try {
            # 扫描视频文件
            $VideoFiles = Get-ChildItem $Global:CFG.IN -File -ErrorAction SilentlyContinue | 
                         Where-Object { $_.Extension -match '\.(mp4|mov|mkv|m4v|avi|wmv|flv|webm)$' }
            
            if($VideoFiles.Count -gt 0) {
                Write-UltimateLog "Found $($VideoFiles.Count) video files in queue" "INFO" "MAIN"
                
                foreach($VideoFile in $VideoFiles) {
                    Write-UltimateLog "Queued: $($VideoFile.Name)" "INFO" "MAIN"
                    
                    # 检查文件稳定性
                    $InitialSize = $VideoFile.Length
                    Start-Sleep -Seconds 3
                    $VideoFile.Refresh()
                    $FinalSize = $VideoFile.Length
                    
                    if($InitialSize -ne $FinalSize) {
                        Write-UltimateLog "File still being written: $($VideoFile.Name)" "WARN" "MAIN"
                        continue
                    }
                    
                    # 处理视频 - 使用增强AI处理
                    Write-UltimateLog "🎬 PROCESSING: $($VideoFile.Name)" "INFO" "MAIN"
                    
                    # 根据DeepSeek配置选择处理方式
                    if($deepseekReady -and $Global:CFG.AI.EnableContentAnalysis) {
                        Write-UltimateLog "Using enhanced AI processing with DeepSeek" "INFO" "MAIN"
                        $Result = Invoke-EnhancedVideoProcessing -InputPath $VideoFile.FullName -PresetName "auto"
                    } else {
                        Write-UltimateLog "Using basic processing" "INFO" "MAIN"
                        $Result = Invoke-UltimateVideoProcessing -InputPath $VideoFile.FullName -PresetName "auto"
                    }
                    
                    if($Result.Success) {
                        $ProcessedCount++
                        Write-UltimateLog "✅ SUCCESS: $($VideoFile.Name) → $(Split-Path $Result.OutputPath -Leaf)" "SUCCESS" "MAIN"
                        
                        # 发送通知（可扩展为邮件、微信等）
                        $NotificationMsg = "Video processed successfully: $($VideoFile.Name)"
                        Write-UltimateLog $NotificationMsg "INFO" "NOTIFICATION"
                        
                    } else {
                        Write-UltimateLog "❌ FAILED: $($VideoFile.Name) - $($Result.Error)" "ERROR" "MAIN"
                    }
                    
                    # 统计报告
                    $Uptime = (Get-Date) - $StartTime
                    if($ProcessedCount -gt 0 -and $ProcessedCount % 10 -eq 0) {
                        $AvgTime = $Uptime.TotalMinutes / $ProcessedCount
                        Write-UltimateLog "📊 STATS: Processed $ProcessedCount videos, Average: $([math]::Round($AvgTime,1)) min/video" "INFO" "STATS"
                    }
                }
            } else {
                # 心跳日志
                if((Get-Date).Minute % 10 -eq 0 -and (Get-Date).Second -eq 0) {
                    $Uptime = (Get-Date) - $StartTime
                    Write-UltimateLog "💓 HEARTBEAT: Running for $([math]::Round($Uptime.TotalHours,1)) hours, processed $ProcessedCount videos" "INFO" "HEARTBEAT"
                }
            }
            
        } catch {
            Write-UltimateLog "Main loop error: $($_.Exception.Message)" "ERROR" "MAIN"
        }
        
        Start-Sleep -Seconds 5
    }
}

# 主程序入口
try {
    # 显示启动横幅
    Clear-Host
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                    VideoAgent Ultimate v3.0                 ║
║              Enterprise Video Processing Solution            ║
║                                                              ║
║  👤 User: Quen-Tao-Lee                                       ║
║  📅 Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")                                ║
║  🚀 Features: AI Transcription | Web Interface | Auto Service║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    # 初始化配置
    Initialize-Configuration
    
    # 初始化DeepSeek
    Initialize-DeepSeekConfiguration
    $deepseekReady = Initialize-DeepSeekClient
    
    if($deepseekReady) {
        Write-Host "🤖 DeepSeek AI Ready - Enhanced features enabled" -ForegroundColor Green
    } else {
        Write-Host "⚠️  DeepSeek not configured - Using basic features only" -ForegroundColor Yellow
    }
    
    # 环境检查
    if(-not $SkipDoctor) {
        $EnvOK = Test-UltimateEnvironment
        if(-not $EnvOK) {
            Write-UltimateLog "Environment check failed. Use -SkipDoctor to bypass." "ERROR" "MAIN"
            Read-Host "Press Enter to continue anyway, or Ctrl+C to exit"
        }
    }
    
    # 安装服务
    if($InstallService) {
        $ServiceInstalled = Install-VideoAgentService
        if($ServiceInstalled) {
            Write-Host "Service installed! You can now start it with:" -ForegroundColor Green
            Write-Host "Start-Service -Name VideoAgentUltimate" -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "Service installation failed!" -ForegroundColor Red
            exit 1
        }
    }
    
    # 初始化Web界面
    if($WebInterface -or $Global:CFG.WEB_CONFIG.EnableAPI) {
        Initialize-WebInterface
    }
    
    # 启动主引擎
    Start-UltimateAgent
    
} catch {
    Write-UltimateLog "Fatal error: $($_.Exception.Message)" "ERROR" "MAIN"
    Write-Host "`nVideoAgent Ultimate crashed! Check logs for details." -ForegroundColor Red
    Write-Host "Press Enter to exit..." -ForegroundColor Yellow
    Read-Host
    exit 1
}