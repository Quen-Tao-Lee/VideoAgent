"""
用户代理轮换工具
User Agent Rotation Utility
"""

import random
from typing import List
from fake_useragent import UserAgent


class UserAgentRotator:
    """
    用户代理轮换器
    User Agent Rotator
    """
    
    def __init__(self, use_external: bool = True):
        """
        初始化用户代理轮换器
        Initialize user agent rotator
        
        Args:
            use_external: 是否使用外部库 / Whether to use external library
        """
        self.use_external = use_external
        self.ua_generator = None
        
        if use_external:
            try:
                self.ua_generator = UserAgent()
            except Exception:
                self.use_external = False
        
        # 备用用户代理列表
        self.backup_agents = [
            # Chrome
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36",
            
            # Firefox
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:109.0) Gecko/20100101 Firefox/119.0",
            "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0",
            
            # Safari
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15",
            
            # Edge
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0",
            
            # Mobile Chrome
            "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1",
        ]
    
    def get_random_agent(self) -> str:
        """
        获取随机用户代理
        Get random user agent
        
        Returns:
            用户代理字符串 / User agent string
        """
        if self.use_external and self.ua_generator:
            try:
                return self.ua_generator.random
            except Exception:
                pass
        
        return random.choice(self.backup_agents)
    
    def get_chrome_agent(self) -> str:
        """
        获取Chrome用户代理
        Get Chrome user agent
        
        Returns:
            Chrome用户代理字符串 / Chrome user agent string
        """
        if self.use_external and self.ua_generator:
            try:
                return self.ua_generator.chrome
            except Exception:
                pass
        
        chrome_agents = [ua for ua in self.backup_agents if 'Chrome' in ua and 'Edg' not in ua]
        return random.choice(chrome_agents)
    
    def get_firefox_agent(self) -> str:
        """
        获取Firefox用户代理
        Get Firefox user agent
        
        Returns:
            Firefox用户代理字符串 / Firefox user agent string
        """
        if self.use_external and self.ua_generator:
            try:
                return self.ua_generator.firefox
            except Exception:
                pass
        
        firefox_agents = [ua for ua in self.backup_agents if 'Firefox' in ua]
        return random.choice(firefox_agents)
    
    def get_mobile_agent(self) -> str:
        """
        获取移动端用户代理
        Get mobile user agent
        
        Returns:
            移动端用户代理字符串 / Mobile user agent string
        """
        mobile_agents = [ua for ua in self.backup_agents if 'Mobile' in ua or 'Android' in ua or 'iPhone' in ua]
        return random.choice(mobile_agents)
    
    def get_desktop_agent(self) -> str:
        """
        获取桌面端用户代理
        Get desktop user agent
        
        Returns:
            桌面端用户代理字符串 / Desktop user agent string
        """
        desktop_agents = [ua for ua in self.backup_agents if 'Mobile' not in ua and 'Android' not in ua and 'iPhone' not in ua]
        return random.choice(desktop_agents)
    
    def get_headers(self, custom_headers: dict = None) -> dict:
        """
        获取完整的请求头
        Get complete request headers
        
        Args:
            custom_headers: 自定义请求头 / Custom headers
            
        Returns:
            请求头字典 / Headers dictionary
        """
        headers = {
            'User-Agent': self.get_random_agent(),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Cache-Control': 'max-age=0'
        }
        
        if custom_headers:
            headers.update(custom_headers)
        
        return headers