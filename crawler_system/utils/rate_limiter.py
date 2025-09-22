"""
请求频率限制工具
Rate Limiting Utility
"""

import time
import asyncio
import random
from typing import Union, Tuple
from collections import defaultdict, deque
from threading import Lock


class RateLimiter:
    """
    请求频率限制器
    Request Rate Limiter
    """
    
    def __init__(self, delay_range: Union[float, Tuple[float, float]] = (1, 3)):
        """
        初始化频率限制器
        Initialize rate limiter
        
        Args:
            delay_range: 延迟范围，可以是固定值或范围 / Delay range, can be fixed value or range
        """
        if isinstance(delay_range, (int, float)):
            self.min_delay = self.max_delay = float(delay_range)
        else:
            self.min_delay, self.max_delay = delay_range
        
        self.last_request_time = defaultdict(float)
        self.request_counts = defaultdict(lambda: deque())
        self.lock = Lock()
    
    def wait(self, domain: str = "default"):
        """
        等待适当的时间间隔
        Wait for appropriate time interval
        
        Args:
            domain: 域名或标识符 / Domain or identifier
        """
        with self.lock:
            current_time = time.time()
            last_time = self.last_request_time.get(domain, 0)
            
            # 计算需要等待的时间
            delay = random.uniform(self.min_delay, self.max_delay)
            elapsed = current_time - last_time
            
            if elapsed < delay:
                wait_time = delay - elapsed
                time.sleep(wait_time)
            
            self.last_request_time[domain] = time.time()
    
    async def async_wait(self, domain: str = "default"):
        """
        异步等待适当的时间间隔
        Async wait for appropriate time interval
        
        Args:
            domain: 域名或标识符 / Domain or identifier
        """
        current_time = time.time()
        last_time = self.last_request_time.get(domain, 0)
        
        # 计算需要等待的时间
        delay = random.uniform(self.min_delay, self.max_delay)
        elapsed = current_time - last_time
        
        if elapsed < delay:
            wait_time = delay - elapsed
            await asyncio.sleep(wait_time)
        
        self.last_request_time[domain] = time.time()
    
    def check_rate_limit(self, domain: str, max_requests: int, time_window: int) -> bool:
        """
        检查是否超过速率限制
        Check if rate limit is exceeded
        
        Args:
            domain: 域名 / Domain
            max_requests: 最大请求数 / Maximum requests
            time_window: 时间窗口（秒） / Time window in seconds
            
        Returns:
            是否允许请求 / Whether request is allowed
        """
        current_time = time.time()
        
        with self.lock:
            # 清理过期的请求记录
            while (self.request_counts[domain] and 
                   current_time - self.request_counts[domain][0] > time_window):
                self.request_counts[domain].popleft()
            
            # 检查当前请求数
            if len(self.request_counts[domain]) >= max_requests:
                return False
            
            # 记录当前请求
            self.request_counts[domain].append(current_time)
            return True
    
    def get_wait_time(self, domain: str, max_requests: int, time_window: int) -> float:
        """
        获取需要等待的时间
        Get required wait time
        
        Args:
            domain: 域名 / Domain
            max_requests: 最大请求数 / Maximum requests
            time_window: 时间窗口（秒） / Time window in seconds
            
        Returns:
            等待时间（秒） / Wait time in seconds
        """
        if self.check_rate_limit(domain, max_requests, time_window):
            return 0
        
        # 计算需要等待到最早请求过期的时间
        if self.request_counts[domain]:
            oldest_request = self.request_counts[domain][0]
            return max(0, time_window - (time.time() - oldest_request))
        
        return 0


class AdaptiveRateLimiter:
    """
    自适应频率限制器
    Adaptive Rate Limiter
    """
    
    def __init__(self, initial_delay: float = 2.0, 
                 min_delay: float = 0.5, 
                 max_delay: float = 10.0):
        """
        初始化自适应频率限制器
        Initialize adaptive rate limiter
        
        Args:
            initial_delay: 初始延迟 / Initial delay
            min_delay: 最小延迟 / Minimum delay
            max_delay: 最大延迟 / Maximum delay
        """
        self.current_delay = initial_delay
        self.min_delay = min_delay
        self.max_delay = max_delay
        self.success_count = 0
        self.error_count = 0
        self.last_request_time = 0
        self.lock = Lock()
    
    def on_success(self):
        """
        记录成功请求
        Record successful request
        """
        with self.lock:
            self.success_count += 1
            self.error_count = 0  # 重置错误计数
            
            # 连续成功则减少延迟
            if self.success_count >= 5:
                self.current_delay = max(
                    self.min_delay, 
                    self.current_delay * 0.9
                )
                self.success_count = 0
    
    def on_error(self, error_type: str = "general"):
        """
        记录错误请求
        Record failed request
        
        Args:
            error_type: 错误类型 / Error type
        """
        with self.lock:
            self.error_count += 1
            self.success_count = 0  # 重置成功计数
            
            # 根据错误类型调整延迟
            if error_type in ["rate_limit", "429", "blocked"]:
                # 被限制时大幅增加延迟
                self.current_delay = min(
                    self.max_delay,
                    self.current_delay * 2.0
                )
            else:
                # 其他错误适度增加延迟
                self.current_delay = min(
                    self.max_delay,
                    self.current_delay * 1.2
                )
    
    def wait(self):
        """等待适当的时间间隔 / Wait for appropriate time interval"""
        with self.lock:
            current_time = time.time()
            elapsed = current_time - self.last_request_time
            
            if elapsed < self.current_delay:
                wait_time = self.current_delay - elapsed
                time.sleep(wait_time)
            
            self.last_request_time = time.time()
    
    async def async_wait(self):
        """异步等待适当的时间间隔 / Async wait for appropriate time interval"""
        current_time = time.time()
        elapsed = current_time - self.last_request_time
        
        if elapsed < self.current_delay:
            wait_time = self.current_delay - elapsed
            await asyncio.sleep(wait_time)
        
        self.last_request_time = time.time()
    
    def get_current_delay(self) -> float:
        """获取当前延迟 / Get current delay"""
        return self.current_delay