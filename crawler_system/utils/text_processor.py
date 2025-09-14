"""
文本处理工具
Text Processing Utility
"""

import re
import jieba
from typing import List, Dict, Any
from snownlp import SnowNLP


class TextProcessor:
    """
    文本处理器
    Text Processor
    """
    
    def __init__(self):
        """初始化文本处理器 / Initialize text processor"""
        # 初始化jieba分词
        jieba.initialize()
        
        # 常用停用词
        self.stop_words = {
            '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '这个', '那', '那个', '他', '她', '它', '我们', '你们', '他们', '她们', '这些', '那些', '什么', '怎么', '为什么', '因为', '所以', '但是', '可是', '不过', '还是', '只是', '而且', '或者', '如果', '虽然', '虽然', '然后', '接着', '最后', '总之', '另外', '而且', '并且', '以及', '同时', '此外', '除此之外'
        }
    
    def clean_text(self, text: str) -> str:
        """
        清理文本
        Clean text
        
        Args:
            text: 原始文本 / Raw text
            
        Returns:
            清理后的文本 / Cleaned text
        """
        if not text:
            return ""
        
        # 移除HTML标签
        text = re.sub(r'<[^>]+>', '', text)
        
        # 移除多余的空白字符
        text = re.sub(r'\s+', ' ', text)
        
        # 移除特殊字符（保留中文、英文、数字、基本标点）
        text = re.sub(r'[^\u4e00-\u9fa5\w\s.,!?;:()[\]{}""''…—-]', '', text)
        
        return text.strip()
    
    def extract_keywords(self, text: str, top_k: int = 10) -> List[Dict[str, Any]]:
        """
        提取关键词
        Extract keywords
        
        Args:
            text: 文本内容 / Text content
            top_k: 返回关键词数量 / Number of keywords to return
            
        Returns:
            关键词列表 / Keywords list
        """
        if not text:
            return []
        
        # 清理文本
        cleaned_text = self.clean_text(text)
        
        # 使用TF-IDF提取关键词
        keywords = jieba.analyse.extract_tags(
            cleaned_text, 
            topK=top_k, 
            withWeight=True
        )
        
        return [
            {
                'keyword': word,
                'weight': weight,
                'score': round(weight, 4)
            }
            for word, weight in keywords
        ]
    
    def segment_text(self, text: str) -> List[str]:
        """
        文本分词
        Text segmentation
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            分词结果 / Segmentation result
        """
        if not text:
            return []
        
        # 清理文本
        cleaned_text = self.clean_text(text)
        
        # 分词
        words = jieba.lcut(cleaned_text)
        
        # 过滤停用词和短词
        filtered_words = [
            word.strip() 
            for word in words 
            if (word.strip() and 
                len(word.strip()) > 1 and 
                word.strip() not in self.stop_words)
        ]
        
        return filtered_words
    
    def analyze_sentiment(self, text: str) -> Dict[str, Any]:
        """
        情感分析
        Sentiment analysis
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            情感分析结果 / Sentiment analysis result
        """
        if not text:
            return {
                'score': 0.5,
                'label': 'neutral',
                'confidence': 0.0
            }
        
        try:
            # 使用SnowNLP进行情感分析
            s = SnowNLP(text)
            sentiment_score = s.sentiments
            
            # 判断情感标签
            if sentiment_score > 0.6:
                label = 'positive'
                confidence = (sentiment_score - 0.6) / 0.4
            elif sentiment_score < 0.4:
                label = 'negative'
                confidence = (0.4 - sentiment_score) / 0.4
            else:
                label = 'neutral'
                confidence = 1 - abs(sentiment_score - 0.5) * 2
            
            return {
                'score': round(sentiment_score, 4),
                'label': label,
                'confidence': round(confidence, 4),
                'positive_score': round(sentiment_score, 4),
                'negative_score': round(1 - sentiment_score, 4),
                'neutral_score': round(abs(sentiment_score - 0.5) * 2, 4)
            }
            
        except Exception as e:
            return {
                'score': 0.5,
                'label': 'neutral',
                'confidence': 0.0,
                'error': str(e)
            }
    
    def extract_price(self, text: str) -> List[float]:
        """
        提取价格信息
        Extract price information
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            价格列表 / Price list
        """
        if not text:
            return []
        
        # 价格匹配模式
        patterns = [
            r'¥(\d+(?:\.\d{2})?)',  # ¥123.45
            r'￥(\d+(?:\.\d{2})?)',  # ￥123.45
            r'(\d+(?:\.\d{2})?)元',  # 123.45元
            r'(\d+(?:\.\d{2})?)块',  # 123.45块
            r'\$(\d+(?:\.\d{2})?)',  # $123.45
            r'(\d+(?:,\d{3})*(?:\.\d{2})?)',  # 1,234.56
        ]
        
        prices = []
        for pattern in patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                try:
                    # 移除千位分隔符
                    price_str = match.replace(',', '')
                    price = float(price_str)
                    if 0 < price < 1000000:  # 合理价格范围
                        prices.append(price)
                except ValueError:
                    continue
        
        return list(set(prices))  # 去重
    
    def extract_numbers(self, text: str) -> List[int]:
        """
        提取数字信息
        Extract number information
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            数字列表 / Number list
        """
        if not text:
            return []
        
        # 数字匹配模式
        patterns = [
            r'(\d+(?:,\d{3})*)',  # 带千位分隔符的数字
            r'(\d+)',  # 普通数字
        ]
        
        numbers = []
        for pattern in patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                try:
                    # 移除千位分隔符
                    number_str = match.replace(',', '')
                    number = int(number_str)
                    if 0 <= number <= 10000000:  # 合理数字范围
                        numbers.append(number)
                except ValueError:
                    continue
        
        return list(set(numbers))  # 去重
    
    def extract_ratings(self, text: str) -> List[float]:
        """
        提取评分信息
        Extract rating information
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            评分列表 / Rating list
        """
        if not text:
            return []
        
        # 评分匹配模式
        patterns = [
            r'(\d(?:\.\d)?)[分星]',  # 4.5分 或 4.5星
            r'(\d(?:\.\d)?)/5',     # 4.5/5
            r'(\d(?:\.\d)?)/10',    # 8.5/10
            r'评分[：:]\s*(\d(?:\.\d)?)',  # 评分：4.5
            r'★+(\d(?:\.\d)?)',     # ★★★★4.5
        ]
        
        ratings = []
        for pattern in patterns:
            matches = re.findall(pattern, text)
            for match in matches:
                try:
                    rating = float(match)
                    if 0 <= rating <= 10:  # 合理评分范围
                        ratings.append(rating)
                except ValueError:
                    continue
        
        return list(set(ratings))  # 去重
    
    def detect_language(self, text: str) -> str:
        """
        检测文本语言
        Detect text language
        
        Args:
            text: 文本内容 / Text content
            
        Returns:
            语言代码 / Language code
        """
        if not text:
            return 'unknown'
        
        # 简单的语言检测
        chinese_chars = len(re.findall(r'[\u4e00-\u9fa5]', text))
        english_chars = len(re.findall(r'[a-zA-Z]', text))
        total_chars = len(text)
        
        if chinese_chars / total_chars > 0.3:
            return 'zh'
        elif english_chars / total_chars > 0.5:
            return 'en'
        else:
            return 'mixed'
    
    def summarize_text(self, text: str, max_length: int = 200) -> str:
        """
        文本摘要
        Text summarization
        
        Args:
            text: 原始文本 / Original text
            max_length: 最大长度 / Maximum length
            
        Returns:
            文本摘要 / Text summary
        """
        if not text or len(text) <= max_length:
            return text
        
        # 简单的摘要方法：取前面的句子
        sentences = re.split(r'[。！？.!?]', text)
        summary = ""
        
        for sentence in sentences:
            if len(summary + sentence) <= max_length:
                summary += sentence + "。"
            else:
                break
        
        return summary.strip()