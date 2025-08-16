# DeepSeek Integration Example Script
# 演示如何使用DeepSeek API进行视频AI处理
# 版本：1.0

param(
    [string]$VideoPath = "",
    [string]$ApiKey = "",
    [switch]$TestMode = $false
)

# 设置脚本根目录
$ScriptRoot = Split-Path $PSScriptRoot -Parent
$ModulePath = Join-Path $ScriptRoot "modules\DeepSeek.ps1"
$ConfigPath = Join-Path $ScriptRoot "config\deepseek-config.json"

Write-Host "=== DeepSeek API集成示例 ===" -ForegroundColor Cyan
Write-Host "版本: 1.0" -ForegroundColor Gray
Write-Host "功能: 视频AI处理演示" -ForegroundColor Gray
Write-Host ""

# 检查环境
if(-not (Test-Path $ModulePath)) {
    Write-Error "DeepSeek模块未找到: $ModulePath"
    exit 1
}

if(-not (Test-Path $ConfigPath)) {
    Write-Error "DeepSeek配置文件未找到: $ConfigPath"
    exit 1
}

# 导入模块
try {
    . $ModulePath
    Write-Host "✅ DeepSeek模块加载成功" -ForegroundColor Green
} catch {
    Write-Error "DeepSeek模块加载失败: $($_.Exception.Message)"
    exit 1
}

# 加载配置
try {
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    Write-Host "✅ 配置文件加载成功" -ForegroundColor Green
} catch {
    Write-Error "配置文件加载失败: $($_.Exception.Message)"
    exit 1
}

# 设置API密钥
if([string]::IsNullOrWhiteSpace($ApiKey)) {
    if([string]::IsNullOrWhiteSpace($env:DEEPSEEK_API_KEY)) {
        $ApiKey = Read-Host "请输入DeepSeek API Key"
        if([string]::IsNullOrWhiteSpace($ApiKey)) {
            Write-Error "API Key是必需的"
            exit 1
        }
        $env:DEEPSEEK_API_KEY = $ApiKey
    } else {
        $ApiKey = $env:DEEPSEEK_API_KEY
    }
}

# 初始化DeepSeek客户端
try {
    $client = [DeepSeekClient]::new($ApiKey)
    Write-Host "✅ DeepSeek客户端初始化成功" -ForegroundColor Green
} catch {
    Write-Error "DeepSeek客户端初始化失败: $($_.Exception.Message)"
    exit 1
}

