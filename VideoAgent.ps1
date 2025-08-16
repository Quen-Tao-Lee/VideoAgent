# VideoAgent - Intelligent Video Processing with DeepSeek AI
# Cost-effective AI-powered video analysis and processing
# Version: 2.0.0

param(
    [string]$ConfigPath = "./config/config.json",
    [string]$InputDirectory = $null,
    [string]$OutputDirectory = $null,
    [string]$Mode = "monitor",
    [switch]$SkipAI = $false,
    [switch]$CostReport = $false,
    [switch]$Test = $false,
    [switch]$Setup = $false
)

$ErrorActionPreference = "Stop"

# Global configuration
$Global:Config = $null
$Global:SessionStats = @{
    StartTime = Get-Date
    ProcessedVideos = 0
    TotalCost = 0.0
    Errors = 0
}

#region Initialization and Configuration

function Initialize-VideoAgent {
    <#
    .SYNOPSIS
    Initialize VideoAgent with configuration and dependencies
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🎬 VideoAgent 2.0.0 - Intelligent Video Processing with DeepSeek AI" -ForegroundColor Cyan
    Write-Host "💰 95% cost savings compared to OpenAI" -ForegroundColor Green
    Write-Host ""
    
    # Load configuration
    if(-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    $Global:Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Log "Configuration loaded from: $ConfigPath" "INFO"
    
    # Create directories
    Initialize-Directories
    
    # Test system requirements
    Test-SystemRequirements
    
    # Load DeepSeek module
    $DeepSeekModulePath = Join-Path $Global:Config.Directories.Modules "DeepSeek.ps1"
    if(Test-Path $DeepSeekModulePath) {
        Import-Module $DeepSeekModulePath -Force
        Write-Log "DeepSeek module loaded successfully" "SUCCESS"
    } else {
        throw "DeepSeek module not found: $DeepSeekModulePath"
    }
    
    # Initialize AI if not skipped
    if(-not $SkipAI) {
        try {
            Initialize-DeepSeekAPI
            Write-Log "DeepSeek AI integration initialized" "SUCCESS"
        } catch {
            Write-Log "Failed to initialize DeepSeek AI: $($_.Exception.Message)" "ERROR"
            if(-not $Test) {
                throw
            }
        }
    }
    
    Write-Log "VideoAgent initialization completed" "SUCCESS"
}

function Initialize-Directories {
    <#
    .SYNOPSIS
    Create required directory structure
    #>
    
    $Directories = @(
        $Global:Config.Directories.Input,
        $Global:Config.Directories.Output,
        $Global:Config.Directories.Temp,
        $Global:Config.Directories.Logs
    )
    
    foreach($Dir in $Directories) {
        $FullPath = Resolve-RelativePath $Dir
        if(-not (Test-Path $FullPath)) {
            New-Item -Path $FullPath -ItemType Directory -Force | Out-Null
            Write-Log "Created directory: $FullPath" "INFO"
        }
    }
}

function Test-SystemRequirements {
    <#
    .SYNOPSIS
    Validate system requirements and dependencies
    #>
    
    Write-Log "Checking system requirements..." "INFO"
    
    # Check PowerShell version
    if($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or later required (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check required tools
    $RequiredTools = @("ffmpeg", "ffprobe")
    foreach($Tool in $RequiredTools) {
        $ToolPath = Get-Command $Tool -ErrorAction SilentlyContinue
        if(-not $ToolPath) {
            throw "Missing required tool: $Tool. Please install FFmpeg."
        }
        Write-Log "Found tool: $Tool at $($ToolPath.Source)" "INFO"
    }
    
    # Check available disk space
    $TempPath = Resolve-RelativePath $Global:Config.Directories.Temp
    $Drive = Split-Path $TempPath -Qualifier
    $FreeSpace = (Get-WmiObject -Class Win32_LogicalDisk | Where-Object DeviceID -eq $Drive).FreeSpace
    $FreeSpaceGB = [math]::Round($FreeSpace / 1GB, 2)
    
    if($FreeSpaceGB -lt 5) {
        Write-Log "Low disk space warning: Only $FreeSpaceGB GB available" "WARN"
    } else {
        Write-Log "Available disk space: $FreeSpaceGB GB" "INFO"
    }
    
    Write-Log "System requirements check completed" "SUCCESS"
}

function Resolve-RelativePath {
    <#
    .SYNOPSIS
    Convert relative path to absolute path
    #>
    param([string]$Path)
    
    if([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    } else {
        return Join-Path (Get-Location) $Path
    }
}

#endregion

#region Video Processing Core

function Start-VideoMonitoring {
    <#
    .SYNOPSIS
    Monitor input directory for new videos and process them
    #>
    [CmdletBinding()]
    param()
    
    $InputPath = Resolve-RelativePath $Global:Config.Directories.Input
    Write-Log "Starting video monitoring on: $InputPath" "INFO"
    Write-Log "Press Ctrl+C to stop monitoring" "INFO"
    
    while($true) {
        try {
            # Get video files
            $VideoFiles = Get-ChildItem -Path $InputPath -File | Where-Object {
                $_.Extension.ToLower() -in ($Global:Config.VideoProcessing.SupportedFormats | ForEach-Object { ".$_" })
            }
            
            if($VideoFiles.Count -gt 0) {
                Write-Log "Found $($VideoFiles.Count) video file(s) to process" "INFO"
                
                foreach($VideoFile in $VideoFiles) {
                    try {
                        Process-VideoFile -VideoPath $VideoFile.FullName
                        $Global:SessionStats.ProcessedVideos++
                        
                        # Move processed file
                        $ProcessedDir = Join-Path $InputPath "processed"
                        if(-not (Test-Path $ProcessedDir)) {
                            New-Item -Path $ProcessedDir -ItemType Directory -Force | Out-Null
                        }
                        
                        $DestinationPath = Join-Path $ProcessedDir $VideoFile.Name
                        Move-Item -Path $VideoFile.FullName -Destination $DestinationPath -Force
                        Write-Log "Moved processed file to: $DestinationPath" "INFO"
                        
                    } catch {
                        Write-Log "Failed to process $($VideoFile.Name): $($_.Exception.Message)" "ERROR"
                        $Global:SessionStats.Errors++
                        
                        # Move to error directory
                        $ErrorDir = Join-Path $InputPath "error"
                        if(-not (Test-Path $ErrorDir)) {
                            New-Item -Path $ErrorDir -ItemType Directory -Force | Out-Null
                        }
                        
                        $ErrorPath = Join-Path $ErrorDir $VideoFile.Name
                        Move-Item -Path $VideoFile.FullName -Destination $ErrorPath -Force
                        Write-Log "Moved failed file to: $ErrorPath" "WARN"
                    }
                }
            }
            
            # Wait before next check
            Start-Sleep -Seconds 10
            
        } catch {
            Write-Log "Monitoring error: $($_.Exception.Message)" "ERROR"
            Start-Sleep -Seconds 30
        }
    }
}

function Process-VideoFile {
    <#
    .SYNOPSIS
    Process a single video file with AI enhancement
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoPath
    )
    
    if(-not (Test-Path $VideoPath)) {
        throw "Video file not found: $VideoPath"
    }
    
    $VideoName = Split-Path $VideoPath -LeafBase
    $VideoExt = Split-Path $VideoPath -Extension
    
    Write-Log "Processing video: $(Split-Path $VideoPath -Leaf)" "INFO"
    
    try {
        # Analyze video properties
        $VideoInfo = Get-VideoInfo -VideoPath $VideoPath
        Write-Log "Video analysis: $($VideoInfo.Width)x$($VideoInfo.Height), $($VideoInfo.Duration)s, $($VideoInfo.Format)" "INFO"
        
        # Validate file size
        $FileSizeMB = [math]::Round((Get-Item $VideoPath).Length / 1MB, 2)
        $MaxSizeMB = [math]::Round($Global:Config.VideoProcessing.MaxFileSize / 1MB, 2)
        
        if($FileSizeMB -gt $MaxSizeMB) {
            Write-Log "Video file too large: $FileSizeMB MB (max: $MaxSizeMB MB)" "WARN"
            # Could implement compression here
        }
        
        # Select processing preset
        $Preset = Select-ProcessingPreset -VideoInfo $VideoInfo
        Write-Log "Selected preset: $Preset" "INFO"
        
        # Extract audio for transcription
        $AudioPath = $null
        $TranscriptionResult = $null
        
        if($Global:Config.Features.AutoSubtitles -and -not $SkipAI) {
            try {
                $AudioPath = Extract-AudioFromVideo -VideoPath $VideoPath
                $TranscriptionResult = Invoke-DeepSeekTranscription -AudioPath $AudioPath -ResponseFormat "srt"
                
                if($TranscriptionResult) {
                    # Save subtitles
                    $SubtitlePath = Join-Path (Resolve-RelativePath $Global:Config.Directories.Output) "$VideoName.srt"
                    $TranscriptionResult | Out-File -FilePath $SubtitlePath -Encoding UTF8
                    Write-Log "Subtitles saved: $SubtitlePath" "SUCCESS"
                }
            } catch {
                Write-Log "Transcription failed: $($_.Exception.Message)" "WARN"
            } finally {
                if($AudioPath -and (Test-Path $AudioPath)) {
                    Remove-Item $AudioPath -Force -ErrorAction SilentlyContinue
                }
            }
        }
        
        # Process video
        $OutputPath = Convert-Video -VideoPath $VideoPath -Preset $Preset
        
        # AI content analysis
        if($Global:Config.Features.ContentAnalysis -and -not $SkipAI) {
            try {
                $TranscriptionText = if($TranscriptionResult) { $TranscriptionResult } else { "" }
                $Analysis = Invoke-VideoContentAnalysis -VideoInfo $VideoInfo -TranscriptionText $TranscriptionText
                
                # Save analysis
                $AnalysisPath = Join-Path (Resolve-RelativePath $Global:Config.Directories.Output) "$VideoName.analysis.json"
                $Analysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $AnalysisPath -Encoding UTF8
                Write-Log "Content analysis saved: $AnalysisPath" "SUCCESS"
                
                # Update cost tracking
                $Global:SessionStats.TotalCost += $Analysis.Cost
                
            } catch {
                Write-Log "Content analysis failed: $($_.Exception.Message)" "WARN"
            }
        }
        
        # Generate marketing copy if enabled
        if($Global:Config.Features.MarketingCopy -and -not $SkipAI) {
            try {
                $MarketingCopy = New-MarketingCopy -VideoTitle $VideoName -ContentSummary $TranscriptionText
                
                # Save marketing copy
                $MarketingPath = Join-Path (Resolve-RelativePath $Global:Config.Directories.Output) "$VideoName.marketing.txt"
                $MarketingCopy.Copy | Out-File -FilePath $MarketingPath -Encoding UTF8
                Write-Log "Marketing copy saved: $MarketingPath" "SUCCESS"
                
                # Update cost tracking
                $Global:SessionStats.TotalCost += $MarketingCopy.Cost
                
            } catch {
                Write-Log "Marketing copy generation failed: $($_.Exception.Message)" "WARN"
            }
        }
        
        Write-Log "Video processing completed: $(Split-Path $OutputPath -Leaf)" "SUCCESS"
        return $OutputPath
        
    } catch {
        Write-Log "Video processing failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-VideoInfo {
    <#
    .SYNOPSIS
    Analyze video file and extract metadata
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoPath
    )
    
    try {
        # Use ffprobe to get video information
        $ProbeCmd = "ffprobe -v quiet -print_format json -show_format -show_streams `"$VideoPath`""
        $ProbeOutput = & cmd /c $ProbeCmd 2>$null | ConvertFrom-Json
        
        # Extract video stream information
        $VideoStream = $ProbeOutput.streams | Where-Object codec_type -eq "video" | Select-Object -First 1
        $AudioStream = $ProbeOutput.streams | Where-Object codec_type -eq "audio" | Select-Object -First 1
        
        if(-not $VideoStream) {
            throw "No video stream found"
        }
        
        # Calculate additional properties
        $Duration = [math]::Round([double]$ProbeOutput.format.duration, 2)
        $FileSize = [long]$ProbeOutput.format.size
        $Bitrate = [math]::Round([double]$ProbeOutput.format.bit_rate / 1000, 0)  # kbps
        
        # Determine aspect ratio category
        $AspectRatio = $VideoStream.width / $VideoStream.height
        $AspectCategory = switch($AspectRatio) {
            {$_ -gt 1.5} { "landscape" }
            {$_ -lt 0.8} { "portrait" }
            default { "square" }
        }
        
        return @{
            FileName = Split-Path $VideoPath -Leaf
            Width = [int]$VideoStream.width
            Height = [int]$VideoStream.height
            Duration = $Duration
            Format = $ProbeOutput.format.format_name
            VideoCodec = $VideoStream.codec_name
            AudioCodec = if($AudioStream) { $AudioStream.codec_name } else { "none" }
            FileSize = $FileSize
            Bitrate = $Bitrate
            AspectRatio = [math]::Round($AspectRatio, 2)
            AspectCategory = $AspectCategory
            HasAudio = $AudioStream -ne $null
            FrameRate = if($VideoStream.r_frame_rate) {
                $parts = $VideoStream.r_frame_rate -split '/'
                [math]::Round([double]$parts[0] / [double]$parts[1], 2)
            } else { 0 }
        }
        
    } catch {
        throw "Failed to analyze video: $($_.Exception.Message)"
    }
}

function Select-ProcessingPreset {
    <#
    .SYNOPSIS
    Select optimal processing preset based on video characteristics
    #>
    [CmdletBinding()]
    param(
        [hashtable]$VideoInfo
    )
    
    # Smart preset selection based on video properties
    $RecommendedPreset = switch($VideoInfo.AspectCategory) {
        "portrait" { 
            if($VideoInfo.Duration -lt 60) { "social" } else { "balanced" }
        }
        "landscape" { 
            if($VideoInfo.Width -ge 3840) { "quality" } 
            elseif($VideoInfo.Duration -gt 600) { "fast" }
            else { "balanced" }
        }
        "square" { "social" }
        default { $Global:Config.VideoProcessing.DefaultPreset }
    }
    
    # Override with user preference if specified
    if($InputPreset -and $Global:Config.VideoProcessing.Presets.ContainsKey($InputPreset)) {
        $RecommendedPreset = $InputPreset
    }
    
    return $RecommendedPreset
}

function Extract-AudioFromVideo {
    <#
    .SYNOPSIS
    Extract audio from video for transcription
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoPath
    )
    
    $TempPath = Resolve-RelativePath $Global:Config.Directories.Temp
    $AudioPath = Join-Path $TempPath "audio_$(Get-Date -Format 'HHmmss').wav"
    
    try {
        $SampleRate = $Global:Config.Audio.DefaultSampleRate
        $Channels = $Global:Config.Audio.DefaultChannels
        
        $ExtractCmd = "ffmpeg -i `"$VideoPath`" -vn -acodec pcm_s16le -ar $SampleRate -ac $Channels `"$AudioPath`" -y"
        
        Write-Log "Extracting audio: $ExtractCmd" "DEBUG"
        $Process = Start-Process -FilePath "ffmpeg" -ArgumentList "-i `"$VideoPath`" -vn -acodec pcm_s16le -ar $SampleRate -ac $Channels `"$AudioPath`" -y" -NoNewWindow -Wait -PassThru
        
        if($Process.ExitCode -eq 0 -and (Test-Path $AudioPath)) {
            Write-Log "Audio extraction successful: $(Split-Path $AudioPath -Leaf)" "SUCCESS"
            return $AudioPath
        } else {
            throw "FFmpeg process failed with exit code: $($Process.ExitCode)"
        }
        
    } catch {
        if(Test-Path $AudioPath) {
            Remove-Item $AudioPath -Force -ErrorAction SilentlyContinue
        }
        throw "Audio extraction failed: $($_.Exception.Message)"
    }
}

function Convert-Video {
    <#
    .SYNOPSIS
    Convert video using specified preset
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoPath,
        
        [Parameter(Mandatory=$true)]
        [string]$Preset
    )
    
    if(-not $Global:Config.VideoProcessing.Presets.ContainsKey($Preset)) {
        throw "Unknown preset: $Preset"
    }
    
    $PresetConfig = $Global:Config.VideoProcessing.Presets.$Preset
    $VideoName = Split-Path $VideoPath -LeafBase
    $OutputPath = Join-Path (Resolve-RelativePath $Global:Config.Directories.Output) "$VideoName.mp4"
    
    try {
        $ConvertCmd = @(
            "ffmpeg -i `"$VideoPath`""
            "-c:v libx264"
            "-preset $($PresetConfig.Preset)"
            "-crf $($PresetConfig.CRF)"
            "-vf `"scale=$($PresetConfig.MaxWidth):$($PresetConfig.MaxHeight):force_original_aspect_ratio=decrease`""
            "-c:a aac"
            "-b:a 128k"
            "`"$OutputPath`""
            "-y"
        ) -join " "
        
        Write-Log "Converting video with preset '$Preset': $ConvertCmd" "INFO"
        
        $Process = Start-Process -FilePath "ffmpeg" -ArgumentList $ConvertCmd.Replace("ffmpeg ", "") -NoNewWindow -Wait -PassThru
        
        if($Process.ExitCode -eq 0 -and (Test-Path $OutputPath)) {
            $OutputSize = (Get-Item $OutputPath).Length
            $OutputSizeMB = [math]::Round($OutputSize / 1MB, 2)
            Write-Log "Video conversion completed: $(Split-Path $OutputPath -Leaf) ($OutputSizeMB MB)" "SUCCESS"
            return $OutputPath
        } else {
            throw "FFmpeg conversion failed with exit code: $($Process.ExitCode)"
        }
        
    } catch {
        if(Test-Path $OutputPath) {
            Remove-Item $OutputPath -Force -ErrorAction SilentlyContinue
        }
        throw "Video conversion failed: $($_.Exception.Message)"
    }
}

#endregion

#region CLI Commands and Utilities

function Show-CostReport {
    <#
    .SYNOPSIS
    Display detailed cost report
    #>
    [CmdletBinding()]
    param()
    
    if(-not $SkipAI) {
        $CostReport = Get-CostReport
        
        Write-Host ""
        Write-Host "💰 DeepSeek AI Cost Report" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan
        Write-Host "Session Duration: $($CostReport.SessionDuration.ToString('hh\:mm\:ss'))" -ForegroundColor White
        Write-Host "Total Cost: $($CostReport.TotalCost) USD" -ForegroundColor Green
        Write-Host "Estimated OpenAI Cost: $($CostReport.EstimatedOpenAICost) USD" -ForegroundColor Red
        Write-Host "Estimated Savings: $($CostReport.EstimatedSavings) USD ($($CostReport.SavingsPercentage)%)" -ForegroundColor Green
        Write-Host "Requests Made: $($CostReport.RequestCount)" -ForegroundColor White
        Write-Host "Tokens Used: $($CostReport.TokensUsed)" -ForegroundColor White
        Write-Host "Audio Minutes: $($CostReport.AudioMinutes)" -ForegroundColor White
        Write-Host "Cache Hits: $($CostReport.CacheHits)" -ForegroundColor White
        Write-Host "Avg Cost/Request: $($CostReport.AvgCostPerRequest) USD" -ForegroundColor White
        Write-Host ""
    }
    
    # Session statistics
    $Duration = (Get-Date) - $Global:SessionStats.StartTime
    Write-Host "📊 Session Statistics" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host "Videos Processed: $($Global:SessionStats.ProcessedVideos)" -ForegroundColor White
    Write-Host "Errors: $($Global:SessionStats.Errors)" -ForegroundColor White
    Write-Host "Success Rate: $([math]::Round((($Global:SessionStats.ProcessedVideos / [math]::Max(1, $Global:SessionStats.ProcessedVideos + $Global:SessionStats.Errors)) * 100), 1))%" -ForegroundColor White
    Write-Host "Session Duration: $($Duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host ""
}

function Start-SetupWizard {
    <#
    .SYNOPSIS
    Interactive setup wizard for first-time configuration
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🎬 VideoAgent Setup Wizard" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host ""
    
    # API Key setup
    $ApiKey = Get-DeepSeekAPIKey
    if([string]::IsNullOrEmpty($ApiKey)) {
        Write-Host "DeepSeek API Key Configuration" -ForegroundColor Yellow
        Write-Host "------------------------------" -ForegroundColor Yellow
        Write-Host "To use AI features, you need a DeepSeek API key."
        Write-Host "Get your API key from: https://platform.deepseek.com/"
        Write-Host ""
        
        $InputKey = Read-Host "Enter your DeepSeek API key (or press Enter to skip)"
        if(-not [string]::IsNullOrEmpty($InputKey)) {
            $env:DEEPSEEK_API_KEY = $InputKey
            [Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $InputKey, "User")
            Write-Host "✅ API key configured successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  AI features will be disabled" -ForegroundColor Yellow
        }
        Write-Host ""
    } else {
        Write-Host "✅ DeepSeek API key already configured" -ForegroundColor Green
        Write-Host ""
    }
    
    # Directory setup
    Write-Host "Directory Configuration" -ForegroundColor Yellow
    Write-Host "-----------------------" -ForegroundColor Yellow
    $InputDir = Read-Host "Input directory for videos (default: ./input)"
    $OutputDir = Read-Host "Output directory for processed videos (default: ./output)"
    
    if(-not [string]::IsNullOrEmpty($InputDir)) {
        $Global:Config.Directories.Input = $InputDir
    }
    if(-not [string]::IsNullOrEmpty($OutputDir)) {
        $Global:Config.Directories.Output = $OutputDir
    }
    
    # Create directories
    Initialize-Directories
    Write-Host "✅ Directories configured" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Setup completed! You can now run VideoAgent with:" -ForegroundColor Green
    Write-Host "  .\VideoAgent.ps1 -Mode monitor" -ForegroundColor White
    Write-Host ""
}

function Test-VideoAgent {
    <#
    .SYNOPSIS
    Run comprehensive tests on VideoAgent functionality
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "🧪 VideoAgent Test Suite" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    
    $TestResults = @()
    
    # Test 1: System Requirements
    Write-Host "Testing system requirements..." -ForegroundColor Yellow
    try {
        Test-SystemRequirements
        $TestResults += @{Test="System Requirements"; Status="PASS"; Message="All requirements met"}
        Write-Host "✅ System requirements check passed" -ForegroundColor Green
    } catch {
        $TestResults += @{Test="System Requirements"; Status="FAIL"; Message=$_.Exception.Message}
        Write-Host "❌ System requirements check failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 2: Configuration
    Write-Host "Testing configuration..." -ForegroundColor Yellow
    try {
        if($Global:Config) {
            $TestResults += @{Test="Configuration"; Status="PASS"; Message="Configuration loaded successfully"}
            Write-Host "✅ Configuration test passed" -ForegroundColor Green
        } else {
            throw "Configuration not loaded"
        }
    } catch {
        $TestResults += @{Test="Configuration"; Status="FAIL"; Message=$_.Exception.Message}
        Write-Host "❌ Configuration test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test 3: DeepSeek API (if not skipped)
    if(-not $SkipAI) {
        Write-Host "Testing DeepSeek API..." -ForegroundColor Yellow
        try {
            if(Test-DeepSeekRequirements) {
                $TestResults += @{Test="DeepSeek API"; Status="PASS"; Message="API connection successful"}
                Write-Host "✅ DeepSeek API test passed" -ForegroundColor Green
            } else {
                throw "DeepSeek requirements not met"
            }
        } catch {
            $TestResults += @{Test="DeepSeek API"; Status="FAIL"; Message=$_.Exception.Message}
            Write-Host "❌ DeepSeek API test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test 4: Directory Structure
    Write-Host "Testing directory structure..." -ForegroundColor Yellow
    try {
        Initialize-Directories
        $TestResults += @{Test="Directory Structure"; Status="PASS"; Message="All directories created/verified"}
        Write-Host "✅ Directory structure test passed" -ForegroundColor Green
    } catch {
        $TestResults += @{Test="Directory Structure"; Status="FAIL"; Message=$_.Exception.Message}
        Write-Host "❌ Directory structure test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test Summary
    Write-Host ""
    Write-Host "📊 Test Summary" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor Cyan
    
    $PassedTests = ($TestResults | Where-Object Status -eq "PASS").Count
    $FailedTests = ($TestResults | Where-Object Status -eq "FAIL").Count
    
    foreach($Result in $TestResults) {
        $Color = if($Result.Status -eq "PASS") { "Green" } else { "Red" }
        $Icon = if($Result.Status -eq "PASS") { "✅" } else { "❌" }
        Write-Host "$Icon $($Result.Test): $($Result.Status)" -ForegroundColor $Color
        if($Result.Status -eq "FAIL") {
            Write-Host "   $($Result.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Passed: $PassedTests, Failed: $FailedTests" -ForegroundColor White
    
    if($FailedTests -eq 0) {
        Write-Host "🎉 All tests passed! VideoAgent is ready to use." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Please fix the issues before using VideoAgent." -ForegroundColor Yellow
    }
    
    return $FailedTests -eq 0
}

function Write-Log {
    <#
    .SYNOPSIS
    Enhanced logging function for VideoAgent
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format $Global:Config.Logging.DateFormat
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    # Console output
    if($Global:Config.Logging.ConsoleOutput) {
        $Color = switch($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "SUCCESS" { "Green" }
            "DEBUG" { "Gray" }
            default { "White" }
        }
        
        Write-Host $LogMessage -ForegroundColor $Color
    }
    
    # File output
    if($Global:Config.Logging.FileOutput) {
        $LogFile = Join-Path (Resolve-RelativePath $Global:Config.Directories.Logs) "videoagent_$(Get-Date -Format 'yyyyMMdd').log"
        
        try {
            $LogMessage | Add-Content -Path $LogFile -Encoding UTF8 -ErrorAction SilentlyContinue
            
            # Rotate log files if needed
            if((Get-Item $LogFile -ErrorAction SilentlyContinue).Length -gt $Global:Config.Logging.MaxLogFileSize) {
                $RotatedFile = Join-Path (Split-Path $LogFile) "videoagent_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
                Move-Item $LogFile $RotatedFile
            }
        } catch {
            # Silently fail on logging errors
        }
    }
}

function Show-Help {
    <#
    .SYNOPSIS
    Display help information
    #>
    
    Write-Host "🎬 VideoAgent 2.0.0 - Intelligent Video Processing with DeepSeek AI" -ForegroundColor Cyan
    Write-Host "=====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  .\VideoAgent.ps1 [parameters]" -ForegroundColor White
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Mode <string>           Processing mode (monitor, single, batch)" -ForegroundColor White
    Write-Host "  -InputDirectory <path>   Override input directory" -ForegroundColor White
    Write-Host "  -OutputDirectory <path>  Override output directory" -ForegroundColor White
    Write-Host "  -SkipAI                  Disable AI features" -ForegroundColor White
    Write-Host "  -CostReport              Show cost report and exit" -ForegroundColor White
    Write-Host "  -Test                    Run test suite" -ForegroundColor White
    Write-Host "  -Setup                   Run setup wizard" -ForegroundColor White
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\VideoAgent.ps1 -Mode monitor" -ForegroundColor White
    Write-Host "  .\VideoAgent.ps1 -Test" -ForegroundColor White
    Write-Host "  .\VideoAgent.ps1 -Setup" -ForegroundColor White
    Write-Host "  .\VideoAgent.ps1 -CostReport" -ForegroundColor White
    Write-Host ""
    Write-Host "For more information, see: docs/DeepSeek-Integration.md" -ForegroundColor Green
    Write-Host ""
}

#endregion

#region Main Execution

# Main script execution
try {
    # Handle special commands first
    if($CostReport) {
        Initialize-VideoAgent
        Show-CostReport
        exit 0
    }
    
    if($Setup) {
        Initialize-VideoAgent
        Start-SetupWizard
        exit 0
    }
    
    if($Test) {
        Initialize-VideoAgent
        $TestPassed = Test-VideoAgent
        exit $(if($TestPassed) { 0 } else { 1 })
    }
    
    # Normal operation
    Initialize-VideoAgent
    
    switch($Mode.ToLower()) {
        "monitor" {
            Start-VideoMonitoring
        }
        "single" {
            if(-not $InputDirectory -or -not (Test-Path $InputDirectory)) {
                throw "Input directory required for single mode"
            }
            $VideoFiles = Get-ChildItem -Path $InputDirectory -File | Where-Object {
                $_.Extension.ToLower() -in ($Global:Config.VideoProcessing.SupportedFormats | ForEach-Object { ".$_" })
            } | Select-Object -First 1
            
            if($VideoFiles) {
                Process-VideoFile -VideoPath $VideoFiles.FullName
                Write-Host "Single video processing completed" -ForegroundColor Green
            } else {
                Write-Host "No video files found in input directory" -ForegroundColor Yellow
            }
        }
        "batch" {
            if(-not $InputDirectory -or -not (Test-Path $InputDirectory)) {
                throw "Input directory required for batch mode"
            }
            $VideoFiles = Get-ChildItem -Path $InputDirectory -File | Where-Object {
                $_.Extension.ToLower() -in ($Global:Config.VideoProcessing.SupportedFormats | ForEach-Object { ".$_" })
            }
            
            Write-Host "Processing $($VideoFiles.Count) video files..." -ForegroundColor Green
            foreach($VideoFile in $VideoFiles) {
                try {
                    Process-VideoFile -VideoPath $VideoFile.FullName
                    $Global:SessionStats.ProcessedVideos++
                } catch {
                    Write-Log "Failed to process $($VideoFile.Name): $($_.Exception.Message)" "ERROR"
                    $Global:SessionStats.Errors++
                }
            }
            Write-Host "Batch processing completed" -ForegroundColor Green
        }
        default {
            Show-Help
            exit 1
        }
    }
    
    # Show final cost report if AI was used
    if(-not $SkipAI) {
        Show-CostReport
    }
    
} catch {
    Write-Log "VideoAgent error: $($_.Exception.Message)" "ERROR"
    exit 1
}

#endregion