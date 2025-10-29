"""
Database base configuration
统一的数据库基类
"""
from sqlalchemy.orm import declarative_base

# 统一的Base类，所有模型都继承这个Base
Base = declarative_base()
