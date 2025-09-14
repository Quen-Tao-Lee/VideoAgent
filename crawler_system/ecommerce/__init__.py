"""电商爬虫模块 - E-commerce Crawler Module"""

from .items import EcommerceItem
from .pipelines import EcommercePipeline
from .base_spider import BaseEcommerceSpider

__all__ = ["EcommerceItem", "EcommercePipeline", "BaseEcommerceSpider"]