"""
Auto-correction algorithm for weight tracking
根据体重变化自动调整建议
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass

from health_tracker.models import DailyCheckIn, User


@dataclass
class CorrectionSuggestion:
    """纠偏建议"""
    category: str  # diet, exercise, sleep
    severity: str  # info, warning, danger
    message: str
    action: str
    details: Dict


class AutoCorrectionAlgorithm:
    """自动纠偏算法"""
    
    # 安全减重速度范围 (kg/周)
    SAFE_WEIGHT_LOSS_MIN = 0.5
    SAFE_WEIGHT_LOSS_MAX = 1.0
    
    # 危险阈值
    RAPID_WEIGHT_LOSS_THRESHOLD = 1.5  # kg/周
    SLOW_WEIGHT_LOSS_THRESHOLD = 0.3   # kg/周
    PLATEAU_WEEKS = 3  # 连续几周体重无变化视为平台期
    
    def __init__(self, user: User, checkins: List[DailyCheckIn]):
        """
        初始化纠偏算法
        
        Args:
            user: 用户信息
            checkins: 打卡记录列表（按时间降序）
        """
        self.user = user
        self.checkins = sorted(checkins, key=lambda x: x.check_date)
    
    def analyze(self) -> List[CorrectionSuggestion]:
        """
        分析并生成纠偏建议
        
        Returns:
            建议列表
        """
        suggestions = []
        
        if len(self.checkins) < 2:
            return suggestions
        
        # 分析体重变化
        weight_suggestions = self._analyze_weight_change()
        suggestions.extend(weight_suggestions)
        
        # 分析饮食遵守情况
        diet_suggestions = self._analyze_diet_compliance()
        suggestions.extend(diet_suggestions)
        
        # 分析运动情况
        exercise_suggestions = self._analyze_exercise()
        suggestions.extend(exercise_suggestions)
        
        # 分析睡眠质量
        sleep_suggestions = self._analyze_sleep()
        suggestions.extend(sleep_suggestions)
        
        return suggestions
    
    def _analyze_weight_change(self) -> List[CorrectionSuggestion]:
        """分析体重变化"""
        suggestions = []
        
        # 获取最近7天的体重数据
        recent_checkins = [c for c in self.checkins if c.weight is not None][-7:]
        
        if len(recent_checkins) < 2:
            return suggestions
        
        # 计算周平均减重速度
        days_span = (recent_checkins[-1].check_date - recent_checkins[0].check_date).days
        if days_span == 0:
            return suggestions
        
        weight_change = recent_checkins[-1].weight - recent_checkins[0].weight
        weekly_rate = (weight_change / days_span) * 7
        
        # 体重下降过快
        if weekly_rate < -self.RAPID_WEIGHT_LOSS_THRESHOLD:
            suggestions.append(CorrectionSuggestion(
                category="diet",
                severity="danger",
                message=f"体重下降过快！当前周均减重 {abs(weekly_rate):.2f} kg，超过安全上限 {self.SAFE_WEIGHT_LOSS_MAX} kg/周",
                action="增加热量摄入",
                details={
                    "current_rate": weekly_rate,
                    "safe_max": self.SAFE_WEIGHT_LOSS_MAX,
                    "recommendations": [
                        "减少PSMF天数（从2天减至1天）",
                        "适当增加主食摄入（0.5拳→1拳）",
                        "增加健康脂肪摄入（如坚果、牛油果）",
                        "考虑就医检查代谢状况"
                    ]
                }
            ))
        
        # 体重下降过慢
        elif weekly_rate > -self.SLOW_WEIGHT_LOSS_THRESHOLD:
            suggestions.append(CorrectionSuggestion(
                category="diet",
                severity="warning",
                message=f"体重下降缓慢。当前周均减重 {abs(weekly_rate):.2f} kg，低于目标 {self.SAFE_WEIGHT_LOSS_MIN} kg/周",
                action="增加热量赤字",
                details={
                    "current_rate": weekly_rate,
                    "safe_min": self.SAFE_WEIGHT_LOSS_MIN,
                    "recommendations": [
                        "严格遵守进食窗口（08:00-16:00）",
                        "确保每周2天PSMF",
                        "减少主食摄入（1拳→0.5拳）",
                        "增加运动强度或时长",
                        "检查是否有隐性热量摄入"
                    ]
                }
            ))
        
        # 检测平台期
        plateau_detected = self._detect_plateau()
        if plateau_detected:
            suggestions.append(CorrectionSuggestion(
                category="diet",
                severity="warning",
                message=f"检测到体重平台期（连续{self.PLATEAU_WEEKS}周体重变化 <0.3kg）",
                action="打破平台期",
                details={
                    "recommendations": [
                        "尝试Refeed Day（适度增加碳水1-2天）",
                        "改变运动模式（如增加HIIT训练）",
                        "调整进食窗口时间（尝试18:6间歇断食）",
                        "检查睡眠和压力水平",
                        "考虑增加NEAT（非运动性活动热量消耗）"
                    ]
                }
            ))
        
        return suggestions
    
    def _detect_plateau(self) -> bool:
        """检测体重平台期"""
        if len(self.checkins) < self.PLATEAU_WEEKS * 7:
            return False
        
        recent_weeks = []
        for i in range(self.PLATEAU_WEEKS):
            week_start = -(i + 1) * 7
            week_end = -i * 7 if i > 0 else None
            week_checkins = [c for c in self.checkins[week_start:week_end] if c.weight is not None]
            
            if week_checkins:
                avg_weight = sum(c.weight for c in week_checkins) / len(week_checkins)
                recent_weeks.append(avg_weight)
        
        if len(recent_weeks) < self.PLATEAU_WEEKS:
            return False
        
        # 检查周平均体重变化是否小于0.3kg
        weight_range = max(recent_weeks) - min(recent_weeks)
        return weight_range < 0.3
    
    def _analyze_diet_compliance(self) -> List[CorrectionSuggestion]:
        """分析饮食遵守情况"""
        suggestions = []
        
        recent_7days = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
        
        # 检查进食窗口遵守率
        window_compliance = sum(1 for c in recent_7days if c.eating_window_followed) / len(recent_7days)
        
        if window_compliance < 0.8:
            suggestions.append(CorrectionSuggestion(
                category="diet",
                severity="warning",
                message=f"进食窗口遵守率较低: {window_compliance*100:.0f}%",
                action="严格遵守进食窗口",
                details={
                    "compliance_rate": window_compliance,
                    "target": 0.9,
                    "recommendations": [
                        "设置进食窗口开始/结束提醒",
                        "提前准备好餐食，避免临时决策",
                        "16点后立即清理厨房，移除食物诱惑",
                        "如有困难，先尝试更宽松的10:00-18:00窗口"
                    ]
                }
            ))
        
        # 检查PSMF天数
        psmf_days = sum(1 for c in recent_7days if c.psmf_day)
        
        if psmf_days < 2:
            suggestions.append(CorrectionSuggestion(
                category="diet",
                severity="info",
                message=f"PSMF天数不足: {psmf_days}/7天（目标2天/周）",
                action="确保每周2天PSMF",
                details={
                    "current_days": psmf_days,
                    "target_days": 2,
                    "recommendations": [
                        "选择固定的PSMF日（如周二、周五）",
                        "PSMF日准备足够的优质蛋白质食物",
                        "PSMF日可适当增加蔬菜摄入以增加饱腹感"
                    ]
                }
            ))
        
        return suggestions
    
    def _analyze_exercise(self) -> List[CorrectionSuggestion]:
        """分析运动情况"""
        suggestions = []
        
        recent_7days = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
        
        # 检查运动完成率
        exercise_completion = sum(1 for c in recent_7days if c.exercise_completed) / len(recent_7days)
        
        if exercise_completion < 0.6:
            suggestions.append(CorrectionSuggestion(
                category="exercise",
                severity="warning",
                message=f"运动完成率较低: {exercise_completion*100:.0f}%",
                action="增加运动频率",
                details={
                    "completion_rate": exercise_completion,
                    "target": 0.8,
                    "recommendations": [
                        "从低强度开始，逐步建立运动习惯",
                        "选择喜欢的运动形式，提高坚持性",
                        "将运动安排在固定时间段",
                        "如果时间紧张，从10分钟开始"
                    ]
                }
            ))
        
        # 检查步数
        avg_steps = sum(c.steps_count or 0 for c in recent_7days) / len(recent_7days)
        
        if avg_steps < 6000:
            suggestions.append(CorrectionSuggestion(
                category="exercise",
                severity="info",
                message=f"日均步数较低: {avg_steps:.0f}步（建议≥8000步）",
                action="增加日常活动量",
                details={
                    "current_avg": avg_steps,
                    "target": 8000,
                    "recommendations": [
                        "饭后散步15-20分钟",
                        "能走楼梯就不坐电梯",
                        "站立工作一段时间",
                        "午休时间外出走动"
                    ]
                }
            ))
        
        return suggestions
    
    def _analyze_sleep(self) -> List[CorrectionSuggestion]:
        """分析睡眠质量"""
        suggestions = []
        
        recent_7days = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
        
        # 检查睡眠时长
        avg_sleep = sum(c.sleep_hours or 0 for c in recent_7days if c.sleep_hours) / max(
            len([c for c in recent_7days if c.sleep_hours]), 1
        )
        
        if avg_sleep < 7:
            suggestions.append(CorrectionSuggestion(
                category="sleep",
                severity="warning",
                message=f"睡眠时间不足: 平均{avg_sleep:.1f}小时/晚（建议≥7小时）",
                action="改善睡眠质量",
                details={
                    "current_avg": avg_sleep,
                    "target": 7.5,
                    "recommendations": [
                        "严格遵守进食窗口，避免夜间进食",
                        "睡前2小时避免蓝光（手机、电脑）",
                        "创建固定的睡前仪式",
                        "确保卧室温度适宜（18-20℃）",
                        "如果打鼾或呼吸暂停，尽快就医检查OSA"
                    ]
                }
            ))
        
        # 检查白天困倦度
        avg_drowsiness = sum(c.daytime_drowsiness or 0 for c in recent_7days if c.daytime_drowsiness) / max(
            len([c for c in recent_7days if c.daytime_drowsiness]), 1
        )
        
        if avg_drowsiness > 5:
            suggestions.append(CorrectionSuggestion(
                category="sleep",
                severity="danger",
                message=f"白天困倦度高: 平均{avg_drowsiness:.1f}/10（建议<5）",
                action="紧急改善睡眠质量",
                details={
                    "current_avg": avg_drowsiness,
                    "target": 3,
                    "recommendations": [
                        "立即预约睡眠专科医生",
                        "进行睡眠呼吸监测（PSG）",
                        "考虑使用CPAP设备（如诊断为OSA）",
                        "避免酒精和镇静剂",
                        "白天可适当使用咖啡因，但16点后停止"
                    ]
                }
            ))
        
        return suggestions
    
    def get_weekly_summary(self) -> Dict:
        """生成周度总结"""
        recent_7days = self.checkins[-7:] if len(self.checkins) >= 7 else self.checkins
        
        if not recent_7days:
            return {}
        
        # 体重变化
        weight_change = None
        if recent_7days[-1].weight and recent_7days[0].weight:
            weight_change = recent_7days[-1].weight - recent_7days[0].weight
        
        # 遵守率统计
        eating_window_rate = sum(1 for c in recent_7days if c.eating_window_followed) / len(recent_7days)
        exercise_rate = sum(1 for c in recent_7days if c.exercise_completed) / len(recent_7days)
        skincare_rate = sum(1 for c in recent_7days if c.skincare_completed) / len(recent_7days)
        
        # 平均值统计
        avg_sleep = sum(c.sleep_hours or 0 for c in recent_7days if c.sleep_hours) / max(
            len([c for c in recent_7days if c.sleep_hours]), 1
        )
        avg_steps = sum(c.steps_count or 0 for c in recent_7days) / len(recent_7days)
        avg_drowsiness = sum(c.daytime_drowsiness or 0 for c in recent_7days if c.daytime_drowsiness) / max(
            len([c for c in recent_7days if c.daytime_drowsiness]), 1
        )
        
        return {
            "period": f"{recent_7days[0].check_date.date()} 至 {recent_7days[-1].check_date.date()}",
            "weight_change": weight_change,
            "compliance": {
                "eating_window": eating_window_rate,
                "exercise": exercise_rate,
                "skincare": skincare_rate,
            },
            "averages": {
                "sleep_hours": avg_sleep,
                "steps": avg_steps,
                "drowsiness": avg_drowsiness,
            },
            "checkin_count": len(recent_7days),
        }
