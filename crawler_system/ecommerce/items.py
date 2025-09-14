"""
电商数据项定义
E-commerce Data Items Definition
"""

import scrapy
from scrapy import Field


class EcommerceItem(scrapy.Item):
    """
    电商商品数据项
    E-commerce Product Data Item
    """
    
    # 基本信息
    platform = Field()         # 平台名称
    product_id = Field()        # 商品ID
    title = Field()            # 商品标题
    price = Field()            # 当前价格
    original_price = Field()    # 原价
    discount = Field()         # 折扣
    
    # 销售信息
    sales_count = Field()      # 销量
    rating = Field()           # 评分
    review_count = Field()     # 评论数量
    
    # 分类信息
    category = Field()         # 商品分类
    brand = Field()           # 品牌
    shop_name = Field()       # 店铺名称
    
    # 详细信息
    description = Field()      # 商品描述
    images = Field()          # 商品图片URL列表
    attributes = Field()      # 商品属性字典
    
    # 链接信息
    url = Field()             # 商品链接
    
    # 抓取元数据
    crawl_time = Field()      # 抓取时间
    source_page = Field()     # 来源页面


class ProductReviewItem(scrapy.Item):
    """
    商品评论数据项
    Product Review Data Item
    """
    
    # 基本信息
    platform = Field()        # 平台名称
    product_id = Field()       # 商品ID
    review_id = Field()        # 评论ID
    
    # 评论内容
    reviewer_name = Field()    # 评论者名称
    reviewer_id = Field()      # 评论者ID
    content = Field()         # 评论内容
    rating = Field()          # 评论评分
    
    # 时间信息
    review_time = Field()     # 评论时间
    
    # 互动信息
    helpful_count = Field()   # 有用数
    reply_count = Field()     # 回复数
    
    # 额外信息
    verified_purchase = Field()  # 是否验证购买
    images = Field()          # 评论图片
    
    # 抓取元数据
    crawl_time = Field()      # 抓取时间


class ShopInfoItem(scrapy.Item):
    """
    店铺信息数据项
    Shop Information Data Item
    """
    
    # 基本信息
    platform = Field()        # 平台名称
    shop_id = Field()         # 店铺ID
    shop_name = Field()       # 店铺名称
    
    # 描述信息
    description = Field()     # 店铺描述
    logo = Field()           # 店铺logo
    
    # 统计信息
    product_count = Field()   # 商品数量
    follower_count = Field()  # 关注者数量
    rating = Field()         # 店铺评分
    
    # 联系信息
    location = Field()        # 店铺位置
    contact = Field()        # 联系方式
    
    # 认证信息
    verified = Field()       # 是否认证
    badges = Field()         # 徽章列表
    
    # 链接信息
    url = Field()            # 店铺链接
    
    # 抓取元数据
    crawl_time = Field()     # 抓取时间


class PriceHistoryItem(scrapy.Item):
    """
    价格历史数据项
    Price History Data Item
    """
    
    # 基本信息
    platform = Field()          # 平台名称
    product_id = Field()         # 商品ID
    
    # 价格信息
    price = Field()             # 价格
    original_price = Field()     # 原价
    discount = Field()          # 折扣
    
    # 时间信息
    record_time = Field()       # 记录时间
    
    # 促销信息
    promotion_info = Field()    # 促销信息
    
    # 抓取元数据
    crawl_time = Field()        # 抓取时间