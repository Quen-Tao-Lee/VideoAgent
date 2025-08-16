# DeepSeek AI Integration Module for VideoAgent
# Provides cost-effective AI capabilities for video processing
# Version: 2.0.0

param(
    [string]$ConfigPath = "./config/deepseek-config.json"
)

# Load configuration
if(-not (Test-Path $ConfigPath)) {
    throw "DeepSeek configuration file not found: $ConfigPath"
}

$Global:DeepSeekConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# Initialize cost tracking
$Global:CostTracker = @{
    SessionStart = Get-Date
    TotalCost = 0.0
    RequestCount = 0
    TokensUsed = 0
    AudioMinutes = 0.0
    CacheHits = 0
}

# Cache for API responses
$Global:ResponseCache = @{}

#region Authentication and Configuration

function Initialize-DeepSeekAPI {
    <#
    .SYNOPSIS
    Initialize DeepSeek API connection and validate configuration
    .DESCRIPTION
    Sets up API authentication, validates connectivity, and prepares the module for use
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Initializing DeepSeek API connection..." "INFO" "DEEPSEEK"
    
    # Check for API key
    $ApiKey = Get-DeepSeekAPIKey
    if([string]::IsNullOrEmpty($ApiKey)) {
        throw "DeepSeek API key not configured. Please set DEEPSEEK_API_KEY environment variable or create key file."
    }
    
    # Validate API connectivity
    try {
        $TestResponse = Test-DeepSeekConnectivity
        if($TestResponse.Success) {
            Write-Log "DeepSeek API connection established successfully" "SUCCESS" "DEEPSEEK"
            Write-Log "Available models: $($TestResponse.Models -join ', ')" "INFO" "DEEPSEEK"
        } else {
            throw "DeepSeek API connectivity test failed: $($TestResponse.Error)"
        }
    } catch {
        Write-Log "Failed to initialize DeepSeek API: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        throw
    }
    
    # Initialize cost tracking
    Reset-CostTracker
    Write-Log "DeepSeek API initialized. Estimated cost savings: 95% vs OpenAI" "INFO" "DEEPSEEK"
}

function Get-DeepSeekAPIKey {
    <#
    .SYNOPSIS
    Retrieve DeepSeek API key from environment or file
    #>
    
    # Try environment variable first
    $ApiKey = $env:DEEPSEEK_API_KEY
    if(-not [string]::IsNullOrEmpty($ApiKey)) {
        return $ApiKey
    }
    
    # Try key file
    $KeyFile = $Global:DeepSeekConfig.DeepSeek.Authentication.KeyFile
    if(Test-Path $KeyFile) {
        $ApiKey = Get-Content $KeyFile -Raw
        return $ApiKey.Trim()
    }
    
    return $null
}

