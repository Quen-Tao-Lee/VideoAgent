# DeepSeek VideoAgent Usage Examples
# Demonstrates various ways to use VideoAgent with DeepSeek AI integration
# Version: 2.0.0

# Example 1: Basic Setup and Testing
# ==================================

Write-Host "🎬 VideoAgent with DeepSeek AI - Usage Examples" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# First-time setup
Write-Host "Example 1: First-time Setup" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow
Write-Host "# Run the setup wizard to configure API keys and directories"
Write-Host ".\VideoAgent.ps1 -Setup" -ForegroundColor Green
Write-Host ""

# Test system
Write-Host "Example 2: System Testing" -ForegroundColor Yellow
Write-Host "-------------------------" -ForegroundColor Yellow
Write-Host "# Run comprehensive tests to ensure everything is working"
Write-Host ".\VideoAgent.ps1 -Test" -ForegroundColor Green
Write-Host ""

# Example 2: Basic Video Processing
# =================================

Write-Host "Example 3: Monitor Mode (Continuous Processing)" -ForegroundColor Yellow
Write-Host "-----------------------------------------------" -ForegroundColor Yellow
Write-Host "# Monitor ./input directory for new videos and process automatically"
Write-Host ".\VideoAgent.ps1 -Mode monitor" -ForegroundColor Green
Write-Host ""

Write-Host "Example 4: Single Video Processing" -ForegroundColor Yellow
Write-Host "----------------------------------" -ForegroundColor Yellow
Write-Host "# Process a single video from specified directory"
Write-Host ".\VideoAgent.ps1 -Mode single -InputDirectory './my-videos'" -ForegroundColor Green
Write-Host ""

Write-Host "Example 5: Batch Processing" -ForegroundColor Yellow
Write-Host "---------------------------" -ForegroundColor Yellow
Write-Host "# Process all videos in a directory at once"
Write-Host ".\VideoAgent.ps1 -Mode batch -InputDirectory './video-batch' -OutputDirectory './processed'" -ForegroundColor Green
Write-Host ""

# Example 3: Advanced Usage
# =========================

Write-Host "Example 6: Processing Without AI (Video Only)" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Yellow
Write-Host "# Process videos without AI features (transcription, analysis)"
Write-Host ".\VideoAgent.ps1 -Mode batch -InputDirectory './videos' -SkipAI" -ForegroundColor Green
Write-Host ""

Write-Host "Example 7: Cost Monitoring" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow
Write-Host "# Check AI usage costs after processing"
Write-Host ".\VideoAgent.ps1 -CostReport" -ForegroundColor Green
Write-Host ""

# Example 4: Practical Scenarios
# ===============================

Write-Host ""
Write-Host "🚀 Practical Usage Scenarios" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

# Scenario 1: Social Media Content Creation
Write-Host "Scenario 1: Social Media Content Pipeline" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Yellow

# Create example directory structure
$ExampleDir = "./example-social-media"
Write-Host "# Setting up social media content pipeline..." -ForegroundColor Green

try {
    # Create directories
    New-Item -Path "$ExampleDir/input" -ItemType Directory -Force | Out-Null
    New-Item -Path "$ExampleDir/output" -ItemType Directory -Force | Out-Null
    
    Write-Host "mkdir $ExampleDir/input" -ForegroundColor White
    Write-Host "mkdir $ExampleDir/output" -ForegroundColor White
    
    # Create sample configuration for social media
    $SocialConfig = @{
        VideoAgent = @{
            Version = "2.0.0"
            Name = "Social Media Pipeline"
        }
        VideoProcessing = @{
            DefaultPreset = "social"
            SupportedFormats = @("mp4", "mov", "mkv")
        }
        Features = @{
            AutoSubtitles = $true
            ContentAnalysis = $true
            MarketingCopy = $true
        }
        Directories = @{
            Input = "$ExampleDir/input"
            Output = "$ExampleDir/output"
            Temp = "$ExampleDir/temp"
            Logs = "$ExampleDir/logs"
        }
    } | ConvertTo-Json -Depth 10
    
    $SocialConfig | Out-File -FilePath "$ExampleDir/social-config.json" -Encoding UTF8
    
    Write-Host ""
    Write-Host "# Process videos with social media optimization" -ForegroundColor Green
    Write-Host ".\VideoAgent.ps1 -ConfigPath '$ExampleDir/social-config.json' -Mode monitor" -ForegroundColor White
    Write-Host ""
    Write-Host "This will:" -ForegroundColor Cyan
    Write-Host "- Monitor input folder for new videos" -ForegroundColor White
    Write-Host "- Optimize for 1080x1920 (portrait) or 1080x1080 (square)" -ForegroundColor White
    Write-Host "- Generate subtitles automatically using DeepSeek" -ForegroundColor White
    Write-Host "- Create content analysis and marketing copy" -ForegroundColor White
    Write-Host "- Track costs (typically 95% cheaper than OpenAI)" -ForegroundColor White
    
} catch {
    Write-Host "Note: This is a demonstration. Actual directories would be created when running the script." -ForegroundColor Gray
}