# 测试模式
if($TestMode) {
    Write-Host "`n=== 测试模式 ===" -ForegroundColor Yellow
    
    # 测试文本生成
    Write-Host "测试文本生成功能..." -ForegroundColor Cyan
    try {
        $testPrompt = "请用一句话介绍DeepSeek AI"
        $response = $client.ChatCompletion($testPrompt, "deepseek-chat", @{max_tokens=100; temperature=0.7})
        Write-Host "✅ 文本生成测试成功" -ForegroundColor Green
        Write-Host "响应: $($response.choices[0].message.content)" -ForegroundColor White
    } catch {
        Write-Host "❌ 文本生成测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 测试内容分析
    Write-Host "`n测试内容分析功能..." -ForegroundColor Cyan
    try {
        $testTranscript = "今天我们来讲解一下人工智能的发展历程。人工智能是一个非常重要的技术领域。"
        $analysis = Invoke-DeepSeekContentAnalysis $testTranscript "test.mp4" $client
        if($analysis) {
            Write-Host "✅ 内容分析测试成功" -ForegroundColor Green
            Write-Host "分析结果: $($analysis | ConvertTo-Json -Depth 2)" -ForegroundColor White
        }
    } catch {
        Write-Host "❌ 内容分析测试失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n测试完成!" -ForegroundColor Green
    return
}

# 视频处理模式
if([string]::IsNullOrWhiteSpace($VideoPath)) {
    $VideoPath = Read-Host "请输入视频文件路径"
}

if(-not (Test-Path $VideoPath)) {
    Write-Error "视频文件未找到: $VideoPath"
    exit 1
}

Write-Host "`n=== 开始视频AI处理 ===" -ForegroundColor Yellow
Write-Host "视频文件: $VideoPath" -ForegroundColor Gray

$outputDir = Split-Path $VideoPath -Parent
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($VideoPath)
$startTime = Get-Date

try {
    # 1. 音频提取和转录
    Write-Host "`n📝 步骤1: 音频转录" -ForegroundColor Cyan
    $audioFile = Join-Path $outputDir "$fileName`_audio.wav"
    
    # 提取音频（需要ffmpeg）
    $extractCmd = "ffmpeg -i `"$VideoPath`" -vn -acodec pcm_s16le -ar 16000 -ac 1 `"$audioFile`" -y"
    Write-Host "提取音频: $extractCmd" -ForegroundColor Gray
    
    $process = Start-Process -FilePath "cmd" -ArgumentList "/c $extractCmd" -Wait -PassThru -NoNewWindow
    if($process.ExitCode -eq 0 -and (Test-Path $audioFile)) {
        Write-Host "✅ 音频提取成功" -ForegroundColor Green
        
        # 调用转录API
        try {
            $transcriptResult = $client.AudioTranscription($audioFile, @{language="auto"})
            $srtFile = Join-Path $outputDir "$fileName.srt"
            $transcriptResult | Out-File -FilePath $srtFile -Encoding UTF8
            Write-Host "✅ 转录完成，保存到: $srtFile" -ForegroundColor Green
            
            # 转换为纯文本
            $transcript = $transcriptResult -replace '\d+\r?\n', '' -replace '\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}\r?\n', ''
            $transcript = ($transcript -split '\r?\n' | Where-Object {$_.Trim() -ne ''}) -join ' '
            
        } catch {
            Write-Host "❌ 转录失败: $($_.Exception.Message)" -ForegroundColor Red
            $transcript = ""
        }
        
        # 清理音频文件
        Remove-Item $audioFile -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "❌ 音频提取失败" -ForegroundColor Red
        $transcript = ""
    }
    
    # 2. 内容分析
    if(-not [string]::IsNullOrWhiteSpace($transcript)) {
        Write-Host "`n🔍 步骤2: 内容分析" -ForegroundColor Cyan
        try {
            $analysis = Invoke-DeepSeekContentAnalysis $transcript $VideoPath $client
            if($analysis) {
                $analysisFile = Join-Path $outputDir "$fileName.analysis.json"
                $analysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $analysisFile -Encoding UTF8
                Write-Host "✅ 内容分析完成，保存到: $analysisFile" -ForegroundColor Green
                
                # 显示关键信息
                Write-Host "   建议标题: $($analysis.title_suggestions -join ', ')" -ForegroundColor White
                Write-Host "   内容类型: $($analysis.content_type)" -ForegroundColor White
                Write-Host "   情感倾向: $($analysis.sentiment)" -ForegroundColor White
            }
        } catch {
            Write-Host "❌ 内容分析失败: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # 3. 营销文案生成
        if($analysis) {
            Write-Host "`n📱 步骤3: 营销文案生成" -ForegroundColor Cyan
            $platforms = @("youtube", "tiktok", "bilibili")
            $marketingContent = @{}
            
            foreach($platform in $platforms) {
                try {
                    $content = New-DeepSeekMarketingContent $analysis $platform $client
                    $marketingContent[$platform] = $content
                    Write-Host "✅ $platform 文案生成完成" -ForegroundColor Green
                } catch {
                    Write-Host "❌ $platform 文案生成失败: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
            
            if($marketingContent.Count -gt 0) {
                $marketingFile = Join-Path $outputDir "$fileName.marketing.txt"
                $output = ""
                foreach($platform in $marketingContent.Keys) {
                    $output += "=== $platform 营销文案 ===`r`n"
                    $output += "$($marketingContent[$platform])`r`n`r`n"
                }
                $output | Out-File -FilePath $marketingFile -Encoding UTF8
                Write-Host "✅ 营销文案保存到: $marketingFile" -ForegroundColor Green
            }
            
            # 4. SEO关键词生成
            Write-Host "`n🔍 步骤4: SEO关键词生成" -ForegroundColor Cyan
            try {
                $seoKeywords = New-DeepSeekSEOKeywords $analysis $client
                $seoFile = Join-Path $outputDir "$fileName.keywords.txt"
                $seoKeywords | Out-File -FilePath $seoFile -Encoding UTF8
                Write-Host "✅ SEO关键词保存到: $seoFile" -ForegroundColor Green
            } catch {
                Write-Host "❌ SEO关键词生成失败: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # 完成
    $processingTime = (Get-Date) - $startTime
    Write-Host "`n🎉 处理完成!" -ForegroundColor Green
    Write-Host "总耗时: $($processingTime.TotalMinutes.ToString('F1')) 分钟" -ForegroundColor White
    Write-Host "输出目录: $outputDir" -ForegroundColor White
    
} catch {
    Write-Host "`n❌ 处理失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")