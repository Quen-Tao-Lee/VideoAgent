"""
API Usage Examples
API使用示例

This script demonstrates how to interact with the Health Tracker API
using the requests library.
"""
import requests
import json
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:5000/api"


def print_response(response, title="Response"):
    """打印响应"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")
    print(f"Status: {response.status_code}")
    
    if response.status_code < 400:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(f"Error: {response.text}")


def example_create_user():
    """示例：创建用户"""
    print("\n1. 创建用户")
    
    user_data = {
        "username": "api_demo_user",
        "nickname": "API演示用户",
        "baseline_weight": 90.0,
        "baseline_height": 178.0,
        "baseline_waist": 95.0,
        "baseline_body_fat": 28.0,
        "baseline_date": "2025-09-21T00:00:00",
        "target_weight": 75.0,
        "target_waist": 82.0,
        "target_body_fat": 13.5,
        "target_date": "2026-02-08T00:00:00",
        "age": 29,
        "gender": "male",
        "eating_window_start": "08:00",
        "eating_window_end": "16:00"
    }
    
    response = requests.post(f"{BASE_URL}/users", json=user_data)
    print_response(response, "创建用户")
    
    if response.status_code == 201:
        return response.json()['data']['id']
    return None


def example_create_checkin(user_id):
    """示例：创建打卡"""
    print("\n2. 创建每日打卡")
    
    checkin_data = {
        "user_id": user_id,
        "check_date": datetime.now().isoformat(),
        "weight": 89.5,
        "waist_circumference": 94.5,
        "eating_window_start": "08:15",
        "eating_window_end": "15:45",
        "eating_window_followed": True,
        "meals_count": 2,
        "psmf_day": False,
        "exercise_completed": True,
        "exercise_type": "力量训练",
        "exercise_duration": 45,
        "steps_count": 8500,
        "sleep_hours": 7.5,
        "sleep_quality": "good",
        "skincare_completed": True,
        "shaving_completed": True,
        "daytime_drowsiness": 3,
        "eye_puffiness": 2,
        "dark_circles": 3,
        "acne_count": 1,
        "notes": "API测试打卡"
    }
    
    response = requests.post(f"{BASE_URL}/checkins", json=checkin_data)
    print_response(response, "创建打卡")
    
    if response.status_code == 201:
        return response.json()['data']['id']
    return None


def example_get_user(user_id):
    """示例：获取用户信息"""
    print("\n3. 获取用户信息")
    
    response = requests.get(f"{BASE_URL}/users/{user_id}")
    print_response(response, "用户信息")


def example_get_checkins(user_id):
    """示例：获取用户的所有打卡"""
    print("\n4. 获取用户的所有打卡")
    
    response = requests.get(f"{BASE_URL}/users/{user_id}/checkins")
    print_response(response, "打卡列表")


def example_get_analysis(user_id):
    """示例：获取自动分析"""
    print("\n5. 获取自动分析结果")
    
    response = requests.get(f"{BASE_URL}/users/{user_id}/analysis")
    print_response(response, "自动分析")


def example_get_weekly_report(user_id):
    """示例：获取周度报告"""
    print("\n6. 获取周度报告")
    
    response = requests.get(f"{BASE_URL}/users/{user_id}/reports/weekly")
    print_response(response, "周度报告")


def example_create_milestone(user_id):
    """示例：创建里程碑"""
    print("\n7. 创建里程碑")
    
    milestone_data = {
        "user_id": user_id,
        "name": "W2里程碑",
        "milestone_type": "weekly",
        "week_number": 2,
        "target_date": "2025-10-05T00:00:00",
        "target_weight": 88.5,
        "target_weight_loss": 1.5,
        "description": "第2周目标：体重总降≥1.0-1.6 kg",
        "medical_checkup_required": False
    }
    
    response = requests.post(f"{BASE_URL}/milestones", json=milestone_data)
    print_response(response, "创建里程碑")
    
    if response.status_code == 201:
        return response.json()['data']['id']
    return None


def example_get_alerts(user_id):
    """示例：获取警报"""
    print("\n8. 获取用户的所有警报")
    
    response = requests.get(f"{BASE_URL}/users/{user_id}/alerts")
    print_response(response, "警报列表")


def main():
    """运行所有示例"""
    print("="*60)
    print("  Health Tracker API Usage Examples")
    print("  健康追踪系统 API 使用示例")
    print("="*60)
    print("\n注意：请确保 API 服务器正在运行")
    print("启动命令: python main.py --debug")
    print("\n按 Enter 继续...")
    input()
    
    try:
        # 测试健康检查端点
        print("\n0. 健康检查")
        response = requests.get(f"{BASE_URL}/health")
        print_response(response, "健康检查")
        
        # 创建用户
        user_id = example_create_user()
        if not user_id:
            print("\n创建用户失败，退出")
            return
        
        # 获取用户信息
        example_get_user(user_id)
        
        # 创建打卡
        checkin_id = example_create_checkin(user_id)
        
        # 获取打卡列表
        example_get_checkins(user_id)
        
        # 获取自动分析
        example_get_analysis(user_id)
        
        # 获取周度报告
        # example_get_weekly_report(user_id)  # 需要更多数据
        
        # 创建里程碑
        milestone_id = example_create_milestone(user_id)
        
        # 获取警报
        example_get_alerts(user_id)
        
        print("\n" + "="*60)
        print("  示例完成")
        print("="*60)
        
    except requests.exceptions.ConnectionError:
        print("\n错误: 无法连接到 API 服务器")
        print("请先启动服务器: python main.py --debug")
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()
