import json
import os
from datetime import datetime
from pathlib import Path
from typing import AsyncGenerator
import logging

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool
from google.genai.types import Content, Part
from .prompt import INSTRUCTION
# ロガーの設定
logger = logging.getLogger(__name__)


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。"""
    return datetime.now().strftime("%Y-%m-%d")




class ConversationAgent(LlmAgent):
    """
    ユーザーと対話して学級通信の構成を計画し、JSON形式で出力するエージェント。
    bot_prompt.mdの内容をベースにした自然な対話を行います。
    """
    def __init__(self, output_key: str = "outline"):
        super().__init__(
            name="conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=INSTRUCTION,
            description="ユーザーと自然な対話を行い、学級通信の構成をJSON形式で出力します。",
            tools=[FunctionTool(get_current_date)],
            output_key=output_key,
        )

    def _generate_sample_json(self) -> str:
        """サンプルのJSONを生成します。"""
        current_date = get_current_date()
        sample_json = {
            "schema_version": "2.4",
            "school_name": "○○小学校",
            "grade": "1年1組", 
            "issue": "12月号",
            "issue_date": current_date,
            "author": { 
                "name": "担任", 
                "title": "担任" 
            },
            "main_title": "1年1組だより12月号",
            "sub_title": None,
            "season": "冬",
            "theme": "学級の様子",
            "color_scheme": { 
                "primary": "#4A90E2", 
                "secondary": "#7ED321", 
                "accent": "#F5A623", 
                "background": "#ffffff" 
            },
            "color_scheme_source": "冬の季節に合わせた爽やかな色合い",
            "sections": [
                {
                    "type": "main_content",
                    "title": "最近の学級の様子",
                    "content": "みなさん、いつも元気に過ごしていますね。最近の学習や生活の様子をお伝えします。",
                    "estimated_length": "medium",
                    "section_visual_hint": "children_activities"
                }
            ],
            "photo_placeholders": {
                "count": 1,
                "suggested_positions": [
                    {
                        "section_type": "main_content",
                        "position": "top-right",
                        "caption_suggestion": "学習の様子"
                    }
                ]
            },
            "enhancement_suggestions": [
                "季節の行事について追加",
                "お知らせやお願い事項の追加"
            ],
            "has_editor_note": False,
            "editor_note": None,
            "layout_suggestion": {
                "page_count": 1,
                "columns": 2,
                "column_ratio": "1:1",
                "blocks": [
                    "header",
                    "main_content",
                    "photos",
                    "footer"
                ]
            },
            "force_single_page": True,
            "max_pages": 1
        }
        return json.dumps(sample_json, ensure_ascii=False, indent=2)

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジックをオーバーライドし、
        LLMの最終応答から `outline.json` として保存します。
        """
        # 親クラスの`_run_async_impl`を呼び出して、通常のLLM対話を実行
        async for event in super()._run_async_impl(ctx):
            # イベントをそのままクライアントにストリーミング
            yield event

        # 最後のLLM応答からJSONを抽出して保存
        await self._save_json_from_conversation(ctx)

    async def _save_json_from_conversation(self, ctx: InvocationContext):
        """対話から生成されたJSONを抽出してセッション状態に保存"""
        try:
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, 'session') or not hasattr(ctx.session, 'events'):
                logger.warning("セッション履歴にアクセスできません")
                await self._save_fallback_json(ctx)
                return
                
            session_events = ctx.session.events
            if not session_events:
                logger.warning("セッションイベントが空です")
                await self._save_fallback_json(ctx)
                return
            
            # 対話エージェントが作成した最後のイベントを探す
            conversation_event = None
            for event in reversed(session_events):
                if hasattr(event, 'author') and event.author == self.name:
                    conversation_event = event
                    break
            
            if conversation_event is None:
                logger.warning(f"{self.name}による最後のイベントが見つかりません")
                # デバッグ情報を出力
                logger.info(f"利用可能なイベント作成者: {[getattr(e, 'author', 'NO_AUTHOR') for e in session_events[-5:]]}")
                await self._save_fallback_json(ctx)
                return
            
            # イベントの内容からテキストを抽出
            llm_response_text = self._extract_text_from_event(conversation_event)
            
            if not llm_response_text.strip():
                logger.warning("コンテンツからテキストを抽出できません")
                await self._save_fallback_json(ctx)
                return

            # JSONの抽出とフォールバック処理
            json_str = await self._extract_or_generate_json(llm_response_text)
            
            # セッション状態に保存（ADK標準）
            if hasattr(ctx, 'session') and hasattr(ctx.session, 'state'):
                ctx.session.state['outline'] = json_str
                logger.info("構成案をセッション状態に保存しました")
            
            # ファイルシステムにもバックアップ保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            artifacts_dir.mkdir(exist_ok=True)
            outline_file = artifacts_dir / "outline.json"
            
            with open(outline_file, "w", encoding="utf-8") as f:
                f.write(json_str)
                
            logger.info(f"構成案をファイルにも保存しました: {outline_file}")

        except Exception as e:
            logger.error(f"JSON保存エラー: {e}")
            await self._save_fallback_json(ctx)

    def _extract_text_from_event(self, event) -> str:
        """イベントからテキストを抽出"""
        llm_response_text = ""
        
        if hasattr(event, 'content') and event.content:
            if hasattr(event.content, 'parts'):
                # Google Generative AI形式
                for part in event.content.parts:
                    if hasattr(part, 'text') and part.text:
                        llm_response_text += part.text
            elif isinstance(event.content, list):
                # リスト形式
                for item in event.content:
                    if isinstance(item, dict) and 'text' in item:
                        llm_response_text += item['text']
        
        return llm_response_text

    async def _extract_or_generate_json(self, llm_response_text: str) -> str:
        """LLM応答からJSONを抽出または自動生成"""
        logger.info(f"LLM応答テキスト長: {len(llm_response_text)}")
        logger.info(f"LLM応答の最初の200文字: {llm_response_text[:200]}")
        
        # 簡単な挨拶の場合のフォールバック検知
        simple_greetings = ["こんにちは", "お疲れ", "はじめまして", "よろしく", "hello", "hi"]
        is_simple_greeting = any(greeting in llm_response_text.lower() for greeting in simple_greetings)
        
        # JSONが含まれているかチェック
        has_json = '{' in llm_response_text and '}' in llm_response_text
        
        if not has_json or is_simple_greeting:
            logger.info("JSONが検出されないか簡単な挨拶のため、サンプルJSONを生成します")
            return self._generate_sample_json()
        
        # JSONの抽出を試行
        try:
            json_str = llm_response_text
            
            # Markdownコードブロックの除去
            if '```json' in json_str:
                logger.info("Markdownコードブロック(```json)を検出、除去中...")
                json_str = json_str.split('```json', 1)[1].rsplit('```', 1)[0]
            elif '```' in json_str:
                logger.info("Markdownコードブロック(```)を検出、除去中...")
                json_str = json_str.split('```', 1)[1].rsplit('```', 1)[0]

            # JSONの開始と終了を検出
            json_start = json_str.find('{')
            json_end = json_str.rfind('}') + 1
            
            if json_start == -1 or json_end == 0:
                logger.warning("JSONの開始または終了が見つかりません")
                return self._generate_sample_json()

            json_str = json_str[json_start:json_end]
            
            # JSONとして有効か検証
            parsed_json = json.loads(json_str)
            logger.info(f"JSONを正常に解析しました: {list(parsed_json.keys())}")
            
            return json_str

        except (ValueError, json.JSONDecodeError) as e:
            logger.error(f"LLMの応答からJSONを抽出できませんでした: {e}")
            return self._generate_sample_json()

    async def _save_fallback_json(self, ctx: InvocationContext):
        """フォールバック用のサンプルJSONを保存"""
        logger.info("フォールバック用サンプルJSONを保存します")
        json_str = self._generate_sample_json()
        
        # セッション状態に保存（ADK標準）
        if hasattr(ctx, 'session') and hasattr(ctx.session, 'state'):
            ctx.session.state['outline'] = json_str
            logger.info("フォールバック構成案をセッション状態に保存しました")
        
        # ファイルシステムにもバックアップ保存
        artifacts_dir = Path("/tmp/adk_artifacts")
        artifacts_dir.mkdir(exist_ok=True)
        outline_file = artifacts_dir / "outline.json"
        
        with open(outline_file, "w", encoding="utf-8") as f:
            f.write(json_str)
            
        logger.info(f"フォールバック構成案をファイルにも保存しました: {outline_file}")


def create_conversation_agent() -> ConversationAgent:
    """ConversationAgentのインスタンスを生成するファクトリ関数。"""
    return ConversationAgent(output_key="outline")

# ADK Web UI用のroot_agent変数
root_agent = create_conversation_agent()