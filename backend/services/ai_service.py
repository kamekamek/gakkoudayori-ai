"""
Vertex AI Gemini統合サービス
テキストリライト・見出し生成・レイアウト最適化機能
"""
import time
import asyncio
from typing import Dict, List, Optional, Any
from google.cloud import aiplatform
from google.cloud.aiplatform import gapic
import vertexai
from vertexai.generative_models import GenerativeModel, Part, Content
import logging

from config.gcloud_config import cloud_config

# ログ設定
logger = logging.getLogger(__name__)

class AIService:
    """Vertex AI Gemini統合サービスクラス"""
    
    def __init__(self):
        """AIサービス初期化"""
        self.project_id = cloud_config.project_id
        self.location = cloud_config.location
        self.model_name = "gemini-1.5-pro"
        
        # Vertex AI初期化
        try:
            vertexai.init(
                project=self.project_id,
                location=self.location,
                credentials=cloud_config.credentials
            )
            self.model = GenerativeModel(self.model_name)
            logger.info(f"Vertex AI初期化成功: {self.project_id} / {self.location}")
        except Exception as e:
            logger.error(f"Vertex AI初期化失敗: {e}")
            raise RuntimeError(f"Failed to initialize Vertex AI: {e}")
    
    async def rewrite_text(
        self,
        original_text: str,
        style: str = "friendly",
        custom_instruction: Optional[str] = None,
        grade_level: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        テキストを学級通信風にリライト
        
        Args:
            original_text: 元のテキスト（音声認識結果等）
            style: 文体スタイル ('friendly', 'formal', 'energetic')
            custom_instruction: カスタム指示（「やさしい語り口」等）
            grade_level: 学年レベル (elementary, middle, high)
            
        Returns:
            Dict containing rewritten text and metadata
        """
        start_time = time.time()
        
        try:
            # プロンプト構築
            prompt = self._build_rewrite_prompt(
                original_text, style, custom_instruction, grade_level
            )
            
            # Gemini API呼び出し
            response = await self._call_gemini_async(prompt)
            
            elapsed_time = time.time() - start_time
            
            # 応答時間チェック（完了条件: <500ms）
            if elapsed_time > 0.5:
                logger.warning(f"Gemini応答時間が目標を超過: {elapsed_time:.3f}s")
            
            result = {
                "original_text": original_text,
                "rewritten_text": response.strip(),
                "style": style,
                "custom_instruction": custom_instruction,
                "grade_level": grade_level,
                "response_time_ms": int(elapsed_time * 1000),
                "model_used": self.model_name,
                "timestamp": int(time.time())
            }
            
            logger.info(f"テキストリライト成功: {len(original_text)}→{len(response)}文字, {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"テキストリライト失敗: {e}")
            raise RuntimeError(f"Failed to rewrite text: {str(e)}")
    
    async def generate_headlines(
        self,
        content: str,
        max_headlines: int = 5
    ) -> Dict[str, Any]:
        """
        コンテンツから見出しを自動生成
        
        Args:
            content: 本文コンテンツ
            max_headlines: 最大見出し数
            
        Returns:
            Dict containing generated headlines
        """
        start_time = time.time()
        
        try:
            prompt = f"""
以下の学級通信の内容を分析し、適切な見出しを{max_headlines}個まで生成してください。

【要件】
- 小学校の保護者にとって分かりやすい見出し
- 内容を的確に表現
- 親しみやすい表現
- 簡潔で覚えやすい

【コンテンツ】
{content}

【出力形式】
1. 見出し1
2. 見出し2
...

見出しのみを番号付きリストで出力してください。説明は不要です。
"""
            
            response = await self._call_gemini_async(prompt)
            
            # 見出しリストを解析
            headlines = self._parse_headlines(response)
            
            elapsed_time = time.time() - start_time
            
            result = {
                "content_preview": content[:100] + "..." if len(content) > 100 else content,
                "headlines": headlines,
                "count": len(headlines),
                "response_time_ms": int(elapsed_time * 1000),
                "model_used": self.model_name,
                "timestamp": int(time.time())
            }
            
            logger.info(f"見出し生成成功: {len(headlines)}個, {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"見出し生成失敗: {e}")
            raise RuntimeError(f"Failed to generate headlines: {str(e)}")
    
    async def optimize_layout(
        self,
        content: str,
        season: str = "current",
        event_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        コンテンツに基づいてレイアウトを最適化提案
        
        Args:
            content: コンテンツ本文
            season: 季節 ('spring', 'summer', 'autumn', 'winter', 'current')
            event_type: イベントタイプ ('sports_day', 'cultural_festival', 'graduation')
            
        Returns:
            Dict containing layout optimization suggestions
        """
        start_time = time.time()
        
        try:
            prompt = f"""
以下の学級通信コンテンツを分析し、最適なレイアウト・デザインを提案してください。

【分析観点】
- コンテンツの種類・トーン
- 季節感の反映（{season}）
- イベント性：{event_type or '特になし'}
- 読みやすさ・親しみやすさ

【コンテンツ】
{content}

【出力形式（JSON）】
{{
  "content_type": "お知らせ|報告|案内|その他",
  "recommended_template": "テンプレート名",
  "color_scheme": ["#カラーコード1", "#カラーコード2", "#カラーコード3"],
  "suggested_icons": ["アイコン名1", "アイコン名2"],
  "layout_tips": ["レイアウトのポイント1", "レイアウトのポイント2"],
  "emphasis_keywords": ["強調すべきキーワード1", "強調すべきキーワード2"]
}}

JSON形式のみで出力してください。他の説明は不要です。
"""
            
            response = await self._call_gemini_async(prompt)
            
            # JSON解析（エラーハンドリング付き）
            layout_suggestion = self._parse_json_response(response)
            
            elapsed_time = time.time() - start_time
            
            result = {
                "content_preview": content[:100] + "..." if len(content) > 100 else content,
                "season": season,
                "event_type": event_type,
                "layout_suggestion": layout_suggestion,
                "response_time_ms": int(elapsed_time * 1000),
                "model_used": self.model_name,
                "timestamp": int(time.time())
            }
            
            logger.info(f"レイアウト最適化成功: {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"レイアウト最適化失敗: {e}")
            raise RuntimeError(f"Failed to optimize layout: {str(e)}")
    
    async def _call_gemini_async(self, prompt: str) -> str:
        """
        Gemini APIを非同期呼び出し
        
        Args:
            prompt: プロンプト文字列
            
        Returns:
            Generated text response
        """
        def _sync_call():
            response = self.model.generate_content(
                prompt,
                generation_config={
                    "temperature": 0.3,  # 一貫性重視
                    "top_p": 0.8,
                    "top_k": 40,
                    "max_output_tokens": 2048,
                }
            )
            return response.text
        
        # 同期呼び出しを非同期実行
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(None, _sync_call)
        return response
    
    def _build_rewrite_prompt(
        self,
        original_text: str,
        style: str,
        custom_instruction: Optional[str],
        grade_level: Optional[str]
    ) -> str:
        """リライト用プロンプトを構築"""
        
        style_instructions = {
            "friendly": "親しみやすく温かい語り口で、保護者との距離感を縮める",
            "formal": "丁寧で礼儀正しい表現を使い、信頼感を重視する",
            "energetic": "元気で明るい表現を使い、子どもたちの活発さを表現する"
        }
        
        grade_instructions = {
            "elementary": "小学生の保護者向け：分かりやすい表現、平仮名を適度に使用",
            "middle": "中学生の保護者向け：適度な敬語、具体的な内容",
            "high": "高校生の保護者向け：より formal、将来への言及"
        }
        
        prompt = f"""
以下の音声認識結果を、小学校の学級通信にふさわしい文章に書き直してください。

【元のテキスト】
{original_text}

【書き直し要件】
- 文体スタイル: {style_instructions.get(style, style)}
- {grade_instructions.get(grade_level, '')}
- 誤字・脱字の修正
- 自然な語順への調整
- 保護者に伝わりやすい表現
- 学校らしい温かみのある表現

【カスタム指示】
{custom_instruction or '特になし'}

【出力形式】
書き直した文章のみを出力してください。説明や前置きは不要です。
"""
        return prompt
    
    def _parse_headlines(self, response: str) -> List[str]:
        """見出しレスポンスを解析してリストに変換"""
        lines = response.strip().split('\n')
        headlines = []
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # 番号を除去（1. 2. など）
            if '. ' in line:
                headline = line.split('. ', 1)[1] if len(line.split('. ', 1)) > 1 else line
            else:
                headline = line
            
            if headline:
                headlines.append(headline)
        
        return headlines[:5]  # 最大5個まで
    
    def _parse_json_response(self, response: str) -> Dict[str, Any]:
        """JSON レスポンスを安全に解析"""
        import json
        
        try:
            # レスポンスからJSON部分を抽出
            response = response.strip()
            if not response.startswith('{'):
                # JSON開始位置を探す
                json_start = response.find('{')
                if json_start != -1:
                    response = response[json_start:]
            
            if not response.endswith('}'):
                # JSON終了位置を探す
                json_end = response.rfind('}')
                if json_end != -1:
                    response = response[:json_end + 1]
            
            return json.loads(response)
            
        except json.JSONDecodeError as e:
            logger.error(f"JSON解析失敗: {e}, Response: {response}")
            # フォールバック用のデフォルト値
            return {
                "content_type": "その他",
                "recommended_template": "basic_newsletter",
                "color_scheme": ["#FFB3BA", "#FFDFBA", "#FFFFBA"],
                "suggested_icons": ["school", "pencil"],
                "layout_tips": ["シンプルで読みやすいレイアウト"],
                "emphasis_keywords": []
            }

# グローバルサービスインスタンス
ai_service = AIService()