Write-Host ""

# Scenario 2: YouTube Content Processing
Write-Host "Scenario 2: YouTube Content Processing" -ForegroundColor Yellow
Write-Host "--------------------------------------" -ForegroundColor Yellow

$YouTubeExample = @'
# YouTube content pipeline example

# 1. Set up API key (one-time setup)
$env:DEEPSEEK_API_KEY = "your-deepseek-api-key-here"

# 2. Create YouTube-optimized configuration
$YouTubeConfig = @{
    VideoProcessing = @{
        DefaultPreset = "quality"  # High quality for YouTube
        Presets = @{
            youtube = @{
                Description = "YouTube optimized"
                CRF = 20
                Preset = "medium"
                MaxWidth = 1920
                MaxHeight = 1080
            }
        }
    }
    Features = @{
        AutoSubtitles = $true
        ContentAnalysis = $true
        MarketingCopy = $true
    }
    Subtitles = @{
        FontFamily = "Arial"
        FontSize = 26
        FontColor = "white"
        BackgroundColor = "black"
        Opacity = 0.8
    }
}

# 3. Process videos
.\VideoAgent.ps1 -Mode batch -InputDirectory ".\youtube-raw" -OutputDirectory ".\youtube-ready"

# 4. Check costs and results
.\VideoAgent.ps1 -CostReport
'@

Write-Host $YouTubeExample -ForegroundColor White
Write-Host ""

# Scenario 3: Educational Content
Write-Host "Scenario 3: Educational Content Processing" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Yellow

$EducationExample = @'
# Educational content pipeline with detailed analysis

# Configuration for educational content
{
    "VideoProcessing": {
        "DefaultPreset": "balanced",
        "Features": {
            "AutoSubtitles": true,
            "ContentAnalysis": true,
            "QualityCheck": true
        }
    },
    "DeepSeek": {
        "PromptTemplates": {
            "EducationalAnalysis": {
                "System": "You are an educational content expert. Analyze this video for learning objectives, key concepts, and educational value.",
                "User": "Analyze this educational video: {content}. Identify: 1) Learning objectives, 2) Key concepts, 3) Target audience level, 4) Suggested improvements."
            }
        }
    }
}

# Process educational videos with enhanced analysis
.\VideoAgent.ps1 -Mode monitor -ConfigPath ".\config\education-config.json"
'@

Write-Host $EducationExample -ForegroundColor White
Write-Host ""

# Example 5: API Integration Examples
# ===================================

Write-Host "🔌 DeepSeek API Integration Examples" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Direct API usage example
Write-Host "Example: Direct DeepSeek Module Usage" -ForegroundColor Yellow
Write-Host "------------------------------------" -ForegroundColor Yellow

$DirectAPIExample = @'
# Load the DeepSeek module directly
Import-Module "./modules/DeepSeek.ps1" -Force

# Initialize the API
Initialize-DeepSeekAPI

# Example 1: Transcribe audio file
$AudioPath = "./audio/sample.wav"
$Transcription = Invoke-DeepSeekTranscription -AudioPath $AudioPath -ResponseFormat "srt"
$Transcription | Out-File "./output/subtitles.srt" -Encoding UTF8

