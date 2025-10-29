"""
Milestone tracking model
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, Text, Boolean, ForeignKey, Enum
import enum

from health_tracker.models.base import Base


class MilestoneType(enum.Enum):
    """里程碑类型"""
    WEEKLY = "weekly"
    BIWEEKLY = "biweekly"
    MONTHLY = "monthly"
    CUSTOM = "custom"


class MilestoneStatus(enum.Enum):
    """里程碑状态"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    ACHIEVED = "achieved"
    MISSED = "missed"


class Milestone(Base):
    """里程碑目标模型"""
    __tablename__ = 'milestones'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    
    # 里程碑信息
    name = Column(String(200), nullable=False)
    milestone_type = Column(String(20), default=MilestoneType.WEEKLY.value)
    week_number = Column(Integer)  # 第几周 (W2, W6, W12, W20)
    day_number = Column(Integer)   # 第几天 (D90)
    
    # 时间
    target_date = Column(DateTime, nullable=False, index=True)
    achieved_date = Column(DateTime)
    
    # 状态
    status = Column(String(20), default=MilestoneStatus.PENDING.value)
    
    # 目标指标
    target_weight = Column(Float)  # kg
    target_weight_loss = Column(Float)  # kg (与基线相比的减重量)
    target_waist = Column(Float)  # cm
    target_waist_reduction = Column(Float)  # cm
    target_body_fat = Column(Float)  # %
    
    # 实际达成值
    actual_weight = Column(Float)
    actual_waist = Column(Float)
    actual_body_fat = Column(Float)
    
    # 其他目标指标
    target_acne_reduction = Column(Float)  # % 新痘减少百分比
    target_sleep_improvement = Column(String(200))  # 睡眠改善描述
    
    # 检查项目 (医学指标)
    medical_checkup_required = Column(Boolean, default=False)
    medical_checkup_completed = Column(Boolean, default=False)
    medical_checkup_notes = Column(Text)
    
    # 描述和备注
    description = Column(Text)
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    def __repr__(self):
        return f"<Milestone(id={self.id}, name='{self.name}', status='{self.status}')>"
    
    def to_dict(self):
        """转换为字典"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'name': self.name,
            'milestone_type': self.milestone_type,
            'week_number': self.week_number,
            'day_number': self.day_number,
            'target_date': self.target_date.isoformat() if self.target_date else None,
            'achieved_date': self.achieved_date.isoformat() if self.achieved_date else None,
            'status': self.status,
            'target_weight': self.target_weight,
            'target_weight_loss': self.target_weight_loss,
            'target_waist': self.target_waist,
            'target_waist_reduction': self.target_waist_reduction,
            'target_body_fat': self.target_body_fat,
            'actual_weight': self.actual_weight,
            'actual_waist': self.actual_waist,
            'actual_body_fat': self.actual_body_fat,
            'medical_checkup_required': self.medical_checkup_required,
            'medical_checkup_completed': self.medical_checkup_completed,
            'description': self.description,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
