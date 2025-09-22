"""
电商数据处理管道
E-commerce Data Processing Pipeline
"""

import json
from datetime import datetime
from typing import Dict, Any
from scrapy import Spider
from scrapy.exceptions import DropItem

from database.manager import DatabaseManager
from config.database_config import DatabaseConfig
from utils.logger import LoggerMixin
from utils.text_processor import TextProcessor


class EcommercePipeline(LoggerMixin):
    """
    电商数据处理管道
    E-commerce Data Processing Pipeline
    """
    
    def __init__(self, db_config: DatabaseConfig = None):
        """
        初始化管道
        Initialize pipeline
        
        Args:
            db_config: 数据库配置 / Database configuration
        """
        self.db_config = db_config or DatabaseConfig()
        self.db_manager = DatabaseManager(self.db_config)
        self.text_processor = TextProcessor()
        self.processed_items = set()
    
    @classmethod
    def from_crawler(cls, crawler):
        """从爬虫配置创建管道 / Create pipeline from crawler"""
        return cls()
    
    def open_spider(self, spider: Spider):
        """爬虫开始时调用 / Called when spider starts"""
        self.log_info(f"电商数据管道启动: {spider.name}")
    
    def close_spider(self, spider: Spider):
        """爬虫结束时调用 / Called when spider closes"""
        self.log_info(f"电商数据管道关闭: {spider.name}, 处理条目数: {len(self.processed_items)}")
    
    def process_item(self, item: Dict[str, Any], spider: Spider) -> Dict[str, Any]:
        """
        处理数据项
        Process data item
        
        Args:
            item: 数据项 / Data item
            spider: 爬虫实例 / Spider instance
            
        Returns:
            处理后的数据项 / Processed data item
        """
        try:
            # 验证必要字段
            if not self._validate_item(item):
                raise DropItem(f"必要字段缺失: {item}")
            
            # 数据清洗和标准化
            cleaned_item = self._clean_item(item)
            
            # 去重检查
            item_key = self._get_item_key(cleaned_item)
            if item_key in self.processed_items:
                raise DropItem(f"重复数据项: {item_key}")
            
            # 保存到数据库
            self._save_item(cleaned_item, spider)
            
            # 记录已处理
            self.processed_items.add(item_key)
            
            self.log_info(f"处理商品数据: {cleaned_item.get('title', 'Unknown')[:50]}")
            
            return cleaned_item
            
        except Exception as e:
            self.log_error(f"处理数据项失败: {e}")
            raise DropItem(f"处理失败: {e}")
    
    def _validate_item(self, item: Dict[str, Any]) -> bool:
        """
        验证数据项
        Validate data item
        
        Args:
            item: 数据项 / Data item
            
        Returns:
            是否有效 / Whether valid
        """
        required_fields = ['platform', 'product_id', 'title']
        
        for field in required_fields:
            if not item.get(field):
                return False
        
        return True
    
    def _clean_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """
        清洗数据项
        Clean data item
        
        Args:
            item: 原始数据项 / Raw data item
            
        Returns:
            清洗后的数据项 / Cleaned data item
        """
        cleaned = dict(item)
        
        # 清洗文本字段
        text_fields = ['title', 'description', 'brand', 'shop_name']
        for field in text_fields:
            if cleaned.get(field):
                cleaned[field] = self.text_processor.clean_text(str(cleaned[field]))
        
        # 标准化价格
        price_fields = ['price', 'original_price', 'discount']
        for field in price_fields:
            if cleaned.get(field):
                cleaned[field] = self._normalize_price(cleaned[field])
        
        # 标准化数字
        number_fields = ['sales_count', 'review_count']
        for field in number_fields:
            if cleaned.get(field):
                cleaned[field] = self._normalize_number(cleaned[field])
        
        # 标准化评分
        if cleaned.get('rating'):
            cleaned['rating'] = self._normalize_rating(cleaned['rating'])
        
        # 处理图片列表
        if cleaned.get('images'):
            cleaned['images'] = self._normalize_images(cleaned['images'])
        
        # 处理属性字典
        if cleaned.get('attributes'):
            cleaned['attributes'] = self._normalize_attributes(cleaned['attributes'])
        
        # 添加抓取时间
        cleaned['crawl_time'] = datetime.utcnow()
        
        return cleaned
    
    def _normalize_price(self, price: Any) -> float:
        """标准化价格 / Normalize price"""
        if isinstance(price, (int, float)):
            return float(price)
        
        if isinstance(price, str):
            # 提取价格数字
            prices = self.text_processor.extract_price(price)
            return prices[0] if prices else 0.0
        
        return 0.0
    
    def _normalize_number(self, number: Any) -> int:
        """标准化数字 / Normalize number"""
        if isinstance(number, int):
            return number
        
        if isinstance(number, float):
            return int(number)
        
        if isinstance(number, str):
            # 提取数字
            numbers = self.text_processor.extract_numbers(number)
            return numbers[0] if numbers else 0
        
        return 0
    
    def _normalize_rating(self, rating: Any) -> float:
        """标准化评分 / Normalize rating"""
        if isinstance(rating, (int, float)):
            return float(rating)
        
        if isinstance(rating, str):
            # 提取评分
            ratings = self.text_processor.extract_ratings(rating)
            return ratings[0] if ratings else 0.0
        
        return 0.0
    
    def _normalize_images(self, images: Any) -> list:
        """标准化图片列表 / Normalize image list"""
        if isinstance(images, list):
            return [img for img in images if isinstance(img, str) and img.strip()]
        
        if isinstance(images, str):
            try:
                # 尝试解析JSON
                return json.loads(images)
            except:
                # 单个图片URL
                return [images] if images.strip() else []
        
        return []
    
    def _normalize_attributes(self, attributes: Any) -> dict:
        """标准化属性字典 / Normalize attributes dictionary"""
        if isinstance(attributes, dict):
            return {str(k): str(v) for k, v in attributes.items() if k and v}
        
        if isinstance(attributes, str):
            try:
                # 尝试解析JSON
                attrs = json.loads(attributes)
                if isinstance(attrs, dict):
                    return {str(k): str(v) for k, v in attrs.items() if k and v}
            except:
                pass
        
        return {}
    
    def _get_item_key(self, item: Dict[str, Any]) -> str:
        """
        获取数据项唯一键
        Get unique key for data item
        
        Args:
            item: 数据项 / Data item
            
        Returns:
            唯一键 / Unique key
        """
        platform = item.get('platform', '')
        product_id = item.get('product_id', '')
        return f"{platform}:{product_id}"
    
    def _save_item(self, item: Dict[str, Any], spider: Spider):
        """
        保存数据项到数据库
        Save data item to database
        
        Args:
            item: 数据项 / Data item
            spider: 爬虫实例 / Spider instance
        """
        try:
            # 转换为数据库格式
            product_data = {
                'platform': item.get('platform'),
                'product_id': item.get('product_id'),
                'title': item.get('title'),
                'price': item.get('price'),
                'original_price': item.get('original_price'),
                'discount': item.get('discount'),
                'sales_count': item.get('sales_count'),
                'rating': item.get('rating'),
                'review_count': item.get('review_count'),
                'category': item.get('category'),
                'brand': item.get('brand'),
                'shop_name': item.get('shop_name'),
                'description': item.get('description'),
                'images': item.get('images'),
                'attributes': item.get('attributes'),
                'url': item.get('url')
            }
            
            # 保存商品信息
            self.db_manager.save_ecommerce_product(product_data)
            
            # 如果有价格信息，保存价格历史
            if item.get('price'):
                price_data = {
                    'platform': item.get('platform'),
                    'external_product_id': item.get('product_id'),
                    'price': item.get('price'),
                    'original_price': item.get('original_price'),
                    'discount': item.get('discount')
                }
                self.db_manager.save_price_history(price_data)
            
        except Exception as e:
            self.log_error(f"保存数据失败: {e}")
            raise


