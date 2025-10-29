"""
Configuration settings for health tracker
"""
import os
from typing import Dict


class Config:
    """基础配置"""
    
    # 数据库配置
    DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///health_tracker.db')
    
    # API配置
    API_HOST = os.getenv('API_HOST', '0.0.0.0')
    API_PORT = int(os.getenv('API_PORT', 5000))
    API_DEBUG = os.getenv('API_DEBUG', 'False').lower() == 'true'
    
    # 安全配置
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-here')
    
    # 进食窗口默认配置
    DEFAULT_EATING_WINDOW_START = "08:00"
    DEFAULT_EATING_WINDOW_END = "16:00"
    
    # 体重管理阈值
    SAFE_WEIGHT_LOSS_MIN = 0.5  # kg/周
    SAFE_WEIGHT_LOSS_MAX = 1.0  # kg/周
    RAPID_WEIGHT_LOSS_THRESHOLD = 1.5  # kg/周
    SLOW_WEIGHT_LOSS_THRESHOLD = 0.3  # kg/周
    
    # 目标阈值
    TARGET_STEPS = 8000  # 日均步数目标
    TARGET_SLEEP_HOURS = 7.5  # 睡眠时长目标
    TARGET_EXERCISE_RATE = 0.8  # 运动完成率目标
    TARGET_EATING_WINDOW_COMPLIANCE = 0.9  # 进食窗口遵守率目标
    
    # PSMF配置
    PSMF_DAYS_PER_WEEK = 2
    
    # 里程碑配置
    MILESTONE_WEEKS = {
        'W2': 2,
        'W6': 6,
        'W12': 12,
        'W20': 20,
    }
    
    # 医学检查里程碑
    MEDICAL_CHECKUP_DAYS = [90]  # D90需要复查
    
    @classmethod
    def to_dict(cls) -> Dict:
        """转换为字典"""
        return {
            key: getattr(cls, key)
            for key in dir(cls)
            if not key.startswith('_') and not callable(getattr(cls, key))
        }


class DevelopmentConfig(Config):
    """开发环境配置"""
    API_DEBUG = True


class ProductionConfig(Config):
    """生产环境配置"""
    API_DEBUG = False


# 根据环境变量选择配置
config_map = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': Config
}

def get_config(env: str = None) -> Config:
    """
    获取配置对象
    
    Args:
        env: 环境名称 (development/production)
    
    Returns:
        配置对象
    """
    if env is None:
        env = os.getenv('FLASK_ENV', 'default')
    
    return config_map.get(env, Config)
