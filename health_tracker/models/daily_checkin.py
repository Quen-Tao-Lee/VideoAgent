"""
Daily check-in model for health tracking
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey, JSON
from sqlalchemy.orm import relationship

from health_tracker.models.base import Base


class DailyCheckIn(Base):
    """每日打卡记录模型"""
    __tablename__ = 'daily_checkins'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    check_date = Column(DateTime, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # 体重相关
    weight = Column(Float)  # kg
    waist_circumference = Column(Float)  # cm
    body_fat_percentage = Column(Float)  # %
    
    # 进食窗口
    eating_window_start = Column(String(5))  # HH:MM - 实际开始时间
    eating_window_end = Column(String(5))    # HH:MM - 实际结束时间
    eating_window_followed = Column(Boolean, default=False)  # 是否遵守进食窗口
    
    # 饮食
    meals_count = Column(Integer, default=0)  # 餐次
    psmf_day = Column(Boolean, default=False)  # 是否PSMF日
    diet_notes = Column(Text)  # 饮食备注
    
    # 运动
    exercise_completed = Column(Boolean, default=False)
    exercise_type = Column(String(100))  # 运动类型
    exercise_duration = Column(Integer)  # 分钟
    steps_count = Column(Integer)  # 步数
    
    # 睡眠
    sleep_hours = Column(Float)  # 睡眠小时数
    sleep_quality = Column(String(20))  # 睡眠质量: excellent, good, fair, poor
    sleep_notes = Column(Text)
    
    # 护肤
    skincare_completed = Column(Boolean, default=False)
    skincare_routine = Column(Text)  # 护肤流程描述
    
    # 剃须
    shaving_completed = Column(Boolean, default=False)
    shaving_notes = Column(Text)
    
    # 症状追踪
    daytime_drowsiness = Column(Integer)  # 1-10评分，1=非常清醒，10=非常困
    eye_puffiness = Column(Integer)  # 1-10评分
    dark_circles = Column(Integer)  # 1-10评分
    acne_count = Column(Integer)  # 新痘数量
    
    # 自定义打卡项
    custom_items = Column(JSON)  # 存储自定义打卡项 {item_name: value}
    
    # 图片
    photos = Column(JSON)  # 存储图片URL列表
    
    # 整体备注
    notes = Column(Text)
    
    def __repr__(self):
        return f"<DailyCheckIn(id={self.id}, user_id={self.user_id}, date={self.check_date})>"
    
    def to_dict(self):
        """转换为字典"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'check_date': self.check_date.isoformat() if self.check_date else None,
            'weight': self.weight,
            'waist_circumference': self.waist_circumference,
            'body_fat_percentage': self.body_fat_percentage,
            'eating_window_start': self.eating_window_start,
            'eating_window_end': self.eating_window_end,
            'eating_window_followed': self.eating_window_followed,
            'meals_count': self.meals_count,
            'psmf_day': self.psmf_day,
            'exercise_completed': self.exercise_completed,
            'exercise_type': self.exercise_type,
            'exercise_duration': self.exercise_duration,
            'steps_count': self.steps_count,
            'sleep_hours': self.sleep_hours,
            'sleep_quality': self.sleep_quality,
            'skincare_completed': self.skincare_completed,
            'shaving_completed': self.shaving_completed,
            'daytime_drowsiness': self.daytime_drowsiness,
            'eye_puffiness': self.eye_puffiness,
            'dark_circles': self.dark_circles,
            'acne_count': self.acne_count,
            'custom_items': self.custom_items,
            'photos': self.photos,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
