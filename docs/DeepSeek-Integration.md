# VideoAgent with DeepSeek AI Integration

## Overview

VideoAgent 2.0.0 is an intelligent video processing system that leverages DeepSeek's cost-effective AI capabilities to provide automated video analysis, transcription, and content generation. With 95% cost savings compared to OpenAI, it offers enterprise-grade AI features at a fraction of the cost.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [DeepSeek Integration](#deepseek-integration)
- [Cost Optimization](#cost-optimization)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Features

### 🎬 Video Processing
- **Multi-format support**: MP4, MOV, MKV, M4V, AVI, WMV
- **Intelligent presets**: Optimized settings for different use cases
- **Automatic quality optimization**: Based on video characteristics
- **Batch processing**: Handle multiple videos efficiently
- **Real-time monitoring**: Watch folders for new content

### 🤖 AI-Powered Analysis
- **Automatic transcription**: High-quality subtitle generation
- **Content analysis**: Intelligent video categorization and insights
- **Marketing copy generation**: Platform-specific promotional content
- **Quality assessment**: Automated video quality evaluation
- **Multi-language support**: Auto-detection and processing

### 💰 Cost Optimization
- **95% cost savings**: Compared to OpenAI equivalents
- **Smart caching**: Avoid duplicate API calls
- **Batch processing**: Optimize API usage
- **Cost tracking**: Real-time expense monitoring
- **Budget controls**: Configurable spending limits

### 🛠 Technical Features
- **Modular architecture**: Easy to extend and maintain
- **Comprehensive logging**: Detailed operation tracking
- **Error recovery**: Robust error handling and retry logic
- **Configuration management**: JSON-based settings
- **CLI interface**: Powerful command-line operations

## Architecture

### Component Overview

```
VideoAgent/
├── VideoAgent.ps1              # Main orchestration script
├── modules/
│   └── DeepSeek.ps1           # AI integration module
├── config/
│   ├── config.json            # General configuration
│   └── deepseek-config.json   # AI-specific settings
├── examples/
│   └── deepseek-example.ps1   # Usage examples
└── docs/
    └── DeepSeek-Integration.md # This documentation
```

### Data Flow

1. **Video Input** → Video files detected in input directory
2. **Analysis** → FFmpeg extracts metadata and audio
3. **AI Processing** → DeepSeek API processes audio and content
4. **Enhancement** → Video converted with optimal settings
5. **Output** → Processed video with subtitles and analysis

### Module Dependencies

- **PowerShell 5.1+**: Core runtime environment
- **FFmpeg**: Video/audio processing
- **DeepSeek API**: AI capabilities
- **JSON Configuration**: Settings management

## Installation

### Prerequisites

1. **PowerShell 5.1 or later**
   ```powershell
   $PSVersionTable.PSVersion
   ```

2. **FFmpeg installation**
   - Download from [https://ffmpeg.org/download.html](https://ffmpeg.org/download.html)
   - Add to system PATH
   - Verify: `ffmpeg -version`

3. **DeepSeek API Key**
   - Sign up at [https://platform.deepseek.com/](https://platform.deepseek.com/)
   - Generate API key
   - Note the key for configuration

### Quick Setup

1. **Clone/Download VideoAgent**
   ```powershell
   # Download or clone the VideoAgent repository
   cd VideoAgent
   ```

2. **Run Setup Wizard**
   ```powershell
   .\VideoAgent.ps1 -Setup
   ```

3. **Configure API Key**
   ```powershell
   $env:DEEPSEEK_API_KEY = "your-api-key-here"
   ```

4. **Test Installation**
   ```powershell
   .\VideoAgent.ps1 -Test
   ```

### Manual Configuration

1. **Set Environment Variable**
   ```powershell
   [Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "your-key", "User")
   ```

2. **Create Directory Structure**
   ```powershell
   mkdir input, output, temp, logs
   ```

3. **Validate Configuration**
   ```powershell
   .\VideoAgent.ps1 -Test
   ```

## Configuration

### General Configuration (config/config.json)

The main configuration file controls video processing, directories, and features:

```json
{
    "VideoAgent": {
        "Version": "2.0.0",
        "Name": "VideoAgent with DeepSeek AI"
    },
    "Directories": {
        "Input": "./input",
        "Output": "./output",
        "Temp": "./temp",
        "Logs": "./logs"
    },
    "VideoProcessing": {
        "SupportedFormats": ["mp4", "mov", "mkv", "m4v", "avi", "wmv"],
        "DefaultPreset": "balanced",
        "Presets": {
            "fast": { "CRF": 28, "Preset": "ultrafast" },
            "balanced": { "CRF": 23, "Preset": "medium" },
            "quality": { "CRF": 18, "Preset": "slow" }
        }
    },
    "Features": {
        "AutoSubtitles": true,
        "ContentAnalysis": true,
        "MarketingCopy": false,
        "CostTracking": true
    }
}
```

### DeepSeek Configuration (config/deepseek-config.json)

AI-specific settings for DeepSeek integration:

```json
{
    "DeepSeek": {
        "API": {
            "BaseURL": "https://api.deepseek.com",
            "Timeout": 300,
            "MaxRetries": 3
        },
        "Models": {
            "Chat": {
                "Primary": "deepseek-chat",
                "MaxTokens": 4096,
                "Temperature": 0.7
            },
            "Audio": {
                "Primary": "whisper-1",
                "Language": "auto"
            }
        },
        "CostOptimization": {
            "MaxDailyCost": 10.00,
            "CacheResults": true,
            "BatchProcessing": true
        }
    }
}
```

### Customization Options

#### Video Presets
Create custom processing presets for specific use cases:

```json
"CustomPresets": {
    "youtube": {
        "Description": "YouTube optimized",
        "CRF": 20,
        "MaxWidth": 1920,
        "MaxHeight": 1080,
        "Preset": "medium"
    },
    "tiktok": {
        "Description": "TikTok vertical",
        "CRF": 25,
        "MaxWidth": 1080,
        "MaxHeight": 1920,
        "Preset": "fast"
    }
}
```

#### AI Prompt Templates
Customize AI behavior with custom prompts:

```json
"PromptTemplates": {
    "CustomAnalysis": {
        "System": "You are a video expert. Analyze content for specific requirements.",
        "User": "Analyze this video: {content}. Focus on: {requirements}."
    }
}
```

## Usage

### Basic Operations

#### Monitor Mode (Continuous Processing)
```powershell
# Monitor input directory for new videos
.\VideoAgent.ps1 -Mode monitor

# Monitor with custom directories
.\VideoAgent.ps1 -Mode monitor -InputDirectory "C:\Videos\Raw" -OutputDirectory "C:\Videos\Processed"
```

#### Single Video Processing
```powershell
# Process one video from a directory
.\VideoAgent.ps1 -Mode single -InputDirectory "./my-video"
```

#### Batch Processing
```powershell
# Process all videos in a directory
.\VideoAgent.ps1 -Mode batch -InputDirectory "./video-batch"
```

### Advanced Usage

#### Without AI Features
```powershell
# Process videos without AI (video conversion only)
.\VideoAgent.ps1 -Mode batch -InputDirectory "./videos" -SkipAI
```

#### Custom Configuration
```powershell
# Use custom configuration file
.\VideoAgent.ps1 -ConfigPath "./custom-config.json" -Mode monitor
```

#### Cost Monitoring
```powershell
# Check current session costs
.\VideoAgent.ps1 -CostReport
```

### Workflow Examples

#### Social Media Pipeline
```powershell
# 1. Configure for social media
# Edit config.json to set "DefaultPreset": "social"

# 2. Enable marketing copy generation
# Set "MarketingCopy": true in config.json

# 3. Process videos
.\VideoAgent.ps1 -Mode monitor

# 4. Check results in output directory:
# - video.mp4 (optimized video)
# - video.srt (subtitles)
# - video.analysis.json (AI analysis)
# - video.marketing.txt (marketing copy)
```

#### Educational Content
```powershell
# 1. Custom configuration for education
$EducationConfig = @{
    Features = @{
        AutoSubtitles = $true
        ContentAnalysis = $true
        QualityAssurance = $true
    }
    VideoProcessing = @{
        DefaultPreset = "quality"
    }
}

# 2. Process educational videos
.\VideoAgent.ps1 -Mode batch -InputDirectory "./lectures"
```

## DeepSeek Integration

### API Capabilities

#### Audio Transcription
- **Model**: Whisper-1 compatible
- **Formats**: SRT, VTT, TXT, JSON
- **Languages**: Auto-detection + 90+ languages
- **Quality**: High accuracy transcription
- **Cost**: ~$0.006 per minute

#### Content Analysis
- **Model**: DeepSeek-Chat
- **Features**: Video categorization, quality assessment
- **Insights**: Audience targeting, content optimization
- **Cost**: ~$0.002 per analysis

#### Marketing Copy Generation
- **Platforms**: YouTube, TikTok, Instagram, Facebook, etc.
- **Content**: Titles, descriptions, hashtags, CTAs
- **Customization**: Platform-specific optimization
- **Cost**: ~$0.001 per generation

### Cost Comparison

| Service | OpenAI GPT-4 | DeepSeek | Savings |
|---------|--------------|----------|---------|
| Text Generation (1K tokens) | $0.030 | $0.0014 | 95.3% |
| Audio Transcription (1 min) | $0.120 | $0.006 | 95.0% |
| Content Analysis | $0.040 | $0.002 | 95.0% |

### Authentication

#### Environment Variable (Recommended)
```powershell
$env:DEEPSEEK_API_KEY = "your-api-key"
```

#### Persistent User Variable
```powershell
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "your-key", "User")
```

#### Key File (Alternative)
```powershell
# Create key file
"your-api-key" | Out-File "./config/.deepseek_key" -Encoding UTF8
```

### Rate Limiting

DeepSeek implements intelligent rate limiting:
- **Requests per minute**: 60
- **Requests per hour**: 1000
- **Concurrent requests**: 5
- **Automatic backoff**: Exponential retry strategy

## Cost Optimization

### Strategies

#### 1. Caching System
```json
{
    "CostOptimization": {
        "CacheResults": true,
        "CacheDuration": 86400
    }
}
```
- Automatic response caching
- 24-hour default duration
- Significant cost reduction for repeated content

#### 2. Batch Processing
```powershell
# Process multiple videos together
.\VideoAgent.ps1 -Mode batch -InputDirectory "./large-batch"
```
- Shared context reduces token usage
- Improved cache hit rates
- Lower per-video costs

#### 3. Selective AI Processing
```powershell
# Skip AI for certain scenarios
.\VideoAgent.ps1 -Mode monitor -SkipAI
```
- Process videos without AI when not needed
- Selective feature enabling
- Cost-conscious operation

#### 4. Budget Controls
```json
{
    "CostOptimization": {
        "MaxDailyCost": 5.00,
        "MaxMonthlyCost": 50.00,
        "AlertThreshold": 0.8
    }
}
```
- Automatic cost tracking
- Spending alerts
- Budget enforcement

### Cost Monitoring

#### Real-time Tracking
```powershell
# Get current session costs
.\VideoAgent.ps1 -CostReport
```

#### Output Example
```
💰 DeepSeek AI Cost Report
=========================
Session Duration: 02:15:30
Total Cost: $0.45 USD
Estimated OpenAI Cost: $9.00 USD
Estimated Savings: $8.55 USD (95.0%)
Requests Made: 25
Tokens Used: 15,420
Audio Minutes: 45.5
Cache Hits: 8
Avg Cost/Request: $0.018 USD
```

## API Reference

### DeepSeek Module Functions

#### Initialize-DeepSeekAPI
```powershell
Initialize-DeepSeekAPI
```
- Initializes API connection
- Validates configuration
- Tests connectivity

#### Invoke-DeepSeekTranscription
```powershell
$Result = Invoke-DeepSeekTranscription -AudioPath "./audio.wav" -ResponseFormat "srt"
```
- **Parameters**:
  - `AudioPath`: Path to audio file
  - `Language`: Language code (default: "auto")
  - `ResponseFormat`: Output format ("srt", "vtt", "txt", "json")
- **Returns**: Transcription result

#### Invoke-VideoContentAnalysis
```powershell
$Analysis = Invoke-VideoContentAnalysis -VideoInfo $VideoInfo -TranscriptionText $Text
```
- **Parameters**:
  - `VideoInfo`: Video metadata hashtable
  - `TranscriptionText`: Optional transcription text
- **Returns**: Analysis result with insights

#### New-MarketingCopy
```powershell
$Copy = New-MarketingCopy -VideoTitle "Title" -ContentSummary "Summary" -TargetPlatform "YouTube"
```
- **Parameters**:
  - `VideoTitle`: Video title
  - `ContentSummary`: Content description
  - `TargetPlatform`: Social media platform
- **Returns**: Marketing copy and metadata

#### Get-CostReport
```powershell
$Report = Get-CostReport
```
- **Returns**: Detailed cost breakdown and statistics

### VideoAgent Core Functions

#### Process-VideoFile
```powershell
$OutputPath = Process-VideoFile -VideoPath "./input/video.mp4"
```
- **Parameters**:
  - `VideoPath`: Path to video file
- **Returns**: Path to processed video

#### Get-VideoInfo
```powershell
$Info = Get-VideoInfo -VideoPath "./video.mp4"
```
- **Parameters**:
  - `VideoPath`: Path to video file
- **Returns**: Video metadata hashtable

## Troubleshooting

### Common Issues

#### 1. API Key Problems
**Symptoms**: Authentication errors, API access denied
**Solutions**:
```powershell
# Verify API key is set
$env:DEEPSEEK_API_KEY

# Test API connectivity
.\VideoAgent.ps1 -Test

# Reset API key
$env:DEEPSEEK_API_KEY = "new-api-key"
```

#### 2. FFmpeg Not Found
**Symptoms**: "Missing tool: ffmpeg" error
**Solutions**:
- Install FFmpeg from official website
- Add FFmpeg to system PATH
- Verify installation: `ffmpeg -version`

#### 3. Large File Processing
**Symptoms**: Upload errors, timeout issues
**Solutions**:
- Files over 25MB are automatically compressed
- Check temp directory space
- Verify network connectivity

#### 4. High API Costs
**Symptoms**: Unexpected charges, budget exceeded
**Solutions**:
```powershell
# Check cost report
.\VideoAgent.ps1 -CostReport

# Review cache settings
# Edit deepseek-config.json

# Enable cost controls
{
    "CostOptimization": {
        "MaxDailyCost": 5.00,
        "AlertThreshold": 0.8
    }
}
```

#### 5. Poor Quality Results
**Symptoms**: Inaccurate transcriptions, poor analysis
**Solutions**:
- Check audio quality in source videos
- Adjust AI model parameters
- Customize prompt templates
- Increase confidence thresholds

### Debugging

#### Enable Detailed Logging
```powershell
# Check log files
Get-Content "./logs/videoagent_*.log" -Tail 50

# Run with verbose output
.\VideoAgent.ps1 -Mode single -InputDirectory "./test" -Verbose
```

#### Test Individual Components
```powershell
# Test system requirements
.\VideoAgent.ps1 -Test

# Test DeepSeek API only
Import-Module "./modules/DeepSeek.ps1"
Test-DeepSeekRequirements
```

#### Network Connectivity
```powershell
# Test DeepSeek API connection
Test-NetConnection -ComputerName "api.deepseek.com" -Port 443

# Check DNS resolution
Resolve-DnsName "api.deepseek.com"
```

### Getting Help

1. **Check Documentation**: This file and inline help
2. **Review Examples**: `./examples/deepseek-example.ps1`
3. **Test System**: `.\VideoAgent.ps1 -Test`
4. **Check Logs**: `./logs/videoagent_*.log`
5. **Verify Configuration**: `./config/*.json`

## Best Practices

### Performance Optimization

#### 1. Resource Management
- Monitor disk space (temp directory)
- Limit concurrent processing
- Clean up temporary files regularly
- Use appropriate video presets

#### 2. Cost Management
- Enable result caching
- Use batch processing when possible
- Set budget limits
- Monitor costs regularly

#### 3. Quality Assurance
- Validate input video quality
- Test configuration changes
- Monitor error rates
- Review AI outputs periodically

### Security Considerations

#### 1. API Key Protection
```powershell
# Use environment variables (not config files)
$env:DEEPSEEK_API_KEY = "key"

# Set user-level environment variables
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "key", "User")

# Avoid hardcoding keys in scripts
```

#### 2. File Handling
- Validate input file paths
- Use temporary directories
- Clean up after processing
- Implement access controls

#### 3. Network Security
- Use HTTPS endpoints only
- Implement timeout controls
- Monitor API usage
- Log security events

### Maintenance

#### Regular Tasks
1. **Update API Keys**: Rotate keys periodically
2. **Clean Temp Files**: Remove old temporary files
3. **Review Logs**: Check for errors and performance issues
4. **Update Configuration**: Adjust settings based on usage patterns
5. **Monitor Costs**: Review spending and optimize

#### Updates and Upgrades
1. **Backup Configuration**: Save current settings
2. **Test New Versions**: Use test mode before production
3. **Update Dependencies**: Keep FFmpeg and PowerShell current
4. **Review Documentation**: Check for new features and changes

### Production Deployment

#### 1. Environment Setup
```powershell
# Production configuration
{
    "Logging": {
        "Level": "INFO",
        "FileOutput": true,
        "MaxLogFiles": 30
    },
    "Performance": {
        "MaxConcurrentJobs": 4,
        "ProcessTimeout": 3600
    },
    "CostOptimization": {
        "MaxDailyCost": 50.00,
        "CacheResults": true
    }
}
```

#### 2. Monitoring
- Set up log rotation
- Monitor API usage and costs
- Track processing statistics
- Implement alerting

#### 3. Scaling
- Use multiple input directories
- Implement load balancing
- Consider cloud deployment
- Optimize for throughput

## Conclusion

VideoAgent with DeepSeek AI integration provides a powerful, cost-effective solution for intelligent video processing. With 95% cost savings compared to OpenAI and comprehensive features for transcription, analysis, and content generation, it's designed for both individual creators and enterprise deployments.

### Key Benefits
- **Cost Effective**: 95% cheaper than OpenAI alternatives
- **Comprehensive**: Complete video processing pipeline
- **Intelligent**: AI-powered analysis and enhancement
- **Flexible**: Configurable for various use cases
- **Scalable**: Suitable for small to large-scale operations

### Getting Started
1. Run `.\VideoAgent.ps1 -Setup` for initial configuration
2. Test with `.\VideoAgent.ps1 -Test`
3. Start processing with `.\VideoAgent.ps1 -Mode monitor`
4. Monitor costs with `.\VideoAgent.ps1 -CostReport`

For the latest updates and additional resources, visit the project repository and DeepSeek documentation.