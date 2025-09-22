"""
淘宝爬虫
Taobao Spider
"""

import json
import re
from urllib.parse import urljoin, quote
from typing import Generator, Dict, Any

from ecommerce.base_spider import BaseEcommerceSpider
from ecommerce.items import EcommerceItem


class TaobaoSpider(BaseEcommerceSpider):
    """
    淘宝商品爬虫
    Taobao Product Spider
    """
    
    name = 'taobao'
    platform = 'taobao'
    allowed_domains = ['taobao.com', 'tmall.com']
    
    # 搜索URL模板
    search_url_template = "https://s.taobao.com/search?q={keyword}&s={start}"
    
    def __init__(self, keyword: str = None, max_pages: int = 10, *args, **kwargs):
        """
        初始化淘宝爬虫
        Initialize Taobao spider
        
        Args:
            keyword: 搜索关键词 / Search keyword
            max_pages: 最大页数 / Maximum pages
        """
        super().__init__(*args, **kwargs)
        self.keyword = keyword or "数码产品"
        self.max_pages = min(max_pages, self.ecommerce_settings.get('max_pages', 10))
        
        # 生成起始URL
        self.start_urls = [
            self.search_url_template.format(
                keyword=quote(self.keyword),
                start=0
            )
        ]
    
    def parse(self, response):
        """
        解析搜索结果页面
        Parse search results page
        
        Args:
            response: 响应对象 / Response object
        """
        self.handle_success(response)
        
        # 提取商品链接
        product_links = self.extract_product_links(response)
        
        for link in product_links:
            if not self.should_skip_url(link):
                yield self.make_request(
                    link,
                    self.parse_product,
                    meta={'product_url': link}
                )
        
        # 生成下一页请求
        current_page = response.meta.get('page', 1)
        if current_page < self.max_pages:
            next_page_url = self.get_next_page_url(response, current_page)
            if next_page_url:
                yield self.make_request(
                    next_page_url,
                    self.parse,
                    meta={'page': current_page + 1}
                )
    
    def extract_product_links(self, response) -> list:
        """
        提取商品链接
        Extract product links
        
        Args:
            response: 响应对象 / Response object
            
        Returns:
            商品链接列表 / Product link list
        """
        links = []
        
        try:
            # 方法1: 从商品卡片提取
            product_selectors = [
                '.item .title a::attr(href)',
                '.item-box .title a::attr(href)',
                '.items .item .pic a::attr(href)',
                '[data-category="auctions"] a::attr(href)'
            ]
            
            for selector in product_selectors:
                urls = response.css(selector).getall()
                for url in urls:
                    if url and 'item.taobao.com' in url:
                        # 转换为绝对URL
                        absolute_url = urljoin(response.url, url)
                        # 清理URL参数
                        clean_url = self.clean_product_url(absolute_url)
                        if clean_url not in links:
                            links.append(clean_url)
            
            # 方法2: 从JSON数据提取
            json_data = self.extract_json_data(response)
            if json_data:
                json_links = self.extract_links_from_json(json_data)
                links.extend(json_links)
            
        except Exception as e:
            self.log_warning(f"提取商品链接失败: {e}")
        
        return links[:20]  # 限制数量避免过载
    
    def extract_json_data(self, response) -> Dict[str, Any]:
        """
        提取页面中的JSON数据
        Extract JSON data from page
        
        Args:
            response: 响应对象 / Response object
            
        Returns:
            JSON数据字典 / JSON data dictionary
        """
        try:
            # 查找包含商品数据的script标签
            scripts = response.css('script::text').getall()
            
            for script in scripts:
                if 'g_page_config' in script or 'g_srp_loadCss' in script:
                    # 提取JSON数据
                    json_match = re.search(r'g_page_config\s*=\s*({.+?});', script)
                    if json_match:
                        return json.loads(json_match.group(1))
                        
        except Exception as e:
            self.log_debug(f"提取JSON数据失败: {e}")
        
        return {}
    
    def extract_links_from_json(self, json_data: Dict[str, Any]) -> list:
        """
        从JSON数据中提取商品链接
        Extract product links from JSON data
        
        Args:
            json_data: JSON数据 / JSON data
            
        Returns:
            商品链接列表 / Product link list
        """
        links = []
        
        try:
            # 遍历查找商品URL
            def find_urls(obj):
                if isinstance(obj, dict):
                    for key, value in obj.items():
                        if key in ['item_url', 'detail_url', 'url'] and isinstance(value, str):
                            if 'item.taobao.com' in value:
                                links.append(self.clean_product_url(value))
                        else:
                            find_urls(value)
                elif isinstance(obj, list):
                    for item in obj:
                        find_urls(item)
            
            find_urls(json_data)
            
        except Exception as e:
            self.log_debug(f"从JSON提取链接失败: {e}")
        
        return links
    
    def clean_product_url(self, url: str) -> str:
        """
        清理商品URL
        Clean product URL
        
        Args:
            url: 原始URL / Original URL
            
        Returns:
            清理后的URL / Cleaned URL
        """
        # 移除跟踪参数
        if '?' in url:
            base_url = url.split('?')[0]
        else:
            base_url = url
        
        # 确保使用HTTPS
        if base_url.startswith('//'):
            base_url = 'https:' + base_url
        elif base_url.startswith('http://'):
            base_url = base_url.replace('http://', 'https://')
        
        return base_url
    
    def get_next_page_url(self, response, current_page: int) -> str:
        """
        获取下一页URL
        Get next page URL
        
        Args:
            response: 响应对象 / Response object
            current_page: 当前页码 / Current page number
            
        Returns:
            下一页URL / Next page URL
        """
        # 计算下一页的起始位置
        next_start = current_page * 44  # 淘宝每页通常44个商品
        
        return self.search_url_template.format(
            keyword=quote(self.keyword),
            start=next_start
        )
    
    def parse_product(self, response) -> Generator[EcommerceItem, None, None]:
        """
        解析商品详情页面
        Parse product detail page
        
        Args:
            response: 响应对象 / Response object
            
        Yields:
            商品数据项 / Product data item
        """
        self.handle_success(response)
        
        try:
            # 提取商品ID
            product_id = self.extract_product_id(response)
            if not product_id:
                self.log_warning(f"无法提取商品ID: {response.url}")
                return
            
            # 创建商品数据项
            item = self.create_item(
                product_id=product_id,
                title=self.extract_title(response),
                price=self.extract_current_price(response),
                original_price=self.extract_original_price(response),
                sales_count=self.extract_sales_count(response),
                rating=self.extract_product_rating(response),
                review_count=self.extract_review_count(response),
                shop_name=self.extract_shop_name(response),
                description=self.extract_description(response),
                images=self.extract_product_images(response),
                attributes=self.extract_attributes(response),
                url=response.url
            )
            
            self.log_info(f"提取商品: {item.get('title', 'Unknown')[:50]}")
            yield item
            
        except Exception as e:
            self.log_error(f"解析商品页面失败 {response.url}: {e}")
    
    def extract_product_id(self, response) -> str:
        """提取商品ID / Extract product ID"""
        # 从URL提取
        id_match = re.search(r'id=(\d+)', response.url)
        if id_match:
            return id_match.group(1)
        
        # 从页面提取
        selectors = [
            '[data-spm-anchor-id*="item"]::attr(data-spm-anchor-id)',
            'input[name="itemId"]::attr(value)',
            '#J_LinkBasket::attr(data-item)'
        ]
        
        for selector in selectors:
            element = response.css(selector).get()
            if element:
                id_match = re.search(r'\d+', element)
                if id_match:
                    return id_match.group()
        
        return ""
    
    def extract_title(self, response) -> str:
        """提取商品标题 / Extract product title"""
        selectors = [
            '.tb-main-title::text',
            'h1[data-spm="1000983"]::text',
            '.tb-detail-hd h1::text',
            'title::text'
        ]
        
        for selector in selectors:
            title = self.extract_text(response, selector)
            if title and len(title) > 5:
                return title
        
        return ""
    
    def extract_current_price(self, response) -> float:
        """提取当前价格 / Extract current price"""
        selectors = [
            '.tb-rmb-num::text',
            '.notranslate::text',
            '[data-spm="price"]::text',
            '.price .num::text'
        ]
        
        for selector in selectors:
            price = self.extract_price(response, selector)
            if price > 0:
                return price
        
        return 0.0
    
    def extract_original_price(self, response) -> float:
        """提取原价 / Extract original price"""
        selectors = [
            '.tb-market-price .tb-rmb-num::text',
            '.original-price::text',
            '.market-price::text'
        ]
        
        for selector in selectors:
            price = self.extract_price(response, selector)
            if price > 0:
                return price
        
        return 0.0
    
    def extract_sales_count(self, response) -> int:
        """提取销量 / Extract sales count"""
        selectors = [
            '.tb-count::text',
            '[data-spm="sold"]::text',
            '.tb-sold-out::text'
        ]
        
        for selector in selectors:
            count = self.extract_number(response, selector)
            if count > 0:
                return count
        
        return 0
    
    def extract_product_rating(self, response) -> float:
        """提取商品评分 / Extract product rating"""
        selectors = [
            '.tb-rate-score::text',
            '.rate-score::text',
            '[data-spm="rating"]::text'
        ]
        
        for selector in selectors:
            rating = self.extract_rating(response, selector)
            if rating > 0:
                return rating
        
        return 0.0
    
    def extract_review_count(self, response) -> int:
        """提取评论数 / Extract review count"""
        selectors = [
            '.tb-rev-num::text',
            '[data-spm="reviews"] .num::text',
            '.rate-count::text'
        ]
        
        for selector in selectors:
            count = self.extract_number(response, selector)
            if count > 0:
                return count
        
        return 0
    
    def extract_shop_name(self, response) -> str:
        """提取店铺名称 / Extract shop name"""
        selectors = [
            '.tb-shop-name a::text',
            '.shop-name::text',
            '[data-spm="shop"] .name::text'
        ]
        
        for selector in selectors:
            name = self.extract_text(response, selector)
            if name:
                return name
        
        return ""
    
    def extract_description(self, response) -> str:
        """提取商品描述 / Extract product description"""
        selectors = [
            '.tb-prop .tb-prop-line::text',
            '.attributes .attr::text',
            '.tb-detail-desc::text'
        ]
        
        descriptions = []
        for selector in selectors:
            elements = response.css(selector).getall()
            descriptions.extend([elem.strip() for elem in elements if elem.strip()])
        
        return ' | '.join(descriptions[:10])  # 限制长度
    
    def extract_product_images(self, response) -> list:
        """提取商品图片 / Extract product images"""
        selectors = [
            '.tb-thumb img::attr(src)',
            '.tb-pic img::attr(src)',
            '.tb-gallery img::attr(src)'
        ]
        
        for selector in selectors:
            images = self.extract_images(response, selector)
            if images:
                return images[:5]  # 限制图片数量
        
        return []
    
    def extract_attributes(self, response) -> dict:
        """提取商品属性 / Extract product attributes"""
        attributes = {}
        
        try:
            # 提取属性表
            attr_elements = response.css('.tb-prop .tb-prop-line')
            
            for element in attr_elements:
                key = element.css('.tb-prop-key::text').get()
                value = element.css('.tb-prop-value::text').get()
                
                if key and value:
                    attributes[key.strip().rstrip(':')] = value.strip()
                    
        except Exception as e:
            self.log_debug(f"提取属性失败: {e}")
        
        return attributes