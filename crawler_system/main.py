"""
爬虫系统主程序
Crawler System Main Application
"""

import os
import sys
import asyncio
from typing import Dict, Any, List, Optional
from pathlib import Path

# 添加项目根目录到Python路径
current_dir = Path(__file__).parent
sys.path.append(str(current_dir))
sys.path.append(str(current_dir.parent))

from config.settings import CrawlerConfig
from config.database_config import DatabaseConfig
from database.manager import DatabaseManager
from utils.logger import setup_logger
from ecommerce.spiders.taobao_spider import TaobaoSpider
from analysis.sentiment_analyzer import SentimentAnalyzer
from analysis.data_visualizer import DataVisualizer


class CrawlerSystem:
    """
    爬虫系统主类
    Crawler System Main Class
    """
    
    def __init__(self, config_file: Optional[str] = None):
        """
        初始化爬虫系统
        Initialize crawler system
        
        Args:
            config_file: 配置文件路径 / Configuration file path
        """
        # 加载配置
        self.config = CrawlerConfig(config_file)
        
        # 设置日志
        log_settings = self.config.logging_settings
        self.logger = setup_logger(
            log_file=log_settings.get('file_path'),
            log_level=log_settings.get('level', 'INFO'),
            max_size=log_settings.get('max_size', '100MB'),
            backup_count=log_settings.get('backup_count', 5)
        )
        
        # 初始化数据库
        self.db_config = DatabaseConfig(self.config.database_settings)
        self.db_manager = DatabaseManager(self.db_config)
        
        # 初始化分析器
        if self.config.analysis_settings.get('sentiment_analysis'):
            self.sentiment_analyzer = SentimentAnalyzer()
        else:
            self.sentiment_analyzer = None
        
        if self.config.analysis_settings.get('visualization_enabled'):
            self.visualizer = DataVisualizer()
        else:
            self.visualizer = None
        
        self.logger.info("爬虫系统初始化完成")
    
    def run_ecommerce_crawler(self, 
                            platform: str, 
                            keyword: str, 
                            max_pages: int = 10) -> Dict[str, Any]:
        """
        运行电商爬虫
        Run e-commerce crawler
        
        Args:
            platform: 平台名称 / Platform name
            keyword: 搜索关键词 / Search keyword
            max_pages: 最大页数 / Maximum pages
            
        Returns:
            爬取结果 / Crawling results
        """
        self.logger.info(f"开始电商爬虫: {platform} - {keyword}")
        
        try:
            if platform.lower() == 'taobao':
                spider = TaobaoSpider(keyword=keyword, max_pages=max_pages)
                results = self._run_spider(spider)
                
                self.logger.info(f"电商爬虫完成: 抓取 {results.get('items_count', 0)} 个商品")
                return results
            else:
                raise ValueError(f"不支持的平台: {platform}")
                
        except Exception as e:
            self.logger.error(f"电商爬虫失败: {e}")
            return {'success': False, 'error': str(e)}
    
    def run_social_media_crawler(self, 
                                platform: str,
                                keyword: str,
                                max_posts: int = 500) -> Dict[str, Any]:
        """
        运行社媒爬虫
        Run social media crawler
        
        Args:
            platform: 平台名称 / Platform name
            keyword: 搜索关键词 / Search keyword
            max_posts: 最大帖子数 / Maximum posts
            
        Returns:
            爬取结果 / Crawling results
        """
        self.logger.info(f"开始社媒爬虫: {platform} - {keyword}")
        
        try:
            # 这里将实现各种社媒爬虫
            self.logger.info("社媒爬虫功能正在开发中...")
            return {'success': True, 'message': '社媒爬虫功能正在开发中'}
            
        except Exception as e:
            self.logger.error(f"社媒爬虫失败: {e}")
            return {'success': False, 'error': str(e)}
    
    def _run_spider(self, spider) -> Dict[str, Any]:
        """
        运行爬虫
        Run spider
        
        Args:
            spider: 爬虫实例 / Spider instance
            
        Returns:
            运行结果 / Running results
        """
        from scrapy.crawler import CrawlerRunner
        from scrapy.utils.project import get_project_settings
        from twisted.internet import reactor
        
        # 配置Scrapy设置
        settings = get_project_settings()
        settings.update({
            'ITEM_PIPELINES': {
                'crawler_system.ecommerce.pipelines.ValidationPipeline': 200,
                'crawler_system.ecommerce.pipelines.DuplicateFilterPipeline': 300,
                'crawler_system.ecommerce.pipelines.EcommercePipeline': 400,
            },
            'ROBOTSTXT_OBEY': self.config.crawler_settings.get('robots_txt_obey', True),
            'DOWNLOAD_DELAY': self.config.crawler_settings.get('delay_range', [1, 3])[0],
            'CONCURRENT_REQUESTS': self.config.crawler_settings.get('concurrent_requests', 8),
            'COOKIES_ENABLED': True,
            'TELNETCONSOLE_ENABLED': False,
        })
        
        # 创建爬虫运行器
        runner = CrawlerRunner(settings)
        
        # 运行爬虫
        deferred = runner.crawl(spider)
        
        # 获取统计信息
        stats = runner.crawlers[0].stats.get_stats() if runner.crawlers else {}
        
        return {
            'success': True,
            'items_count': stats.get('item_scraped_count', 0),
            'requests_count': stats.get('downloader/request_count', 0),
            'response_count': stats.get('downloader/response_count', 0),
            'stats': stats
        }
    
    def analyze_sentiment(self, platform: Optional[str] = None) -> Dict[str, Any]:
        """
        分析情感
        Analyze sentiment
        
        Args:
            platform: 平台名称 / Platform name
            
        Returns:
            分析结果 / Analysis results
        """
        if not self.sentiment_analyzer:
            return {'success': False, 'error': '情感分析未启用'}
        
        try:
            self.logger.info(f"开始情感分析: {platform or 'all'}")
            
            # 获取社媒数据
            posts = self.db_manager.get_social_media_posts(platform=platform)
            
            results = []
            for post in posts:
                if post.content:
                    sentiment = self.sentiment_analyzer.analyze_text(post.content)
                    
                    # 保存分析结果
                    analysis_data = {
                        'post_id': post.id,
                        'platform': post.platform,
                        'sentiment_score': sentiment['score'],
                        'sentiment_label': sentiment['label'],
                        'confidence': sentiment.get('confidence', 0),
                        'positive_score': sentiment.get('positive_score', 0),
                        'negative_score': sentiment.get('negative_score', 0),
                        'neutral_score': sentiment.get('neutral_score', 0),
                        'keywords': sentiment.get('keywords', []),
                        'model_used': 'snownlp'
                    }
                    
                    self.db_manager.save_sentiment_analysis(analysis_data)
                    results.append(analysis_data)
            
            self.logger.info(f"情感分析完成: {len(results)} 条记录")
            return {'success': True, 'analyzed_count': len(results)}
            
        except Exception as e:
            self.logger.error(f"情感分析失败: {e}")
            return {'success': False, 'error': str(e)}
    
    def generate_report(self, report_type: str = 'summary') -> Dict[str, Any]:
        """
        生成报告
        Generate report
        
        Args:
            report_type: 报告类型 / Report type
            
        Returns:
            报告结果 / Report results
        """
        try:
            self.logger.info(f"开始生成报告: {report_type}")
            
            if report_type == 'summary':
                return self._generate_summary_report()
            elif report_type == 'ecommerce':
                return self._generate_ecommerce_report()
            elif report_type == 'sentiment':
                return self._generate_sentiment_report()
            else:
                raise ValueError(f"不支持的报告类型: {report_type}")
                
        except Exception as e:
            self.logger.error(f"生成报告失败: {e}")
            return {'success': False, 'error': str(e)}
    
    def _generate_summary_report(self) -> Dict[str, Any]:
        """生成摘要报告 / Generate summary report"""
        stats = self.db_manager.get_platform_statistics()
        
        return {
            'success': True,
            'report_type': 'summary',
            'statistics': stats,
            'timestamp': str(asyncio.get_event_loop().time())
        }
    
    def _generate_ecommerce_report(self) -> Dict[str, Any]:
        """生成电商报告 / Generate e-commerce report"""
        # 获取电商数据
        products = self.db_manager.get_ecommerce_products(limit=1000)
        
        # 基本统计
        total_products = len(products)
        platforms = set(p.platform for p in products)
        avg_price = sum(p.price or 0 for p in products) / total_products if total_products else 0
        
        return {
            'success': True,
            'report_type': 'ecommerce',
            'total_products': total_products,
            'platforms': list(platforms),
            'average_price': round(avg_price, 2),
            'timestamp': str(asyncio.get_event_loop().time())
        }
    
    def _generate_sentiment_report(self) -> Dict[str, Any]:
        """生成情感分析报告 / Generate sentiment analysis report"""
        posts = self.db_manager.get_social_media_posts(limit=1000)
        
        # 情感统计
        sentiments = {}
        for post in posts:
            if post.sentiment_label:
                sentiments[post.sentiment_label] = sentiments.get(post.sentiment_label, 0) + 1
        
        return {
            'success': True,
            'report_type': 'sentiment',
            'total_posts': len(posts),
            'sentiment_distribution': sentiments,
            'timestamp': str(asyncio.get_event_loop().time())
        }
    
    def cleanup_data(self, days: int = 30):
        """
        清理过期数据
        Clean up expired data
        
        Args:
            days: 保留天数 / Days to retain
        """
        try:
            self.logger.info(f"开始清理 {days} 天前的数据")
            self.db_manager.cleanup_old_data(days)
            self.logger.info("数据清理完成")
        except Exception as e:
            self.logger.error(f"数据清理失败: {e}")
    
    def get_status(self) -> Dict[str, Any]:
        """
        获取系统状态
        Get system status
        
        Returns:
            系统状态 / System status
        """
        try:
            stats = self.db_manager.get_platform_statistics()
            
            return {
                'status': 'running',
                'config_loaded': True,
                'database_connected': True,
                'statistics': stats
            }
        except Exception as e:
            return {
                'status': 'error',
                'error': str(e)
            }


