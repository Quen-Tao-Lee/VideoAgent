# DeepSeek Integration Test Script
# 验证DeepSeek API集成是否正常工作

param(
    [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [switch]$QuickTest = $false
)

Write-Host "=== DeepSeek Integration Test ===" -ForegroundColor Cyan
Write-Host "Testing VideoAgent DeepSeek Integration" -ForegroundColor Gray
Write-Host ""

# Test 1: Module Loading
Write-Host "🔧 Test 1: Module Loading" -ForegroundColor Yellow
$ModulePath = Join-Path $PSScriptRoot "..\modules\DeepSeek.ps1"
try {
    if(Test-Path $ModulePath) {
        . $ModulePath
        Write-Host "✅ DeepSeek module loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ DeepSeek module not found: $ModulePath" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Failed to load DeepSeek module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Configuration Loading
Write-Host "`n🔧 Test 2: Configuration Loading" -ForegroundColor Yellow
$ConfigPath = Join-Path $PSScriptRoot "..\config\deepseek-config.json"
try {
    if(Test-Path $ConfigPath) {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "✅ Configuration loaded successfully" -ForegroundColor Green
        Write-Host "   API Base URL: $($config.deepseek.api_base_url)" -ForegroundColor Gray
        Write-Host "   Features enabled: $($config.deepseek.features | ConvertTo-Json -Compress)" -ForegroundColor Gray
    } else {
        Write-Host "❌ Configuration file not found: $ConfigPath" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to load configuration: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: API Key Check
Write-Host "`n🔧 Test 3: API Key Validation" -ForegroundColor Yellow
if([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "❌ DeepSeek API Key not provided" -ForegroundColor Red
    Write-Host "   Set environment variable: `$env:DEEPSEEK_API_KEY = 'your-key'" -ForegroundColor Gray
    Write-Host "   Or pass as parameter: -ApiKey 'your-key'" -ForegroundColor Gray
    if(-not $QuickTest) {
        exit 1
    }
} else {
    Write-Host "✅ API Key found (${($ApiKey.Substring(0, [Math]::Min(8, $ApiKey.Length)))}...)" -ForegroundColor Green
}

if(-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    # Test 4: Client Initialization
    Write-Host "`n🔧 Test 4: Client Initialization" -ForegroundColor Yellow
    try {
        $client = [DeepSeekClient]::new($ApiKey)
        Write-Host "✅ DeepSeek client initialized successfully" -ForegroundColor Green
        Write-Host "   Base URL: $($client.BaseUrl)" -ForegroundColor Gray
        Write-Host "   Max Retries: $($client.MaxRetries)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Failed to initialize client: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    if(-not $QuickTest) {
        # Test 5: API Connectivity
        Write-Host "`n🔧 Test 5: API Connectivity Test" -ForegroundColor Yellow
        try {
            $testPrompt = "Hello! Please respond with just 'Connection successful'"
            $response = $client.ChatCompletion($testPrompt, "deepseek-chat", @{max_tokens=10; temperature=0})
            Write-Host "✅ API connectivity test successful" -ForegroundColor Green
            Write-Host "   Response: $($response.choices[0].message.content)" -ForegroundColor Gray
        } catch {
            Write-Host "❌ API connectivity test failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "   This might be due to network issues or invalid API key" -ForegroundColor Gray
        }

        # Test 6: Function Testing
        Write-Host "`n🔧 Test 6: Function Testing" -ForegroundColor Yellow
        
        # Test content analysis function
        try {
            $testTranscript = "这是一个关于人工智能发展的视频，介绍了机器学习和深度学习的基本概念。"
            Write-Host "   Testing content analysis..." -ForegroundColor Gray
            $analysis = Invoke-DeepSeekContentAnalysis $testTranscript "test.mp4" $client
            if($analysis) {
                Write-Host "   ✅ Content analysis function works" -ForegroundColor Green
                Write-Host "   Sample title: $($analysis.title_suggestions[0])" -ForegroundColor Gray
            } else {
                Write-Host "   ❌ Content analysis returned null" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ❌ Content analysis test failed: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Test marketing content generation
        try {
            if($analysis) {
                Write-Host "   Testing marketing content generation..." -ForegroundColor Gray
                $marketing = New-DeepSeekMarketingContent $analysis "youtube" $client
                if($marketing -and $marketing.Length -gt 0) {
                    Write-Host "   ✅ Marketing content generation works" -ForegroundColor Green
                    $preview = if($marketing.Length -gt 100) { $marketing.Substring(0, 100) + "..." } else { $marketing }
                    Write-Host "   Preview: $preview" -ForegroundColor Gray
                } else {
                    Write-Host "   ❌ Marketing content generation returned empty" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "   ❌ Marketing content test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Test 7: File Structure Validation
Write-Host "`n🔧 Test 7: File Structure Validation" -ForegroundColor Yellow
$requiredFiles = @(
    "modules\DeepSeek.ps1",
    "config\deepseek-config.json",
    "docs\DeepSeek-Integration.md",
    "examples\deepseek-example.ps1"
)

$missingFiles = @()
foreach($file in $requiredFiles) {
    $fullPath = Join-Path $PSScriptRoot "..\$file"
    if(Test-Path $fullPath) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file missing" -ForegroundColor Red
        $missingFiles += $file
    }
}

if($missingFiles.Count -eq 0) {
    Write-Host "✅ All required files present" -ForegroundColor Green
} else {
    Write-Host "❌ Missing $($missingFiles.Count) required files" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
if([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "⚠️  Limited testing due to missing API key" -ForegroundColor Yellow
    Write-Host "💡 Tip: Set `$env:DEEPSEEK_API_KEY to run full tests" -ForegroundColor Cyan
} elseif($QuickTest) {
    Write-Host "✅ Quick test completed - basic integration verified" -ForegroundColor Green
} else {
    Write-Host "✅ Full integration test completed" -ForegroundColor Green
}

Write-Host "`n📚 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set DeepSeek API key in environment variables" -ForegroundColor White
Write-Host "2. Run VideoAgent_Ultimate.ps1 to test full integration" -ForegroundColor White
Write-Host "3. Process a test video to verify AI features" -ForegroundColor White
Write-Host "4. Check output files (.srt, .analysis.json, .marketing.txt)" -ForegroundColor White

Write-Host "`n📖 Documentation: docs\DeepSeek-Integration.md" -ForegroundColor Gray
Write-Host "🔧 Example usage: examples\deepseek-example.ps1" -ForegroundColor Gray