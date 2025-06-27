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

# ロガーの設定
logger = logging.getLogger(__name__)


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。"""
    return datetime.now().strftime("%Y-%m-%d")

def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "planner_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        # フォールバック用の基本的なプロンプト
        return "あなたはユーザーの要求をJSON形式で要約するアシスタントです。"


class PlannerAgent(LlmAgent):
    """
    ユーザーと対話して学級通信の構成を計画し、JSON形式で出力するエージェント。
    """
    def __init__(self):
        super().__init__(
            name="planner_agent",
            model=Gemini(model_name="gemini-1.5-pro-latest"),
            instruction=_load_instruction(),
            description="ユーザーと対話して学級通信の構成を計画し、JSON形式で出力します。",
            tools=[FunctionTool(get_current_date)],
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
        LLMの最終応答を `outline.json` として保存します。
        """
        # 親クラスの`_run_async_impl`を呼び出して、通常のLLM対話を実行
        async for event in super()._run_async_impl(ctx):
            # イベントをそのままクライアントにストリーミング
            yield event

        # ADK v1.0.0では履歴アクセス方法が変更されたため、
        # セッションイベントから最後のLLM応答を取得
        if not hasattr(ctx, 'session') or not hasattr(ctx.session, 'events'):
            logger.warning("セッション履歴にアクセスできません")
            return
            
        session_events = ctx.session.events
        if not session_events:
            logger.warning("セッションイベントが空です")
            return
        
        logger.info(f"セッションに{len(session_events)}個のイベントがあります")
        
        # プランナーエージェントが作成した最後のイベントを探す
        planner_event = None
        for event in reversed(session_events):
            if hasattr(event, 'author') and event.author == self.name:
                planner_event = event
                break
        
        if planner_event is None:
            logger.warning(f"{self.name}による最後のイベントが見つかりません")
            # すべてのイベントをデバッグ用にログ出力
            for i, event in enumerate(session_events):
                author = getattr(event, 'author', 'no_author')
                logger.info(f"イベント{i}: author={author}")
            return
        
        logger.info(f"プランナーエージェントの最後のイベントを発見")
        
        # last_event を planner_event に変更
        last_event = planner_event
            
        if not hasattr(last_event, 'content') or not last_event.content:
            logger.warning("最後のイベントにコンテンツがありません")
            return
            
        # イベントの内容からテキストを抽出
        llm_response_text = ""
        
        logger.info(f"last_event.content の型: {type(last_event.content)}")
        
        if isinstance(last_event.content, list) and len(last_event.content) > 0:
            logger.info(f"コンテンツリストに{len(last_event.content)}個の要素があります")
            # content内のすべてのpartsからtextを収集
            for i, part in enumerate(last_event.content):
                logger.info(f"Part {i}: type={type(part)}, keys={list(part.keys()) if isinstance(part, dict) else 'not_dict'}")
                if isinstance(part, dict):
                    if 'text' in part and part['text']:
                        llm_response_text += part['text']
                        logger.info(f"Part {i} text length: {len(part['text'])}")
                    # function_responseは無視（ツール実行結果）
                    
            if not llm_response_text.strip():
                logger.warning("コンテンツからテキストを抽出できません")
                return
        else:
            logger.warning(f"コンテンツの形式が予期していないものです: {type(last_event.content)}")
            # 他の形式も試してみる
            if hasattr(last_event.content, 'parts'):
                logger.info("content.partsからテキストの抽出を試行中...")
                for i, part in enumerate(last_event.content.parts):
                    logger.info(f"Part {i}: type={type(part)}")
                    if hasattr(part, 'text'):
                        llm_response_text += part.text
                        logger.info(f"Part {i} text length: {len(part.text)}")
            if not llm_response_text.strip():
                return

        # LLMの応答からJSON部分を抽出または自動生成
        try:
            logger.info(f"LLM応答テキスト長: {len(llm_response_text)}")
            logger.info(f"LLM応答の最初の200文字: {llm_response_text[:200]}")
            
            # 簡単な挨拶の場合のフォールバック検知
            simple_greetings = ["こんにちは", "お疲れ", "はじめまして", "よろしく", "hello", "hi"]
            is_simple_greeting = any(greeting in llm_response_text.lower() for greeting in simple_greetings)
            
            # JSONが含まれていない場合はフォールバック
            has_json = '{' in llm_response_text and '}' in llm_response_text
            
            if not has_json or is_simple_greeting:
                logger.info("JSONが検出されないか簡単な挨拶のため、サンプルJSONを生成します")
                json_str = self._generate_sample_json()
            else:
                json_str = llm_response_text
            # 応答にMarkdownのコードブロックが含まれている場合、それを取り除く
            if '```json' in json_str:
                logger.info("Markdownコードブロック(```json)を検出、除去中...")
                json_str = json_str.split('```json', 1)[1].rsplit('```', 1)[0]
            elif '```' in json_str:
                # 'json'指定子がない場合も考慮
                logger.info("Markdownコードブロック(```)を検出、除去中...")
                json_str = json_str.split('```', 1)[1].rsplit('```', 1)[0]

            # 応答に含まれる最初の'{'から最後の'}'までをJSONとみなす
            json_start = json_str.find('{')
            json_end = json_str.rfind('}') + 1
            logger.info(f"JSON抽出: start={json_start}, end={json_end}")
            
            if json_start == -1 or json_end == 0:
                logger.error("JSONの開始または終了が見つかりません")
                logger.error(f"処理中のテキスト: {json_str[:500]}")
                raise ValueError("JSONの開始または終了が見つかりません。")

            json_str = json_str[json_start:json_end]
            logger.info(f"抽出されたJSON長: {len(json_str)}")

            # JSONとして有効か検証
            parsed_json = json.loads(json_str)
            logger.info(f"JSONを正常に解析しました: {list(parsed_json.keys())}")

            # ファイルシステムベースのアーティファクト管理（v1.0.0対応）
            artifacts_dir = Path("/tmp/adk_artifacts")
            artifacts_dir.mkdir(exist_ok=True)
            outline_file = artifacts_dir / "outline.json"
            
            with open(outline_file, "w", encoding="utf-8") as f:
                f.write(json_str)
                
            logger.info(f"構成案を保存しました: {outline_file}")

        except (ValueError, json.JSONDecodeError) as e:
            error_msg = f"LLMの応答からJSONを抽出できませんでした: {e}\n応答の最初の500文字: {llm_response_text[:500]}"
            logger.error(error_msg)


def create_planner_agent() -> LlmAgent:
    """PlannerAgentのインスタンスを生成するファクトリ関数。"""
    return PlannerAgent()

# ADK Web UI用のroot_agent変数
root_agent = create_planner_agent()
