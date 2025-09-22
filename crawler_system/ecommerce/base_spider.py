"""
电商爬虫基类
Base E-commerce Spider
"""

import scrapy
import random
from typing import Dict, Any, Optional, List
from urllib.parse import urljoin, urlparse

from utils.logger import LoggerMixin
from utils.rate_limiter import RateLimiter, AdaptiveRateLimiter
from utils.user_agent import UserAgentRotator
from utils.proxy_manager import ProxyManager
from config.settings import CrawlerConfig
from .items import EcommerceItem


class BaseEcommerceSpider(scrapy.Spider, LoggerMixin):
    """
    电商爬虫基类
    Base E-commerce Spider Class
    """
    
    name = 'base_ecommerce'
    platform = 'unknown'
    
    def __init__(self, *args, **kwargs):
        """初始化爬虫 / Initialize spider"""
        super().__init__(*args, **kwargs)
        
        # 加载配置
        self.config = CrawlerConfig()
        self.crawler_settings = self.config.crawler_settings
        self.ecommerce_settings = self.config.ecommerce_settings
        
        # 初始化工具
        self.rate_limiter = AdaptiveRateLimiter(
            initial_delay=self.crawler_settings.get('delay_range', [1, 3])[0]
        )
        self.user_agent_rotator = UserAgentRotator()
        
        # 代理管理
        if self.config.proxy_settings.get('enabled'):
            proxy_list = self.config.proxy_settings.get('proxy_list', [])
            self.proxy_manager = ProxyManager(proxy_list)
        else:
            self.proxy_manager = None
        
        # 统计信息
        self.stats = {
            'requests_made': 0,
            'items_scraped': 0,
            'errors_occurred': 0
        }
    
    def start_requests(self):
        """生成初始请求 / Generate initial requests"""
        start_urls = getattr(self, 'start_urls', [])
        
        for url in start_urls:
            yield self.make_request(url, self.parse)
    
    def make_request(self, url: str, callback, meta: Dict = None, **kwargs):
        """
        创建请求
        Create request
        
        Args:
            url: 请求URL / Request URL
            callback: 回调函数 / Callback function
            meta: 元数据 / Metadata
            **kwargs: 其他参数 / Other parameters
            
        Returns:
            Scrapy请求对象 / Scrapy request object
        """
        # 应用频率限制
        self.rate_limiter.wait()
        
        # 准备请求头
        headers = self.user_agent_rotator.get_headers()
        
        # 准备代理
        proxy = None
        if self.proxy_manager:
            proxy_dict = self.proxy_manager.get_proxy()
            if proxy_dict:
                proxy = proxy_dict.get('http')
        
        # 准备元数据
        request_meta = meta or {}
        if proxy:
            request_meta['proxy'] = proxy
        
        # 更新统计
        self.stats['requests_made'] += 1
        
        self.log_debug(f"发起请求: {url}")
        
        return scrapy.Request(
            url=url,
            callback=callback,
            headers=headers,
            meta=request_meta,
            dont_filter=kwargs.get('dont_filter', False),
            **kwargs
        )
    
    def parse(self, response):
        """
        默认解析方法
        Default parse method
        
        Args:
            response: 响应对象 / Response object
        """
        self.log_warning("使用默认解析方法，请在子类中重写此方法")
        return []
    
    def parse_product(self, response) -> EcommerceItem:
        """
        解析商品页面
        Parse product page
        
        Args:
            response: 响应对象 / Response object
            
        Returns:
            商品数据项 / Product data item
        """
        raise NotImplementedError("子类必须实现parse_product方法")
    
    def extract_text(self, response, selector: str, default: str = "") -> str:
        """
        提取文本内容
        Extract text content
        
        Args:
            response: 响应对象 / Response object
            selector: CSS选择器 / CSS selector
            default: 默认值 / Default value
            
        Returns:
            提取的文本 / Extracted text
        """
        try:
            element = response.css(selector)
            if element:
                text = element.get()
                return text.strip() if text else default
        except Exception as e:
            self.log_warning(f"提取文本失败 {selector}: {e}")
        
        return default
    
    def extract_number(self, response, selector: str, default: int = 0) -> int:
        """
        提取数字
        Extract number
        
        Args:
            response: 响应对象 / Response object
            selector: CSS选择器 / CSS selector
            default: 默认值 / Default value
            
        Returns:
            提取的数字 / Extracted number
        """
        text = self.extract_text(response, selector)
        
        if text:
            # 提取数字
            import re
            numbers = re.findall(r'\d+', text.replace(',', '').replace('.', ''))
            if numbers:
                try:
                    return int(numbers[0])
                except ValueError:
                    pass
        
        return default
    
    def extract_price(self, response, selector: str, default: float = 0.0) -> float:
        """
        提取价格
        Extract price
        
        Args:
            response: 响应对象 / Response object
            selector: CSS选择器 / CSS selector
            default: 默认值 / Default value
            
        Returns:
            提取的价格 / Extracted price
        """
        text = self.extract_text(response, selector)
        
        if text:
            # 提取价格数字
            import re
            # 匹配价格模式
            price_patterns = [
                r'(\d+(?:\.\d{2})?)',  # 123.45
                r'(\d+(?:,\d{3})*(?:\.\d{2})?)',  # 1,234.56
            ]
            
            for pattern in price_patterns:
                matches = re.findall(pattern, text.replace('¥', '').replace('￥', '').replace('$', ''))
                if matches:
                    try:
                        return float(matches[0].replace(',', ''))
                    except ValueError:
                        continue
        
        return default
    
    def extract_rating(self, response, selector: str, default: float = 0.0) -> float:
        """
        提取评分
        Extract rating
        
        Args:
            response: 响应对象 / Response object
            selector: CSS选择器 / CSS selector
            default: 默认值 / Default value
            
        Returns:
            提取的评分 / Extracted rating
        """
        text = self.extract_text(response, selector)
        
        if text:
            # 提取评分数字
            import re
            rating_patterns = [
                r'(\d(?:\.\d)?)',  # 4.5
                r'(\d(?:\.\d)?)/5',  # 4.5/5
                r'(\d(?:\.\d)?)/10',  # 8.5/10
            ]
            
            for pattern in rating_patterns:
                matches = re.findall(pattern, text)
                if matches:
                    try:
                        rating = float(matches[0])
                        # 标准化到5分制
                        if rating > 5:
                            rating = rating / 2
                        return rating
                    except ValueError:
                        continue
        
        return default
    
    def extract_images(self, response, selector: str) -> List[str]:
        """
        提取图片URL列表
        Extract image URL list
        
        Args:
            response: 响应对象 / Response object
            selector: CSS选择器 / CSS selector
            
        Returns:
            图片URL列表 / Image URL list
        """
        try:
            images = []
            elements = response.css(selector)
            
            for element in elements:
                src = element.attrib.get('src') or element.attrib.get('data-src')
                if src:
                    # 转换为绝对URL
                    absolute_url = urljoin(response.url, src)
                    images.append(absolute_url)
            
            return images
        except Exception as e:
            self.log_warning(f"提取图片失败 {selector}: {e}")
            return []
    
    def handle_error(self, failure):
        """
        处理请求错误
        Handle request error
        
        Args:
            failure: 失败对象 / Failure object
        """
        self.stats['errors_occurred'] += 1
        self.rate_limiter.on_error("general")
        
        if self.proxy_manager:
            self.proxy_manager.mark_proxy_failed()
        
        self.log_error(f"请求失败: {failure.value}")
    
    def handle_success(self, response):
        """
        处理请求成功
        Handle request success
        
        Args:
            response: 响应对象 / Response object
        """
        self.rate_limiter.on_success()
        
        if self.proxy_manager:
            self.proxy_manager.mark_proxy_success()
    
    def create_item(self, **kwargs) -> EcommerceItem:
        """
        创建商品数据项
        Create product data item
        
        Args:
            **kwargs: 商品数据 / Product data
            
        Returns:
            商品数据项 / Product data item
        """
        item = EcommerceItem()
        
        # 设置平台信息
        item['platform'] = self.platform
        
        # 设置其他字段
        for key, value in kwargs.items():
            if key in item.fields:
                item[key] = value
        
        # 更新统计
        self.stats['items_scraped'] += 1
        
        return item
    
    def closed(self, reason):
        """
        爬虫关闭时调用
        Called when spider closes
        
        Args:
            reason: 关闭原因 / Close reason
        """
        self.log_info(f"爬虫关闭: {reason}")
        self.log_info(f"统计信息: {self.stats}")
    
    def should_skip_url(self, url: str) -> bool:
        """
        判断是否跳过URL
        Check if URL should be skipped
        
        Args:
            url: URL地址 / URL address
            
        Returns:
            是否跳过 / Whether to skip
        """
        # 检查robots.txt
        if self.crawler_settings.get('robots_txt_obey', True):
            # 这里可以添加robots.txt检查逻辑
            pass
        
        # 检查URL格式
        parsed = urlparse(url)
        if not parsed.scheme or not parsed.netloc:
            return True
        
        return False
    
    def get_domain(self, url: str) -> str:
        """
        获取URL域名
        Get URL domain
        
        Args:
            url: URL地址 / URL address
            
        Returns:
            域名 / Domain
        """
        try:
            return urlparse(url).netloc
        except Exception:
            return ""