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
        self.model_name = "gemini-1.5-flash"  # より高速なFlashモデルを使用
        
        # Vertex AI初期化
        try:
            vertexai.init(
                project=self.project_id,
                location=self.location,
                credentials=cloud_config.credentials
            )
            self.model = GenerativeModel(self.model_name)
            
            # パフォーマンス最適化設定
            self.generation_config = {
                "temperature": 0.1,  # より一貫性重視（速度向上）
                "top_p": 0.6,       # より集中的な出力（速度向上）
                "top_k": 20,        # 候補数を削減（速度向上）
                "max_output_tokens": 512,  # 出力を制限（速度向上）
                "candidate_count": 1  # 候補数を1つに制限
            }
            
            logger.info(f"Vertex AI初期化成功: {self.project_id} / {self.location} / {self.model_name}")
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
            # コンパクトなプロンプト構築（応答時間短縮）
            prompt = self._build_compact_rewrite_prompt(
                original_text, style, custom_instruction, grade_level
            )
            
            # Gemini API呼び出し（最適化設定適用）
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
        max_headlines: int = 5,
        topic_type: Optional[str] = None,
        grade_level: Optional[str] = None,
        style: str = "friendly"
    ) -> Dict[str, Any]:
        """
        コンテンツから見出しを自動生成（トピック分割・適切な見出し候補提示）
        
        Args:
            content: 本文コンテンツ
            max_headlines: 最大見出し数
            topic_type: トピックタイプ ('event', 'study', 'announcement', 'daily')
            grade_level: 学年レベル ('elementary', 'middle', 'high')
            style: 見出しスタイル ('friendly', 'formal', 'energetic')
            
        Returns:
            Dict containing generated headlines with topic analysis
        """
        start_time = time.time()
        
        try:
            # トピック分析を先に実行
            topic_analysis = await self._analyze_content_topics(content)
            
            # スタイル別の見出し生成
            headlines_by_style = await self._generate_styled_headlines(
                content=content,
                max_headlines=max_headlines,
                topic_type=topic_type or topic_analysis.get("primary_topic", "general"),
                grade_level=grade_level or "elementary",
                style=style,
                topics=topic_analysis.get("topics", [])
            )
            
            elapsed_time = time.time() - start_time
            
            result = {
                "content_preview": content[:100] + "..." if len(content) > 100 else content,
                "headlines": headlines_by_style["headlines"],
                "alternative_headlines": headlines_by_style.get("alternatives", []),
                "topic_analysis": topic_analysis,
                "count": len(headlines_by_style["headlines"]),
                "style": style,
                "grade_level": grade_level,
                "response_time_ms": int(elapsed_time * 1000),
                "model_used": self.model_name,
                "timestamp": int(time.time())
            }
            
            logger.info(f"見出し生成成功: {len(headlines_by_style['headlines'])}個, トピック{len(topic_analysis.get('topics', []))}個, {elapsed_time:.3f}s")
            return result
            
        except Exception as e:
            logger.error(f"見出し生成失敗: {e}")
            raise RuntimeError(f"Failed to generate headlines: {str(e)}")
    
    async def _analyze_content_topics(self, content: str) -> Dict[str, Any]:
        """
        コンテンツを解析してトピックを特定
        
        Args:
            content: 分析対象コンテンツ
            
        Returns:
            Dict containing topic analysis results
        """
        try:
            prompt = f"""以下の学級通信コンテンツをトピック分析してJSON形式で出力:

{content[:300]}{'...' if len(content) > 300 else ''}

出力JSON:
{{
  "primary_topic": "event|study|announcement|daily|mixed",
  "topics": [
    {{
      "topic": "トピック名",
      "importance": "high|medium|low",
      "keywords": ["キーワード1", "キーワード2"],
      "suggested_headline": "推奨見出し"
    }}
  ],
  "content_type": "お知らせ|報告|案内|日常",
  "emotional_tone": "positive|neutral|serious",
  "target_audience": "保護者|生徒|両方"
}}"""
            
            response = await self._call_gemini_async(prompt)
            topic_analysis = self._parse_json_response(response)
            
            # デフォルト値を設定
            if not topic_analysis.get("topics"):
                topic_analysis["topics"] = [{
                    "topic": "学校生活",
                    "importance": "medium",
                    "keywords": ["学級", "活動"],
                    "suggested_headline": "学級の様子"
                }]
            
            return topic_analysis
            
        except Exception as e:
            logger.warning(f"トピック分析失敗、デフォルト値を使用: {e}")
            return {
                "primary_topic": "general",
                "topics": [{"topic": "学校生活", "importance": "medium", "keywords": [], "suggested_headline": "学級の様子"}],
                "content_type": "その他",
                "emotional_tone": "neutral",
                "target_audience": "保護者"
            }
    
    async def _generate_styled_headlines(
        self,
        content: str,
        max_headlines: int,
        topic_type: str,
        grade_level: str,
        style: str,
        topics: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        スタイル別見出し生成
        
        Args:
            content: コンテンツ
            max_headlines: 最大見出し数
            topic_type: トピックタイプ
            grade_level: 学年レベル
            style: スタイル
            topics: トピック情報
            
        Returns:
            Dict containing styled headlines
        """
        # スタイル設定
        style_map = {
            "friendly": {
                "tone": "親しみやすく温かい",
                "examples": ["みんなで楽しく", "〜の様子", "元気いっぱい"],
                "emoji": True
            },
            "formal": {
                "tone": "丁寧で礼儀正しい",
                "examples": ["〜についてのお知らせ", "〜の実施について", "〜のご報告"],
                "emoji": False
            },
            "energetic": {
                "tone": "元気で明るい",
                "examples": ["がんばっています！", "大成功！", "みんなでチャレンジ"],
                "emoji": True
            }
        }
        
        grade_map = {
            "elementary": "小学生保護者向け・親しみやすく",
            "middle": "中学生保護者向け・適度にフォーマル",
            "high": "高校生保護者向け・丁寧で詳細"
        }
        
        style_config = style_map.get(style, style_map["friendly"])
        grade_config = grade_map.get(grade_level, grade_map["elementary"])
        
        # 重要なトピックから見出し生成
        high_importance_topics = [t for t in topics if t.get("importance") == "high"]
        medium_importance_topics = [t for t in topics if t.get("importance") == "medium"]
        
        prompt = f"""学級通信の見出しを{max_headlines}個生成:

コンテンツ: {content[:200]}{'...' if len(content) > 200 else ''}
トピック: {topic_type}
重要トピック: {[t.get('topic', '') for t in high_importance_topics[:3]]}

スタイル要件:
- {style_config['tone']}調で
- {grade_config}
- {'絵文字使用可' if style_config['emoji'] else '絵文字使用不可'}
- 例: {', '.join(style_config['examples'])}

出力形式（番号付きリスト）:
1. 見出し1
2. 見出し2
3. 見出し3

代替案も3個追加で生成。"""
        
        response = await self._call_gemini_async(prompt)
        
        # 見出しを解析
        lines = response.strip().split('\n')
        headlines = []
        alternatives = []
        is_alternative_section = False
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            if "代替" in line or "オルタ" in line or "別案" in line:
                is_alternative_section = True
                continue
            
            # 番号を除去
            if '. ' in line:
                headline = line.split('. ', 1)[1] if len(line.split('. ', 1)) > 1 else line
            else:
                headline = line
            
            if headline:
                if is_alternative_section:
                    alternatives.append(headline)
                else:
                    headlines.append(headline)
        
        return {
            "headlines": headlines[:max_headlines],
            "alternatives": alternatives[:3],
            "style_applied": style,
            "topic_basis": [t.get('topic', '') for t in high_importance_topics[:2]]
        }
    
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
            # コンパクトなプロンプト（応答時間短縮）
            prompt = f"""学級通信のレイアウト提案をJSON形式で出力:

コンテンツ: {content[:150]}{'...' if len(content) > 150 else ''}
季節: {season}
イベント: {event_type or 'なし'}

JSON出力:
{{
  "content_type": "お知らせ|報告|案内",
  "recommended_template": "テンプレート名",
  "color_scheme": ["#色1", "#色2", "#色3"],
  "suggested_icons": ["アイコン1", "アイコン2"],
  "layout_tips": ["コツ1", "コツ2"]
}}"""
            
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
        Gemini APIを非同期呼び出し（最適化設定適用）
        
        Args:
            prompt: プロンプト文字列
            
        Returns:
            Generated text response
        """
        def _sync_call():
            response = self.model.generate_content(
                prompt,
                generation_config=self.generation_config
            )
            return response.text
        
        # 同期呼び出しを非同期実行
        response = await asyncio.to_thread(_sync_call)
        return response
    
    def _build_compact_rewrite_prompt(
        self,
        original_text: str,
        style: str,
        custom_instruction: Optional[str],
        grade_level: Optional[str]
    ) -> str:
        """コンパクトなリライト用プロンプトを構築（応答時間短縮）"""
        
        style_map = {
            "friendly": "親しみやすく温かい",
            "formal": "丁寧で礼儀正しい", 
            "energetic": "元気で明るい"
        }
        
        grade_map = {
            "elementary": "小学生保護者向け・平仮名を適度に使用",
            "middle": "中学生保護者向け・適度な敬語",
            "high": "高校生保護者向け・formal"
        }
        
        prompt = f"""学級通信用にリライト:

元テキスト: {original_text}

要件:
- {style_map.get(style, style)}文体
- {grade_map.get(grade_level, '')}
- 誤字脱字修正
- 自然な語順
- 保護者に分かりやすく
{f"- {custom_instruction}" if custom_instruction else ""}

リライト結果のみ出力:"""
        
        return prompt
    
    def _build_rewrite_prompt(
        self,
        original_text: str,
        style: str,
        custom_instruction: Optional[str],
        grade_level: Optional[str]
    ) -> str:
        """従来のリライト用プロンプトを構築（後方互換性）"""
        return self._build_compact_rewrite_prompt(original_text, style, custom_instruction, grade_level)
    
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