def main():
    """主函数 / Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='智能爬虫系统')
    parser.add_argument('--action', choices=['ecommerce', 'social', 'analyze', 'report', 'status'], 
                       required=True, help='执行动作')
    parser.add_argument('--platform', help='平台名称')
    parser.add_argument('--keyword', help='搜索关键词')
    parser.add_argument('--pages', type=int, default=10, help='最大页数')
    parser.add_argument('--posts', type=int, default=500, help='最大帖子数')
    parser.add_argument('--report-type', choices=['summary', 'ecommerce', 'sentiment'], 
                       default='summary', help='报告类型')
    
    args = parser.parse_args()
    
    # 创建爬虫系统
    crawler = CrawlerSystem()
    
    try:
        if args.action == 'ecommerce':
            if not args.platform or not args.keyword:
                print("电商爬虫需要指定 --platform 和 --keyword 参数")
                return
            
            result = crawler.run_ecommerce_crawler(args.platform, args.keyword, args.pages)
            print(f"电商爬虫结果: {result}")
            
        elif args.action == 'social':
            if not args.platform or not args.keyword:
                print("社媒爬虫需要指定 --platform 和 --keyword 参数")
                return
            
            result = crawler.run_social_media_crawler(args.platform, args.keyword, args.posts)
            print(f"社媒爬虫结果: {result}")
            
        elif args.action == 'analyze':
            result = crawler.analyze_sentiment(args.platform)
            print(f"情感分析结果: {result}")
            
        elif args.action == 'report':
            result = crawler.generate_report(args.report_type)
            print(f"报告生成结果: {result}")
            
        elif args.action == 'status':
            status = crawler.get_status()
            print(f"系统状态: {status}")
            
    except Exception as e:
        print(f"执行失败: {e}")


if __name__ == '__main__':
    main()