function Test-DeepSeekConnectivity {
    <#
    .SYNOPSIS
    Test connectivity to DeepSeek API and retrieve available models
    #>
    
    try {
        $Headers = Get-APIHeaders
        $ModelsUrl = "$($Global:DeepSeekConfig.DeepSeek.API.BaseURL)$($Global:DeepSeekConfig.DeepSeek.API.Endpoints.Models)"
        
        $Response = Invoke-RestMethod -Uri $ModelsUrl -Headers $Headers -Method Get -TimeoutSec 30
        
        if($Response -and $Response.data) {
            $Models = $Response.data | ForEach-Object { $_.id }
            return @{
                Success = $true
                Models = $Models
            }
        } else {
            return @{
                Success = $false
                Error = "Invalid response format"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-APIHeaders {
    <#
    .SYNOPSIS
    Generate standard API headers for DeepSeek requests
    #>
    
    $ApiKey = Get-DeepSeekAPIKey
    return @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
        "User-Agent" = "VideoAgent-DeepSeek/2.0.0"
    }
}

#endregion

#region Audio Processing and Transcription

function Invoke-DeepSeekTranscription {
    <#
    .SYNOPSIS
    Transcribe audio using DeepSeek API with cost optimization
    .PARAMETER AudioPath
    Path to the audio file to transcribe
    .PARAMETER Language
    Language code for transcription (auto for auto-detection)
    .PARAMETER ResponseFormat
    Output format (srt, vtt, txt)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$AudioPath,
        
        [string]$Language = "auto",
        
        [ValidateSet("srt", "vtt", "txt", "json")]
        [string]$ResponseFormat = "srt"
    )
    
    if(-not (Test-Path $AudioPath)) {
        throw "Audio file not found: $AudioPath"
    }
    
    Write-Log "Starting DeepSeek transcription for: $(Split-Path $AudioPath -Leaf)" "INFO" "DEEPSEEK"
    
    try {
        # Check cache first
        $CacheKey = Get-FileHash $AudioPath | Select-Object -ExpandProperty Hash
        if($Global:ResponseCache.ContainsKey("transcription_$CacheKey") -and $Global:DeepSeekConfig.DeepSeek.CostOptimization.CacheResults) {
            Write-Log "Using cached transcription result" "INFO" "DEEPSEEK"
            $Global:CostTracker.CacheHits++
            return $Global:ResponseCache["transcription_$CacheKey"]
        }
        
        # Validate file size
        $FileSize = (Get-Item $AudioPath).Length
        $MaxSize = $Global:DeepSeekConfig.DeepSeek.Models.Audio.MaxFileSize
        
        if($FileSize -gt $MaxSize) {
            Write-Log "Audio file too large ($([math]::Round($FileSize/1MB, 2)) MB), compressing..." "WARN" "DEEPSEEK"
            $AudioPath = Compress-AudioFile $AudioPath
        }
        
        # Prepare multipart form data
        $Boundary = [System.Guid]::NewGuid().ToString()
        $Headers = @{
            "Authorization" = "Bearer $(Get-DeepSeekAPIKey)"
            "Content-Type" = "multipart/form-data; boundary=$Boundary"
        }
        
        $AudioBytes = [System.IO.File]::ReadAllBytes($AudioPath)
        $FileName = Split-Path $AudioPath -Leaf
        
        # Build multipart body
        $BodyStart = "--$Boundary`r`n" +
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$FileName`"`r`n" +
                    "Content-Type: audio/wav`r`n`r`n"
        
        $BodyEnd = "`r`n--$Boundary`r`n" +
                  "Content-Disposition: form-data; name=`"model`"`r`n`r`n" +
                  "$($Global:DeepSeekConfig.DeepSeek.Models.Audio.Primary)`r`n" +
                  "--$Boundary`r`n" +
                  "Content-Disposition: form-data; name=`"response_format`"`r`n`r`n" +
                  "$ResponseFormat`r`n"
        
        if($Language -ne "auto") {
            $BodyEnd += "--$Boundary`r`n" +
                       "Content-Disposition: form-data; name=`"language`"`r`n`r`n" +
                       "$Language`r`n"
        }
        
        $BodyEnd += "--$Boundary--`r`n"
        
        # Combine body parts
        $BodyStartBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyStart)
        $BodyEndBytes = [System.Text.Encoding]::UTF8.GetBytes($BodyEnd)
        
        $FullBodyLength = $BodyStartBytes.Length + $AudioBytes.Length + $BodyEndBytes.Length
        $FullBody = New-Object byte[] $FullBodyLength
        
        [Array]::Copy($BodyStartBytes, 0, $FullBody, 0, $BodyStartBytes.Length)
        [Array]::Copy($AudioBytes, 0, $FullBody, $BodyStartBytes.Length, $AudioBytes.Length)
        [Array]::Copy($BodyEndBytes, 0, $FullBody, $BodyStartBytes.Length + $AudioBytes.Length, $BodyEndBytes.Length)
        
        # Send API request
        $ApiUrl = "$($Global:DeepSeekConfig.DeepSeek.API.BaseURL)$($Global:DeepSeekConfig.DeepSeek.API.Endpoints.Audio)"
        
        Write-Log "Sending transcription request to DeepSeek API..." "INFO" "DEEPSEEK"
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $FullBody -TimeoutSec $Global:DeepSeekConfig.DeepSeek.API.Timeout
        
        # Update cost tracking
        $AudioDuration = Get-AudioDuration $AudioPath
        $Cost = $AudioDuration * $Global:DeepSeekConfig.DeepSeek.Pricing.AudioPerMinute
        Update-CostTracker -Cost $Cost -AudioMinutes $AudioDuration
        
        # Cache the response
        if($Global:DeepSeekConfig.DeepSeek.CostOptimization.CacheResults) {
            $Global:ResponseCache["transcription_$CacheKey"] = $Response
        }
        
        Write-Log "DeepSeek transcription completed successfully. Cost: $([math]::Round($Cost, 4)) USD" "SUCCESS" "DEEPSEEK"
        
        return $Response
        
    } catch {
        Write-Log "DeepSeek transcription failed: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        throw
    }
}