# Example 2: Analyze video content
$VideoInfo = @{
    FileName = "tutorial.mp4"
    Duration = 180
    Width = 1920
    Height = 1080
}

$Analysis = Invoke-VideoContentAnalysis -VideoInfo $VideoInfo -TranscriptionText $Transcription

# Example 3: Generate marketing copy
$MarketingCopy = New-MarketingCopy -VideoTitle "Amazing Tutorial" -ContentSummary "Learn advanced techniques" -TargetPlatform "YouTube"

# Example 4: Get cost report
$CostReport = Get-CostReport
Write-Host "Total cost: $($CostReport.TotalCost) USD"
Write-Host "Estimated savings vs OpenAI: $($CostReport.EstimatedSavings) USD"
'@

Write-Host $DirectAPIExample -ForegroundColor White
Write-Host ""

# Cost Optimization Examples
Write-Host "💰 Cost Optimization Strategies" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

$CostOptimizationExample = @'
# Strategy 1: Batch Processing
# Process multiple videos together to leverage caching
.\VideoAgent.ps1 -Mode batch -InputDirectory "./large-batch"

# Strategy 2: Use Caching
# Results are automatically cached to avoid duplicate API calls
# Cache duration: 24 hours (configurable in deepseek-config.json)

# Strategy 3: Monitor Costs
# Set up cost alerts in configuration
{
    "DeepSeek": {
        "CostOptimization": {
            "MaxDailyCost": 5.00,
            "MaxMonthlyCost": 50.00,
            "AlertThreshold": 0.8
        }
    }
}

# Strategy 4: Selective AI Processing
# Skip AI for certain file types or sizes
.\VideoAgent.ps1 -Mode monitor -SkipAI  # Process videos without AI

# Check costs regularly
.\VideoAgent.ps1 -CostReport

# Expected costs (examples):
# - 10-minute video transcription: ~$0.06 USD
# - Content analysis: ~$0.002 USD
# - Marketing copy generation: ~$0.001 USD
# Total per 10-min video: ~$0.063 USD (vs ~$1.26 USD with OpenAI)
'@

Write-Host $CostOptimizationExample -ForegroundColor White
Write-Host ""

# Troubleshooting Examples
Write-Host "🔧 Troubleshooting Examples" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

$TroubleshootingExample = @'
# Problem 1: API Key Issues
# Solution: Verify API key setup
$env:DEEPSEEK_API_KEY = "your-api-key"
.\VideoAgent.ps1 -Test

# Problem 2: FFmpeg Not Found
# Solution: Install FFmpeg and add to PATH
# Download from: https://ffmpeg.org/download.html

# Problem 3: Large File Processing
# Solution: Files over 25MB are automatically compressed
# No action needed - handled automatically

# Problem 4: Network Issues
# Solution: Test connectivity
Test-NetConnection -ComputerName "api.deepseek.com" -Port 443

# Problem 5: High Costs
# Solution: Check cost report and optimize
.\VideoAgent.ps1 -CostReport
# Review cache settings in deepseek-config.json

# Problem 6: Poor Quality Results
# Solution: Adjust AI settings
# Modify prompt templates in deepseek-config.json
# Increase confidence thresholds

# Get detailed logs
.\VideoAgent.ps1 -Mode single -InputDirectory "./test" -Verbose
'@

Write-Host $TroubleshootingExample -ForegroundColor White
Write-Host ""

Write-Host "📚 Additional Resources" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "- Configuration: ./config/config.json" -ForegroundColor White
Write-Host "- DeepSeek Settings: ./config/deepseek-config.json" -ForegroundColor White
Write-Host "- Documentation: ./docs/DeepSeek-Integration.md" -ForegroundColor White
Write-Host "- Logs: ./logs/videoagent_*.log" -ForegroundColor White
Write-Host "- DeepSeek API Docs: https://platform.deepseek.com/api-docs" -ForegroundColor White
Write-Host ""
Write-Host "🎉 Start with: .\VideoAgent.ps1 -Setup" -ForegroundColor Green
Write-Host "