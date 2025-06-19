"""
ADK統合サービス - Google ADKマルチエージェントシステム統合レイヤー

既存のgemini_api_serviceとaudio_to_json_serviceを
ADKマルチエージェントシステムと統合するブリッジレイヤー
"""

import asyncio
import json
import logging
from typing import Dict, Any, List, Optional, Union
from datetime import datetime

# 既存サービス
from gemini_api_service import generate_text
from audio_to_json_service import convert_speech_to_json, get_json_schema

logger = logging.getLogger(__name__)

class ADKIntegrationService:
    """ADKマルチエージェントと既存システムの統合管理サービス"""
    
    def __init__(self, project_id: str, credentials_path: str):
        self.project_id = project_id
        self.credentials_path = credentials_path
        self.fallback_enabled = True
        
    def get_system_status(self) -> Dict[str, Any]:
        """システム状況を取得"""
        return {
            "adk_available": False,  # Phase 2で true に変更予定
            "classic_available": True,
            "fallback_enabled": self.fallback_enabled,
            "project_id": self.project_id,
            "phase": "1_completed",
            "agents_ready": {
                "orchestrator": True,
                "content_writer": True,
                "layout_designer": True,
                "html_generator": True,
                "html_modifier": True,
                "media": False,  # Phase 2で実装
                "output": False,  # Phase 3で実装
                "classroom": False  # Phase 4で実装
            }
        }
    
    def get_available_methods(self) -> List[str]:
        """利用可能な生成手法一覧"""
        return ["classic", "auto", "ab_test"] # "adk" はPhase 2で追加
    
    async def generate_newsletter_hybrid(
        self,
        audio_transcript: str,
        generation_method: str = "auto",
        **kwargs
    ) -> Dict[str, Any]:
        """ハイブリッド生成: ADK + 従来手法の選択実行"""
        
        if generation_method == "auto":
            generation_method = self._auto_select_method(audio_transcript)
            
        logger.info(f"Using generation method: {generation_method}")
        
        try:
            if generation_method == "adk":
                return await self._generate_with_adk(audio_transcript, **kwargs)
            elif generation_method == "classic":
                return await self._generate_with_classic(audio_transcript, **kwargs)
            else:
                return await self._generate_ab_test(audio_transcript, **kwargs)
                
        except Exception as e:
            logger.error(f"Generation failed: {e}")
            if self.fallback_enabled and generation_method != "classic":
                return await self._generate_with_classic(audio_transcript, **kwargs)
            else:
                raise e
    
    def _auto_select_method(self, audio_transcript: str) -> str:
        """音声内容の複雑さに基づいて生成手法を自動選択"""
        
        word_count = len(audio_transcript.split())
        complex_keywords = ["デザイン", "レイアウト", "画像", "写真", "きれいに", "見やすく"]
        
        complexity_score = min(word_count / 100, 3)
        for keyword in complex_keywords:
            if keyword in audio_transcript:
                complexity_score += 1
        
        return "adk" if complexity_score >= 4 else "classic"
    
    async def _generate_with_adk(self, audio_transcript: str, **kwargs) -> Dict[str, Any]:
        """ADKマルチエージェントによる生成（未実装時は従来手法にフォールバック）"""
        
        # ADK実装完了時にここを置き換え
        logger.info("ADK generation requested, falling back to enhanced classic method")
        
        result = await self._generate_with_classic(audio_transcript, **kwargs)
        result["generation_method"] = "adk_fallback"
        result["note"] = "ADK実装準備中のため従来手法で生成"
        
        return result
    
    async def _generate_with_classic(self, audio_transcript: str, **kwargs) -> Dict[str, Any]:
        """従来のGemini単体による生成"""
        
        result = convert_speech_to_json(
            transcribed_text=audio_transcript,
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            style=kwargs.get("style", "classic"),
            custom_context=kwargs.get("custom_context", ""),
            model_name=kwargs.get("model_name", "gemini-2.5-pro-preview-06-05"),
            temperature=kwargs.get("temperature", 0.3),
            max_output_tokens=kwargs.get("max_output_tokens", 8192)
        )
        
        return self._normalize_classic_result(result)
    
    async def _generate_ab_test(self, audio_transcript: str, **kwargs) -> Dict[str, Any]:
        """A/Bテスト用: 両手法で生成して比較"""
        
        classic_result = await self._generate_with_classic(audio_transcript, **kwargs)
        
        return {
            "generation_method": "ab_test",
            "primary_result": classic_result,
            "note": "ADK実装完了後に真のA/Bテストが可能",
            "timestamp": datetime.now().isoformat()
        }
    
    def _normalize_classic_result(self, classic_result: Dict[str, Any]) -> Dict[str, Any]:
        """従来結果を統一フォーマットに正規化"""
        
        return {
            "success": classic_result.get("success", True),
            "generation_method": "classic_single_agent",
            "content": self._extract_content_from_classic(classic_result),
            "html": self._generate_html_from_classic(classic_result),
            "design_spec": classic_result.get("color_scheme"),
            "timestamp": classic_result.get("timestamp", datetime.now().isoformat()),
            "error": classic_result.get("error")
        }
    
    def _extract_content_from_classic(self, classic_result: Dict[str, Any]) -> str:
        """従来結果から文章コンテンツを抽出"""
        
        if not classic_result.get("sections"):
            return ""
        
        content_parts = []
        for section in classic_result["sections"]:
            if section.get("title"):
                content_parts.append(f"## {section['title']}")
            if section.get("content"):
                content_parts.append(section["content"])
        
        return "\n\n".join(content_parts)
    
    def _generate_html_from_classic(self, classic_result: Dict[str, Any]) -> str:
        """従来結果からHTMLを生成"""
        
        if not classic_result.get("sections"):
            return "<p>生成に失敗しました</p>"
        
        html_parts = []
        
        # メインタイトル
        if classic_result.get("main_title"):
            html_parts.append(f"<h1>{classic_result['main_title']}</h1>")
        
        # セクション
        for section in classic_result["sections"]:
            if section.get("title"):
                html_parts.append(f"<h2>{section['title']}</h2>")
            if section.get("content"):
                html_parts.append(f"<p>{section['content']}</p>")
        
        return "\n".join(html_parts)


