"""
数据库模型定义
Database Models Definition
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, DateTime, Boolean, JSON
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class EcommerceProduct(Base):
    """
    电商商品信息模型
    E-commerce Product Information Model
    """
    __tablename__ = 'ecommerce_products'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    platform = Column(String(50), nullable=False, comment='平台名称')
    product_id = Column(String(100), nullable=False, comment='商品ID')
    title = Column(String(500), nullable=False, comment='商品标题')
    price = Column(Float, comment='价格')
    original_price = Column(Float, comment='原价')
    discount = Column(Float, comment='折扣')
    sales_count = Column(Integer, comment='销量')
    rating = Column(Float, comment='评分')
    review_count = Column(Integer, comment='评论数量')
    category = Column(String(200), comment='商品分类')
    brand = Column(String(100), comment='品牌')
    shop_name = Column(String(200), comment='店铺名称')
    description = Column(Text, comment='商品描述')
    images = Column(JSON, comment='商品图片URL列表')
    attributes = Column(JSON, comment='商品属性')
    url = Column(String(500), comment='商品链接')
    
    # 元数据
    created_at = Column(DateTime, default=datetime.utcnow, comment='创建时间')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, comment='更新时间')
    is_active = Column(Boolean, default=True, comment='是否有效')
    
    def __repr__(self):
        return f"<EcommerceProduct(platform='{self.platform}', title='{self.title[:50]}')>"


class SocialMediaPost(Base):
    """
    社交媒体帖子模型
    Social Media Post Model
    """
    __tablename__ = 'social_media_posts'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    platform = Column(String(50), nullable=False, comment='平台名称')
    post_id = Column(String(100), nullable=False, comment='帖子ID')
    author = Column(String(100), comment='作者')
    author_id = Column(String(100), comment='作者ID')
    title = Column(String(500), comment='标题')
    content = Column(Text, comment='内容')
    publish_time = Column(DateTime, comment='发布时间')
    
    # 互动数据
    like_count = Column(Integer, default=0, comment='点赞数')
    comment_count = Column(Integer, default=0, comment='评论数')
    share_count = Column(Integer, default=0, comment='分享数')
    view_count = Column(Integer, default=0, comment='浏览数')
    
    # 媒体内容
    images = Column(JSON, comment='图片URL列表')
    videos = Column(JSON, comment='视频URL列表')
    
    # 分析结果
    sentiment_score = Column(Float, comment='情感分数')
    sentiment_label = Column(String(20), comment='情感标签')
    topics = Column(JSON, comment='话题标签')
    keywords = Column(JSON, comment='关键词')
    
    # 元数据
    url = Column(String(500), comment='帖子链接')
    hashtags = Column(JSON, comment='标签列表')
    mentions = Column(JSON, comment='提及用户列表')
    location = Column(String(200), comment='地理位置')
    
    created_at = Column(DateTime, default=datetime.utcnow, comment='抓取时间')
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, comment='更新时间')
    is_active = Column(Boolean, default=True, comment='是否有效')
    
    def __repr__(self):
        return f"<SocialMediaPost(platform='{self.platform}', author='{self.author}')>"


class CrawlLog(Base):
    """
    爬取日志模型
    Crawl Log Model
    """
    __tablename__ = 'crawl_logs'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    task_id = Column(String(100), nullable=False, comment='任务ID')
    platform = Column(String(50), nullable=False, comment='平台名称')
    crawler_type = Column(String(50), nullable=False, comment='爬虫类型')
    
    # 任务信息
    start_time = Column(DateTime, comment='开始时间')
    end_time = Column(DateTime, comment='结束时间')
    status = Column(String(20), comment='状态')
    
    # 统计信息
    total_requests = Column(Integer, default=0, comment='总请求数')
    successful_requests = Column(Integer, default=0, comment='成功请求数')
    failed_requests = Column(Integer, default=0, comment='失败请求数')
    items_scraped = Column(Integer, default=0, comment='抓取条目数')
    
    # 错误信息
    error_message = Column(Text, comment='错误信息')
    error_details = Column(JSON, comment='错误详情')
    
    # 配置信息
    config = Column(JSON, comment='爬取配置')
    
    created_at = Column(DateTime, default=datetime.utcnow, comment='创建时间')
    
    def __repr__(self):
        return f"<CrawlLog(task_id='{self.task_id}', platform='{self.platform}')>"


class PriceHistory(Base):
    """
    价格历史模型
    Price History Model
    """
    __tablename__ = 'price_history'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    product_id = Column(Integer, nullable=False, comment='商品ID')
    platform = Column(String(50), nullable=False, comment='平台名称')
    external_product_id = Column(String(100), nullable=False, comment='外部商品ID')
    
    price = Column(Float, nullable=False, comment='价格')
    original_price = Column(Float, comment='原价')
    discount = Column(Float, comment='折扣')
    
    recorded_at = Column(DateTime, default=datetime.utcnow, comment='记录时间')
    
    def __repr__(self):
        return f"<PriceHistory(product_id={self.product_id}, price={self.price})>"


class SentimentAnalysis(Base):
    """
    情感分析结果模型
    Sentiment Analysis Results Model
    """
    __tablename__ = 'sentiment_analysis'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    post_id = Column(Integer, nullable=False, comment='帖子ID')
    platform = Column(String(50), nullable=False, comment='平台名称')
    
    # 分析结果
    sentiment_score = Column(Float, comment='情感分数 (-1到1)')
    sentiment_label = Column(String(20), comment='情感标签')
    confidence = Column(Float, comment='置信度')
    
    # 细分情感
    positive_score = Column(Float, comment='积极情感分数')
    negative_score = Column(Float, comment='消极情感分数')
    neutral_score = Column(Float, comment='中性情感分数')
    
    # 关键词和主题
    keywords = Column(JSON, comment='关键词及权重')
    topics = Column(JSON, comment='主题标签')
    
    # 元数据
    model_used = Column(String(50), comment='使用的模型')
    analysis_time = Column(DateTime, default=datetime.utcnow, comment='分析时间')
    
    def __repr__(self):
        return f"<SentimentAnalysis(post_id={self.post_id}, sentiment='{self.sentiment_label}')>"