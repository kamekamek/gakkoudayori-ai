"""
AI Service Interface - ADK実装のための抽象レイヤー

このモジュールはVertex AI GeminiとADKの両方をサポートするための
抽象インターフェースを提供します。

TDD要件: Red → Green → Refactor サイクルで実装
- Red: テストファースト実装
- Green: 最小限の実装でテスト通過
- Refactor: コード品質向上
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional, TypedDict, Literal
from dataclasses import dataclass
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

# 型定義
AIProviderType = Literal["vertex_ai", "adk_multi_agent"]
ProcessingPhase = Literal["content_analysis", "style_writing", "layout_design", "fact_checking", "engagement_optimization"]

@dataclass
class AIConfig:
    """AI設定クラス"""
    provider: AIProviderType = "vertex_ai"
    model_name: str = "gemini-1.5-flash"
    project_id: str = ""
    credentials_path: str = ""
    location: str = "us-central1"
    multi_agent_enabled: bool = False
    agents_config: Optional[Dict[str, Any]] = None
    temperature: float = 0.2
    max_output_tokens: int = 1024

class ContentRequest(TypedDict):
    """コンテンツ生成リクエスト"""
    text: str
    template_type: str
    include_greeting: bool
    target_audience: str
    season: str
    context: Optional[List[Dict[str, str]]]

class ContentResult(TypedDict):
    """コンテンツ生成結果"""
    success: bool
    data: Optional[Dict[str, Any]]
    error: Optional[Dict[str, Any]]
    processing_phases: Optional[List[Dict[str, Any]]]

class ProcessingPhaseResult(TypedDict):
    """処理フェーズ結果"""
    phase: ProcessingPhase
    agent_name: str
    input_text: str
    output_text: str
    processing_time_ms: int
    success: bool
    error: Optional[str]

class AIServiceInterface(ABC):
    """AIサービスの抽象インターフェース"""
    
    def __init__(self, config: AIConfig):
        self.config = config
        self.logger = logging.getLogger(f"{__name__}.{self.__class__.__name__}")
    
    @abstractmethod
    async def generate_newsletter(self, request: ContentRequest) -> ContentResult:
        """
        学級通信を生成する
        
        Args:
            request (ContentRequest): 生成リクエスト
            
        Returns:
            ContentResult: 生成結果
        """
        pass
    
    @abstractmethod
    async def generate_text(self, prompt: str, context: Optional[List[Dict[str, str]]] = None) -> ContentResult:
        """
        汎用テキスト生成
        
        Args:
            prompt (str): プロンプトテキスト
            context (Optional[List[Dict[str, str]]]): コンテキスト履歴
            
        Returns:
            ContentResult: 生成結果
        """
        pass
    
    @abstractmethod
    async def check_connection(self) -> Dict[str, Any]:
        """
        AIサービスへの接続確認
        
        Returns:
            Dict[str, Any]: 接続結果
        """
        pass
    
    @abstractmethod
    def get_service_info(self) -> Dict[str, Any]:
        """
        サービス情報取得
        
        Returns:
            Dict[str, Any]: サービス情報
        """
        pass

class AIServiceFactory:
    """AIサービスファクトリー"""
    
    @staticmethod
    def create_service(config: AIConfig) -> AIServiceInterface:
        """
        設定に基づいてAIサービスを作成
        
        Args:
            config (AIConfig): AI設定
            
        Returns:
            AIServiceInterface: AIサービスインスタンス
            
        Raises:
            ValueError: 未対応のプロバイダーが指定された場合
        """
        if config.provider == "vertex_ai":
            from .vertex_ai_service import VertexAIService
            return VertexAIService(config)
        elif config.provider == "adk_multi_agent":
            from .adk_multi_agent_service import ADKMultiAgentService
            return ADKMultiAgentService(config)
        else:
            raise ValueError(f"Unsupported AI provider: {config.provider}")

class HybridAIService(AIServiceInterface):
    """
    ハイブリッドAIサービス
    リクエストの複雑さに応じてVertex AIとADKを切り替え
    """
    
    def __init__(self, vertex_config: AIConfig, adk_config: AIConfig):
        super().__init__(vertex_config)
        self.vertex_service = AIServiceFactory.create_service(vertex_config)
        self.adk_service = AIServiceFactory.create_service(adk_config)
        self.complexity_threshold = 0.7
    
    def _calculate_complexity_score(self, request: ContentRequest) -> float:
        """
        リクエストの複雑さスコアを計算
        
        Args:
            request (ContentRequest): コンテンツ生成リクエスト
            
        Returns:
            float: 複雑さスコア (0.0-1.0)
        """
        score = 0.0
        
        # テキスト長による加点
        text_length = len(request["text"])
        if text_length > 500:
            score += 0.3
        elif text_length > 200:
            score += 0.2
        
        # テンプレートタイプによる加点
        if request["template_type"] in ["event_report", "weekly_summary"]:
            score += 0.2
        
        # コンテキストありの場合加点
        if request.get("context"):
            score += 0.1
        
        # 特別なキーワードによる加点
        complex_keywords = ["運動会", "学習発表会", "遠足", "特別授業", "保護者会"]
        if any(keyword in request["text"] for keyword in complex_keywords):
            score += 0.2
        
        return min(score, 1.0)
    
    async def generate_newsletter(self, request: ContentRequest) -> ContentResult:
        """
        複雑さに応じてサービスを選択して学級通信を生成
        """
        complexity_score = self._calculate_complexity_score(request)
        
        if complexity_score > self.complexity_threshold:
            self.logger.info(f"Using ADK service for complex request (score: {complexity_score})")
            return await self.adk_service.generate_newsletter(request)
        else:
            self.logger.info(f"Using Vertex AI service for simple request (score: {complexity_score})")
            return await self.vertex_service.generate_newsletter(request)
    
    async def generate_text(self, prompt: str, context: Optional[List[Dict[str, str]]] = None) -> ContentResult:
        """汎用テキスト生成（デフォルトはVertex AI）"""
        return await self.vertex_service.generate_text(prompt, context)
    
    async def check_connection(self) -> Dict[str, Any]:
        """両サービスの接続確認"""
        vertex_result = await self.vertex_service.check_connection()
        adk_result = await self.adk_service.check_connection()
        
        return {
            "success": vertex_result.get("success", False) or adk_result.get("success", False),
            "vertex_ai": vertex_result,
            "adk": adk_result,
            "hybrid_status": "available"
        }
    
    def get_service_info(self) -> Dict[str, Any]:
        """ハイブリッドサービス情報"""
        return {
            "service_type": "hybrid",
            "providers": ["vertex_ai", "adk_multi_agent"],
            "complexity_threshold": self.complexity_threshold,
            "vertex_ai_info": self.vertex_service.get_service_info(),
            "adk_info": self.adk_service.get_service_info()
        }