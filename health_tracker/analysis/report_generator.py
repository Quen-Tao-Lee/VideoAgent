"""
Report generator for weekly and milestone reviews
"""
from typing import Dict, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict

from health_tracker.models import User, DailyCheckIn, Milestone
from health_tracker.analysis.auto_correction import AutoCorrectionAlgorithm


@dataclass
class WeeklyReport:
    """周度复盘报告"""
    user_id: int
    week_number: int
    start_date: datetime
    end_date: datetime
    
    # 体重数据
    starting_weight: Optional[float]
    ending_weight: Optional[float]
    weight_change: Optional[float]
    avg_weight: Optional[float]
    
    # 腰围数据
    starting_waist: Optional[float]
    ending_waist: Optional[float]
    waist_change: Optional[float]
    
    # 遵守率
    eating_window_compliance: float
    exercise_completion_rate: float
    skincare_completion_rate: float
    psmf_days: int
    
    # 平均指标
    avg_sleep_hours: float
    avg_steps: float
    avg_drowsiness: float
    avg_eye_puffiness: float
    avg_dark_circles: float
    
    # 痘痘追踪
    total_new_acne: int
    avg_daily_acne: float
    
    # 打卡天数
    checkin_days: int
    total_days: int
    checkin_rate: float
    
    # 建议
    suggestions: List[Dict]
    
    # 总结
    summary: str
    highlights: List[str]
    concerns: List[str]
    
    generated_at: datetime


@dataclass
class MilestoneReport:
    """里程碑复盘报告"""
    user_id: int
    milestone_id: int
    milestone_name: str
    target_date: datetime
    
    # 目标 vs 实际
    target_weight: Optional[float]
    actual_weight: Optional[float]
    weight_goal_achieved: bool
    
    target_waist: Optional[float]
    actual_waist: Optional[float]
    waist_goal_achieved: bool
    
    target_body_fat: Optional[float]
    actual_body_fat: Optional[float]
    body_fat_goal_achieved: bool
    
    # 整体进度
    overall_progress: float  # 0-100%
    goals_achieved: int
    total_goals: int
    
    # 期间统计
    period_start: datetime
    period_end: datetime
    total_weight_loss: float
    total_waist_reduction: float
    
    # 关键指标改善
    sleep_improvement: bool
    energy_improvement: bool
    skin_improvement: bool
    
    # 总结
    summary: str
    achievements: List[str]
    areas_for_improvement: List[str]
    
    # 医学检查
    medical_checkup_required: bool
    medical_checkup_completed: bool
    
    generated_at: datetime


