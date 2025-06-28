import json
import logging
from datetime import datetime
from typing import AsyncGenerator, Optional

from pathlib import Path
from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool
from google.genai.types import Content, Part

from .prompt import MAIN_CONVERSATION_INSTRUCTION

# ロガーの設定
logger = logging.getLogger(__name__)


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。"""
    return datetime.now().strftime("%Y-%m-%d")


def save_json_to_session(json_data: str) -> str:
    """JSONデータをセッション状態とファイルシステムに保存します。"""
    try:
        # TODO: InvocationContextをツール関数で直接取得する方法を検討
        # 現在はMainConversationAgentのメソッドで実装
        return f"JSON構成案を準備しました: {len(json_data)} 文字"
    except Exception as e:
        logger.error(f"JSON保存エラー: {e}")
        return f"保存中にエラーが発生しました: {str(e)}"


class MainConversationAgent(LlmAgent):
    """
    メインの対話エージェント。
    ユーザーと自然な対話を行い、適切なタイミングでLayoutAgentにHTML生成を委譲します。
    """

    def __init__(self):
        # LayoutAgentをサブエージェントとして設定
        from agents.layout_agent.agent import create_layout_agent
        
        layout_agent = create_layout_agent()

        super().__init__(
            name="main_conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=MAIN_CONVERSATION_INSTRUCTION,
            description="ユーザーと自然な対話を行い、学級通信作成をサポートします。必要に応じてHTML生成を委譲します。",
            tools=[
                FunctionTool(get_current_date)
            ],
            sub_agents=[layout_agent],
            output_key="conversation_state",
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        純粋な対話エージェントとして実行します。
        HTML生成は明示的なユーザー要求があった場合のみ委譲します。
        """
        try:
            # 親クラスの通常のLLM対話を実行
            async for event in super()._run_async_impl(ctx):
                yield event

            # 最後に対話状態をセッションに保存
            await self._save_conversation_state(ctx)
            
            # JSON構成案が生成された場合はセッション状態に保存
            await self._check_and_save_json_from_conversation(ctx)

        except Exception as e:
            error_msg = f"対話中にエラーが発生しました: {str(e)}"
            logger.error(error_msg)
            yield Event(
                author=self.name, 
                content=Content(parts=[Part(text=error_msg)])
            )

    async def _save_conversation_state(self, ctx: InvocationContext):
        """対話の状態をセッションに保存"""
        try:
            # セッション状態に対話完了フラグを保存
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["conversation_active"] = True
                ctx.session.state["last_interaction"] = get_current_date()
                logger.info("対話状態をセッション状態に保存しました")

        except Exception as e:
            logger.error(f"対話状態保存エラー: {e}")

    async def _check_and_save_json_from_conversation(self, ctx: InvocationContext):
        """対話からJSON構成案を検出して保存"""
        try:
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                return

            session_events = ctx.session.events
            if not session_events:
                return

            # メインエージェントが作成した最後のイベントを探す
            conversation_event = None
            for event in reversed(session_events):
                if hasattr(event, "author") and event.author == self.name:
                    conversation_event = event
                    break

            if conversation_event is None:
                return

            # イベントの内容からテキストを抽出
            llm_response_text = self._extract_text_from_event(conversation_event)

            if not llm_response_text.strip():
                return

            # JSONブロックが含まれているかチェック
            if "```json" in llm_response_text and "```" in llm_response_text:
                json_str = self._extract_json_from_response(llm_response_text)
                if json_str:
                    await self._save_json_data(ctx, json_str)

        except Exception as e:
            logger.error(f"JSON検出・保存エラー: {e}")

    def _extract_text_from_event(self, event) -> str:
        """イベントからテキストを抽出"""
        llm_response_text = ""

        if hasattr(event, "content") and event.content:
            if hasattr(event.content, "parts"):
                # Google Generative AI形式
                for part in event.content.parts:
                    if hasattr(part, "text") and part.text:
                        llm_response_text += part.text
            elif isinstance(event.content, list):
                # リスト形式
                for item in event.content:
                    if isinstance(item, dict) and "text" in item:
                        llm_response_text += item["text"]

        return llm_response_text

    def _extract_json_from_response(self, response_text: str) -> Optional[str]:
        """LLM応答からJSONを抽出"""
        try:
            # Markdownコードブロック(```json)を検出して抽出
            if "```json" in response_text:
                json_start = response_text.find("```json") + 7
                json_end = response_text.find("```", json_start)
                if json_end != -1:
                    json_str = response_text[json_start:json_end].strip()
                    # JSONとして有効か検証
                    json.loads(json_str)
                    return json_str
        except (ValueError, json.JSONDecodeError) as e:
            logger.warning(f"JSON抽出・検証エラー: {e}")
        
        return None

    async def _save_json_data(self, ctx: InvocationContext, json_str: str):
        """JSONデータをセッション状態とファイルシステムに保存"""
        try:
            # セッション状態に保存（ADK標準）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["outline"] = json_str
                logger.info("JSON構成案をセッション状態に保存しました")

            # ファイルシステムにもバックアップ保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            artifacts_dir.mkdir(exist_ok=True)
            outline_file = artifacts_dir / "outline.json"

            with open(outline_file, "w", encoding="utf-8") as f:
                f.write(json_str)

            logger.info(f"JSON構成案をファイルにも保存しました: {outline_file}")

        except Exception as e:
            logger.error(f"JSON保存エラー: {e}")


def create_main_conversation_agent() -> MainConversationAgent:
    """MainConversationAgentのインスタンスを生成するファクトリ関数。"""
    return MainConversationAgent()


# ADK Web UI用のroot_agent変数
root_agent = create_main_conversation_agent()