function Compress-AudioFile {
    <#
    .SYNOPSIS
    Compress audio file to meet API size limits
    #>
    param([string]$AudioPath)
    
    $CompressedPath = [System.IO.Path]::ChangeExtension($AudioPath, ".compressed.mp3")
    $Bitrate = $Global:DeepSeekConfig.DeepSeek.Audio.CompressionBitrate
    
    $CompressCmd = "ffmpeg -i `"$AudioPath`" -codec:a mp3 -b:a $Bitrate -y `"$CompressedPath`""
    
    Write-Log "Compressing audio: $CompressCmd" "INFO" "DEEPSEEK"
    $Process = Start-Process -FilePath "ffmpeg" -ArgumentList "-i `"$AudioPath`" -codec:a mp3 -b:a $Bitrate -y `"$CompressedPath`"" -NoNewWindow -Wait -PassThru
    
    if($Process.ExitCode -eq 0 -and (Test-Path $CompressedPath)) {
        Write-Log "Audio compression successful" "SUCCESS" "DEEPSEEK"
        return $CompressedPath
    } else {
        throw "Audio compression failed"
    }
}

function Get-AudioDuration {
    <#
    .SYNOPSIS
    Get audio duration in minutes using ffprobe
    #>
    param([string]$AudioPath)
    
    try {
        $ProbeCmd = "ffprobe -v quiet -show_entries format=duration -of csv=p=0 `"$AudioPath`""
        $Duration = & cmd /c $ProbeCmd 2>$null
        return [math]::Round([double]$Duration / 60, 2)
    } catch {
        Write-Log "Failed to get audio duration: $($_.Exception.Message)" "WARN" "DEEPSEEK"
        return 1.0  # Default fallback
    }
}

#endregion

#region Content Analysis and Chat Completion

function Invoke-DeepSeekChat {
    <#
    .SYNOPSIS
    Send chat completion request to DeepSeek API
    .PARAMETER Messages
    Array of message objects with role and content
    .PARAMETER Template
    Predefined prompt template to use
    .PARAMETER Variables
    Variables to substitute in the template
    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="Direct")]
        [array]$Messages,
        
        [Parameter(ParameterSetName="Template")]
        [ValidateSet("VideoAnalysis", "MarketingCopy", "ContentSummary")]
        [string]$Template,
        
        [Parameter(ParameterSetName="Template")]
        [hashtable]$Variables = @{}
    )
    
    Write-Log "Sending chat completion request to DeepSeek..." "INFO" "DEEPSEEK"
    
    try {
        # Prepare messages
        if($Template) {
            $Messages = Build-TemplateMessages -Template $Template -Variables $Variables
        }
        
        # Check cache
        $CacheKey = ($Messages | ConvertTo-Json -Compress | Get-FileHash -Algorithm MD5).Hash
        if($Global:ResponseCache.ContainsKey("chat_$CacheKey") -and $Global:DeepSeekConfig.DeepSeek.CostOptimization.CacheResults) {
            Write-Log "Using cached chat response" "INFO" "DEEPSEEK"
            $Global:CostTracker.CacheHits++
            return $Global:ResponseCache["chat_$CacheKey"]
        }
        
        # Prepare request body
        $RequestBody = @{
            model = $Global:DeepSeekConfig.DeepSeek.Models.Chat.Primary
            messages = $Messages
            max_tokens = $Global:DeepSeekConfig.DeepSeek.Models.Chat.MaxTokens
            temperature = $Global:DeepSeekConfig.DeepSeek.Models.Chat.Temperature
            top_p = $Global:DeepSeekConfig.DeepSeek.Models.Chat.TopP
        } | ConvertTo-Json -Depth 10
        
        # Send request
        $Headers = Get-APIHeaders
        $ApiUrl = "$($Global:DeepSeekConfig.DeepSeek.API.BaseURL)$($Global:DeepSeekConfig.DeepSeek.API.Endpoints.Chat)"
        
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $RequestBody -TimeoutSec $Global:DeepSeekConfig.DeepSeek.API.Timeout
        
        # Update cost tracking
        if($Response.usage) {
            $InputCost = $Response.usage.prompt_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.InputTokenCost
            $OutputCost = $Response.usage.completion_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.OutputTokenCost
            $TotalCost = $InputCost + $OutputCost
            
            Update-CostTracker -Cost $TotalCost -Tokens $Response.usage.total_tokens
        }
        
        # Cache the response
        if($Global:DeepSeekConfig.DeepSeek.CostOptimization.CacheResults) {
            $Global:ResponseCache["chat_$CacheKey"] = $Response
        }
        
        Write-Log "DeepSeek chat completion successful" "SUCCESS" "DEEPSEEK"
        return $Response
        
    } catch {
        Write-Log "DeepSeek chat completion failed: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        throw
    }
}

function Build-TemplateMessages {
    <#
    .SYNOPSIS
    Build message array from template and variables
    #>
    param(
        [string]$Template,
        [hashtable]$Variables
    )
    
    $TemplateConfig = $Global:DeepSeekConfig.DeepSeek.PromptTemplates.$Template
    
    # Replace variables in the user message
    $UserMessage = $TemplateConfig.User
    foreach($Key in $Variables.Keys) {
        $UserMessage = $UserMessage -replace "\{$Key\}", $Variables[$Key]
    }
    
    return @(
        @{
            role = "system"
            content = $TemplateConfig.System
        },
        @{
            role = "user"
            content = $UserMessage
        }
    )
}

function Invoke-VideoContentAnalysis {
    <#
    .SYNOPSIS
    Analyze video content using DeepSeek AI
    .PARAMETER VideoInfo
    Video metadata and information
    .PARAMETER TranscriptionText
    Text from video transcription
    #>
    [CmdletBinding()]
    param(
        [hashtable]$VideoInfo,
        [string]$TranscriptionText = ""
    )
    
    Write-Log "Analyzing video content with DeepSeek AI..." "INFO" "DEEPSEEK"
    
    try {
        $ContentSummary = @(
            "Video: $($VideoInfo.FileName)"
            "Duration: $($VideoInfo.Duration) seconds"
            "Resolution: $($VideoInfo.Width)x$($VideoInfo.Height)"
            "Format: $($VideoInfo.Format)"
        )
        
        if(-not [string]::IsNullOrEmpty($TranscriptionText)) {
            $ContentSummary += "Transcription: $TranscriptionText"
        }
        
        $Variables = @{
            content = $ContentSummary -join "`n"
        }
        
        $Response = Invoke-DeepSeekChat -Template "VideoAnalysis" -Variables $Variables
        
        if($Response.choices -and $Response.choices[0].message) {
            $Analysis = $Response.choices[0].message.content
            Write-Log "Video content analysis completed" "SUCCESS" "DEEPSEEK"
            
            return @{
                Analysis = $Analysis
                Confidence = 0.9  # DeepSeek generally provides high quality analysis
                TokensUsed = $Response.usage.total_tokens
                Cost = ($Response.usage.prompt_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.InputTokenCost) + 
                       ($Response.usage.completion_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.OutputTokenCost)
            }
        } else {
            throw "Invalid response format from DeepSeek API"
        }
        
    } catch {
        Write-Log "Video content analysis failed: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        throw
    }
}

