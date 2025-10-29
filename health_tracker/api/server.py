"""
RESTful API endpoints for health tracker mini-program
使用Flask框架实现后端API
"""
from flask import Flask, request, jsonify
from datetime import datetime
from typing import Dict, Optional
import traceback

from health_tracker.utils.database import DatabaseManager
from health_tracker.analysis.auto_correction import AutoCorrectionAlgorithm
from health_tracker.analysis.report_generator import ReportGenerator
from health_tracker.models import AlertSeverity, AlertType


class HealthTrackerAPI:
    """健康追踪API服务"""
    
    def __init__(self, db_url: str = "sqlite:///health_tracker.db"):
        """
        初始化API服务
        
        Args:
            db_url: 数据库连接URL
        """
        self.app = Flask(__name__)
        self.db_manager = DatabaseManager(db_url)
        self.db_manager.create_tables()
        
        # 注册路由
        self._register_routes()
    
    def _register_routes(self):
        """注册所有API路由"""
        
        # 用户相关
        self.app.route('/api/users', methods=['POST'])(self.create_user)
        self.app.route('/api/users/<int:user_id>', methods=['GET'])(self.get_user)
        self.app.route('/api/users/<int:user_id>', methods=['PUT'])(self.update_user)
        
        # 每日打卡
        self.app.route('/api/checkins', methods=['POST'])(self.create_checkin)
        self.app.route('/api/checkins/<int:checkin_id>', methods=['GET'])(self.get_checkin)
        self.app.route('/api/checkins/<int:checkin_id>', methods=['PUT'])(self.update_checkin)
        self.app.route('/api/users/<int:user_id>/checkins', methods=['GET'])(self.get_user_checkins)
        
        # 里程碑
        self.app.route('/api/milestones', methods=['POST'])(self.create_milestone)
        self.app.route('/api/milestones/<int:milestone_id>', methods=['GET'])(self.get_milestone)
        self.app.route('/api/milestones/<int:milestone_id>', methods=['PUT'])(self.update_milestone)
        self.app.route('/api/users/<int:user_id>/milestones', methods=['GET'])(self.get_user_milestones)
        
        # 安全警报
        self.app.route('/api/alerts', methods=['POST'])(self.create_alert)
        self.app.route('/api/alerts/<int:alert_id>', methods=['GET'])(self.get_alert)
        self.app.route('/api/alerts/<int:alert_id>/read', methods=['POST'])(self.mark_alert_read)
        self.app.route('/api/alerts/<int:alert_id>/resolve', methods=['POST'])(self.resolve_alert)
        self.app.route('/api/users/<int:user_id>/alerts', methods=['GET'])(self.get_user_alerts)
        
        # 分析和报告
        self.app.route('/api/users/<int:user_id>/analysis', methods=['GET'])(self.get_analysis)
        self.app.route('/api/users/<int:user_id>/reports/weekly', methods=['GET'])(self.get_weekly_report)
        self.app.route('/api/users/<int:user_id>/reports/milestone/<int:milestone_id>', methods=['GET'])(self.get_milestone_report)
        
        # 健康检查
        self.app.route('/api/health', methods=['GET'])(self.health_check)
    
    # ==================== 用户管理 ====================
    
    def create_user(self):
        """创建用户"""
        try:
            data = request.json
            user = self.db_manager.create_user(**data)
            return jsonify({
                'success': True,
                'data': user.to_dict()
            }), 201
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_user(self, user_id: int):
        """获取用户信息"""
        try:
            user = self.db_manager.get_user(user_id)
            if not user:
                return jsonify({
                    'success': False,
                    'error': 'User not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': user.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def update_user(self, user_id: int):
        """更新用户信息"""
        try:
            data = request.json
            user = self.db_manager.update_user(user_id, **data)
            if not user:
                return jsonify({
                    'success': False,
                    'error': 'User not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': user.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    # ==================== 每日打卡 ====================
    
    def create_checkin(self):
        """创建每日打卡"""
        try:
            data = request.json
            
            # 转换日期字符串为datetime对象
            if 'check_date' in data and isinstance(data['check_date'], str):
                data['check_date'] = datetime.fromisoformat(data['check_date'])
            
            checkin = self.db_manager.create_checkin(**data)
            
            # 触发自动分析
            self._trigger_auto_analysis(data['user_id'])
            
            return jsonify({
                'success': True,
                'data': checkin.to_dict()
            }), 201
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_checkin(self, checkin_id: int):
        """获取打卡记录"""
        try:
            checkin = self.db_manager.get_checkin(checkin_id)
            if not checkin:
                return jsonify({
                    'success': False,
                    'error': 'Check-in not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': checkin.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def update_checkin(self, checkin_id: int):
        """更新打卡记录"""
        try:
            data = request.json
            checkin = self.db_manager.update_checkin(checkin_id, **data)
            if not checkin:
                return jsonify({
                    'success': False,
                    'error': 'Check-in not found'
                }), 404
            
            # 触发自动分析
            self._trigger_auto_analysis(checkin.user_id)
            
            return jsonify({
                'success': True,
                'data': checkin.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def get_user_checkins(self, user_id: int):
        """获取用户的所有打卡记录"""
        try:
            start_date = request.args.get('start_date')
            end_date = request.args.get('end_date')
            
            if start_date:
                start_date = datetime.fromisoformat(start_date)
            if end_date:
                end_date = datetime.fromisoformat(end_date)
            
            checkins = self.db_manager.get_user_checkins(user_id, start_date, end_date)
            
            return jsonify({
                'success': True,
                'data': [c.to_dict() for c in checkins],
                'count': len(checkins)
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    # ==================== 里程碑管理 ====================
    
    def create_milestone(self):
        """创建里程碑"""
        try:
            data = request.json
            
            # 转换日期字符串为datetime对象
            if 'target_date' in data and isinstance(data['target_date'], str):
                data['target_date'] = datetime.fromisoformat(data['target_date'])
            
            milestone = self.db_manager.create_milestone(**data)
            
            return jsonify({
                'success': True,
                'data': milestone.to_dict()
            }), 201
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_milestone(self, milestone_id: int):
        """获取里程碑"""
        try:
            milestone = self.db_manager.get_milestone(milestone_id)
            if not milestone:
                return jsonify({
                    'success': False,
                    'error': 'Milestone not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': milestone.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def update_milestone(self, milestone_id: int):
        """更新里程碑"""
        try:
            data = request.json
            milestone = self.db_manager.update_milestone(milestone_id, **data)
            if not milestone:
                return jsonify({
                    'success': False,
                    'error': 'Milestone not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': milestone.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def get_user_milestones(self, user_id: int):
        """获取用户的所有里程碑"""
        try:
            status = request.args.get('status')
            milestones = self.db_manager.get_user_milestones(user_id, status)
            
            return jsonify({
                'success': True,
                'data': [m.to_dict() for m in milestones],
                'count': len(milestones)
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    # ==================== 安全警报 ====================
    
    def create_alert(self):
        """创建安全警报"""
        try:
            data = request.json
            alert = self.db_manager.create_alert(**data)
            
            return jsonify({
                'success': True,
                'data': alert.to_dict()
            }), 201
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_alert(self, alert_id: int):
        """获取警报"""
        try:
            alert = self.db_manager.get_alert(alert_id)
            if not alert:
                return jsonify({
                    'success': False,
                    'error': 'Alert not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': alert.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def mark_alert_read(self, alert_id: int):
        """标记警报为已读"""
        try:
            alert = self.db_manager.mark_alert_as_read(alert_id)
            if not alert:
                return jsonify({
                    'success': False,
                    'error': 'Alert not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': alert.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def resolve_alert(self, alert_id: int):
        """解决警报"""
        try:
            data = request.json
            resolution_notes = data.get('resolution_notes', '')
            
            alert = self.db_manager.resolve_alert(alert_id, resolution_notes)
            if not alert:
                return jsonify({
                    'success': False,
                    'error': 'Alert not found'
                }), 404
            
            return jsonify({
                'success': True,
                'data': alert.to_dict()
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    def get_user_alerts(self, user_id: int):
        """获取用户的所有警报"""
        try:
            is_active = request.args.get('is_active')
            is_read = request.args.get('is_read')
            
            # 转换字符串为布尔值
            if is_active is not None:
                is_active = is_active.lower() == 'true'
            if is_read is not None:
                is_read = is_read.lower() == 'true'
            
            alerts = self.db_manager.get_user_alerts(user_id, is_active, is_read)
            
            return jsonify({
                'success': True,
                'data': [a.to_dict() for a in alerts],
                'count': len(alerts)
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e)
            }), 400
    
    # ==================== 分析和报告 ====================
    
    def get_analysis(self, user_id: int):
        """获取自动分析结果"""
        try:
            user = self.db_manager.get_user(user_id)
            if not user:
                return jsonify({
                    'success': False,
                    'error': 'User not found'
                }), 404
            
            checkins = self.db_manager.get_user_checkins(user_id)
            
            if not checkins:
                return jsonify({
                    'success': True,
                    'data': {
                        'suggestions': [],
                        'message': 'No check-in data available for analysis'
                    }
                })
            
            # 运行自动纠偏算法
            algo = AutoCorrectionAlgorithm(user, checkins)
            suggestions = algo.analyze()
            weekly_summary = algo.get_weekly_summary()
            
            return jsonify({
                'success': True,
                'data': {
                    'suggestions': [
                        {
                            'category': s.category,
                            'severity': s.severity,
                            'message': s.message,
                            'action': s.action,
                            'details': s.details
                        }
                        for s in suggestions
                    ],
                    'weekly_summary': weekly_summary
                }
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_weekly_report(self, user_id: int):
        """获取周度报告"""
        try:
            user = self.db_manager.get_user(user_id)
            if not user:
                return jsonify({
                    'success': False,
                    'error': 'User not found'
                }), 404
            
            week_number = request.args.get('week_number', type=int)
            start_date = request.args.get('start_date')
            end_date = request.args.get('end_date')
            
            if start_date:
                start_date = datetime.fromisoformat(start_date)
            if end_date:
                end_date = datetime.fromisoformat(end_date)
            
            checkins = self.db_manager.get_user_checkins(user_id)
            
            if not checkins:
                return jsonify({
                    'success': False,
                    'error': 'No check-in data available'
                }), 404
            
            # 生成报告
            generator = ReportGenerator(user, checkins)
            report = generator.generate_weekly_report(week_number, start_date, end_date)
            
            return jsonify({
                'success': True,
                'data': {
                    'user_id': report.user_id,
                    'week_number': report.week_number,
                    'period': f"{report.start_date.date()} to {report.end_date.date()}",
                    'weight': {
                        'starting': report.starting_weight,
                        'ending': report.ending_weight,
                        'change': report.weight_change,
                        'average': report.avg_weight
                    },
                    'waist': {
                        'starting': report.starting_waist,
                        'ending': report.ending_waist,
                        'change': report.waist_change
                    },
                    'compliance': {
                        'eating_window': report.eating_window_compliance,
                        'exercise': report.exercise_completion_rate,
                        'skincare': report.skincare_completion_rate,
                        'psmf_days': report.psmf_days
                    },
                    'averages': {
                        'sleep_hours': report.avg_sleep_hours,
                        'steps': report.avg_steps,
                        'drowsiness': report.avg_drowsiness,
                        'eye_puffiness': report.avg_eye_puffiness,
                        'dark_circles': report.avg_dark_circles
                    },
                    'acne': {
                        'total_new': report.total_new_acne,
                        'avg_daily': report.avg_daily_acne
                    },
                    'checkin': {
                        'days': report.checkin_days,
                        'total_days': report.total_days,
                        'rate': report.checkin_rate
                    },
                    'summary': report.summary,
                    'highlights': report.highlights,
                    'concerns': report.concerns,
                    'suggestions': report.suggestions,
                    'generated_at': report.generated_at.isoformat()
                }
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    def get_milestone_report(self, user_id: int, milestone_id: int):
        """获取里程碑报告"""
        try:
            user = self.db_manager.get_user(user_id)
            if not user:
                return jsonify({
                    'success': False,
                    'error': 'User not found'
                }), 404
            
            milestone = self.db_manager.get_milestone(milestone_id)
            if not milestone or milestone.user_id != user_id:
                return jsonify({
                    'success': False,
                    'error': 'Milestone not found'
                }), 404
            
            checkins = self.db_manager.get_user_checkins(user_id)
            
            if not checkins:
                return jsonify({
                    'success': False,
                    'error': 'No check-in data available'
                }), 404
            
            # 生成报告
            generator = ReportGenerator(user, checkins)
            report = generator.generate_milestone_report(milestone)
            
            return jsonify({
                'success': True,
                'data': {
                    'user_id': report.user_id,
                    'milestone_id': report.milestone_id,
                    'milestone_name': report.milestone_name,
                    'target_date': report.target_date.isoformat(),
                    'goals': {
                        'weight': {
                            'target': report.target_weight,
                            'actual': report.actual_weight,
                            'achieved': report.weight_goal_achieved
                        },
                        'waist': {
                            'target': report.target_waist,
                            'actual': report.actual_waist,
                            'achieved': report.waist_goal_achieved
                        },
                        'body_fat': {
                            'target': report.target_body_fat,
                            'actual': report.actual_body_fat,
                            'achieved': report.body_fat_goal_achieved
                        }
                    },
                    'progress': {
                        'overall': report.overall_progress,
                        'goals_achieved': report.goals_achieved,
                        'total_goals': report.total_goals
                    },
                    'period': {
                        'start': report.period_start.isoformat(),
                        'end': report.period_end.isoformat()
                    },
                    'totals': {
                        'weight_loss': report.total_weight_loss,
                        'waist_reduction': report.total_waist_reduction
                    },
                    'improvements': {
                        'sleep': report.sleep_improvement,
                        'energy': report.energy_improvement,
                        'skin': report.skin_improvement
                    },
                    'summary': report.summary,
                    'achievements': report.achievements,
                    'areas_for_improvement': report.areas_for_improvement,
                    'medical_checkup': {
                        'required': report.medical_checkup_required,
                        'completed': report.medical_checkup_completed
                    },
                    'generated_at': report.generated_at.isoformat()
                }
            })
        except Exception as e:
            return jsonify({
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc()
            }), 400
    
    # ==================== 辅助方法 ====================
    
    def _trigger_auto_analysis(self, user_id: int):
        """
        触发自动分析，检测异常并创建警报
        
        Args:
            user_id: 用户ID
        """
        try:
            user = self.db_manager.get_user(user_id)
            if not user:
                return
            
            checkins = self.db_manager.get_user_checkins(user_id)
            if len(checkins) < 2:
                return
            
            # 运行分析
            algo = AutoCorrectionAlgorithm(user, checkins)
            suggestions = algo.analyze()
            
            # 为危险级别的建议创建警报
            for suggestion in suggestions:
                if suggestion.severity == 'danger':
                    self.db_manager.create_alert(
                        user_id=user_id,
                        alert_type=AlertType.CUSTOM.value,
                        severity=AlertSeverity.DANGER.value,
                        title=f"需要注意: {suggestion.category}",
                        message=suggestion.message,
                        recommended_action=suggestion.action,
                        triggered_by=f"Auto-correction algorithm: {suggestion.details}"
                    )
        except Exception as e:
            # 静默失败，不影响主流程
            print(f"Error in auto-analysis: {e}")
    
    def health_check(self):
        """健康检查端点"""
        return jsonify({
            'success': True,
            'status': 'healthy',
            'message': 'Health Tracker API is running'
        })
    
    def run(self, host: str = '0.0.0.0', port: int = 5000, debug: bool = False):
        """
        运行API服务器
        
        Args:
            host: 主机地址
            port: 端口号
            debug: 是否开启调试模式
        """
        self.app.run(host=host, port=port, debug=debug)


# 创建默认应用实例
def create_app(db_url: str = "sqlite:///health_tracker.db"):
    """
    创建Flask应用实例
    
    Args:
        db_url: 数据库连接URL
    
    Returns:
        Flask应用实例
    """
    api = HealthTrackerAPI(db_url)
    return api.app


if __name__ == '__main__':
    # 创建并运行API服务
    api = HealthTrackerAPI()
    api.run(debug=True)