class DuplicateFilterPipeline(LoggerMixin):
    """
    重复数据过滤管道
    Duplicate Data Filter Pipeline
    """
    
    def __init__(self):
        """初始化过滤器 / Initialize filter"""
        self.seen_items = set()
    
    def process_item(self, item: Dict[str, Any], spider: Spider) -> Dict[str, Any]:
        """
        过滤重复数据
        Filter duplicate data
        
        Args:
            item: 数据项 / Data item
            spider: 爬虫实例 / Spider instance
            
        Returns:
            数据项 / Data item
            
        Raises:
            DropItem: 重复数据时抛出 / Raised when duplicate data found
        """
        # 生成唯一标识
        item_id = f"{item.get('platform', '')}:{item.get('product_id', '')}"
        
        if item_id in self.seen_items:
            raise DropItem(f"重复商品: {item_id}")
        
        self.seen_items.add(item_id)
        return item


class ValidationPipeline(LoggerMixin):
    """
    数据验证管道
    Data Validation Pipeline
    """
    
    def process_item(self, item: Dict[str, Any], spider: Spider) -> Dict[str, Any]:
        """
        验证数据
        Validate data
        
        Args:
            item: 数据项 / Data item
            spider: 爬虫实例 / Spider instance
            
        Returns:
            数据项 / Data item
            
        Raises:
            DropItem: 数据无效时抛出 / Raised when data is invalid
        """
        # 验证必要字段
        required_fields = ['platform', 'product_id', 'title']
        for field in required_fields:
            if not item.get(field):
                raise DropItem(f"缺少必要字段 {field}: {item}")
        
        # 验证价格范围
        price = item.get('price')
        if price is not None:
            try:
                price_value = float(price)
                if price_value < 0 or price_value > 1000000:
                    raise DropItem(f"价格超出合理范围: {price_value}")
            except (ValueError, TypeError):
                raise DropItem(f"无效价格格式: {price}")
        
        # 验证评分范围
        rating = item.get('rating')
        if rating is not None:
            try:
                rating_value = float(rating)
                if rating_value < 0 or rating_value > 10:
                    raise DropItem(f"评分超出合理范围: {rating_value}")
            except (ValueError, TypeError):
                raise DropItem(f"无效评分格式: {rating}")
        
        return item