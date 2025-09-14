"""
情感分析器
Sentiment Analyzer
"""

from typing import Dict, Any, List
from ..utils.text_processor import TextProcessor
from ..utils.logger import LoggerMixin


class SentimentAnalyzer(LoggerMixin):
    """
    情感分析器类
    Sentiment Analyzer Class
    """
    
    def __init__(self):
        """初始化情感分析器 / Initialize sentiment analyzer"""
        self.text_processor = TextProcessor()
        self.log_info("情感分析器初始化完成")
    
    def analyze_text(self, text: str) -> Dict[str, Any]:
        """
        分析文本情感
        Analyze text sentiment
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            情感分析结果 / Sentiment analysis result
        """
        if not text:
            return self._get_default_result()
        
        try:
            # 使用文本处理器进行情感分析
            sentiment_result = self.text_processor.analyze_sentiment(text)
            
            # 提取关键词
            keywords = self.text_processor.extract_keywords(text, top_k=5)
            sentiment_result['keywords'] = keywords
            
            return sentiment_result
            
        except Exception as e:
            self.log_error(f"情感分析失败: {e}")
            return self._get_default_result()
    
    def analyze_batch(self, texts: List[str]) -> List[Dict[str, Any]]:
        """
        批量分析文本情感
        Batch analyze text sentiment
        
        Args:
            texts: 文本列表 / Text list
            
        Returns:
            情感分析结果列表 / Sentiment analysis results list
        """
        results = []
        
        for text in texts:
            result = self.analyze_text(text)
            results.append(result)
        
        return results
    
    def _get_default_result(self) -> Dict[str, Any]:
        """获取默认结果 / Get default result"""
        return {
            'score': 0.5,
            'label': 'neutral',
            'confidence': 0.0,
            'positive_score': 0.5,
            'negative_score': 0.5,
            'neutral_score': 1.0,
            'keywords': []
        }