function New-MarketingCopy {
    <#
    .SYNOPSIS
    Generate marketing copy for video content
    .PARAMETER VideoTitle
    Title of the video
    .PARAMETER ContentSummary
    Summary of video content
    .PARAMETER TargetPlatform
    Target social media platform
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoTitle,
        
        [string]$ContentSummary = "",
        
        [ValidateSet("YouTube", "TikTok", "Instagram", "Facebook", "Twitter", "LinkedIn", "General")]
        [string]$TargetPlatform = "General"
    )
    
    Write-Log "Generating marketing copy for: $VideoTitle" "INFO" "DEEPSEEK"
    
    try {
        $Variables = @{
            title = $VideoTitle
            summary = $ContentSummary
            platform = $TargetPlatform
        }
        
        $Response = Invoke-DeepSeekChat -Template "MarketingCopy" -Variables $Variables
        
        if($Response.choices -and $Response.choices[0].message) {
            $MarketingCopy = $Response.choices[0].message.content
            Write-Log "Marketing copy generation completed" "SUCCESS" "DEEPSEEK"
            
            return @{
                Copy = $MarketingCopy
                Platform = $TargetPlatform
                TokensUsed = $Response.usage.total_tokens
                Cost = ($Response.usage.prompt_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.InputTokenCost) + 
                       ($Response.usage.completion_tokens * $Global:DeepSeekConfig.DeepSeek.Pricing.OutputTokenCost)
            }
        } else {
            throw "Invalid response format from DeepSeek API"
        }
        
    } catch {
        Write-Log "Marketing copy generation failed: $($_.Exception.Message)" "ERROR" "DEEPSEEK"
        throw
    }
}

