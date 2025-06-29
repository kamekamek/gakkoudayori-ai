import json
import logging
from datetime import datetime
from typing import AsyncGenerator, Optional

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool, ToolContext
from google.genai.types import Content, Part

from .prompt import MAIN_CONVERSATION_INSTRUCTION

# ロガーの設定
logger = logging.getLogger(__name__)


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。ユーザーには自然な形で表示されます。"""
    current_date = datetime.now().strftime("%Y-%m-%d")
    logger.info(f"正確な現在日付を取得しました: {current_date}")
    return current_date


async def get_user_settings_context(user_id: str, tool_context: ToolContext = None) -> str:
    """
    ADK ToolContext を使用してユーザー設定情報を取得します。
    学校名、クラス名、先生名、タイトルテンプレートなどの個人設定を返します。
    """
    try:
        # ADK ToolContext からユーザーIDを取得（優先）
        actual_user_id = user_id
        if tool_context and hasattr(tool_context, 'session'):
            # セッションからユーザーIDを取得
            if hasattr(tool_context.session, 'user_id') and tool_context.session.user_id:
                actual_user_id = tool_context.session.user_id
            elif hasattr(tool_context.session, 'state') and tool_context.session.state.get("user_id"):
                actual_user_id = tool_context.session.state["user_id"]
            
            # セッション状態からキャッシュされたユーザー設定を確認
            cached_settings = tool_context.session.state.get("user_settings_context")
            if cached_settings:
                logger.info(f"キャッシュされたユーザー設定を使用: user_id={actual_user_id}")
                return cached_settings
        
        logger.info(f"ユーザー設定を取得中: user_id={actual_user_id}")

        # UserSettingsServiceを使用してユーザー設定を取得
        import os
        import sys
        sys.path.append(os.path.join(os.path.dirname(__file__), '..', '..'))
        from services.user_settings_service import UserSettingsService
        service = UserSettingsService()
        settings = await service.get_user_settings(actual_user_id)

        if settings:
            context_info = {
                "学校名": settings.school_name,
                "クラス名": settings.class_name,
                "先生名": settings.teacher_name,
                "メインタイトルパターン": settings.title_templates.primary,
                "現在の号数": settings.title_templates.current_number,
                "自動ナンバリング": settings.title_templates.auto_numbering,
                "季節テンプレート": settings.title_templates.seasonal,
                "カスタムテンプレート": [{"名前": t.name, "パターン": t.pattern} for t in settings.title_templates.custom],
                "設定完了": bool(settings.school_name and settings.class_name and settings.teacher_name),
                "作成日": settings.created_at.isoformat() if settings.created_at else None,
            }

            settings_json = json.dumps(context_info, ensure_ascii=False, indent=2)
            
            # セッション状態にキャッシュ保存
            if tool_context and hasattr(tool_context, 'session') and hasattr(tool_context.session, 'state'):
                tool_context.session.state["user_settings_context"] = settings_json
                tool_context.session.state["user_id"] = actual_user_id
                logger.info("ユーザー設定をセッション状態にキャッシュしました")

            logger.info(f"ユーザー設定取得成功: {settings.school_name} {settings.class_name}")
            return settings_json
        else:
            logger.warning(f"ユーザー設定が見つかりません: user_id={actual_user_id}")
            return json.dumps({
                "status": "設定なし",
                "message": "ユーザー設定が未作成です。設定画面から基本情報を入力してください。",
                "required_fields": ["学校名", "クラス名", "先生名"]
            }, ensure_ascii=False, indent=2)

    except Exception as e:
        logger.error(f"ユーザー設定取得エラー: {e}")
        return json.dumps({
            "status": "エラー",
            "message": f"ユーザー設定の取得に失敗しました: {str(e)}"
        }, ensure_ascii=False, indent=2)


def save_json_to_session(json_data: str, tool_context: ToolContext = None) -> str:
    """ADK ToolContext を使用してJSONデータをセッション状態に保存します。"""
    try:
        if not json_data or not json_data.strip():
            logger.warning("空のJSONデータは保存できません")
            return "❌ 保存するデータがありません"
        
        # JSONの有効性を確認
        try:
            json.loads(json_data)
            logger.info(f"JSON検証成功: {len(json_data)} 文字")
        except json.JSONDecodeError as e:
            logger.error(f"無効なJSONデータ: {e}")
            return f"❌ 無効なJSONデータです: {str(e)}"
        
        # ADK ToolContext を使用してセッション状態に保存
        if tool_context and hasattr(tool_context, 'session') and hasattr(tool_context.session, 'state'):
            # ADK標準のoutput_keyを使用
            tool_context.session.state["outline"] = json_data
            tool_context.session.state["json_ready_for_layout"] = True
            tool_context.session.state["json_timestamp"] = datetime.now().isoformat()
            
            logger.info(f"JSONデータをセッション状態に保存: outline キー使用")
            return f"✅ JSON構成案をセッション状態に保存しました: {len(json_data)} 文字"
        else:
            logger.warning("ToolContextまたはセッション状態にアクセスできません")
            return "⚠️ セッション状態への保存に失敗しました（ToolContextが無効）"
            
    except Exception as e:
        logger.error(f"JSON保存エラー: {e}")
        return f"❌ 保存中にエラーが発生しました: {str(e)}"


class MainConversationAgent(LlmAgent):
    """
    メインの対話エージェント。
    ユーザーと自然な対話を行い、適切なタイミングでLayoutAgentにHTML生成を委譲します。
    """

    def __init__(self):
        # ADK Auto-Flow対応: 適切なdescriptionで自動委譲を実現
        from agents.layout_agent.agent import create_layout_agent
        layout_agent = create_layout_agent()

        super().__init__(
            name="main_conversation_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=MAIN_CONVERSATION_INSTRUCTION,
            description="先生方との自然な対話を通じて学級通信の基本情報（学校名、クラス、内容等）を収集し、必要に応じて専門エージェントに委譲する対話管理エージェントです。",
            tools=[
                FunctionTool(get_current_date),
                FunctionTool(get_user_settings_context)
            ],
            sub_agents=[layout_agent],  # ADK Auto-Flow対応
            output_key="outline",  # ADK標準のoutput_key機能
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        ADK Auto-Flow対応: 自然な対話とシンプルなエージェント委譲を実現。
        """
        try:
            logger.info("=== MainConversationAgent実行開始 (ADK Auto-Flow対応版) ===")
            
            # ユーザー設定の初期取得
            await self._initialize_user_context(ctx)

            # ADK標準の親エージェント実行（Auto-Flowが自動的にLayoutAgentを委譲）
            async for event in super()._run_async_impl(ctx):
                yield event

            # セッション状態への情報保存（ADK標準のoutput_key使用）
            await self._check_and_save_json_from_conversation(ctx)

            logger.info("=== MainConversationAgent実行完了 ===")

        except Exception as e:
            error_msg = f"申し訳ございません。処理中に問題が発生しました。もう一度お試しください。"
            logger.error(f"MainConversationAgent実行エラー: {str(e)}")
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text=error_msg)])
            )

    async def _initialize_user_context(self, ctx: InvocationContext):
        """エージェント実行開始時にユーザー設定を取得してコンテキストに保存"""
        try:
            logger.info("🔍 ユーザーコンテキスト初期化開始")

            # ユーザーIDをセッション状態から取得
            user_id = None
            if hasattr(ctx, "session") and hasattr(ctx.session, "user_id"):
                user_id = ctx.session.user_id
            elif hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                user_id = ctx.session.state.get("user_id")

            if not user_id:
                logger.warning("ユーザーIDが取得できません - デフォルト設定を使用")
                return

            logger.info(f"ユーザーID取得: {user_id}")

            # セッション状態にユーザーIDを保存
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["user_context_initialized"] = True
                ctx.session.state["user_id"] = user_id

                logger.info("✅ ユーザーコンテキスト初期化完了")
                logger.info(f"ユーザーID: {user_id}")
            else:
                logger.error("セッション状態にアクセスできません")

        except Exception as e:
            logger.error(f"ユーザーコンテキスト初期化エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

    async def _extract_conversation_info(self, ctx: InvocationContext) -> str:
        """対話履歴から学級通信作成に必要な情報を抽出"""
        try:
            # セッション履歴から最新の対話内容を取得
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                return None

            # ユーザー設定から基本情報を取得
            user_settings_json = ctx.session.state.get('user_settings_context', '{}')
            
            # 対話から収集した情報をJSON形式で構築
            summary_data = {
                "schema_version": "2.4",
                "user_settings": user_settings_json,
                "conversation_complete": True,
                "ready_for_layout": True,
                "timestamp": get_current_date()
            }
            
            import json
            return json.dumps(summary_data, ensure_ascii=False, indent=2)

        except Exception as e:
            logger.error(f"対話情報抽出エラー: {e}")
            return None

    async def _check_and_save_json_from_conversation(self, ctx: InvocationContext):
        """対話から学級通信情報を抽出してセッション状態に保存"""
        try:
            logger.info("🔍 対話からJSON情報を抽出中")
            
            # 対話履歴から情報を抽出
            extracted_info = await self._extract_conversation_info(ctx)
            
            if extracted_info:
                # セッション状態に保存
                save_result = save_json_to_session(extracted_info, ctx)
                logger.info(f"JSON保存結果: {save_result}")
            else:
                logger.info("抽出可能な情報がありませんでした")
                
        except Exception as e:
            logger.error(f"JSON抽出・保存エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")


def create_main_conversation_agent() -> MainConversationAgent:
    """MainConversationAgentのインスタンスを生成するファクトリ関数。"""
    return MainConversationAgent()


# ADK Web UI用のroot_agent変数
root_agent = create_main_conversation_agent()