class ReportGenerator:
    """报告生成器"""
    
    def __init__(self, user: User, checkins: List[DailyCheckIn]):
        """
        初始化报告生成器
        
        Args:
            user: 用户信息
            checkins: 打卡记录列表
        """
        self.user = user
        self.checkins = sorted(checkins, key=lambda x: x.check_date)
        self.correction_algo = AutoCorrectionAlgorithm(user, checkins)
    
    def generate_weekly_report(
        self, 
        week_number: int = None,
        start_date: datetime = None,
        end_date: datetime = None
    ) -> WeeklyReport:
        """
        生成周度报告
        
        Args:
            week_number: 第几周
            start_date: 开始日期
            end_date: 结束日期
        """
        if start_date and end_date:
            period_checkins = [
                c for c in self.checkins 
                if start_date <= c.check_date <= end_date
            ]
        elif week_number:
            # 计算周的起止日期
            if self.user.baseline_date:
                start_date = self.user.baseline_date + timedelta(weeks=week_number-1)
                end_date = start_date + timedelta(days=6)
                period_checkins = [
                    c for c in self.checkins 
                    if start_date <= c.check_date <= end_date
                ]
            else:
                period_checkins = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
                if period_checkins:
                    start_date = period_checkins[0].check_date
                    end_date = period_checkins[-1].check_date
        else:
            # 默认最近7天
            period_checkins = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
            if period_checkins:
                start_date = period_checkins[0].check_date
                end_date = period_checkins[-1].check_date
        
        if not period_checkins:
            raise ValueError("没有可用的打卡数据")
        
        # 体重分析
        weights = [c.weight for c in period_checkins if c.weight is not None]
        starting_weight = weights[0] if weights else None
        ending_weight = weights[-1] if weights else None
        weight_change = ending_weight - starting_weight if starting_weight and ending_weight else None
        avg_weight = sum(weights) / len(weights) if weights else None
        
        # 腰围分析
        waists = [c.waist_circumference for c in period_checkins if c.waist_circumference is not None]
        starting_waist = waists[0] if waists else None
        ending_waist = waists[-1] if waists else None
        waist_change = ending_waist - starting_waist if starting_waist and ending_waist else None
        
        # 遵守率统计
        eating_window_compliance = sum(1 for c in period_checkins if c.eating_window_followed) / len(period_checkins)
        exercise_completion_rate = sum(1 for c in period_checkins if c.exercise_completed) / len(period_checkins)
        skincare_completion_rate = sum(1 for c in period_checkins if c.skincare_completed) / len(period_checkins)
        psmf_days = sum(1 for c in period_checkins if c.psmf_day)
        
        # 平均指标
        sleep_hours = [c.sleep_hours for c in period_checkins if c.sleep_hours is not None]
        avg_sleep_hours = sum(sleep_hours) / len(sleep_hours) if sleep_hours else 0
        
        steps = [c.steps_count for c in period_checkins if c.steps_count is not None]
        avg_steps = sum(steps) / len(steps) if steps else 0
        
        drowsiness = [c.daytime_drowsiness for c in period_checkins if c.daytime_drowsiness is not None]
        avg_drowsiness = sum(drowsiness) / len(drowsiness) if drowsiness else 0
        
        eye_puffiness = [c.eye_puffiness for c in period_checkins if c.eye_puffiness is not None]
        avg_eye_puffiness = sum(eye_puffiness) / len(eye_puffiness) if eye_puffiness else 0
        
        dark_circles = [c.dark_circles for c in period_checkins if c.dark_circles is not None]
        avg_dark_circles = sum(dark_circles) / len(dark_circles) if dark_circles else 0
        
        # 痘痘统计
        acne_counts = [c.acne_count for c in period_checkins if c.acne_count is not None]
        total_new_acne = sum(acne_counts)
        avg_daily_acne = total_new_acne / len(period_checkins)
        
        # 打卡率
        total_days = (end_date - start_date).days + 1
        checkin_days = len(period_checkins)
        checkin_rate = checkin_days / total_days
        
        # 生成建议
        suggestions = self.correction_algo.analyze()
        suggestions_dict = [asdict(s) for s in suggestions]
        
        # 生成总结
        summary, highlights, concerns = self._generate_weekly_summary(
            weight_change, waist_change, 
            eating_window_compliance, exercise_completion_rate,
            avg_sleep_hours, avg_drowsiness, suggestions
        )
        
        return WeeklyReport(
            user_id=self.user.id,
            week_number=week_number,
            start_date=start_date,
            end_date=end_date,
            starting_weight=starting_weight,
            ending_weight=ending_weight,
            weight_change=weight_change,
            avg_weight=avg_weight,
            starting_waist=starting_waist,
            ending_waist=ending_waist,
            waist_change=waist_change,
            eating_window_compliance=eating_window_compliance,
            exercise_completion_rate=exercise_completion_rate,
            skincare_completion_rate=skincare_completion_rate,
            psmf_days=psmf_days,
            avg_sleep_hours=avg_sleep_hours,
            avg_steps=avg_steps,
            avg_drowsiness=avg_drowsiness,
            avg_eye_puffiness=avg_eye_puffiness,
            avg_dark_circles=avg_dark_circles,
            total_new_acne=total_new_acne,
            avg_daily_acne=avg_daily_acne,
            checkin_days=checkin_days,
            total_days=total_days,
            checkin_rate=checkin_rate,
            suggestions=suggestions_dict,
            summary=summary,
            highlights=highlights,
            concerns=concerns,
            generated_at=datetime.now()
        )
    
    def generate_milestone_report(self, milestone: Milestone) -> MilestoneReport:
        """
        生成里程碑报告
        
        Args:
            milestone: 里程碑对象
        """
        # 获取里程碑期间的打卡记录
        if self.user.baseline_date:
            period_start = self.user.baseline_date
        else:
            period_start = self.checkins[0].check_date if self.checkins else datetime.now()
        
        period_end = milestone.target_date
        
        period_checkins = [
            c for c in self.checkins 
            if period_start <= c.check_date <= period_end
        ]
        
        # 获取最新数据
        latest_checkin = period_checkins[-1] if period_checkins else None
        
        actual_weight = latest_checkin.weight if latest_checkin else None
        actual_waist = latest_checkin.waist_circumference if latest_checkin else None
        actual_body_fat = latest_checkin.body_fat_percentage if latest_checkin else None
        
        # 判断目标达成情况
        goals_achieved = 0
        total_goals = 0
        
        weight_goal_achieved = False
        if milestone.target_weight and actual_weight:
            total_goals += 1
            if actual_weight <= milestone.target_weight:
                weight_goal_achieved = True
                goals_achieved += 1
        
        waist_goal_achieved = False
        if milestone.target_waist and actual_waist:
            total_goals += 1
            if actual_waist <= milestone.target_waist:
                waist_goal_achieved = True
                goals_achieved += 1
        
        body_fat_goal_achieved = False
        if milestone.target_body_fat and actual_body_fat:
            total_goals += 1
            if actual_body_fat <= milestone.target_body_fat:
                body_fat_goal_achieved = True
                goals_achieved += 1
        
        overall_progress = (goals_achieved / total_goals * 100) if total_goals > 0 else 0
        
        # 计算总体变化
        baseline_weight = self.user.baseline_weight
        baseline_waist = self.user.baseline_waist
        
        total_weight_loss = baseline_weight - actual_weight if baseline_weight and actual_weight else 0
        total_waist_reduction = baseline_waist - actual_waist if baseline_waist and actual_waist else 0
        
        # 评估改善情况
        sleep_improvement, energy_improvement, skin_improvement = self._evaluate_improvements(period_checkins)
        
        # 生成总结
        summary, achievements, areas_for_improvement = self._generate_milestone_summary(
            milestone, weight_goal_achieved, waist_goal_achieved, 
            body_fat_goal_achieved, overall_progress
        )
        
        return MilestoneReport(
            user_id=self.user.id,
            milestone_id=milestone.id,
            milestone_name=milestone.name,
            target_date=milestone.target_date,
            target_weight=milestone.target_weight,
            actual_weight=actual_weight,
            weight_goal_achieved=weight_goal_achieved,
            target_waist=milestone.target_waist,
            actual_waist=actual_waist,
            waist_goal_achieved=waist_goal_achieved,
            target_body_fat=milestone.target_body_fat,
            actual_body_fat=actual_body_fat,
            body_fat_goal_achieved=body_fat_goal_achieved,
            overall_progress=overall_progress,
            goals_achieved=goals_achieved,
            total_goals=total_goals,
            period_start=period_start,
            period_end=period_end,
            total_weight_loss=total_weight_loss,
            total_waist_reduction=total_waist_reduction,
            sleep_improvement=sleep_improvement,
            energy_improvement=energy_improvement,
            skin_improvement=skin_improvement,
            summary=summary,
            achievements=achievements,
            areas_for_improvement=areas_for_improvement,
            medical_checkup_required=milestone.medical_checkup_required,
            medical_checkup_completed=milestone.medical_checkup_completed,
            generated_at=datetime.now()
        )
    
    def _generate_weekly_summary(
        self, 
        weight_change: Optional[float],
        waist_change: Optional[float],
        eating_compliance: float,
        exercise_rate: float,
        avg_sleep: float,
        avg_drowsiness: float,
        suggestions: List
    ) -> tuple:
        """生成周度总结"""
        highlights = []
        concerns = []
        
        # 体重变化
        if weight_change:
            if weight_change < 0:
                highlights.append(f"体重下降 {abs(weight_change):.2f} kg")
            elif weight_change > 0:
                concerns.append(f"体重上升 {weight_change:.2f} kg")
        
        # 腰围变化
        if waist_change:
            if waist_change < 0:
                highlights.append(f"腰围减少 {abs(waist_change):.2f} cm")
            elif waist_change > 0:
                concerns.append(f"腰围增加 {waist_change:.2f} cm")
        
        # 遵守率
        if eating_compliance >= 0.9:
            highlights.append(f"进食窗口遵守率优秀 ({eating_compliance*100:.0f}%)")
        elif eating_compliance < 0.7:
            concerns.append(f"进食窗口遵守率较低 ({eating_compliance*100:.0f}%)")
        
        if exercise_rate >= 0.8:
            highlights.append(f"运动完成率良好 ({exercise_rate*100:.0f}%)")
        elif exercise_rate < 0.5:
            concerns.append(f"运动完成率不足 ({exercise_rate*100:.0f}%)")
        
        # 睡眠
        if avg_sleep >= 7.5:
            highlights.append(f"睡眠充足 (平均 {avg_sleep:.1f} 小时)")
        elif avg_sleep < 7:
            concerns.append(f"睡眠不足 (平均 {avg_sleep:.1f} 小时)")
        
        # 困倦度
        if avg_drowsiness <= 3:
            highlights.append("白天精力充沛")
        elif avg_drowsiness > 6:
            concerns.append(f"白天困倦度高 ({avg_drowsiness:.1f}/10)")
        
        # 生成总结文本
        summary = f"本周进度: "
        if weight_change:
            summary += f"体重变化 {weight_change:+.2f} kg, "
        summary += f"进食窗口遵守率 {eating_compliance*100:.0f}%, "
        summary += f"运动完成率 {exercise_rate*100:.0f}%。"
        
        if suggestions:
            summary += f" 系统检测到 {len(suggestions)} 项需要调整的建议。"
        
        return summary, highlights, concerns
    
    def _evaluate_improvements(self, checkins: List[DailyCheckIn]) -> tuple:
        """评估改善情况"""
        if len(checkins) < 7:
            return False, False, False
        
        # 分割前后期数据
        mid_point = len(checkins) // 2
        early_checkins = checkins[:mid_point]
        late_checkins = checkins[mid_point:]
        
        # 睡眠改善
        early_sleep = [c.sleep_hours for c in early_checkins if c.sleep_hours is not None]
        late_sleep = [c.sleep_hours for c in late_checkins if c.sleep_hours is not None]
        
        sleep_improvement = False
        if early_sleep and late_sleep:
            early_avg = sum(early_sleep) / len(early_sleep)
            late_avg = sum(late_sleep) / len(late_sleep)
            sleep_improvement = late_avg > early_avg + 0.5
        
        # 精力改善
        early_drowsiness = [c.daytime_drowsiness for c in early_checkins if c.daytime_drowsiness is not None]
        late_drowsiness = [c.daytime_drowsiness for c in late_checkins if c.daytime_drowsiness is not None]
        
        energy_improvement = False
        if early_drowsiness and late_drowsiness:
            early_avg = sum(early_drowsiness) / len(early_drowsiness)
            late_avg = sum(late_drowsiness) / len(late_drowsiness)
            energy_improvement = late_avg < early_avg - 1
        
        # 皮肤改善
        early_acne = [c.acne_count for c in early_checkins if c.acne_count is not None]
        late_acne = [c.acne_count for c in late_checkins if c.acne_count is not None]
        
        skin_improvement = False
        if early_acne and late_acne:
            early_avg = sum(early_acne) / len(early_acne)
            late_avg = sum(late_acne) / len(late_acne)
            skin_improvement = late_avg < early_avg * 0.5
        
        return sleep_improvement, energy_improvement, skin_improvement
    
    def _generate_milestone_summary(
        self,
        milestone: Milestone,
        weight_achieved: bool,
        waist_achieved: bool,
        body_fat_achieved: bool,
        progress: float
    ) -> tuple:
        """生成里程碑总结"""
        achievements = []
        areas_for_improvement = []
        
        if weight_achieved:
            achievements.append(f"✓ 达成体重目标 ({milestone.target_weight} kg)")
        else:
            areas_for_improvement.append(f"体重目标未达成 (目标: {milestone.target_weight} kg)")
        
        if waist_achieved:
            achievements.append(f"✓ 达成腰围目标 ({milestone.target_waist} cm)")
        else:
            areas_for_improvement.append(f"腰围目标未达成 (目标: {milestone.target_waist} cm)")
        
        if body_fat_achieved:
            achievements.append(f"✓ 达成体脂目标 ({milestone.target_body_fat}%)")
        else:
            areas_for_improvement.append(f"体脂目标未达成 (目标: {milestone.target_body_fat}%)")
        
        summary = f"{milestone.name} - 完成度: {progress:.1f}%。"
        if progress >= 100:
            summary += " 恭喜完全达成本里程碑的所有目标！"
        elif progress >= 70:
            summary += " 大部分目标已达成，继续保持！"
        elif progress >= 50:
            summary += " 进度良好，仍需努力达成剩余目标。"
        else:
            summary += " 需要加强执行力度，重点关注未达成项。"
        
        return summary, achievements, areas_for_improvement