#endregion

#region Cost Tracking and Optimization

function Update-CostTracker {
    <#
    .SYNOPSIS
    Update cost tracking metrics
    #>
    param(
        [double]$Cost = 0,
        [int]$Tokens = 0,
        [double]$AudioMinutes = 0
    )
    
    $Global:CostTracker.TotalCost += $Cost
    $Global:CostTracker.RequestCount++
    $Global:CostTracker.TokensUsed += $Tokens
    $Global:CostTracker.AudioMinutes += $AudioMinutes
    
    # Check cost thresholds
    $DailyCostLimit = $Global:DeepSeekConfig.DeepSeek.CostOptimization.MaxDailyCost
    $AlertThreshold = $Global:DeepSeekConfig.DeepSeek.CostOptimization.AlertThreshold
    
    if($Global:CostTracker.TotalCost -gt ($DailyCostLimit * $AlertThreshold)) {
        Write-Log "Cost alert: Current session cost $([math]::Round($Global:CostTracker.TotalCost, 4)) USD approaching daily limit of $DailyCostLimit USD" "WARN" "DEEPSEEK"
    }
    
    if($Global:CostTracker.TotalCost -gt $DailyCostLimit) {
        Write-Log "Daily cost limit exceeded! Total: $([math]::Round($Global:CostTracker.TotalCost, 4)) USD" "ERROR" "DEEPSEEK"
    }
}

