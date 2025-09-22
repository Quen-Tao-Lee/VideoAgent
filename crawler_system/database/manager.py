"""
数据库管理器
Database Manager
"""

from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func
from datetime import datetime, timedelta

from .models import (
    Base, EcommerceProduct, SocialMediaPost, CrawlLog, 
    PriceHistory, SentimentAnalysis
)
from config.database_config import DatabaseConfig


class DatabaseManager:
    """
    数据库管理器类
    Database Manager Class
    """
    
    def __init__(self, db_config: DatabaseConfig):
        """
        初始化数据库管理器
        Initialize database manager
        
        Args:
            db_config: 数据库配置对象 / Database configuration object
        """
        self.db_config = db_config
        self.db_config.create_engine()
        self.db_config.create_tables()
    
    def get_session(self) -> Session:
        """
        获取数据库会话
        Get database session
        
        Returns:
            数据库会话 / Database session
        """
        return self.db_config.get_session()
    
    # 电商商品相关操作
    def save_ecommerce_product(self, product_data: Dict[str, Any]) -> EcommerceProduct:
        """
        保存电商商品信息
        Save e-commerce product information
        
        Args:
            product_data: 商品数据字典 / Product data dictionary
            
        Returns:
            保存的商品对象 / Saved product object
        """
        session = self.get_session()
        try:
            # 检查是否已存在
            existing = session.query(EcommerceProduct).filter(
                and_(
                    EcommerceProduct.platform == product_data.get('platform'),
                    EcommerceProduct.product_id == product_data.get('product_id')
                )
            ).first()
            
            if existing:
                # 更新现有记录
                for key, value in product_data.items():
                    if hasattr(existing, key):
                        setattr(existing, key, value)
                existing.updated_at = datetime.utcnow()
                product = existing
            else:
                # 创建新记录
                product = EcommerceProduct(**product_data)
                session.add(product)
            
            session.commit()
            return product
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    def get_ecommerce_products(self, platform: Optional[str] = None, 
                             limit: int = 100) -> List[EcommerceProduct]:
        """
        获取电商商品列表
        Get e-commerce products list
        
        Args:
            platform: 平台名称 / Platform name
            limit: 限制数量 / Limit count
            
        Returns:
            商品列表 / Products list
        """
        session = self.get_session()
        try:
            query = session.query(EcommerceProduct).filter(
                EcommerceProduct.is_active == True
            )
            
            if platform:
                query = query.filter(EcommerceProduct.platform == platform)
            
            return query.order_by(desc(EcommerceProduct.created_at)).limit(limit).all()
        finally:
            session.close()
    
    def save_price_history(self, price_data: Dict[str, Any]) -> PriceHistory:
        """
        保存价格历史记录
        Save price history record
        
        Args:
            price_data: 价格数据字典 / Price data dictionary
            
        Returns:
            保存的价格历史对象 / Saved price history object
        """
        session = self.get_session()
        try:
            price_history = PriceHistory(**price_data)
            session.add(price_history)
            session.commit()
            return price_history
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    # 社交媒体相关操作
    def save_social_media_post(self, post_data: Dict[str, Any]) -> SocialMediaPost:
        """
        保存社交媒体帖子
        Save social media post
        
        Args:
            post_data: 帖子数据字典 / Post data dictionary
            
        Returns:
            保存的帖子对象 / Saved post object
        """
        session = self.get_session()
        try:
            # 检查是否已存在
            existing = session.query(SocialMediaPost).filter(
                and_(
                    SocialMediaPost.platform == post_data.get('platform'),
                    SocialMediaPost.post_id == post_data.get('post_id')
                )
            ).first()
            
            if existing:
                # 更新现有记录
                for key, value in post_data.items():
                    if hasattr(existing, key):
                        setattr(existing, key, value)
                existing.updated_at = datetime.utcnow()
                post = existing
            else:
                # 创建新记录
                post = SocialMediaPost(**post_data)
                session.add(post)
            
            session.commit()
            return post
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    def get_social_media_posts(self, platform: Optional[str] = None,
                              keyword: Optional[str] = None,
                              limit: int = 100) -> List[SocialMediaPost]:
        """
        获取社交媒体帖子列表
        Get social media posts list
        
        Args:
            platform: 平台名称 / Platform name
            keyword: 关键词搜索 / Keyword search
            limit: 限制数量 / Limit count
            
        Returns:
            帖子列表 / Posts list
        """
        session = self.get_session()
        try:
            query = session.query(SocialMediaPost).filter(
                SocialMediaPost.is_active == True
            )
            
            if platform:
                query = query.filter(SocialMediaPost.platform == platform)
            
            if keyword:
                query = query.filter(
                    or_(
                        SocialMediaPost.title.contains(keyword),
                        SocialMediaPost.content.contains(keyword)
                    )
                )
            
            return query.order_by(desc(SocialMediaPost.created_at)).limit(limit).all()
        finally:
            session.close()
    
    def save_sentiment_analysis(self, analysis_data: Dict[str, Any]) -> SentimentAnalysis:
        """
        保存情感分析结果
        Save sentiment analysis result
        
        Args:
            analysis_data: 分析数据字典 / Analysis data dictionary
            
        Returns:
            保存的分析结果对象 / Saved analysis result object
        """
        session = self.get_session()
        try:
            analysis = SentimentAnalysis(**analysis_data)
            session.add(analysis)
            session.commit()
            return analysis
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    # 日志相关操作
    def save_crawl_log(self, log_data: Dict[str, Any]) -> CrawlLog:
        """
        保存爬取日志
        Save crawl log
        
        Args:
            log_data: 日志数据字典 / Log data dictionary
            
        Returns:
            保存的日志对象 / Saved log object
        """
        session = self.get_session()
        try:
            log = CrawlLog(**log_data)
            session.add(log)
            session.commit()
            return log
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    def update_crawl_log(self, task_id: str, update_data: Dict[str, Any]):
        """
        更新爬取日志
        Update crawl log
        
        Args:
            task_id: 任务ID / Task ID
            update_data: 更新数据字典 / Update data dictionary
        """
        session = self.get_session()
        try:
            log = session.query(CrawlLog).filter(
                CrawlLog.task_id == task_id
            ).first()
            
            if log:
                for key, value in update_data.items():
                    if hasattr(log, key):
                        setattr(log, key, value)
                session.commit()
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()
    
    # 统计分析方法
    def get_platform_statistics(self) -> Dict[str, Any]:
        """
        获取平台统计信息
        Get platform statistics
        
        Returns:
            统计信息字典 / Statistics dictionary
        """
        session = self.get_session()
        try:
            # 电商平台统计
            ecommerce_stats = session.query(
                EcommerceProduct.platform,
                func.count(EcommerceProduct.id).label('count')
            ).filter(
                EcommerceProduct.is_active == True
            ).group_by(EcommerceProduct.platform).all()
            
            # 社媒平台统计
            social_stats = session.query(
                SocialMediaPost.platform,
                func.count(SocialMediaPost.id).label('count')
            ).filter(
                SocialMediaPost.is_active == True
            ).group_by(SocialMediaPost.platform).all()
            
            return {
                'ecommerce': {stat.platform: stat.count for stat in ecommerce_stats},
                'social_media': {stat.platform: stat.count for stat in social_stats}
            }
        finally:
            session.close()
    
    def cleanup_old_data(self, days: int = 30):
        """
        清理过期数据
        Clean up old data
        
        Args:
            days: 保留天数 / Days to retain
        """
        session = self.get_session()
        try:
            cutoff_date = datetime.utcnow() - timedelta(days=days)
            
            # 清理过期的爬取日志
            session.query(CrawlLog).filter(
                CrawlLog.created_at < cutoff_date
            ).delete()
            
            # 清理过期的价格历史（保留更长时间）
            price_cutoff = datetime.utcnow() - timedelta(days=days * 3)
            session.query(PriceHistory).filter(
                PriceHistory.recorded_at < price_cutoff
            ).delete()
            
            session.commit()
        except Exception as e:
            session.rollback()
            raise e
        finally:
            session.close()