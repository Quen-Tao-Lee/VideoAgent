"""
数据库配置管理
Database Configuration Management
"""

import os
from typing import Dict, Any
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


class DatabaseConfig:
    """
    数据库配置类
    Database Configuration Class
    """
    
    def __init__(self, config_dict: Dict[str, Any] = None):
        """
        初始化数据库配置
        Initialize database configuration
        
        Args:
            config_dict: 数据库配置字典 / Database configuration dictionary
        """
        self.config = config_dict or self.get_default_config()
        self.engine = None
        self.session_factory = None
        self.base = declarative_base()
    
    def get_default_config(self) -> Dict[str, Any]:
        """获取默认数据库配置 / Get default database configuration"""
        return {
            "type": "sqlite",
            "path": "crawler_data.db",
            "host": "localhost",
            "port": 3306,
            "username": "",
            "password": "",
            "database": "crawler_db",
            "charset": "utf8mb4",
            "pool_size": 10,
            "pool_recycle": 3600,
            "echo": False
        }
    
    def get_connection_string(self) -> str:
        """
        获取数据库连接字符串
        Get database connection string
        
        Returns:
            数据库连接字符串 / Database connection string
        """
        db_type = self.config.get("type", "sqlite")
        
        if db_type == "sqlite":
            db_path = self.config.get("path", "crawler_data.db")
            # 确保数据库文件在正确的目录中
            if not os.path.isabs(db_path):
                from pathlib import Path
                base_dir = Path(__file__).parent.parent
                db_path = base_dir / "database" / db_path
                os.makedirs(os.path.dirname(db_path), exist_ok=True)
            return f"sqlite:///{db_path}"
        
        elif db_type == "mysql":
            host = self.config.get("host", "localhost")
            port = self.config.get("port", 3306)
            username = self.config.get("username", "")
            password = self.config.get("password", "")
            database = self.config.get("database", "crawler_db")
            charset = self.config.get("charset", "utf8mb4")
            
            return f"mysql+pymysql://{username}:{password}@{host}:{port}/{database}?charset={charset}"
        
        else:
            raise ValueError(f"不支持的数据库类型: {db_type}")
    
    def create_engine(self):
        """创建数据库引擎 / Create database engine"""
        if self.engine is None:
            connection_string = self.get_connection_string()
            
            engine_kwargs = {
                "echo": self.config.get("echo", False),
                "pool_pre_ping": True
            }
            
            # MySQL特定配置
            if self.config.get("type") == "mysql":
                engine_kwargs.update({
                    "pool_size": self.config.get("pool_size", 10),
                    "pool_recycle": self.config.get("pool_recycle", 3600),
                    "max_overflow": 20
                })
            
            self.engine = create_engine(connection_string, **engine_kwargs)
    
    def get_session_factory(self):
        """
        获取会话工厂
        Get session factory
        
        Returns:
            SQLAlchemy会话工厂 / SQLAlchemy session factory
        """
        if self.session_factory is None:
            if self.engine is None:
                self.create_engine()
            self.session_factory = sessionmaker(bind=self.engine)
        
        return self.session_factory
    
    def get_session(self):
        """
        获取数据库会话
        Get database session
        
        Returns:
            数据库会话对象 / Database session object
        """
        session_factory = self.get_session_factory()
        return session_factory()
    
    def create_tables(self):
        """创建数据表 / Create database tables"""
        if self.engine is None:
            self.create_engine()
        
        # 导入所有模型以确保它们被注册
        from ..database.models import *
        
        # 创建所有表
        self.base.metadata.create_all(self.engine)
    
    def drop_tables(self):
        """删除数据表 / Drop database tables"""
        if self.engine is None:
            self.create_engine()
        
        self.base.metadata.drop_all(self.engine)