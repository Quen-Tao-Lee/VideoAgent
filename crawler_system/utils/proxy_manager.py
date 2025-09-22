"""
代理管理工具
Proxy Management Utility
"""

import random
import requests
from typing import List, Dict, Optional
from collections import deque
from threading import Lock


class ProxyManager:
    """
    代理管理器
    Proxy Manager
    """
    
    def __init__(self, proxy_list: List[str] = None):
        """
        初始化代理管理器
        Initialize proxy manager
        
        Args:
            proxy_list: 代理列表 / Proxy list
        """
        self.proxy_list = proxy_list or []
        self.working_proxies = deque()
        self.failed_proxies = set()
        self.lock = Lock()
        self.current_proxy = None
        
        if self.proxy_list:
            self.working_proxies.extend(self.proxy_list)
    
    def add_proxy(self, proxy: str):
        """
        添加代理
        Add proxy
        
        Args:
            proxy: 代理地址 / Proxy address
        """
        with self.lock:
            if proxy not in self.failed_proxies:
                self.working_proxies.append(proxy)
    
    def add_proxies(self, proxies: List[str]):
        """
        批量添加代理
        Add multiple proxies
        
        Args:
            proxies: 代理列表 / Proxy list
        """
        for proxy in proxies:
            self.add_proxy(proxy)
    
    def get_proxy(self) -> Optional[Dict[str, str]]:
        """
        获取可用代理
        Get available proxy
        
        Returns:
            代理配置字典 / Proxy configuration dictionary
        """
        with self.lock:
            if not self.working_proxies:
                return None
            
            proxy = self.working_proxies.popleft()
            self.current_proxy = proxy
            
            # 解析代理格式
            if '://' in proxy:
                # 完整格式: http://username:password@host:port
                return {'http': proxy, 'https': proxy}
            else:
                # 简单格式: host:port
                return {
                    'http': f'http://{proxy}',
                    'https': f'http://{proxy}'
                }
    
    def mark_proxy_failed(self, proxy: Optional[str] = None):
        """
        标记代理失败
        Mark proxy as failed
        
        Args:
            proxy: 代理地址，如果为None则使用当前代理 / Proxy address, use current if None
        """
        proxy_to_mark = proxy or self.current_proxy
        if proxy_to_mark:
            with self.lock:
                self.failed_proxies.add(proxy_to_mark)
                # 从工作队列中移除
                if proxy_to_mark in self.working_proxies:
                    self.working_proxies.remove(proxy_to_mark)
    
    def mark_proxy_success(self, proxy: Optional[str] = None):
        """
        标记代理成功
        Mark proxy as successful
        
        Args:
            proxy: 代理地址，如果为None则使用当前代理 / Proxy address, use current if None
        """
        proxy_to_mark = proxy or self.current_proxy
        if proxy_to_mark:
            with self.lock:
                # 将成功的代理放回队列末尾
                self.working_proxies.append(proxy_to_mark)
    
    def test_proxy(self, proxy: str, test_url: str = "http://httpbin.org/ip", 
                   timeout: int = 10) -> bool:
        """
        测试代理是否可用
        Test if proxy is working
        
        Args:
            proxy: 代理地址 / Proxy address
            test_url: 测试URL / Test URL
            timeout: 超时时间 / Timeout
            
        Returns:
            是否可用 / Whether it's working
        """
        try:
            proxy_dict = {
                'http': f'http://{proxy}' if '://' not in proxy else proxy,
                'https': f'http://{proxy}' if '://' not in proxy else proxy
            }
            
            response = requests.get(
                test_url,
                proxies=proxy_dict,
                timeout=timeout,
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            )
            
            return response.status_code == 200
            
        except Exception:
            return False
    
    def test_all_proxies(self, test_url: str = "http://httpbin.org/ip", 
                        timeout: int = 10) -> List[str]:
        """
        测试所有代理
        Test all proxies
        
        Args:
            test_url: 测试URL / Test URL
            timeout: 超时时间 / Timeout
            
        Returns:
            可用代理列表 / Working proxy list
        """
        working_proxies = []
        
        for proxy in self.proxy_list:
            if self.test_proxy(proxy, test_url, timeout):
                working_proxies.append(proxy)
            else:
                self.mark_proxy_failed(proxy)
        
        return working_proxies
    
    def get_random_proxy(self) -> Optional[Dict[str, str]]:
        """
        获取随机代理
        Get random proxy
        
        Returns:
            随机代理配置 / Random proxy configuration
        """
        with self.lock:
            if not self.working_proxies:
                return None
            
            proxy = random.choice(self.working_proxies)
            self.current_proxy = proxy
            
            if '://' in proxy:
                return {'http': proxy, 'https': proxy}
            else:
                return {
                    'http': f'http://{proxy}',
                    'https': f'http://{proxy}'
                }
    
    def get_proxy_count(self) -> Dict[str, int]:
        """
        获取代理统计信息
        Get proxy statistics
        
        Returns:
            统计信息字典 / Statistics dictionary
        """
        with self.lock:
            return {
                'total': len(self.proxy_list),
                'working': len(self.working_proxies),
                'failed': len(self.failed_proxies)
            }
    
    def reset_failed_proxies(self):
        """重置失败代理列表 / Reset failed proxy list"""
        with self.lock:
            self.failed_proxies.clear()
            self.working_proxies.extend(self.proxy_list)
    
    def load_proxies_from_file(self, file_path: str):
        """
        从文件加载代理列表
        Load proxy list from file
        
        Args:
            file_path: 文件路径 / File path
        """
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                proxies = [line.strip() for line in f if line.strip()]
                self.add_proxies(proxies)
        except Exception as e:
            print(f"加载代理文件失败: {e}")
    
    def save_working_proxies(self, file_path: str):
        """
        保存可用代理到文件
        Save working proxies to file
        
        Args:
            file_path: 文件路径 / File path
        """
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                for proxy in self.working_proxies:
                    f.write(f"{proxy}\n")
        except Exception as e:
            print(f"保存代理文件失败: {e}")


class ProxyRotator:
    """
    代理轮换器
    Proxy Rotator
    """
    
    def __init__(self, proxy_manager: ProxyManager, rotation_count: int = 10):
        """
        初始化代理轮换器
        Initialize proxy rotator
        
        Args:
            proxy_manager: 代理管理器 / Proxy manager
            rotation_count: 轮换次数 / Rotation count
        """
        self.proxy_manager = proxy_manager
        self.rotation_count = rotation_count
        self.current_count = 0
        self.current_proxy = None
    
    def get_proxy(self) -> Optional[Dict[str, str]]:
        """
        获取代理（自动轮换）
        Get proxy with automatic rotation
        
        Returns:
            代理配置 / Proxy configuration
        """
        if self.current_count >= self.rotation_count or not self.current_proxy:
            self.current_proxy = self.proxy_manager.get_proxy()
            self.current_count = 0
        
        self.current_count += 1
        return self.current_proxy
    
    def mark_failed(self):
        """标记当前代理失败 / Mark current proxy as failed"""
        if self.current_proxy:
            self.proxy_manager.mark_proxy_failed()
            self.current_proxy = None
            self.current_count = 0
    
    def mark_success(self):
        """标记当前代理成功 / Mark current proxy as successful"""
        if self.current_proxy:
            self.proxy_manager.mark_proxy_success()