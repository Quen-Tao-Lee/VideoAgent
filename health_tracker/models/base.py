"""
Database base configuration
统一的数据库基类
"""
from sqlalchemy.orm import declarative_base

# 统一的Base类，所有模型都继承这个Base
# 使用 sqlalchemy.orm.declarative_base (SQLAlchemy 2.0+ 推荐方式)
Base = declarative_base()
