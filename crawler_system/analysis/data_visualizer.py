"""
数据可视化器
Data Visualizer
"""

import matplotlib
matplotlib.use('Agg')  # 使用非交互式后端
import matplotlib.pyplot as plt
import pandas as pd
from typing import Dict, Any, List, Optional
from ..utils.logger import LoggerMixin


class DataVisualizer(LoggerMixin):
    """
    数据可视化器类
    Data Visualizer Class
    """
    
    def __init__(self):
        """初始化数据可视化器 / Initialize data visualizer"""
        # 设置中文字体
        plt.rcParams['font.sans-serif'] = ['DejaVu Sans', 'SimHei']
        plt.rcParams['axes.unicode_minus'] = False
        
        self.log_info("数据可视化器初始化完成")
    
    def create_sentiment_chart(self, sentiment_data: List[Dict[str, Any]], 
                             save_path: str = "sentiment_chart.png") -> str:
        """
        创建情感分析图表
        Create sentiment analysis chart
        
        Args:
            sentiment_data: 情感数据 / Sentiment data
            save_path: 保存路径 / Save path
            
        Returns:
            图表文件路径 / Chart file path
        """
        try:
            # 统计情感分布
            sentiment_counts = {}
            for item in sentiment_data:
                label = item.get('label', 'neutral')
                sentiment_counts[label] = sentiment_counts.get(label, 0) + 1
            
            # 创建饼图
            labels = list(sentiment_counts.keys())
            sizes = list(sentiment_counts.values())
            colors = ['#ff6b6b', '#4ecdc4', '#45b7d1']
            
            plt.figure(figsize=(10, 8))
            plt.pie(sizes, labels=labels, colors=colors, autopct='%1.1f%%', startangle=90)
            plt.title('Sentiment Distribution', fontsize=16)
            plt.axis('equal')
            
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            plt.close()
            
            self.log_info(f"情感分析图表已保存: {save_path}")
            return save_path
            
        except Exception as e:
            self.log_error(f"创建情感图表失败: {e}")
            return ""
    
    def create_price_trend_chart(self, price_data: List[Dict[str, Any]], 
                               save_path: str = "price_trend.png") -> str:
        """
        创建价格趋势图表
        Create price trend chart
        
        Args:
            price_data: 价格数据 / Price data
            save_path: 保存路径 / Save path
            
        Returns:
            图表文件路径 / Chart file path
        """
        try:
            if not price_data:
                return ""
            
            # 转换为DataFrame
            df = pd.DataFrame(price_data)
            
            plt.figure(figsize=(12, 6))
            plt.plot(df['date'], df['price'], marker='o', linewidth=2)
            plt.title('Price Trend', fontsize=16)
            plt.xlabel('Date')
            plt.ylabel('Price')
            plt.xticks(rotation=45)
            plt.grid(True, alpha=0.3)
            
            plt.tight_layout()
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            plt.close()
            
            self.log_info(f"价格趋势图表已保存: {save_path}")
            return save_path
            
        except Exception as e:
            self.log_error(f"创建价格趋势图表失败: {e}")
            return ""