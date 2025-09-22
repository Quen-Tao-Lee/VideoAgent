"""
日志配置工具
Logging Configuration Utility
"""

import os
import sys
from pathlib import Path
from loguru import logger
from typing import Optional


def setup_logger(log_file: Optional[str] = None, 
                log_level: str = "INFO",
                max_size: str = "100MB",
                backup_count: int = 5) -> logger:
    """
    设置日志配置
    Setup logging configuration
    
    Args:
        log_file: 日志文件路径 / Log file path
        log_level: 日志级别 / Log level
        max_size: 最大文件大小 / Maximum file size
        backup_count: 备份文件数量 / Backup file count
        
    Returns:
        配置好的logger对象 / Configured logger object
    """
    # 移除默认处理器
    logger.remove()
    
    # 控制台输出格式
    console_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )
    
    # 文件输出格式
    file_format = (
        "{time:YYYY-MM-DD HH:mm:ss} | "
        "{level: <8} | "
        "{name}:{function}:{line} | "
        "{message}"
    )
    
    # 添加控制台处理器
    logger.add(
        sys.stdout,
        format=console_format,
        level=log_level,
        colorize=True
    )
    
    # 添加文件处理器
    if log_file:
        # 确保日志目录存在
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        logger.add(
            log_file,
            format=file_format,
            level=log_level,
            rotation=max_size,
            retention=backup_count,
            compression="zip",
            encoding="utf-8"
        )
    
    return logger


def get_crawler_logger(name: str = "crawler") -> logger:
    """
    获取爬虫专用logger
    Get crawler-specific logger
    
    Args:
        name: logger名称 / Logger name
        
    Returns:
        logger对象 / Logger object
    """
    return logger.bind(name=name)


class LoggerMixin:
    """
    日志混入类
    Logger Mixin Class
    """
    
    @property
    def logger(self) -> logger:
        """获取logger实例 / Get logger instance"""
        if not hasattr(self, '_logger'):
            class_name = self.__class__.__name__
            self._logger = logger.bind(name=class_name)
        return self._logger
    
    def log_info(self, message: str, **kwargs):
        """记录信息日志 / Log info message"""
        self.logger.info(message, **kwargs)
    
    def log_warning(self, message: str, **kwargs):
        """记录警告日志 / Log warning message"""
        self.logger.warning(message, **kwargs)
    
    def log_error(self, message: str, **kwargs):
        """记录错误日志 / Log error message"""
        self.logger.error(message, **kwargs)
    
    def log_debug(self, message: str, **kwargs):
        """记录调试日志 / Log debug message"""
        self.logger.debug(message, **kwargs)