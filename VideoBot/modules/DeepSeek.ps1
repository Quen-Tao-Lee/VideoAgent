# DeepSeek API Integration Module
# 功能：语音转文字、智能内容分析、营销文案生成
# 版本：1.0
# 作者：VideoAgent Team

# DeepSeek API客户端类
class DeepSeekClient {
    [string]$ApiKey
    [string]$BaseUrl
    [hashtable]$DefaultHeaders
    [int]$MaxRetries
    [int]$RetryDelay
    
    DeepSeekClient([string]$apiKey) {
        $this.ApiKey = $apiKey
        $this.BaseUrl = "https://api.deepseek.com/v1"
        $this.MaxRetries = 3
        $this.RetryDelay = 1000
        $this.DefaultHeaders = @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        }
    }
    
    # 文本生成（聊天补全）
    [object] ChatCompletion([string]$prompt, [string]$model = "deepseek-chat", [hashtable]$options = @{}) {
        $requestBody = @{
            model = $model
            messages = @(
                @{
                    role = "user"
                    content = $prompt
                }
            )
            max_tokens = if($options.max_tokens) { $options.max_tokens } else { 2000 }
            temperature = if($options.temperature) { $options.temperature } else { 0.7 }
            stream = $false
        }
        
        return $this.MakeRequest("chat/completions", $requestBody)
    }
    
    # 语音转文字
    [object] AudioTranscription([string]$audioFilePath, [hashtable]$options = @{}) {
        if(-not (Test-Path $audioFilePath)) {
            throw "Audio file not found: $audioFilePath"
        }
        
        $boundary = [System.Guid]::NewGuid().ToString()
        $audioBytes = [System.IO.File]::ReadAllBytes($audioFilePath)
        
        # 构建multipart请求体
        $bodyStart = "--$boundary`r`n" +
                    "Content-Disposition: form-data; name=`"file`"; filename=`"audio.wav`"`r`n" +
                    "Content-Type: audio/wav`r`n`r`n"
        
        $bodyEnd = "`r`n--$boundary`r`n" +
                  "Content-Disposition: form-data; name=`"model`"`r`n`r`n" +
                  "whisper-1`r`n" +
                  "--$boundary`r`n" +
                  "Content-Disposition: form-data; name=`"response_format`"`r`n`r`n" +
                  "srt`r`n"
        
        if($options.language -and $options.language -ne "auto") {
            $bodyEnd += "--$boundary`r`n" +
                       "Content-Disposition: form-data; name=`"language`"`r`n`r`n" +
                       "$($options.language)`r`n"
        }
        
        $bodyEnd += "--$boundary--`r`n"
        
        $bodyStartBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyStart)
        $bodyEndBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyEnd)
        
        # 合并请求体
        $fullBodyLength = $bodyStartBytes.Length + $audioBytes.Length + $bodyEndBytes.Length
        $fullBody = New-Object byte[] $fullBodyLength
        
        [Array]::Copy($bodyStartBytes, 0, $fullBody, 0, $bodyStartBytes.Length)
        [Array]::Copy($audioBytes, 0, $fullBody, $bodyStartBytes.Length, $audioBytes.Length)
        [Array]::Copy($bodyEndBytes, 0, $fullBody, $bodyStartBytes.Length + $audioBytes.Length, $bodyEndBytes.Length)
        
        $headers = @{
            "Authorization" = "Bearer $($this.ApiKey)"
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        
        return $this.MakeRawRequest("audio/transcriptions", $fullBody, $headers)
    }
    
    # 通用API请求方法
    [object] MakeRequest([string]$endpoint, [object]$requestBody) {
        $uri = "$($this.BaseUrl)/$endpoint"
        $jsonBody = $requestBody | ConvertTo-Json -Depth 10
        
        for($attempt = 1; $attempt -le $this.MaxRetries; $attempt++) {
            try {
                Write-Host "DeepSeek API Request to $endpoint (Attempt $attempt/$($this.MaxRetries))" -ForegroundColor Cyan
                
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $this.DefaultHeaders -Body $jsonBody
                
                Write-Host "✅ DeepSeek API Request successful" -ForegroundColor Green
                return $response
                
            } catch {
                $errorMessage = $_.Exception.Message
                Write-Host "❌ DeepSeek API Request failed (Attempt $attempt): $errorMessage" -ForegroundColor Red
                
                if($attempt -eq $this.MaxRetries) {
                    throw "DeepSeek API request failed after $($this.MaxRetries) attempts: $errorMessage"
                }
                
                Start-Sleep -Milliseconds $this.RetryDelay
                $this.RetryDelay *= 2  # 指数退避
            }
        }
    }
    
    # 原始请求方法（用于文件上传）
    [object] MakeRawRequest([string]$endpoint, [byte[]]$body, [hashtable]$headers) {
        $uri = "$($this.BaseUrl)/$endpoint"
        
        for($attempt = 1; $attempt -le $this.MaxRetries; $attempt++) {
            try {
                Write-Host "DeepSeek API Raw Request to $endpoint (Attempt $attempt/$($this.MaxRetries))" -ForegroundColor Cyan
                
                $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
                
                Write-Host "✅ DeepSeek API Raw Request successful" -ForegroundColor Green
                return $response
                
            } catch {
                $errorMessage = $_.Exception.Message
                Write-Host "❌ DeepSeek API Raw Request failed (Attempt $attempt): $errorMessage" -ForegroundColor Red
                
                if($attempt -eq $this.MaxRetries) {
                    throw "DeepSeek API raw request failed after $($this.MaxRetries) attempts: $errorMessage"
                }
                
                Start-Sleep -Milliseconds $this.RetryDelay
                $this.RetryDelay *= 2
            }
        }
    }
}

# 智能内容分析功能
function Invoke-DeepSeekContentAnalysis {
    param(
        [string]$TranscriptText,
        [string]$VideoPath,
        [object]$DeepSeekClient
    )
    
    $analysisPrompt = @"
请分析以下视频转录文本，生成详细的内容分析报告。请用JSON格式返回结果，包含以下字段：

转录文本：
$TranscriptText

请分析并返回：
{
    "title_suggestions": ["建议标题1", "建议标题2", "建议标题3"],
    "description": "视频描述文本",
    "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"],
    "category": "视频分类",
    "key_topics": ["主要话题1", "主要话题2", "主要话题3"],
    "sentiment": "positive|neutral|negative",
    "language_detected": "语言代码",
    "summary": "视频内容摘要",
    "target_audience": "目标受众描述",
    "content_type": "教育|娱乐|新闻|营销|其他"
}

只返回JSON，不要其他文本。
"@
    
    try {
        $response = $DeepSeekClient.ChatCompletion($analysisPrompt, "deepseek-chat", @{
            max_tokens = 1500
            temperature = 0.3
        })
        
        $analysisContent = $response.choices[0].message.content
        
        # 尝试解析JSON
        try {
            $analysisJson = $analysisContent | ConvertFrom-Json
            return $analysisJson
        } catch {
            # 如果JSON解析失败，返回基础分析
            Write-Warning "Failed to parse analysis JSON, returning basic analysis"
            return @{
                title_suggestions = @("AI Generated Title")
                description = "AI generated video description"
                tags = @("video", "ai", "content")
                category = "General"
                key_topics = @("Video Content")
                sentiment = "neutral"
                language_detected = "auto"
                summary = $analysisContent
                target_audience = "General audience"
                content_type = "其他"
            }
        }
        
    } catch {
        Write-Error "Content analysis failed: $($_.Exception.Message)"
        return $null
    }
}

# 营销文案生成
function New-DeepSeekMarketingContent {
    param(
        [object]$ContentAnalysis,
        [string]$Platform = "general",
        [object]$DeepSeekClient
    )
    
    $marketingPrompt = @"
基于以下视频内容分析，为 $Platform 平台生成营销文案：

视频分析：
标题建议：$($ContentAnalysis.title_suggestions -join ', ')
描述：$($ContentAnalysis.description)
标签：$($ContentAnalysis.tags -join ', ')
关键话题：$($ContentAnalysis.key_topics -join ', ')
目标受众：$($ContentAnalysis.target_audience)

请生成适合 $Platform 平台的营销文案，包括：
1. 吸引人的标题（3个选项）
2. 描述文本（适合平台特点）
3. 话题标签（相关热门标签）
4. 发布最佳时间建议
5. 互动策略建议

请用简洁明了的中文回复。
"@
    
    try {
        $response = $DeepSeekClient.ChatCompletion($marketingPrompt, "deepseek-chat", @{
            max_tokens = 1000
            temperature = 0.8
        })
        
        return $response.choices[0].message.content
        
    } catch {
        Write-Error "Marketing content generation failed: $($_.Exception.Message)"
        return "营销文案生成失败，请检查API配置。"
    }
}

# SEO关键词生成
function New-DeepSeekSEOKeywords {
    param(
        [object]$ContentAnalysis,
        [object]$DeepSeekClient
    )
    
    $seoPrompt = @"
基于以下视频内容分析，生成SEO优化关键词列表：

内容摘要：$($ContentAnalysis.summary)
主要话题：$($ContentAnalysis.key_topics -join ', ')
目标受众：$($ContentAnalysis.target_audience)
内容类型：$($ContentAnalysis.content_type)

请生成：
1. 主要关键词（5-8个）
2. 长尾关键词（8-12个）
3. 相关话题标签（10-15个）
4. 搜索意图分析
5. 竞争度评估建议

请用结构化格式返回，每行一个关键词或建议。
"@
    
    try {
        $response = $DeepSeekClient.ChatCompletion($seoPrompt, "deepseek-chat", @{
            max_tokens = 800
            temperature = 0.5
        })
        
        return $response.choices[0].message.content
        
    } catch {
        Write-Error "SEO keywords generation failed: $($_.Exception.Message)"
        return "SEO关键词生成失败，请检查API配置。"
    }
}

# 字幕优化
function Optimize-DeepSeekSubtitles {
    param(
        [string]$OriginalSRT,
        [object]$DeepSeekClient
    )
    
    $optimizePrompt = @"
请优化以下SRT字幕文件，提高可读性和准确性：

原始字幕：
$OriginalSRT

优化要求：
1. 修正语法和标点符号
2. 改善句子结构和流畅度
3. 保持时间轴不变
4. 确保字幕长度适中
5. 修正可能的语音识别错误

请返回优化后的SRT格式字幕。
"@
    
    try {
        $response = $DeepSeekClient.ChatCompletion($optimizePrompt, "deepseek-chat", @{
            max_tokens = 2000
            temperature = 0.3
        })
        
        return $response.choices[0].message.content
        
    } catch {
        Write-Error "Subtitle optimization failed: $($_.Exception.Message)"
        return $OriginalSRT  # 返回原始字幕作为后备
    }
}

# 成本估算和监控
function Get-DeepSeekCostEstimate {
    param(
        [int]$InputTokens,
        [int]$OutputTokens,
        [string]$Model = "deepseek-chat"
    )
    
    # DeepSeek定价（示例，实际价格请参考官方文档）
    $pricing = @{
        "deepseek-chat" = @{
            input = 0.00014   # 每1K tokens
            output = 0.00028  # 每1K tokens
        }
        "deepseek-coder" = @{
            input = 0.00014
            output = 0.00028
        }
        "whisper-1" = @{
            audio = 0.006     # 每分钟
        }
    }
    
    if($pricing.ContainsKey($Model)) {
        $modelPricing = $pricing[$Model]
        $inputCost = ($InputTokens / 1000) * $modelPricing.input
        $outputCost = ($OutputTokens / 1000) * $modelPricing.output
        $totalCost = $inputCost + $outputCost
        
        return @{
            InputTokens = $InputTokens
            OutputTokens = $OutputTokens
            InputCost = $inputCost
            OutputCost = $outputCost
            TotalCost = $totalCost
            Currency = "USD"
            Model = $Model
        }
    } else {
        return @{
            Error = "Unknown model: $Model"
        }
    }
}

# 导出模块函数
Export-ModuleMember -Function @(
    'Invoke-DeepSeekContentAnalysis',
    'New-DeepSeekMarketingContent', 
    'New-DeepSeekSEOKeywords',
    'Optimize-DeepSeekSubtitles',
    'Get-DeepSeekCostEstimate'
) -Variable @() -Cmdlet @() -Alias @()