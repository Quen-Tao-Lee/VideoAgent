"""
User model for health tracking system
"""
from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Integer, String, Float, DateTime, Text

from health_tracker.models.base import Base


class User(Base):
    """用户基本信息模型"""
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    nickname = Column(String(100))
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # 基线数据
    baseline_weight = Column(Float)  # kg
    baseline_height = Column(Float)  # cm
    baseline_waist = Column(Float)   # cm
    baseline_body_fat = Column(Float)  # %
    baseline_date = Column(DateTime)
    
    # 目标数据
    target_weight = Column(Float)  # kg
    target_waist = Column(Float)   # cm
    target_body_fat = Column(Float)  # %
    target_date = Column(DateTime)
    
    # 个人信息
    age = Column(Integer)
    gender = Column(String(10))
    
    # 配置
    eating_window_start = Column(String(5), default="08:00")  # HH:MM
    eating_window_end = Column(String(5), default="16:00")    # HH:MM
    
    # 备注
    notes = Column(Text)
    
    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"
    
    def to_dict(self):
        """转换为字典"""
        return {
            'id': self.id,
            'username': self.username,
            'nickname': self.nickname,
            'baseline_weight': self.baseline_weight,
            'baseline_height': self.baseline_height,
            'baseline_waist': self.baseline_waist,
            'baseline_body_fat': self.baseline_body_fat,
            'target_weight': self.target_weight,
            'target_waist': self.target_waist,
            'target_body_fat': self.target_body_fat,
            'eating_window_start': self.eating_window_start,
            'eating_window_end': self.eating_window_end,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
