# DeepSeek API集成文档

## 📋 概述

VideoAgent现已完全集成DeepSeek API，提供高性价比的AI视频处理能力。相比OpenAI，成本降低95%，同时提供强大的中文内容理解和生成能力。

## 🚀 核心功能

### 1. 语音转文字 (Audio Transcription)
- 支持多种视频格式自动提取音频
- 使用DeepSeek Whisper-1模型进行转录
- 自动生成SRT字幕文件
- 支持多语言识别

### 2. 智能内容分析 (Content Analysis)
- 分析视频转录文本
- 生成标题建议、描述、标签
- 识别关键话题和目标受众
- 情感分析和内容分类

### 3. 营销文案生成 (Marketing Content)
- 针对不同平台生成定制化文案
- 支持YouTube、TikTok、Bilibili等平台
- 自动生成吸引人的标题和描述
- 提供发布策略建议

### 4. SEO优化 (SEO Optimization)
- 生成主要关键词和长尾关键词
- 提供话题标签建议
- 搜索意图分析
- 竞争度评估

### 5. 字幕优化 (Subtitle Enhancement)
- 优化原始转录文本
- 改善语法和标点符号
- 提高可读性和流畅度
- 保持时间轴同步

## 📁 文件结构

```
VideoBot/
├── modules/
│   └── DeepSeek.ps1              # DeepSeek API模块
├── config/
│   ├── deepseek-config.json      # DeepSeek配置文件
│   └── settings.json             # 主配置文件（已更新）
├── agent/
│   └── VideoAgent_Ultimate.ps1   # 主处理脚本（已增强）
├── examples/
│   └── deepseek-example.ps1      # 使用示例
└── docs/
    └── DeepSeek-Integration.md    # 本文档
```

## ⚙️ 配置指南

### 1. 环境变量设置

设置DeepSeek API密钥：
```powershell
$env:DEEPSEEK_API_KEY = "your-deepseek-api-key-here"
```

或在Windows系统环境变量中设置：
```
DEEPSEEK_API_KEY=your-deepseek-api-key-here
```

### 2. 配置文件说明

#### deepseek-config.json
```json
{
    "deepseek": {
        "api_base_url": "https://api.deepseek.com/v1",
        "models": {
            "chat": "deepseek-chat",
            "coder": "deepseek-coder",
            "transcription": "whisper-1"
        },
        "features": {
            "audio_transcription": true,
            "content_analysis": true,
            "marketing_generation": true,
            "seo_optimization": true,
            "subtitle_optimization": true
        }
    }
}
```

#### settings.json (AI部分)
```json
{
    "AI": {
        "Provider": "deepseek",
        "EnableContentAnalysis": true,
        "EnableMarketingGeneration": true,
        "EnableSEOOptimization": true,
        "EnableSubtitleOptimization": true
    }
}
```

## 🔧 使用方法

### 1. 基础使用

启动VideoAgent Ultimate：
```powershell
.\VideoAgent_Ultimate.ps1
```

VideoAgent会自动检测DeepSeek配置，如果配置正确，将显示：
```
🤖 DeepSeek AI Ready - Enhanced features enabled
```

### 2. 手动测试

运行示例脚本进行测试：
```powershell
.\examples\deepseek-example.ps1 -TestMode
```

处理特定视频文件：
```powershell
.\examples\deepseek-example.ps1 -VideoPath "C:\path\to\video.mp4"
```

### 3. API直接调用

```powershell
# 导入模块
. .\modules\DeepSeek.ps1

# 创建客户端
$client = [DeepSeekClient]::new($env:DEEPSEEK_API_KEY)

# 文本生成
$response = $client.ChatCompletion("生成一个视频标题", "deepseek-chat")

# 音频转录
$transcript = $client.AudioTranscription("audio.wav")
```

## 📊 输出文件

处理完成后，会在输出目录生成以下文件：

1. **video.mp4** - 处理后的视频文件
2. **video.srt** - 自动生成的字幕文件
3. **video.analysis.json** - 内容分析报告
4. **video.marketing.txt** - 营销文案合集
5. **video.keywords.txt** - SEO关键词列表
6. **video.optimized.srt** - 优化后的字幕文件

### 示例输出

#### analysis.json
```json
{
    "title_suggestions": [
        "AI技术发展趋势分析",
        "人工智能的未来展望",
        "深度解析AI技术革命"
    ],
    "description": "本视频深入分析了人工智能技术的发展历程和未来趋势...",
    "tags": ["人工智能", "AI技术", "科技发展", "机器学习", "深度学习"],
    "category": "教育",
    "sentiment": "positive",
    "target_audience": "科技爱好者和专业人士"
}
```

#### marketing.txt
```
=== youtube 营销文案 ===
🤖 AI技术大揭秘！未来已来，你准备好了吗？

本期视频为您深度解析人工智能技术发展趋势，从基础概念到前沿应用，全方位展示AI技术的强大潜力。

#人工智能 #AI技术 #科技前沿 #机器学习 #深度学习

=== tiktok 营销文案 ===
🔥AI技术3分钟速懂！
💡 从零基础到专业认知
🚀 未来科技趋势预测

#AI #人工智能 #科技 #学习 #知识分享
```

## 💰 成本优势

### DeepSeek vs OpenAI 定价对比

| 功能 | DeepSeek | OpenAI | 节省 |
|------|----------|--------|------|
| 文本生成 | $0.14/1K tokens | $20/1K tokens | 95% |
| 音频转录 | $0.006/分钟 | $0.006/分钟 | 持平 |
| 总体成本 | 极低 | 高 | 95% |

### 成本监控

系统会自动记录API调用成本：
```json
{
    "InputTokens": 1500,
    "OutputTokens": 800,
    "TotalCost": 0.0032,
    "Currency": "USD",
    "Model": "deepseek-chat"
}
```

## 🔍 故障排除

### 常见问题

1. **DeepSeek客户端初始化失败**
   - 检查API密钥是否正确设置
   - 确认网络连接正常
   - 验证API密钥有效性

2. **转录功能不工作**
   - 确保ffmpeg已安装并在PATH中
   - 检查视频文件是否包含音频
   - 验证音频文件大小不超过25MB

3. **内容分析返回空结果**
   - 确认转录文本不为空
   - 检查DeepSeek API配额
   - 验证网络连接稳定性

### 日志调试

启用详细日志：
```powershell
$Global:CFG.LOG_LEVEL = "DEBUG"
```

查看日志文件：
```
C:\VideoBot\logs\agent_20241201.log
C:\VideoBot\logs\enhanced_stats_202412.jsonl
```

## 🔄 更新和维护

### 配置更新
- 定期检查DeepSeek API文档获取最新特性
- 根据需要调整模型参数和成本限制
- 更新营销文案模板以适应平台变化

### 性能优化
- 监控API调用响应时间
- 调整批处理策略
- 优化缓存机制

## 📞 技术支持

如遇到技术问题，请：

1. 查看日志文件确定具体错误
2. 检查网络连接和API配额
3. 参考示例脚本进行测试
4. 联系开发团队获取支持

---

**版本：** 1.0  
**更新日期：** 2024-12-01  
**作者：** VideoAgent Team  
**用户：** Quen-Tao-Lee