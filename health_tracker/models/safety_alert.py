"""
Safety alert model for medical monitoring
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, Boolean, ForeignKey, Enum
import enum

from health_tracker.models.base import Base


class AlertSeverity(enum.Enum):
    """警报严重程度"""
    INFO = "info"           # 信息提示
    WARNING = "warning"     # 警告
    DANGER = "danger"       # 危险
    CRITICAL = "critical"   # 紧急


class AlertType(enum.Enum):
    """警报类型"""
    WEIGHT_LOSS_TOO_FAST = "weight_loss_too_fast"  # 体重下降过快
    WEIGHT_LOSS_TOO_SLOW = "weight_loss_too_slow"  # 体重下降过慢
    WEIGHT_PLATEAU = "weight_plateau"              # 体重平台期
    BLOOD_PRESSURE = "blood_pressure"              # 血压异常
    SLEEP_QUALITY = "sleep_quality"                # 睡眠质量差
    EXCESSIVE_FATIGUE = "excessive_fatigue"        # 过度疲劳
    INJURY_RISK = "injury_risk"                    # 运动损伤风险
    MEDICAL_CHECKUP = "medical_checkup"            # 需要医学检查
    CUSTOM = "custom"                              # 自定义警报


class SafetyAlert(Base):
    """医学安全警报模型"""
    __tablename__ = 'safety_alerts'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False, index=True)
    
    # 警报信息
    alert_type = Column(String(50), nullable=False)
    severity = Column(String(20), nullable=False, default=AlertSeverity.INFO.value)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    
    # 触发条件
    triggered_by = Column(Text)  # 描述触发警报的数据或条件
    trigger_date = Column(DateTime, default=datetime.now, nullable=False, index=True)
    
    # 状态
    is_active = Column(Boolean, default=True)
    is_read = Column(Boolean, default=False)
    is_resolved = Column(Boolean, default=False)
    resolved_date = Column(DateTime)
    resolution_notes = Column(Text)
    
    # 建议行动
    recommended_action = Column(Text)
    
    # 关联数据
    related_checkin_id = Column(Integer)
    related_milestone_id = Column(Integer)
    
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    def __repr__(self):
        return f"<SafetyAlert(id={self.id}, type='{self.alert_type}', severity='{self.severity}')>"
    
    def to_dict(self):
        """转换为字典"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'alert_type': self.alert_type,
            'severity': self.severity,
            'title': self.title,
            'message': self.message,
            'triggered_by': self.triggered_by,
            'trigger_date': self.trigger_date.isoformat() if self.trigger_date else None,
            'is_active': self.is_active,
            'is_read': self.is_read,
            'is_resolved': self.is_resolved,
            'resolved_date': self.resolved_date.isoformat() if self.resolved_date else None,
            'recommended_action': self.recommended_action,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
