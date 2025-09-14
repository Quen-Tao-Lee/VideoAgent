#!/usr/bin/env python3
"""
智能爬虫系统安装脚本
Intelligent Crawler System Setup Script
"""

import os
import sys
import subprocess
from pathlib import Path


def install_dependencies():
    """安装依赖包"""
    print("📦 安装依赖包...")
    
    requirements = [
        # 核心依赖
        "pyyaml>=6.0.1",
        "loguru>=0.7.2", 
        "sqlalchemy>=2.0.0",
        "pandas>=2.1.0",
        "numpy>=1.24.0",
        "matplotlib>=3.7.0",
        
        # 网络爬虫依赖 (可选)
        "scrapy>=2.11.0",
        "selenium>=4.15.0", 
        "requests>=2.31.0",
        "beautifulsoup4>=4.12.0",
        "lxml>=4.9.0",
        
        # 文本处理依赖 (可选)
        "jieba>=0.42.1",
        "snownlp>=0.12.3",
        
        # 反爬虫依赖 (可选)
        "fake-useragent>=1.4.0",
        
        # 可视化依赖 (可选)
        "plotly>=5.17.0",
        "dash>=2.14.0",
        
        # 其他
        "pillow>=10.0.0",
        "aiofiles>=23.2.1",
    ]
    
    # 安装核心依赖
    core_deps = requirements[:6]
    print("🔧 安装核心依赖...")
    for dep in core_deps:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", dep])
            print(f"  ✅ {dep}")
        except subprocess.CalledProcessError:
            print(f"  ❌ {dep} - 安装失败，但系统可能仍能工作")
    
    # 安装可选依赖
    optional_deps = requirements[6:]
    print("\n🔧 安装可选依赖（失败不影响核心功能）...")
    for dep in optional_deps:
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", dep])
            print(f"  ✅ {dep}")
        except subprocess.CalledProcessError:
            print(f"  ⚠️ {dep} - 可选依赖安装失败")
    
    print("\n✅ 依赖安装完成！")


def setup_directories():
    """创建必要的目录"""
    print("\n📁 创建系统目录...")
    
    dirs = [
        "logs",
        "data", 
        "database",
        "reports",
        "temp"
    ]
    
    for dir_name in dirs:
        dir_path = Path(dir_name)
        dir_path.mkdir(exist_ok=True)
        print(f"  📂 {dir_name}/")
    
    print("✅ 目录创建完成！")


def setup_config():
    """初始化配置"""
    print("\n⚙️ 初始化配置...")
    
    try:
        from config.settings import CrawlerConfig
        config = CrawlerConfig()
        print("  ✅ 配置文件已生成")
        print(f"  📄 位置: {config.config_file}")
    except Exception as e:
        print(f"  ❌ 配置初始化失败: {e}")


def setup_database():
    """初始化数据库""" 
    print("\n🗄️ 初始化数据库...")
    
    try:
        from config.database_config import DatabaseConfig
        db_config = DatabaseConfig()
        db_config.create_tables()
        print("  ✅ 数据库表已创建")
        print(f"  📄 位置: {db_config.get_connection_string()}")
    except Exception as e:
        print(f"  ❌ 数据库初始化失败: {e}")


def run_tests():
    """运行系统测试"""
    print("\n🧪 运行系统测试...")
    
    try:
        result = subprocess.run([sys.executable, "test_system.py"], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("  ✅ 所有测试通过！")
            return True
        else:
            print("  ⚠️ 部分测试失败")
            print(result.stdout)
            return False
            
    except Exception as e:
        print(f"  ❌ 测试运行失败: {e}")
        return False


def main():
    """主安装函数"""
    print("🚀 智能爬虫系统安装程序")
    print("=" * 50)
    
    # 检查Python版本
    if sys.version_info < (3, 8):
        print("❌ 需要Python 3.8或更高版本")
        return 1
    
    print(f"✅ Python版本: {sys.version}")
    
    # 安装步骤
    steps = [
        ("安装依赖包", install_dependencies),
        ("创建目录", setup_directories), 
        ("初始化配置", setup_config),
        ("初始化数据库", setup_database),
        ("运行测试", run_tests),
    ]
    
    success_count = 0
    
    for step_name, step_func in steps:
        print(f"\n{'='*20} {step_name} {'='*20}")
        try:
            if step_func():
                success_count += 1
            elif step_name != "运行测试":  # 测试失败不算致命错误
                success_count += 1
        except Exception as e:
            print(f"❌ {step_name}失败: {e}")
    
    print("\n" + "="*50)
    
    if success_count >= 4:  # 至少4个步骤成功
        print("🎉 安装完成！")
        print("\n📋 使用指南:")
        print("  1. 查看系统状态:")
        print("     python main.py --action status")
        print("\n  2. 运行电商爬虫:")
        print("     python main.py --action ecommerce --platform taobao --keyword '数码产品' --pages 5")
        print("\n  3. 生成分析报告:")
        print("     python main.py --action report --report-type summary")
        print("\n  4. 查看配置文件:")
        print("     config/crawler_config.yaml")
        print("\n📚 更多信息请查看 README.md")
        
        return 0
    else:
        print("⚠️ 安装过程中遇到问题，请检查错误信息")
        return 1


if __name__ == "__main__":
    sys.exit(main())