# API統合関数
async def generate_newsletter_integrated(
    audio_transcript: str,
    project_id: str,
    credentials_path: str,
    method: str = "auto",
    **kwargs
) -> Dict[str, Any]:
    """統合学級通信生成API"""
    
    service = ADKIntegrationService(project_id, credentials_path)
    return await service.generate_newsletter_hybrid(
        audio_transcript=audio_transcript,
        generation_method=method,
        **kwargs
    )


# ==============================================================================
# テスト関数
# ==============================================================================

async def test_adk_integration():
    """ADK統合システムのテスト"""
    
    test_transcript = """
    今日は運動会の練習をしました。
    子どもたちは徒競走とダンスの練習を頑張っていました。
    特にたかしくんは最初は走るのが苦手でしたが、
    毎日練習を重ねて今ではクラスで3番目に速くなりました。
    みんなで応援し合う姿が印象的でした。
    きれいなレイアウトで保護者の方に共有したいと思います。
    """
    
    service = ADKIntegrationService("test-project", "test-credentials.json")
    
    print("=== ADK Integration Test ===")
    print(f"System Status: {service.get_system_status()}")
    print(f"Available Methods: {service.get_available_methods()}")
    
    # 自動選択テスト
    auto_result = await service.generate_newsletter_hybrid(
        audio_transcript=test_transcript,
        generation_method="auto"
    )
    
    print(f"\nAuto Method Selected: {auto_result.get('generation_method')}")
    print(f"Success: {auto_result.get('success')}")
    
    return auto_result


if __name__ == "__main__":
    # テスト実行
    asyncio.run(test_adk_integration()) 