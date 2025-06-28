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
    """現在の日付を'YYYY-MM-DD'形式で返します。ユーザーには自然な形で表示されます。"""
    current_date = datetime.now().strftime("%Y-%m-%d")
    logger.info(f"正確な現在日付を取得しました: {current_date}")
    return current_date


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
            
            # ユーザー承認後のHTML生成準備
            await self._prepare_html_generation_if_approved(ctx)

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
                
                # ユーザー承認状態の初期化
                if "user_approved" not in ctx.session.state:
                    ctx.session.state["user_approved"] = False
                    
                # 情報収集進捗の管理
                if "collection_stage" not in ctx.session.state:
                    ctx.session.state["collection_stage"] = "initial"
                    
                logger.info("対話状態をセッション状態に保存しました")

        except Exception as e:
            logger.error(f"対話状態保存エラー: {e}")

    async def _check_and_save_json_from_conversation(self, ctx: InvocationContext):
        """対話からJSON構成案を検出して保存（完全サイレント処理）"""
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

            # JSONブロックをユーザー表示から除去し、内部処理のみ実行
            json_str = None
            cleaned_response = llm_response_text
            
            if "```json" in llm_response_text and "```" in llm_response_text:
                json_str = self._extract_json_from_response(llm_response_text)
                if json_str:
                    # JSONブロックをユーザー表示から完全に除去
                    cleaned_response = self._remove_json_blocks_from_response(llm_response_text)
                    
                    # 内部保存処理（サイレント）
                    await self._save_json_data(ctx, json_str)
                    logger.info("JSON構成案をサイレントで保存しました（ユーザーには非表示）")
                    
                    # イベント内容を更新（JSONブロックを除去したクリーンなテキストに置き換え）
                    await self._update_event_content_silently(ctx, conversation_event, cleaned_response)
            
            # ユーザー承認確認を判定
            if self._is_user_approval(cleaned_response):
                await self._mark_user_approval(ctx)

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

    def _remove_json_blocks_from_response(self, response_text: str) -> str:
        """LLM応答からJSONブロックを完全に除去してクリーンなテキストを返す"""
        try:
            # 複数のJSONブロックに対応
            cleaned_text = response_text
            while "```json" in cleaned_text and "```" in cleaned_text:
                json_start = cleaned_text.find("```json")
                json_end = cleaned_text.find("```", json_start + 7) + 3
                if json_end > json_start:
                    # JSONブロックを除去
                    cleaned_text = cleaned_text[:json_start] + cleaned_text[json_end:]
                else:
                    break
            
            # 余分な空白行を整理
            lines = cleaned_text.split('\n')
            cleaned_lines = []
            consecutive_empty = 0
            
            for line in lines:
                if line.strip() == '':
                    consecutive_empty += 1
                    if consecutive_empty <= 1:  # 最大1行の空白行のみ許可
                        cleaned_lines.append(line)
                else:
                    consecutive_empty = 0
                    cleaned_lines.append(line)
            
            return '\n'.join(cleaned_lines).strip()
            
        except Exception as e:
            logger.warning(f"JSONブロック除去中にエラー: {e}")
            return response_text

    async def _update_event_content_silently(self, ctx: InvocationContext, event, new_content: str):
        """イベント内容をサイレントに更新（ユーザー表示をクリーン化）"""
        try:
            from google.genai.types import Content, Part
            
            # 新しいコンテンツでイベントを更新
            if hasattr(event, "content") and event.content:
                # Google Generative AI形式での更新
                new_content_obj = Content(parts=[Part(text=new_content)])
                event.content = new_content_obj
                logger.info("イベント内容をクリーンなテキストに更新しました")
                
        except Exception as e:
            logger.warning(f"イベント内容更新中にエラー: {e}")

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

    def _is_user_approval(self, response_text: str) -> bool:
        """ユーザーの承認を示すキーワードを検出"""
        approval_keywords = [
            "この内容でよろしいですか？",
            "この内容で大丈夫ですか？",
            "修正点があればお聞かせください",
            "いかがでしょうか？"
        ]
        return any(keyword in response_text for keyword in approval_keywords)

    async def _mark_user_approval(self, ctx: InvocationContext):
        """ユーザー承認段階をマーク"""
        try:
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["collection_stage"] = "awaiting_approval"
                logger.info("ユーザー承認待ち状態に設定しました")
        except Exception as e:
            logger.error(f"承認状態設定エラー: {e}")

    async def _prepare_html_generation_if_approved(self, ctx: InvocationContext):
        """ユーザー承認後のHTML生成準備"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                return

            # セッション状態からファイルシステムのJSONを強制的にセッション状態に同期
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"
            
            if outline_file.exists():
                with open(outline_file, "r", encoding="utf-8") as f:
                    json_data = f.read()
                    
                # セッション状態に強制保存
                ctx.session.state["outline"] = json_data
                logger.info("ファイルシステムからセッション状態にJSONを同期しました")
                
        except Exception as e:
            logger.error(f"HTML生成準備エラー: {e}")


def create_main_conversation_agent() -> MainConversationAgent:
    """MainConversationAgentのインスタンスを生成するファクトリ関数。"""
    return MainConversationAgent()


# ADK Web UI用のroot_agent変数
root_agent = create_main_conversation_agent()