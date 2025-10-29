# 健康行为监控与目标达成小程序

Health Behavior Monitoring and Goal Achievement Mini-Program

## 项目简介

这是一个全面的健康追踪和目标管理系统，专门为健康转型计划设计。支持每日行为监控、自动纠偏算法、周度/里程碑复盘报告生成，以及医学安全警报功能。

### 核心功能

- ✅ **每日打卡**: 支持多维度健康数据记录
  - 体重、腰围、体脂率追踪
  - 进食窗口监控
  - 运动、步数记录
  - 睡眠质量追踪
  - 护肤、剃须等个护记录
  - 症状追踪（困倦度、眼部浮肿、黑眼圈、痘痘）
  - 自定义打卡项
  - 图片上传支持

- 🤖 **自动纠偏算法**: 智能分析体重变化，自动生成调整建议
  - 检测体重下降过快/过慢
  - 识别体重平台期
  - 分析饮食遵守情况
  - 评估运动完成率
  - 监控睡眠质量
  - 提供个性化改善建议

- 📊 **报告生成**: 自动生成详细的复盘报告
  - 周度报告：追踪7天进度，提供遵守率统计
  - 里程碑报告：评估长期目标达成情况
  - 可视化数据展示
  - 亮点与关注点总结

- ⚠️ **医学安全警报**: 实时监控健康风险
  - 体重变化异常警报
  - 睡眠质量预警
  - 过度疲劳提醒
  - 医学检查提醒
  - 自定义警报

## 技术架构

### 后端技术栈

- **框架**: Flask (Python REST API)
- **数据库**: SQLAlchemy ORM (支持SQLite/MySQL/PostgreSQL)
- **数据分析**: Pandas, NumPy
- **架构模式**: MVC + Service Layer

### 项目结构

```
health_tracker/
├── models/                 # 数据模型
│   ├── user.py            # 用户模型
│   ├── daily_checkin.py   # 每日打卡模型
│   ├── milestone.py       # 里程碑模型
│   └── safety_alert.py    # 安全警报模型
├── api/                   # API接口
│   └── server.py          # Flask API服务器
├── analysis/              # 分析模块
│   ├── auto_correction.py # 自动纠偏算法
│   └── report_generator.py # 报告生成器
├── utils/                 # 工具模块
│   └── database.py        # 数据库管理器
├── config/                # 配置
│   └── settings.py        # 配置文件
├── main.py               # 主程序入口
└── requirements.txt      # 依赖列表
```

## 安装和使用

### 1. 安装依赖

```bash
cd health_tracker
pip install -r requirements.txt
```

### 2. 启动API服务器

```bash
# 开发模式
python main.py --env development --debug

# 生产模式
python main.py --env production --port 8000

# 自定义数据库
python main.py --db-url mysql://user:pass@localhost/healthdb
```

### 3. API端点

#### 用户管理

- `POST /api/users` - 创建用户
- `GET /api/users/<user_id>` - 获取用户信息
- `PUT /api/users/<user_id>` - 更新用户信息

#### 每日打卡

- `POST /api/checkins` - 创建打卡
- `GET /api/checkins/<checkin_id>` - 获取打卡记录
- `PUT /api/checkins/<checkin_id>` - 更新打卡记录
- `GET /api/users/<user_id>/checkins` - 获取用户所有打卡

#### 里程碑管理

- `POST /api/milestones` - 创建里程碑
- `GET /api/milestones/<milestone_id>` - 获取里程碑
- `PUT /api/milestones/<milestone_id>` - 更新里程碑
- `GET /api/users/<user_id>/milestones` - 获取用户所有里程碑

#### 安全警报

- `POST /api/alerts` - 创建警报
- `GET /api/alerts/<alert_id>` - 获取警报
- `POST /api/alerts/<alert_id>/read` - 标记已读
- `POST /api/alerts/<alert_id>/resolve` - 解决警报
- `GET /api/users/<user_id>/alerts` - 获取用户所有警报

#### 分析和报告

- `GET /api/users/<user_id>/analysis` - 获取自动分析结果
- `GET /api/users/<user_id>/reports/weekly` - 获取周度报告
- `GET /api/users/<user_id>/reports/milestone/<milestone_id>` - 获取里程碑报告

## 使用示例

### 创建用户

```bash
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user001",
    "nickname": "健康达人",
    "baseline_weight": 90,
    "baseline_height": 178,
    "baseline_waist": 95,
    "baseline_body_fat": 28,
    "baseline_date": "2025-09-21T00:00:00",
    "target_weight": 75,
    "target_waist": 82,
    "target_body_fat": 13.5,
    "target_date": "2026-02-08T00:00:00",
    "age": 29,
    "gender": "male",
    "eating_window_start": "08:00",
    "eating_window_end": "16:00"
  }'
```

### 创建每日打卡

```bash
curl -X POST http://localhost:5000/api/checkins \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "check_date": "2025-10-29T00:00:00",
    "weight": 89.5,
    "waist_circumference": 94.5,
    "eating_window_start": "08:15",
    "eating_window_end": "15:45",
    "eating_window_followed": true,
    "meals_count": 2,
    "psmf_day": false,
    "exercise_completed": true,
    "exercise_type": "力量训练",
    "exercise_duration": 45,
    "steps_count": 8500,
    "sleep_hours": 7.5,
    "sleep_quality": "good",
    "skincare_completed": true,
    "shaving_completed": true,
    "daytime_drowsiness": 3,
    "eye_puffiness": 2,
    "dark_circles": 3,
    "acne_count": 1,
    "notes": "今天状态不错，坚持了进食窗口"
  }'
```

