"""
爬虫系统配置管理
Crawler System Configuration Management
"""

import os
import yaml
from typing import Dict, Any, Optional
from pathlib import Path


class CrawlerConfig:
    """
    爬虫系统配置类
    Crawler System Configuration Class
    """
    
    def __init__(self, config_file: Optional[str] = None):
        """
        初始化配置
        Initialize configuration
        
        Args:
            config_file: 配置文件路径 / Configuration file path
        """
        self.base_dir = Path(__file__).parent.parent
        self.config_file = config_file or self.base_dir / "config" / "crawler_config.yaml"
        self.config_data = {}
        self.load_config()
    
    def load_config(self):
        """加载配置文件 / Load configuration file"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    self.config_data = yaml.safe_load(f) or {}
            else:
                self.config_data = self.get_default_config()
                self.save_config()
        except Exception as e:
            print(f"配置文件加载失败，使用默认配置: {e}")
            self.config_data = self.get_default_config()
    
    def save_config(self):
        """保存配置文件 / Save configuration file"""
        try:
            os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
            with open(self.config_file, 'w', encoding='utf-8') as f:
                yaml.dump(self.config_data, f, default_flow_style=False, 
                         allow_unicode=True, indent=2)
        except Exception as e:
            print(f"配置文件保存失败: {e}")
    
    def get_default_config(self) -> Dict[str, Any]:
        """获取默认配置 / Get default configuration"""
        return {
            # 通用爬虫配置
            "crawler": {
                "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
                "delay_range": [1, 3],  # 请求间隔范围（秒）
                "timeout": 30,
                "retry_times": 3,
                "concurrent_requests": 8,
                "robots_txt_obey": True
            },
            
            # 电商爬虫配置
            "ecommerce": {
                "enabled_platforms": ["taobao", "jd", "tmall"],
                "max_pages": 10,
                "price_monitor": True,
                "review_limit": 100,
                "image_download": False
            },
            
            # 社媒爬虫配置
            "social_media": {
                "enabled_platforms": ["weibo", "zhihu", "xiaohongshu"],
                "max_posts": 500,
                "sentiment_analysis": True,
                "keyword_filtering": True,
                "authenticity_check": True
            },
            
            # 数据库配置
            "database": {
                "type": "sqlite",
                "path": "crawler_data.db",
                "backup_enabled": True,
                "retention_days": 30
            },
            
            # 代理配置
            "proxy": {
                "enabled": False,
                "proxy_list": [],
                "rotation_enabled": True
            },
            
            # 分析配置
            "analysis": {
                "sentiment_model": "snownlp",
                "visualization_enabled": True,
                "report_generation": True,
                "trend_analysis": True
            },
            
            # 日志配置
            "logging": {
                "level": "INFO",
                "file_path": "logs/crawler.log",
                "max_size": "100MB",
                "backup_count": 5
            }
        }
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        获取配置值
        Get configuration value
        
        Args:
            key: 配置键，支持点号分隔的嵌套键 / Configuration key with dot notation
            default: 默认值 / Default value
            
        Returns:
            配置值 / Configuration value
        """
        keys = key.split('.')
        value = self.config_data
        
        try:
            for k in keys:
                value = value[k]
            return value
        except (KeyError, TypeError):
            return default
    
    def set(self, key: str, value: Any):
        """
        设置配置值
        Set configuration value
        
        Args:
            key: 配置键 / Configuration key
            value: 配置值 / Configuration value
        """
        keys = key.split('.')
        config = self.config_data
        
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        
        config[keys[-1]] = value
        self.save_config()
    
    def update(self, config_dict: Dict[str, Any]):
        """
        批量更新配置
        Batch update configuration
        
        Args:
            config_dict: 配置字典 / Configuration dictionary
        """
        self.config_data.update(config_dict)
        self.save_config()
    
    @property
    def crawler_settings(self) -> Dict[str, Any]:
        """获取爬虫设置 / Get crawler settings"""
        return self.get("crawler", {})
    
    @property
    def ecommerce_settings(self) -> Dict[str, Any]:
        """获取电商爬虫设置 / Get e-commerce crawler settings"""
        return self.get("ecommerce", {})
    
    @property  
    def social_media_settings(self) -> Dict[str, Any]:
        """获取社媒爬虫设置 / Get social media crawler settings"""
        return self.get("social_media", {})
    
    @property
    def database_settings(self) -> Dict[str, Any]:
        """获取数据库设置 / Get database settings"""
        return self.get("database", {})
    
    @property
    def proxy_settings(self) -> Dict[str, Any]:
        """获取代理设置 / Get proxy settings"""
        return self.get("proxy", {})
    
    @property
    def analysis_settings(self) -> Dict[str, Any]:
        """获取分析设置 / Get analysis settings"""
        return self.get("analysis", {})
    
    @property
    def logging_settings(self) -> Dict[str, Any]:
        """获取日志设置 / Get logging settings"""
        return self.get("logging", {})