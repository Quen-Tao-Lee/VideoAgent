"""
天猫爬虫
Tmall Spider
"""

import json
import re
from urllib.parse import urljoin, quote
from typing import Generator, Dict, Any

from ecommerce.base_spider import BaseEcommerceSpider
from ecommerce.items import EcommerceItem


class TmallSpider(BaseEcommerceSpider):
    """
    天猫商品爬虫
    Tmall Product Spider
    """
    
    name = 'tmall'
    platform = 'tmall'
    allowed_domains = ['tmall.com', 'detail.tmall.com', 'list.tmall.com']
    
    # 搜索URL模板
    search_url_template = "https://list.tmall.com/search_product.htm?q={keyword}&s={start}"
    
    def __init__(self, keyword: str = None, max_pages: int = 10, *args, **kwargs):
        """
        初始化天猫爬虫
        Initialize Tmall spider
        
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
        """解析搜索结果页面"""
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
            next_start = current_page * 60  # 天猫每页约60个商品
            next_page_url = self.search_url_template.format(
                keyword=quote(self.keyword),
                start=next_start
            )
            yield self.make_request(
                next_page_url,
                self.parse,
                meta={'page': current_page + 1}
            )
    
    def extract_product_links(self, response) -> list:
        """提取商品链接"""
        links = []
        
        try:
            # 天猫商品链接选择器
            selectors = [
                '.product .pic a::attr(href)',
                '.item .pic-link::attr(href)',
                '.product-item .product-title a::attr(href)'
            ]
            
            for selector in selectors:
                urls = response.css(selector).getall()
                for url in urls:
                    if url and 'detail.tmall.com' in url:
                        # 转换为绝对URL
                        if url.startswith('//'):
                            url = 'https:' + url
                        elif url.startswith('/'):
                            url = 'https://detail.tmall.com' + url
                        
                        links.append(url)
            
        except Exception as e:
            self.log_warning(f"提取商品链接失败: {e}")
        
        return links[:20]  # 限制数量
    
    def parse_product(self, response) -> Generator[EcommerceItem, None, None]:
        """解析商品详情页面"""
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
        """提取商品ID"""
        # 从URL提取
        id_match = re.search(r'id=(\d+)', response.url)
        if id_match:
            return id_match.group(1)
        
        # 从页面提取
        selectors = [
            '[data-item-id]::attr(data-item-id)',
            '#J_ItemId::attr(value)',
            'input[name="itemId"]::attr(value)'
        ]
        
        for selector in selectors:
            element = response.css(selector).get()
            if element:
                return element
        
        return ""
    
    def extract_title(self, response) -> str:
        """提取商品标题"""
        selectors = [
            '.tb-detail-hd h1::text',
            '.item-title::text',
            'h1::text',
            'title::text'
        ]
        
        for selector in selectors:
            title = self.extract_text(response, selector)
            if title and len(title) > 5:
                return title
        
        return ""
    
    def extract_current_price(self, response) -> float:
        """提取当前价格"""
        selectors = [
            '.tm-price-cur .tm-price::text',
            '.tb-rmb-num::text',
            '.price-current::text'
        ]
        
        for selector in selectors:
            price = self.extract_price(response, selector)
            if price > 0:
                return price
        
        return 0.0
    
    def extract_original_price(self, response) -> float:
        """提取原价"""
        selectors = [
            '.tm-price-ori .tm-price::text',
            '.price-original::text'
        ]
        
        for selector in selectors:
            price = self.extract_price(response, selector)
            if price > 0:
                return price
        
        return 0.0
    
    def extract_sales_count(self, response) -> int:
        """提取销量"""
        selectors = [
            '.tm-ind-sellCount .tm-count::text',
            '.sales-count::text'
        ]
        
        for selector in selectors:
            count = self.extract_number(response, selector)
            if count > 0:
                return count
        
        return 0
    
    def extract_product_rating(self, response) -> float:
        """提取商品评分"""
        selectors = [
            '.tm-rate-score .tm-rate-star::text',
            '.rate-score::text'
        ]
        
        for selector in selectors:
            rating = self.extract_rating(response, selector)
            if rating > 0:
                return rating
        
        return 0.0
    
    def extract_review_count(self, response) -> int:
        """提取评论数"""
        selectors = [
            '.tm-rate-count .tm-count::text',
            '.review-count::text'
        ]
        
        for selector in selectors:
            count = self.extract_number(response, selector)
            if count > 0:
                return count
        
        return 0
    
    def extract_shop_name(self, response) -> str:
        """提取店铺名称"""
        selectors = [
            '.slogo .shopname::text',
            '.shop-name a::text',
            '.seller-name::text'
        ]
        
        for selector in selectors:
            name = self.extract_text(response, selector)
            if name:
                return name
        
        return ""
    
    def extract_description(self, response) -> str:
        """提取商品描述"""
        selectors = [
            '.attributes-list .attr::text',
            '.tb-prop .tb-prop-line::text'
        ]
        
        descriptions = []
        for selector in selectors:
            elements = response.css(selector).getall()
            descriptions.extend([elem.strip() for elem in elements if elem.strip()])
        
        return ' | '.join(descriptions[:10])
    
    def extract_product_images(self, response) -> list:
        """提取商品图片"""
        selectors = [
            '.tb-thumb img::attr(src)',
            '.tb-pic img::attr(src)',
            '.img-list img::attr(src)'
        ]
        
        for selector in selectors:
            images = self.extract_images(response, selector)
            if images:
                return images[:5]
        
        return []
    
    def extract_attributes(self, response) -> dict:
        """提取商品属性"""
        attributes = {}
        
        try:
            # 提取属性表  
            attr_elements = response.css('.attributes-list .attr')
            
            for element in attr_elements:
                key = element.css('.attr-key::text').get()
                value = element.css('.attr-value::text').get()
                
                if key and value:
                    attributes[key.strip().rstrip(':')] = value.strip()
                    
        except Exception as e:
            self.log_debug(f"提取属性失败: {e}")
        
        return attributes