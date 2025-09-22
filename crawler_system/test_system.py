#!/usr/bin/env python3
"""
测试爬虫系统基本功能
Test basic crawler system functionality
"""

import sys
import os
from pathlib import Path

# 添加当前目录到Python路径
current_dir = Path(__file__).parent
sys.path.append(str(current_dir))

def test_config():
    """测试配置系统"""
    print("🔧 测试配置系统...")
    try:
        from config.settings import CrawlerConfig
        config = CrawlerConfig()
        
        print(f"  ✅ 配置加载成功")
        print(f"  📝 爬虫设置: {config.crawler_settings}")
        print(f"  🛒 电商设置: {config.ecommerce_settings}")
        print(f"  🗄️ 数据库设置: {config.database_settings}")
        
        return True
    except Exception as e:
        print(f"  ❌ 配置测试失败: {e}")
        return False

def test_database():
    """测试数据库系统"""
    print("\n🗄️ 测试数据库系统...")
    try:
        from config.database_config import DatabaseConfig
        from database.manager import DatabaseManager
        
        db_config = DatabaseConfig()
        
        # 创建数据库表
        print("  🔨 创建数据库表...")
        db_config.create_tables()
        
        db_manager = DatabaseManager(db_config)
        
        print(f"  ✅ 数据库连接成功")
        
        # 测试统计功能
        stats = db_manager.get_platform_statistics()
        print(f"  📊 平台统计: {stats}")
        
        return True
    except Exception as e:
        print(f"  ❌ 数据库测试失败: {e}")
        return False

def test_utilities():
    """测试工具模块"""
    print("\n🛠️ 测试工具模块...")
    
    # 测试日志系统
    try:
        from utils.logger import setup_logger
        logger = setup_logger()
        logger.info("日志系统测试成功")
        print("  ✅ 日志系统正常")
    except Exception as e:
        print(f"  ❌ 日志系统失败: {e}")
        return False
    
    # 测试用户代理
    try:
        from utils.user_agent import UserAgentRotator
        ua_rotator = UserAgentRotator()
        user_agent = ua_rotator.get_random_agent()
        print(f"  ✅ 用户代理系统正常: {user_agent[:50]}...")
    except Exception as e:
        print(f"  ❌ 用户代理系统失败: {e}")
        return False
    
    # 测试频率限制器
    try:
        from utils.rate_limiter import RateLimiter
        limiter = RateLimiter((0.1, 0.2))  # 快速测试
        limiter.wait()
        print("  ✅ 频率限制器正常")
    except Exception as e:
        print(f"  ❌ 频率限制器失败: {e}")
        return False
    
    # 测试文本处理器
    try:
        from utils.text_processor import TextProcessor
        processor = TextProcessor()
        test_text = "这是一个很好的产品，价格是99.99元"
        
        cleaned = processor.clean_text(test_text)
        sentiment = processor.analyze_sentiment(test_text)
        prices = processor.extract_price(test_text)
        
        print(f"  ✅ 文本处理器正常")
        print(f"    - 清理文本: {cleaned}")
        print(f"    - 情感分析: {sentiment}")
        print(f"    - 价格提取: {prices}")
    except Exception as e:
        print(f"  ❌ 文本处理器失败: {e}")
        return False
    
    return True

def test_analysis():
    """测试分析模块"""
    print("\n🧠 测试分析模块...")
    try:
        from analysis.sentiment_analyzer import SentimentAnalyzer
        from analysis.data_visualizer import DataVisualizer
        
        analyzer = SentimentAnalyzer()
        result = analyzer.analyze_text("这个产品很好用，我很喜欢")
        print(f"  ✅ 情感分析器正常: {result}")
        
        visualizer = DataVisualizer()
        print("  ✅ 数据可视化器正常")
        
        return True
    except Exception as e:
        print(f"  ❌ 分析模块失败: {e}")
        return False

def main():
    """主测试函数"""
    print("🚀 开始测试智能爬虫系统...\n")
    
    tests = [
        ("配置系统", test_config),
        ("数据库系统", test_database),
        ("工具模块", test_utilities),
        ("分析模块", test_analysis),
    ]
    
    passed = 0
    total = len(tests)
    
    for name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"❌ {name}测试异常: {e}")
    
    print(f"\n📊 测试结果: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！系统基本功能正常。")
        print("\n📋 系统功能概览:")
        print("  ✅ 配置管理 (YAML)")
        print("  ✅ 数据库管理 (SQLite/MySQL)")
        print("  ✅ 日志系统 (Loguru)")
        print("  ✅ 反爬虫机制 (代理、用户代理、频率限制)")
        print("  ✅ 文本处理 (清洗、情感分析、关键词提取)")
        print("  ✅ 数据分析 (情感分析、可视化)")
        print("\n🚀 可以开始使用爬虫系统了！")
        
        # 显示使用示例
        print("\n💡 使用示例:")
        print("  python main.py --action status")
        print("  python main.py --action ecommerce --platform taobao --keyword '手机' --pages 5")
        print("  python main.py --action report --report-type summary")
    else:
        print("⚠️ 部分测试失败，请检查相关模块。")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())