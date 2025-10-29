"""
Demo script showing how to use the Health Tracker system
演示脚本：展示如何使用健康追踪系统
"""
import sys
import os
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from health_tracker.utils.database import DatabaseManager
from health_tracker.analysis.auto_correction import AutoCorrectionAlgorithm
from health_tracker.analysis.report_generator import ReportGenerator
from health_tracker.models import MilestoneStatus


def print_section(title):
    """打印分节标题"""
    print("\n" + "=" * 60)
    print(f"  {title}")
    print("=" * 60 + "\n")


def demo_basic_usage():
    """演示基本使用"""
    print_section("健康追踪系统演示 - Health Tracker Demo")
    
    # 1. 初始化数据库
    print("1. 初始化数据库...")
    db = DatabaseManager(db_url="sqlite:///demo_health_tracker.db")
    db.create_tables()
    print("   ✓ 数据库创建成功")
    
    # 2. 创建用户
    print("\n2. 创建用户...")
    user = db.create_user(
        username="demo_user",
        nickname="演示用户",
        baseline_weight=90.0,
        baseline_height=178.0,
        baseline_waist=95.0,
        baseline_body_fat=28.0,
        baseline_date=datetime(2025, 9, 21),
        target_weight=75.0,
        target_waist=82.0,
        target_body_fat=13.5,
        target_date=datetime(2026, 2, 8),
        age=29,
        gender="male",
        eating_window_start="08:00",
        eating_window_end="16:00"
    )
    print(f"   ✓ 用户创建成功 (ID: {user.id})")
    print(f"   - 基线体重: {user.baseline_weight} kg")
    print(f"   - 目标体重: {user.target_weight} kg")
    print(f"   - 需要减重: {user.baseline_weight - user.target_weight} kg")
    
    # 3. 创建里程碑
    print("\n3. 创建里程碑...")
    milestones = [
        {
            "name": "W2里程碑",
            "week_number": 2,
            "target_date": datetime(2025, 10, 5),
            "target_weight": 88.5,
            "target_weight_loss": 1.5,
            "description": "第2周目标：体重总降≥1.0-1.6 kg"
        },
        {
            "name": "W6里程碑",
            "week_number": 6,
            "target_date": datetime(2025, 11, 2),
            "target_weight": 85.0,
            "target_waist": 91.0,
            "description": "第6周目标：腰围较起点 -3~4 cm"
        },
        {
            "name": "W12里程碑",
            "week_number": 12,
            "target_date": datetime(2025, 12, 14),
            "target_weight": 80.0,
            "description": "第12周目标：下颌线/颧弓光影明显"
        }
    ]
    
    for milestone_data in milestones:
        milestone = db.create_milestone(
            user_id=user.id,
            **milestone_data
        )
        print(f"   ✓ {milestone.name} 已创建 (目标: {milestone.target_weight} kg)")
    
    # 4. 创建每日打卡（模拟14天数据）
    print("\n4. 创建每日打卡记录（模拟14天）...")
    base_date = datetime.now() - timedelta(days=13)
    
    for i in range(14):
        check_date = base_date + timedelta(days=i)
        
        # 模拟数据：体重逐渐下降，遵守情况良好
        checkin = db.create_checkin(
            user_id=user.id,
            check_date=check_date,
            weight=90.0 - i * 0.4,  # 平均每天减0.4kg
            waist_circumference=95.0 - i * 0.15,
            eating_window_start="08:15" if i % 7 < 6 else "09:00",
            eating_window_end="15:50" if i % 7 < 6 else "17:30",
            eating_window_followed=i % 7 < 6,  # 6/7天遵守
            meals_count=2,
            psmf_day=i % 4 == 0,  # 每4天一次PSMF
            exercise_completed=i % 2 == 0,  # 隔天运动
            exercise_type="力量训练" if i % 2 == 0 else None,
            exercise_duration=45 if i % 2 == 0 else 0,
            steps_count=7000 + i * 150,
            sleep_hours=6.5 + (i % 3) * 0.5,  # 6.5-7.5小时
            sleep_quality="good" if i % 3 != 0 else "fair",
            skincare_completed=i % 7 < 6,
            shaving_completed=i % 3 == 0,
            daytime_drowsiness=5 - i // 4,  # 逐渐改善
            eye_puffiness=4 - i // 4,
            dark_circles=5 - i // 4,
            acne_count=max(0, 3 - i // 5),
            notes=f"第{i+1}天打卡"
        )
        
        if i % 3 == 0:
            print(f"   ✓ 第{i+1}天: 体重 {checkin.weight:.1f} kg")
    
    print(f"   ✓ 共创建 14 天打卡记录")
    
    # 5. 运行自动分析
    print("\n5. 运行自动分析...")
    checkins = db.get_user_checkins(user.id)
    algo = AutoCorrectionAlgorithm(user, checkins)
    suggestions = algo.analyze()
    
    print(f"   发现 {len(suggestions)} 条建议：")
    for suggestion in suggestions:
        severity_icon = {
            'info': 'ℹ️',
            'warning': '⚠️',
            'danger': '🚨'
        }.get(suggestion.severity, '•')
        
        print(f"\n   {severity_icon} [{suggestion.category.upper()}] {suggestion.message}")
        print(f"      建议行动: {suggestion.action}")
    
    # 6. 生成周度报告
    print_section("周度报告")
    generator = ReportGenerator(user, checkins)
    weekly_report = generator.generate_weekly_report()
    
    print(f"报告期间: {weekly_report.start_date.date()} 至 {weekly_report.end_date.date()}")
    print(f"\n【体重变化】")
    print(f"  起始: {weekly_report.starting_weight:.1f} kg")
    print(f"  结束: {weekly_report.ending_weight:.1f} kg")
    print(f"  变化: {weekly_report.weight_change:+.1f} kg")
    
    print(f"\n【遵守率】")
    print(f"  进食窗口: {weekly_report.eating_window_compliance*100:.0f}%")
    print(f"  运动完成: {weekly_report.exercise_completion_rate*100:.0f}%")
    print(f"  护肤完成: {weekly_report.skincare_completion_rate*100:.0f}%")
    print(f"  PSMF天数: {weekly_report.psmf_days} 天")
    
    print(f"\n【平均指标】")
    print(f"  睡眠: {weekly_report.avg_sleep_hours:.1f} 小时")
    print(f"  步数: {weekly_report.avg_steps:.0f} 步")
    print(f"  困倦度: {weekly_report.avg_drowsiness:.1f}/10")
    
    print(f"\n【打卡情况】")
    print(f"  打卡天数: {weekly_report.checkin_days}/{weekly_report.total_days} 天")
    print(f"  打卡率: {weekly_report.checkin_rate*100:.0f}%")
    
    print(f"\n【总结】")
    print(f"  {weekly_report.summary}")
    
    if weekly_report.highlights:
        print(f"\n【亮点】")
        for highlight in weekly_report.highlights:
            print(f"  ✓ {highlight}")
    
    if weekly_report.concerns:
        print(f"\n【需要关注】")
        for concern in weekly_report.concerns:
            print(f"  • {concern}")
    
    # 7. 创建警报
    print_section("安全警报")
    
    # 创建一个示例警报
    alert = db.create_alert(
        user_id=user.id,
        alert_type="weight_loss_too_fast",
        severity="warning",
        title="体重下降速度需要注意",
        message="当前周均减重 2.8 kg，略高于建议的 1.0 kg/周",
        recommended_action="适当增加热量摄入，减少PSMF频率",
        triggered_by="Auto-correction algorithm"
    )
    
    print(f"创建警报: {alert.title}")
    print(f"  严重程度: {alert.severity}")
    print(f"  消息: {alert.message}")
    print(f"  建议: {alert.recommended_action}")
    
    # 8. 获取所有警报
    alerts = db.get_user_alerts(user.id, is_active=True)
    print(f"\n当前有 {len(alerts)} 条活跃警报")
    
    print_section("演示完成")
    print("数据已保存到: demo_health_tracker.db")
    print("你可以使用 API 服务器来访问这些数据")
    print("\n启动 API 服务器:")
    print("  python main.py --debug")
    print("\n然后访问:")
    print("  http://localhost:5000/api/users/1")
    print("  http://localhost:5000/api/users/1/checkins")
    print("  http://localhost:5000/api/users/1/analysis")
    print("  http://localhost:5000/api/users/1/reports/weekly")
    print()


if __name__ == '__main__':
    try:
        demo_basic_usage()
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()
