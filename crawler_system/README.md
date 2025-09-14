# 智能电商和社媒爬虫系统

## 项目概述

这是一个模块化的网络爬虫系统，支持电商平台商品信息抓取和社交媒体舆论分析。系统采用Python开发，具有以下特点：

- 🛒 **电商爬虫**: 支持淘宝、京东、天猫等主流电商平台
- 📱 **社媒爬虫**: 支持微博、知乎、小红书等社交媒体平台
- 🧠 **AI分析**: 集成情感分析和舆论趋势分析
- 📊 **数据可视化**: 自动生成分析报告和图表
- ⚡ **反爬虫**: 内置代理轮换、请求频率控制等反爬虫机制

## 功能特性

### 电商爬虫模块
- ✅ 商品信息提取（标题、价格、图片、描述、评价）
- ✅ 价格监控和变化追踪
- ✅ 销量和评分分析
- ✅ 店铺信息抓取

### 社媒舆论爬虫模块
- 🚧 关键词相关内容抓取
- 🚧 情感分析和舆论导向判断
- 🚧 真实用户评论筛选

### 数据处理和分析
- ✅ 数据清洗和去重
- ✅ 情感分析算法
- 🚧 舆论趋势分析
- 🚧 数据可视化报告

## 技术栈

- **语言**: Python 3.8+
- **爬虫框架**: Scrapy, Selenium, requests
- **数据处理**: pandas, numpy
- **数据库**: SQLite/MySQL
- **AI分析**: jieba, snownlp, transformers
- **可视化**: matplotlib, plotly, dash
- **反爬虫**: fake-useragent, 代理池管理

## 安装和使用

### 安装依赖

```bash
cd crawler_system
pip install -r requirements.txt
```

### 基本使用

1. **运行电商爬虫**:
```bash
python main.py --action ecommerce --platform taobao --keyword "数码产品" --pages 5
```

2. **查看系统状态**:
```bash
python main.py --action status
```

3. **生成分析报告**:
```bash
python main.py --action report --report-type summary
```

### 配置文件

系统使用YAML配置文件，首次运行会自动生成默认配置：

```yaml
crawler:
  user_agent: "Mozilla/5.0 ..."
  delay_range: [1, 3]
  timeout: 30
  retry_times: 3
  concurrent_requests: 8
  robots_txt_obey: true

ecommerce:
  enabled_platforms: ["taobao", "jd", "tmall"]
  max_pages: 10
  price_monitor: true
  review_limit: 100

database:
  type: "sqlite"
  path: "crawler_data.db"

logging:
  level: "INFO"
  file_path: "logs/crawler.log"
```

## 项目结构

```
crawler_system/
├── ecommerce/              # 电商爬虫模块
│   ├── spiders/           # 各平台爬虫
│   ├── items.py           # 数据结构定义
│   └── pipelines.py       # 数据处理管道
├── social_media/          # 社媒爬虫模块
│   └── platforms/         # 各平台爬虫
├── database/              # 数据库模块
│   ├── models.py          # 数据模型
│   └── manager.py         # 数据库管理
├── analysis/              # 数据分析模块
│   ├── sentiment_analyzer.py
│   └── data_visualizer.py
├── utils/                 # 工具函数
│   ├── logger.py
│   ├── rate_limiter.py
│   ├── user_agent.py
│   └── text_processor.py
├── config/                # 配置文件
│   └── settings.py
├── main.py               # 主程序入口
└── requirements.txt      # 依赖列表
```

## 合规性说明

本系统严格遵守以下原则：

1. **遵守robots.txt协议**
2. **合理请求频率控制**
3. **用户隐私保护**
4. **仅爬取公开可见数据**
5. **遵守平台服务条款**

## 开发状态

- ✅ **已完成**: 基础框架、电商爬虫（淘宝）、数据库管理、配置系统
- 🚧 **开发中**: 社媒爬虫、高级分析功能、可视化报告
- 📋 **计划中**: 更多平台支持、实时监控、Web界面

## 许可证

本项目仅用于学习和研究目的，请勿用于商业用途。使用时请遵守相关法律法规和平台服务条款。