### 创建里程碑

```bash
curl -X POST http://localhost:5000/api/milestones \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "name": "W2里程碑",
    "milestone_type": "weekly",
    "week_number": 2,
    "target_date": "2025-10-05T00:00:00",
    "target_weight": 88.5,
    "target_weight_loss": 1.5,
    "description": "第2周目标：体重总降≥1.0-1.6 kg；浮肿↓、清醒度↑",
    "medical_checkup_required": false
  }'
```

### 获取自动分析

```bash
curl http://localhost:5000/api/users/1/analysis
```

### 获取周度报告

```bash
# 获取最近7天报告
curl http://localhost:5000/api/users/1/reports/weekly

# 获取指定周
curl http://localhost:5000/api/users/1/reports/weekly?week_number=2

# 获取指定日期范围
curl "http://localhost:5000/api/users/1/reports/weekly?start_date=2025-10-22T00:00:00&end_date=2025-10-28T00:00:00"
```

### 获取里程碑报告

```bash
curl http://localhost:5000/api/users/1/reports/milestone/1
```

## 核心算法说明

### 自动纠偏算法

系统会自动分析用户的体重变化趋势，并根据以下规则提供建议：

#### 体重下降速度判断

- **正常范围**: 0.5-1.0 kg/周
- **过快**: >1.5 kg/周 → 增加热量摄入
- **过慢**: <0.3 kg/周 → 增加热量赤字
- **平台期**: 连续3周体重变化<0.3kg → 打破平台期策略

#### 建议等级

- **info**: 信息提示，建议改进
- **warning**: 警告，需要关注
- **danger**: 危险，需要立即调整

### 报告生成

#### 周度报告内容

- 体重/腰围变化
- 各项遵守率统计（进食窗口、运动、护肤等）
- 平均睡眠/步数/困倦度
- 痘痘追踪
- 打卡率
- 自动生成的建议
- 亮点与关注点

#### 里程碑报告内容

- 目标达成情况
- 整体进度百分比
- 总体变化统计
- 关键指标改善评估
- 成就与改进点
- 医学检查提醒

## 数据模型

### User (用户)

```python
{
  "id": 1,
  "username": "user001",
  "nickname": "健康达人",
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
```

### DailyCheckIn (每日打卡)

```python
{
  "id": 1,
  "user_id": 1,
  "check_date": "2025-10-29T00:00:00",
  "weight": 89.5,
  "waist_circumference": 94.5,
  "body_fat_percentage": null,
  "eating_window_start": "08:15",
  "eating_window_end": "15:45",
  "eating_window_followed": true,
  "meals_count": 2,
  "psmf_day": false,
  "diet_notes": null,
  "exercise_completed": true,
  "exercise_type": "力量训练",
  "exercise_duration": 45,
  "steps_count": 8500,
  "sleep_hours": 7.5,
  "sleep_quality": "good",
  "sleep_notes": null,
  "skincare_completed": true,
  "skincare_routine": null,
  "shaving_completed": true,
  "shaving_notes": null,
  "daytime_drowsiness": 3,
  "eye_puffiness": 2,
  "dark_circles": 3,
  "acne_count": 1,
  "custom_items": {},
  "photos": [],
  "notes": "今天状态不错"
}
```

### Milestone (里程碑)

```python
{
  "id": 1,
  "user_id": 1,
  "name": "W2里程碑",
  "milestone_type": "weekly",
  "week_number": 2,
  "target_date": "2025-10-05T00:00:00",
  "status": "pending",
  "target_weight": 88.5,
  "target_weight_loss": 1.5,
  "target_waist": null,
  "target_waist_reduction": null,
  "target_body_fat": null,
  "actual_weight": null,
  "actual_waist": null,
  "actual_body_fat": null,
  "medical_checkup_required": false,
  "medical_checkup_completed": false,
  "description": "第2周目标..."
}
```

### SafetyAlert (安全警报)

```python
{
  "id": 1,
  "user_id": 1,
  "alert_type": "weight_loss_too_fast",
  "severity": "danger",
  "title": "体重下降过快",
  "message": "当前周均减重 1.8 kg...",
  "triggered_by": "Auto-correction algorithm",
  "trigger_date": "2025-10-29T00:00:00",
  "is_active": true,
  "is_read": false,
  "is_resolved": false,
  "recommended_action": "增加热量摄入..."
}
```

## 配置说明

系统配置在 `config/settings.py` 中定义，可以通过环境变量覆盖：

```bash
# 数据库
DATABASE_URL=sqlite:///health_tracker.db

# API服务
API_HOST=0.0.0.0
API_PORT=5000
API_DEBUG=False

# 安全
SECRET_KEY=your-secret-key-here
```

## 开发和扩展

### 添加自定义打卡项

在 `DailyCheckIn` 模型中使用 `custom_items` JSON字段：

```python
{
  "custom_items": {
    "meditation_minutes": 20,
    "water_intake_liters": 2.5,
    "stress_level": 3
  }
}
```

### 扩展警报类型

在 `models/safety_alert.py` 中的 `AlertType` 枚举添加新类型：

```python
class AlertType(enum.Enum):
    # ... 现有类型
    CUSTOM_NEW_TYPE = "custom_new_type"
```

## 许可证

本项目仅用于学习和个人健康管理目的。

## 联系方式

如有问题或建议，请提交 Issue。
