"""
Vertex AI Service - 既存のVertex AI Gemini実装をラップ

既存のgemini_api_service.pyとnewsletter_generator.pyの機能を
AIServiceInterfaceに準拠する形でラップします。
"""

import asyncio
import time
from typing import Dict, Any, List, Optional
from datetime import datetime

from .ai_service_interface import AIServiceInterface, AIConfig, ContentRequest, ContentResult
from .gemini_api_service import generate_text, generate_text_with_context, check_gemini_connection
from .newsletter_generator import generate_newsletter_from_speech, get_newsletter_templates


class VertexAIService(AIServiceInterface):
    """Vertex AI Geminiサービス実装"""
    
    def __init__(self, config: AIConfig):
        super().__init__(config)
        self.model_name = config.model_name
        self.project_id = config.project_id
        self.credentials_path = config.credentials_path
        self.location = config.location
        self.temperature = config.temperature
        self.max_output_tokens = config.max_output_tokens
    
    async def generate_newsletter(self, request: ContentRequest) -> ContentResult:
        """
        学級通信を生成
        
        Args:
            request (ContentRequest): 生成リクエスト
            
        Returns:
            ContentResult: 生成結果
        """
        start_time = time.time()
        
        try:
            # 既存のnewsletter_generator.pyを非同期で実行
            result = await asyncio.get_event_loop().run_in_executor(
                None,
                generate_newsletter_from_speech,
                request["text"],
                request["template_type"],
                request["include_greeting"],
                request["target_audience"],
                request["season"],
                self.credentials_path
            )
            
            if result["success"]:
                # AIServiceInterface形式に変換
                return ContentResult(
                    success=True,
                    data={
                        "newsletter_html": result["data"]["newsletter_html"],
                        "original_speech": result["data"]["original_speech"],
                        "template_type": result["data"]["template_type"],
                        "season": result["data"]["season"],
                        "ai_metadata": {
                            "provider": "vertex_ai",
                            "model": self.model_name,
                            "processing_time_ms": result["data"]["processing_time_ms"],
                            "word_count": result["data"]["word_count"],
                            "character_count": result["data"]["character_count"],
                            "single_agent": True
                        },
                        "generated_at": result["data"]["generated_at"]
                    },
                    error=None,
                    processing_phases=[
                        {
                            "phase": "content_analysis",
                            "agent_name": "gemini_single_model",
                            "input_text": request["text"],
                            "output_text": result["data"]["newsletter_html"],
                            "processing_time_ms": result["data"]["processing_time_ms"],
                            "success": True,
                            "error": None
                        }
                    ]
                )
            else:
                return ContentResult(
                    success=False,
                    data=None,
                    error={
                        "code": "VERTEX_AI_ERROR",
                        "message": result["error"],
                        "details": {
                            "processing_time_ms": result.get("processing_time_ms", 0),
                            "timestamp": datetime.now().isoformat()
                        }
                    },
                    processing_phases=None
                )
                
        except Exception as e:
            processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"Newsletter generation failed: {e}")
            
            return ContentResult(
                success=False,
                data=None,
                error={
                    "code": "VERTEX_AI_EXCEPTION",
                    "message": str(e),
                    "details": {
                        "processing_time_ms": processing_time,
                        "timestamp": datetime.now().isoformat()
                    }
                },
                processing_phases=None
            )
    
    async def generate_text(self, prompt: str, context: Optional[List[Dict[str, str]]] = None) -> ContentResult:
        """
        汎用テキスト生成
        
        Args:
            prompt (str): プロンプトテキスト
            context (Optional[List[Dict[str, str]]]): コンテキスト履歴
            
        Returns:
            ContentResult: 生成結果
        """
        start_time = time.time()
        
        try:
            # コンテキストありかなしかで呼び分け
            if context:
                result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    generate_text_with_context,
                    prompt,
                    context,
                    self.project_id,
                    self.credentials_path,
                    self.model_name,
                    self.temperature,
                    self.max_output_tokens
                )
            else:
                result = await asyncio.get_event_loop().run_in_executor(
                    None,
                    generate_text,
                    prompt,
                    self.project_id,
                    self.credentials_path,
                    self.model_name,
                    self.temperature,
                    self.max_output_tokens
                )
            
            if result["success"]:
                return ContentResult(
                    success=True,
                    data={
                        "text": result["data"]["text"],
                        "ai_metadata": result["data"]["ai_metadata"],
                        "context": result["data"].get("context"),
                        "timestamp": result["data"]["timestamp"]
                    },
                    error=None,
                    processing_phases=[
                        {
                            "phase": "content_analysis",
                            "agent_name": "gemini_single_model",
                            "input_text": prompt,
                            "output_text": result["data"]["text"],
                            "processing_time_ms": result["data"]["ai_metadata"]["processing_time_ms"],
                            "success": True,
                            "error": None
                        }
                    ]
                )
            else:
                return ContentResult(
                    success=False,
                    data=None,
                    error=result["error"],
                    processing_phases=None
                )
                
        except Exception as e:
            processing_time = int((time.time() - start_time) * 1000)
            self.logger.error(f"Text generation failed: {e}")
            
            return ContentResult(
                success=False,
                data=None,
                error={
                    "code": "VERTEX_AI_EXCEPTION",
                    "message": str(e),
                    "details": {
                        "processing_time_ms": processing_time,
                        "timestamp": datetime.now().isoformat()
                    }
                },
                processing_phases=None
            )
    
    async def check_connection(self) -> Dict[str, Any]:
        """
        Vertex AI接続確認
        
        Returns:
            Dict[str, Any]: 接続結果
        """
        try:
            result = await asyncio.get_event_loop().run_in_executor(
                None,
                check_gemini_connection,
                self.project_id,
                self.credentials_path,
                self.model_name,
                self.location
            )
            
            return result
            
        except Exception as e:
            self.logger.error(f"Connection check failed: {e}")
            return {
                "success": False,
                "error": {
                    "code": "CONNECTION_ERROR",
                    "message": str(e),
                    "details": {
                        "timestamp": datetime.now().isoformat()
                    }
                }
            }
    
    def get_service_info(self) -> Dict[str, Any]:
        """
        Vertex AIサービス情報
        
        Returns:
            Dict[str, Any]: サービス情報
        """
        return {
            "provider": "vertex_ai",
            "model_name": self.model_name,
            "project_id": self.project_id,
            "location": self.location,
            "capabilities": {
                "text_generation": True,
                "contextual_generation": True,
                "newsletter_generation": True,
                "multi_agent": False
            },
            "configuration": {
                "temperature": self.temperature,
                "max_output_tokens": self.max_output_tokens
            },
            "available_templates": get_newsletter_templates()
        }