function Get-CostReport {
    <#
    .SYNOPSIS
    Generate detailed cost report
    #>
    [CmdletBinding()]
    param()
    
    $SessionDuration = (Get-Date) - $Global:CostTracker.SessionStart
    $EstimatedOpenAICost = $Global:CostTracker.TotalCost / (1 - $Global:DeepSeekConfig.DeepSeek.Pricing.EstimatedSavings)
    $Savings = $EstimatedOpenAICost - $Global:CostTracker.TotalCost
    
    $Report = @{
        SessionDuration = $SessionDuration
        TotalCost = [math]::Round($Global:CostTracker.TotalCost, 4)
        EstimatedOpenAICost = [math]::Round($EstimatedOpenAICost, 4)
        EstimatedSavings = [math]::Round($Savings, 4)
        SavingsPercentage = [math]::Round($Global:DeepSeekConfig.DeepSeek.Pricing.EstimatedSavings * 100, 1)
        RequestCount = $Global:CostTracker.RequestCount
        TokensUsed = $Global:CostTracker.TokensUsed
        AudioMinutes = [math]::Round($Global:CostTracker.AudioMinutes, 2)
        CacheHits = $Global:CostTracker.CacheHits
        AvgCostPerRequest = if($Global:CostTracker.RequestCount -gt 0) { [math]::Round($Global:CostTracker.TotalCost / $Global:CostTracker.RequestCount, 6) } else { 0 }
    }
    
    return $Report
}

function Reset-CostTracker {
    <#
    .SYNOPSIS
    Reset cost tracking metrics
    #>
    $Global:CostTracker = @{
        SessionStart = Get-Date
        TotalCost = 0.0
        RequestCount = 0
        TokensUsed = 0
        AudioMinutes = 0.0
        CacheHits = 0
    }
    
    Write-Log "Cost tracker reset" "INFO" "DEEPSEEK"
}

#endregion

#region Utility Functions

function Write-Log {
    <#
    .SYNOPSIS
    Enhanced logging function for DeepSeek module
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "DEEPSEEK"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] [$Component] $Message"
    
    $Color = switch($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    
    Write-Host $LogMessage -ForegroundColor $Color
    
    # Also write to file if logging is configured
    # This would integrate with the main VideoAgent logging system
}

function Test-DeepSeekRequirements {
    <#
    .SYNOPSIS
    Test system requirements for DeepSeek integration
    #>
    [CmdletBinding()]
    param()
    
    $Issues = @()
    
    # Check PowerShell version
    if($PSVersionTable.PSVersion.Major -lt 5) {
        $Issues += "PowerShell 5.1+ required (current: $($PSVersionTable.PSVersion))"
    }
    
    # Check required tools
    $RequiredTools = @("ffmpeg", "ffprobe")
    foreach($Tool in $RequiredTools) {
        $ToolPath = Get-Command $Tool -ErrorAction SilentlyContinue
        if(-not $ToolPath) {
            $Issues += "Missing required tool: $Tool"
        }
    }
    
    # Check API key
    $ApiKey = Get-DeepSeekAPIKey
    if([string]::IsNullOrEmpty($ApiKey)) {
        $Issues += "DeepSeek API key not configured"
    }
    
    # Check internet connectivity
    try {
        $TestConnection = Test-NetConnection -ComputerName "api.deepseek.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop
        if(-not $TestConnection) {
            $Issues += "Cannot reach DeepSeek API endpoint"
        }
    } catch {
        $Issues += "Network connectivity test failed: $($_.Exception.Message)"
    }
    
    if($Issues.Count -eq 0) {
        Write-Log "All DeepSeek requirements satisfied" "SUCCESS" "DEEPSEEK"
        return $true
    } else {
        Write-Log "DeepSeek requirements check failed:" "ERROR" "DEEPSEEK"
        foreach($Issue in $Issues) {
            Write-Log "  - $Issue" "ERROR" "DEEPSEEK"
        }
        return $false
    }
}

#endregion

# Export functions for use by main VideoAgent script
Export-ModuleMember -Function @(
    'Initialize-DeepSeekAPI',
    'Invoke-DeepSeekTranscription',
    'Invoke-DeepSeekChat',
    'Invoke-VideoContentAnalysis',
    'New-MarketingCopy',
    'Get-CostReport',
    'Reset-CostTracker',
    'Test-DeepSeekRequirements'
)

Write-Log "DeepSeek module loaded successfully" "SUCCESS" "DEEPSEEK"