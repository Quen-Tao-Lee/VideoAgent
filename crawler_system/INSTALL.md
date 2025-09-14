# 智能爬虫系统安装指南

## 系统要求

- Python 3.8+
- 操作系统: Windows, macOS, Linux
- 内存: 至少 2GB RAM
- 存储空间: 至少 1GB 可用空间

## 快速安装

### 方法一: 自动安装（推荐）

```bash
cd crawler_system
python setup.py
```

### 方法二: 手动安装

1. **安装Python依赖**:
```bash
pip install -r requirements.txt
```

2. **测试系统**:
```bash
python test_system.py
```

3. **初始化配置**:
```bash
python -c "from config.settings import CrawlerConfig; CrawlerConfig()"
```

## 依赖说明

### 核心依赖（必需）
- `pyyaml` - 配置文件管理
- `loguru` - 日志系统
- `sqlalchemy` - 数据库ORM
- `pandas` - 数据处理
- `numpy` - 数值计算
- `matplotlib` - 基础可视化

### 爬虫依赖（推荐）
- `scrapy` - 爬虫框架
- `selenium` - 浏览器自动化
- `requests` - HTTP客户端
- `beautifulsoup4` - HTML解析
- `lxml` - XML/HTML解析器

### 文本处理依赖（推荐）
- `jieba` - 中文分词
- `snownlp` - 中文情感分析

### 反爬虫依赖（可选）
- `fake-useragent` - 用户代理轮换

### 可视化依赖（可选）
- `plotly` - 交互式图表
- `dash` - Web应用框架

## 常见问题

### Q: pip安装失败怎么办？
A: 尝试使用国内镜像:
```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### Q: 系统测试失败怎么办？
A: 
1. 检查Python版本是否 >= 3.8
2. 确保所有核心依赖都已安装
3. 检查系统权限，确保可以创建文件和目录

### Q: 数据库连接失败怎么办？
A: 
1. 系统默认使用SQLite，无需额外配置
2. 如需使用MySQL，请在配置文件中修改数据库设置
3. 确保有读写权限

### Q: 某些功能不可用怎么办？
A:
1. 某些功能需要可选依赖，请根据需要安装
2. 网络爬虫功能需要stable的网络连接
3. 部分功能可能需要特定的系统环境

## 验证安装

运行以下命令验证安装是否成功:

```bash
# 检查系统状态
python main.py --action status

# 运行系统测试
python test_system.py
```

如果看到 "🎉 所有测试通过！" 消息，说明安装成功。

## 下一步

安装完成后，请阅读 [README.md](README.md) 了解如何使用系统。