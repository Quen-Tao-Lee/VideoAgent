"""
Basic tests for health tracker functionality
"""
import pytest
from datetime import datetime, timedelta
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from health_tracker.utils.database import DatabaseManager
from health_tracker.analysis.auto_correction import AutoCorrectionAlgorithm
from health_tracker.analysis.report_generator import ReportGenerator


class TestDatabaseManager:
    """测试数据库管理器"""
    
    @pytest.fixture
    def db_manager(self):
        """创建测试数据库管理器"""
        db = DatabaseManager(db_url="sqlite:///:memory:")
        db.create_tables()
        return db
    
    def test_create_user(self, db_manager):
        """测试创建用户"""
        user = db_manager.create_user(
            username="testuser",
            nickname="测试用户",
            baseline_weight=90.0,
            baseline_height=178.0,
            target_weight=75.0
        )
        
        assert user.id is not None
        assert user.username == "testuser"
        assert user.baseline_weight == 90.0
    
    def test_create_checkin(self, db_manager):
        """测试创建打卡"""
        # 先创建用户
        user = db_manager.create_user(username="testuser")
        
        # 创建打卡
        checkin = db_manager.create_checkin(
            user_id=user.id,
            check_date=datetime.now(),
            weight=89.5,
            eating_window_followed=True
        )
        
        assert checkin.id is not None
        assert checkin.user_id == user.id
        assert checkin.weight == 89.5
    
    def test_get_user_checkins(self, db_manager):
        """测试获取用户打卡列表"""
        user = db_manager.create_user(username="testuser")
        
        # 创建多个打卡
        for i in range(7):
            db_manager.create_checkin(
                user_id=user.id,
                check_date=datetime.now() - timedelta(days=i),
                weight=90.0 - i * 0.5
            )
        
        checkins = db_manager.get_user_checkins(user.id)
        assert len(checkins) == 7
    
    def test_create_milestone(self, db_manager):
        """测试创建里程碑"""
        user = db_manager.create_user(username="testuser")
        
        milestone = db_manager.create_milestone(
            user_id=user.id,
            name="W2里程碑",
            target_date=datetime.now() + timedelta(weeks=2),
            target_weight=88.5
        )
        
        assert milestone.id is not None
        assert milestone.name == "W2里程碑"
        assert milestone.target_weight == 88.5
    
    def test_create_alert(self, db_manager):
        """测试创建警报"""
        user = db_manager.create_user(username="testuser")
        
        alert = db_manager.create_alert(
            user_id=user.id,
            alert_type="weight_loss_too_fast",
            severity="danger",
            title="体重下降过快",
            message="需要注意"
        )
        
        assert alert.id is not None
        assert alert.alert_type == "weight_loss_too_fast"
        assert alert.severity == "danger"


class TestAutoCorrectionAlgorithm:
    """测试自动纠偏算法"""
    
    @pytest.fixture
    def setup_data(self):
        """设置测试数据"""
        db = DatabaseManager(db_url="sqlite:///:memory:")
        db.create_tables()
        
        user = db.create_user(
            username="testuser",
            baseline_weight=90.0,
            baseline_height=178.0,
            baseline_date=datetime.now() - timedelta(days=14)
        )
        
        # 创建14天的打卡数据
        checkins = []
        for i in range(14):
            checkin = db.create_checkin(
                user_id=user.id,
                check_date=datetime.now() - timedelta(days=13-i),
                weight=90.0 - i * 0.5,  # 每天减重0.5kg
                eating_window_followed=True,
                exercise_completed=i % 2 == 0,
                sleep_hours=7.0 + (i % 3),
                steps_count=8000 + i * 100
            )
            checkins.append(checkin)
        
        return user, checkins
    
    def test_analyze_weight_change(self, setup_data):
        """测试体重变化分析"""
        user, checkins = setup_data
        
        algo = AutoCorrectionAlgorithm(user, checkins)
        suggestions = algo.analyze()
        
        # 应该检测到体重下降过快（每天0.5kg）
        weight_suggestions = [s for s in suggestions if s.category == "diet"]
        assert len(weight_suggestions) > 0
    
    def test_weekly_summary(self, setup_data):
        """测试周度总结"""
        user, checkins = setup_data
        
        algo = AutoCorrectionAlgorithm(user, checkins)
        summary = algo.get_weekly_summary()
        
        assert 'period' in summary
        assert 'weight_change' in summary
        assert 'compliance' in summary
        assert 'averages' in summary


class TestReportGenerator:
    """测试报告生成器"""
    
    @pytest.fixture
    def setup_report_data(self):
        """设置报告测试数据"""
        db = DatabaseManager(db_url="sqlite:///:memory:")
        db.create_tables()
        
        user = db.create_user(
            username="testuser",
            baseline_weight=90.0,
            baseline_height=178.0,
            baseline_waist=95.0,
            baseline_date=datetime.now() - timedelta(days=14)
        )
        
        # 创建14天的打卡数据
        checkins = []
        for i in range(14):
            checkin = db.create_checkin(
                user_id=user.id,
                check_date=datetime.now() - timedelta(days=13-i),
                weight=90.0 - i * 0.3,
                waist_circumference=95.0 - i * 0.2,
                eating_window_followed=i % 7 < 6,
                exercise_completed=i % 3 != 0,
                sleep_hours=7.0 + (i % 2),
                steps_count=8000 + i * 100,
                skincare_completed=True,
                acne_count=max(0, 5 - i // 3)
            )
            checkins.append(checkin)
        
        return db, user, checkins
    
    def test_generate_weekly_report(self, setup_report_data):
        """测试生成周度报告"""
        db, user, checkins = setup_report_data
        
        generator = ReportGenerator(user, checkins)
        report = generator.generate_weekly_report()
        
        assert report.user_id == user.id
        assert report.starting_weight is not None
        assert report.ending_weight is not None
        assert report.weight_change is not None
        assert 0 <= report.eating_window_compliance <= 1
        assert report.summary is not None
        assert isinstance(report.highlights, list)
        assert isinstance(report.concerns, list)
    
    def test_generate_milestone_report(self, setup_report_data):
        """测试生成里程碑报告"""
        db, user, checkins = setup_report_data
        
        # 创建里程碑
        milestone = db.create_milestone(
            user_id=user.id,
            name="W2里程碑",
            target_date=datetime.now(),
            target_weight=88.5,
            target_waist=93.0
        )
        
        generator = ReportGenerator(user, checkins)
        report = generator.generate_milestone_report(milestone)
        
        assert report.user_id == user.id
        assert report.milestone_id == milestone.id
        assert report.milestone_name == "W2里程碑"
        assert report.overall_progress >= 0
        assert report.summary is not None
        assert isinstance(report.achievements, list)
        assert isinstance(report.areas_for_improvement, list)


def test_imports():
    """测试所有模块可以正常导入"""
    from health_tracker.models import User, DailyCheckIn, Milestone, SafetyAlert
    from health_tracker.utils.database import DatabaseManager
    from health_tracker.analysis.auto_correction import AutoCorrectionAlgorithm
    from health_tracker.analysis.report_generator import ReportGenerator
    from health_tracker.config.settings import Config
    
    assert User is not None
    assert DailyCheckIn is not None
    assert Milestone is not None
    assert SafetyAlert is not None
    assert DatabaseManager is not None
    assert AutoCorrectionAlgorithm is not None
    assert ReportGenerator is not None
    assert Config is not None


if __name__ == '__main__':
    # 运行测试
    pytest.main([__file__, '-v'])
