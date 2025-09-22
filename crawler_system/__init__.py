"""
智能电商和社媒爬虫系统
Intelligent E-commerce and Social Media Crawler System

一个模块化的网络爬虫系统，支持电商平台商品信息抓取和社交媒体舆论分析。
A modular web crawler system supporting e-commerce product information extraction
and social media sentiment analysis.

Author: VideoAgent Team
Version: 1.0.0
"""

__version__ = "1.0.0"
__author__ = "VideoAgent Team"

# 导入主要模块
from .main import CrawlerSystem
from .config.settings import CrawlerConfig

__all__ = [
    "CrawlerSystem",
    "CrawlerConfig"
]