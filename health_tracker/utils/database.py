"""
Database manager for health tracker
"""
from typing import Optional, List
from datetime import datetime, timedelta
from sqlalchemy import create_engine, and_, or_
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.ext.declarative import declarative_base

from health_tracker.models import (
    User, DailyCheckIn, Milestone, SafetyAlert,
    MilestoneStatus, AlertSeverity
)

Base = declarative_base()


class DatabaseManager:
    """健康追踪数据库管理器"""
    
    def __init__(self, db_url: str = "sqlite:///health_tracker.db"):
        """
        初始化数据库管理器
        
        Args:
            db_url: 数据库连接URL
        """
        self.engine = create_engine(db_url, echo=False)
        self.SessionLocal = sessionmaker(bind=self.engine)
        
    def create_tables(self):
        """创建所有表"""
        from health_tracker.models.user import Base as UserBase
        from health_tracker.models.daily_checkin import Base as CheckInBase
        from health_tracker.models.milestone import Base as MilestoneBase
        from health_tracker.models.safety_alert import Base as AlertBase
        
        UserBase.metadata.create_all(self.engine)
        CheckInBase.metadata.create_all(self.engine)
        MilestoneBase.metadata.create_all(self.engine)
        AlertBase.metadata.create_all(self.engine)
        
    def get_session(self) -> Session:
        """获取数据库会话"""
        return self.SessionLocal()
    
    # User operations
    def create_user(self, username: str, **kwargs) -> User:
        """创建用户"""
        session = self.get_session()
        try:
            user = User(username=username, **kwargs)
            session.add(user)
            session.commit()
            session.refresh(user)
            return user
        finally:
            session.close()
    
    def get_user(self, user_id: int) -> Optional[User]:
        """获取用户"""
        session = self.get_session()
        try:
            return session.query(User).filter(User.id == user_id).first()
        finally:
            session.close()
    
    def get_user_by_username(self, username: str) -> Optional[User]:
        """通过用户名获取用户"""
        session = self.get_session()
        try:
            return session.query(User).filter(User.username == username).first()
        finally:
            session.close()
    
    def update_user(self, user_id: int, **kwargs) -> Optional[User]:
        """更新用户信息"""
        session = self.get_session()
        try:
            user = session.query(User).filter(User.id == user_id).first()
            if user:
                for key, value in kwargs.items():
                    if hasattr(user, key):
                        setattr(user, key, value)
                session.commit()
                session.refresh(user)
            return user
        finally:
            session.close()
    
    # DailyCheckIn operations
    def create_checkin(self, user_id: int, check_date: datetime, **kwargs) -> DailyCheckIn:
        """创建每日打卡"""
        session = self.get_session()
        try:
            checkin = DailyCheckIn(user_id=user_id, check_date=check_date, **kwargs)
            session.add(checkin)
            session.commit()
            session.refresh(checkin)
            return checkin
        finally:
            session.close()
    
    def get_checkin(self, checkin_id: int) -> Optional[DailyCheckIn]:
        """获取打卡记录"""
        session = self.get_session()
        try:
            return session.query(DailyCheckIn).filter(DailyCheckIn.id == checkin_id).first()
        finally:
            session.close()
    
    def get_user_checkins(
        self, 
        user_id: int, 
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[DailyCheckIn]:
        """获取用户的打卡记录"""
        session = self.get_session()
        try:
            query = session.query(DailyCheckIn).filter(DailyCheckIn.user_id == user_id)
            
            if start_date:
                query = query.filter(DailyCheckIn.check_date >= start_date)
            if end_date:
                query = query.filter(DailyCheckIn.check_date <= end_date)
            
            return query.order_by(DailyCheckIn.check_date.desc()).all()
        finally:
            session.close()
    
    def get_checkin_by_date(self, user_id: int, check_date: datetime) -> Optional[DailyCheckIn]:
        """获取特定日期的打卡记录"""
        session = self.get_session()
        try:
            return session.query(DailyCheckIn).filter(
                and_(
                    DailyCheckIn.user_id == user_id,
                    DailyCheckIn.check_date == check_date
                )
            ).first()
        finally:
            session.close()
    
    def update_checkin(self, checkin_id: int, **kwargs) -> Optional[DailyCheckIn]:
        """更新打卡记录"""
        session = self.get_session()
        try:
            checkin = session.query(DailyCheckIn).filter(DailyCheckIn.id == checkin_id).first()
            if checkin:
                for key, value in kwargs.items():
                    if hasattr(checkin, key):
                        setattr(checkin, key, value)
                session.commit()
                session.refresh(checkin)
            return checkin
        finally:
            session.close()
    
    # Milestone operations
    def create_milestone(self, user_id: int, name: str, target_date: datetime, **kwargs) -> Milestone:
        """创建里程碑"""
        session = self.get_session()
        try:
            milestone = Milestone(user_id=user_id, name=name, target_date=target_date, **kwargs)
            session.add(milestone)
            session.commit()
            session.refresh(milestone)
            return milestone
        finally:
            session.close()
    
    def get_milestone(self, milestone_id: int) -> Optional[Milestone]:
        """获取里程碑"""
        session = self.get_session()
        try:
            return session.query(Milestone).filter(Milestone.id == milestone_id).first()
        finally:
            session.close()
    
    def get_user_milestones(
        self, 
        user_id: int, 
        status: Optional[str] = None
    ) -> List[Milestone]:
        """获取用户的里程碑"""
        session = self.get_session()
        try:
            query = session.query(Milestone).filter(Milestone.user_id == user_id)
            
            if status:
                query = query.filter(Milestone.status == status)
            
            return query.order_by(Milestone.target_date).all()
        finally:
            session.close()
    
    def update_milestone(self, milestone_id: int, **kwargs) -> Optional[Milestone]:
        """更新里程碑"""
        session = self.get_session()
        try:
            milestone = session.query(Milestone).filter(Milestone.id == milestone_id).first()
            if milestone:
                for key, value in kwargs.items():
                    if hasattr(milestone, key):
                        setattr(milestone, key, value)
                session.commit()
                session.refresh(milestone)
            return milestone
        finally:
            session.close()
    
    # SafetyAlert operations
    def create_alert(
        self, 
        user_id: int, 
        alert_type: str, 
        severity: str,
        title: str,
        message: str,
        **kwargs
    ) -> SafetyAlert:
        """创建安全警报"""
        session = self.get_session()
        try:
            alert = SafetyAlert(
                user_id=user_id,
                alert_type=alert_type,
                severity=severity,
                title=title,
                message=message,
                **kwargs
            )
            session.add(alert)
            session.commit()
            session.refresh(alert)
            return alert
        finally:
            session.close()
    
    def get_alert(self, alert_id: int) -> Optional[SafetyAlert]:
        """获取警报"""
        session = self.get_session()
        try:
            return session.query(SafetyAlert).filter(SafetyAlert.id == alert_id).first()
        finally:
            session.close()
    
    def get_user_alerts(
        self, 
        user_id: int,
        is_active: Optional[bool] = None,
        is_read: Optional[bool] = None
    ) -> List[SafetyAlert]:
        """获取用户的警报"""
        session = self.get_session()
        try:
            query = session.query(SafetyAlert).filter(SafetyAlert.user_id == user_id)
            
            if is_active is not None:
                query = query.filter(SafetyAlert.is_active == is_active)
            if is_read is not None:
                query = query.filter(SafetyAlert.is_read == is_read)
            
            return query.order_by(SafetyAlert.trigger_date.desc()).all()
        finally:
            session.close()
    
    def update_alert(self, alert_id: int, **kwargs) -> Optional[SafetyAlert]:
        """更新警报"""
        session = self.get_session()
        try:
            alert = session.query(SafetyAlert).filter(SafetyAlert.id == alert_id).first()
            if alert:
                for key, value in kwargs.items():
                    if hasattr(alert, key):
                        setattr(alert, key, value)
                session.commit()
                session.refresh(alert)
            return alert
        finally:
            session.close()
    
    def mark_alert_as_read(self, alert_id: int) -> Optional[SafetyAlert]:
        """标记警报为已读"""
        return self.update_alert(alert_id, is_read=True)
    
    def resolve_alert(self, alert_id: int, resolution_notes: str = "") -> Optional[SafetyAlert]:
        """解决警报"""
        return self.update_alert(
            alert_id,
            is_resolved=True,
            is_active=False,
            resolved_date=datetime.now(),
            resolution_notes=resolution_notes
        )
