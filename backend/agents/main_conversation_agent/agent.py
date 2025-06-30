import json
import logging
import os
from datetime import datetime
from typing import AsyncGenerator, Optional

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool, ToolContext
from google.genai.types import Content, Part

from services.user_settings_service import UserSettingsService

from .prompt import MAIN_CONVERSATION_INSTRUCTION

# ロガーの設定
logger = logging.getLogger(__name__)

# モジュールレベルのユーザーID管理（ADK FunctionTool制限の回避）
_current_user_id = None

def set_current_user_id(user_id: str):
    """現在のユーザーIDを設定（MainConversationAgentが呼び出し）"""
    global _current_user_id
    _current_user_id = user_id
    logger.info(f"現在のユーザーIDを設定: {user_id}")

def get_current_user_id() -> Optional[str]:
    """現在のユーザーIDを取得（get_user_settings_context関数が使用）"""
    global _current_user_id
    return _current_user_id


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。ユーザーには自然な形で表示されます。"""
    current_date = datetime.now().strftime("%Y-%m-%d")
    logger.info(f"正確な現在日付を取得しました: {current_date}")
    return current_date


async def get_user_settings_context() -> str:
    """
    ユーザー設定情報を取得します。
    学校名、クラス名、先生名、タイトルテンプレートなどの個人設定を返します。
    
    注意: この関数はADK FunctionToolとして使用されるため、
    tool_contextは直接受け取れません。グローバル変数でユーザーIDを管理します。
    """
    try:
        # グローバル変数から現在のユーザーIDを取得
        actual_user_id = get_current_user_id()
        
        if not actual_user_id:
            logger.warning("ユーザーIDが設定されていません。デフォルト設定を使用します。")
            return json.dumps({
                "status": "設定なし",
                "message": "ユーザーIDが設定されていません。",
                "学校名": "○○小学校",
                "クラス名": "3年2組", 
                "先生名": "田中先生",
                "設定完了": False
            }, ensure_ascii=False, indent=2)
        
        logger.info(f"ユーザー設定を取得中: user_id={actual_user_id}")

        # UserSettingsServiceを使用してユーザー設定を取得
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
            
            # 注意: tool_contextはADK FunctionToolでは利用不可
            # セッション状態への保存は将来のADK更新で対応予定
            logger.info("ユーザー設定取得完了（セッション状態保存はスキップ）")

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

        # 環境変数からGCPプロジェクト情報を取得
        project_id = os.environ.get("GCP_PROJECT_ID", "gakkoudayori-ai")  # デフォルト値設定
        location = os.environ.get("GCP_REGION", "asia-northeast1")  # デフォルト値設定
        api_key = os.environ.get("GOOGLE_API_KEY")

        model_config = {"model_name": "gemini-2.5-pro"}
        
        # Cloud Run環境（デフォルト認証）またはローカル環境での分岐
        if api_key:
            # APIキーが設定されている場合（ローカル開発）
            model_config["api_key"] = api_key
            logger.info("<<<<< API KEY CONFIG v4 APPLIED IN MAIN_CONVERSATION_AGENT >>>>>")
            logger.info("APIキーモードでGeminiを初期化（ローカル開発用）")
        else:
            # Cloud Run環境でのVertex AI使用（デフォルト認証）
            model_config["vertexai"] = True
            model_config["project"] = project_id
            model_config["location"] = location
            logger.info("<<<<< VERTEX AI CONFIG v4 APPLIED IN MAIN_CONVERSATION_AGENT >>>>>")
            logger.info(f"Vertex AIモードでGeminiを初期化: project={project_id}, location={location}")


        super().__init__(
            name="main_conversation_agent",
            model=Gemini(**model_config),
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
        シンプルなADK標準実装: 自然な対話でLayoutAgentに自動委譲
        """
        try:
            logger.info("=== MainConversationAgent実行開始 (シンプル版) ===")
            
            # ユーザー設定の初期取得
            await self._initialize_user_context(ctx)

            # 基本情報をセッション状態に保存
            await self._save_basic_info_to_session(ctx)

            # プロンプトにセッション状態の情報を動的に追加
            await self._enhance_prompt_with_session_context(ctx)

            # ADK標準の親エージェント実行（transfer_to_agentで自動委譲）
            async for event in super()._run_async_impl(ctx):
                yield event

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

            # グローバル変数にユーザーIDを設定（get_user_settings_context関数で使用）
            set_current_user_id(user_id)

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

    async def _save_basic_info_to_session(self, ctx: InvocationContext):
        """基本情報をセッション状態に保存（LayoutAgentで使用）"""
        try:
            logger.info("基本情報をセッション状態に保存中...")
            
            # ツールを手動実行してデータを取得
            logger.info("🔧 手動でツールを実行してデータを取得中...")
            
            # 1. 現在の日付を取得
            current_date = get_current_date()
            logger.info(f"📅 現在の日付取得: {current_date}")
            
            # 2. ユーザー設定を取得
            user_settings = {}
            try:
                user_settings_json = await get_user_settings_context()
                if user_settings_json:
                    import json
                    user_settings = json.loads(user_settings_json)
                    logger.info(f"👤 ユーザー設定取得: {user_settings.get('学校名', '未設定')} {user_settings.get('クラス名', '未設定')}")
            except Exception as e:
                logger.error(f"ユーザー設定取得エラー: {e}")
            
            # セッション状態に基本情報を保存
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                # 日付情報を保存
                ctx.session.state["current_date"] = current_date
                ctx.session.state["tool_date_retrieved"] = current_date
                
                # ユーザー設定を保存
                ctx.session.state["school_name"] = user_settings.get("学校名", "○○小学校")
                ctx.session.state["class_name"] = user_settings.get("クラス名", "3年2組") 
                ctx.session.state["teacher_name"] = user_settings.get("先生名", "田中先生")
                ctx.session.state["settings_complete"] = user_settings.get("設定完了", False)
                
                # エージェントの応答用コンテキストを保存
                response_context = f"""
今日の日付: {current_date}
学校名: {ctx.session.state['school_name']}
クラス名: {ctx.session.state['class_name']}
担任の先生: {ctx.session.state['teacher_name']}
設定状況: {'完了' if ctx.session.state['settings_complete'] else '未完了'}
"""
                ctx.session.state["response_context"] = response_context
                
                logger.info(f"✅ 基本情報保存完了: {ctx.session.state['school_name']} {ctx.session.state['class_name']} {ctx.session.state['teacher_name']} (日付: {current_date})")
            else:
                logger.error("セッション状態にアクセスできません")
                
        except Exception as e:
            logger.error(f"基本情報保存エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

    async def _enhance_prompt_with_session_context(self, ctx: InvocationContext):
        """セッション状態の情報をプロンプトに動的に追加"""
        try:
            logger.info("📝 プロンプトにセッション状態情報を追加中...")
            
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.error("セッション状態にアクセスできません")
                return
            
            state = ctx.session.state
            
            # セッション状態から情報を取得
            current_date = state.get("current_date", "2025-06-30")
            school_name = state.get("school_name", "○○小学校")
            class_name = state.get("class_name", "3年2組")
            teacher_name = state.get("teacher_name", "田中先生")
            settings_complete = state.get("settings_complete", False)
            
            # 動的なコンテキスト情報を作成
            context_info = f"""

=== 現在のセッション情報 ===
📅 今日の日付: {current_date}
🏫 学校名: {school_name}
📚 クラス名: {class_name}
👨‍🏫 担任の先生: {teacher_name}
⚙️ 設定状況: {'完了' if settings_complete else '未完了'}

**重要指示**: 
- 上記の情報を必ず使用して応答してください
- 「今日は何日でしょうか？」などの質問は不要です
- 設定が完了している場合は具体的な情報を使用してください
- 設定が未完了の場合のみ、設定画面での登録を案内してください

"""
            
            # 既存のプロンプトに動的情報を追加
            original_instruction = self.instruction
            enhanced_instruction = original_instruction + context_info
            
            # プロンプトを一時的に更新
            self.instruction = enhanced_instruction
            
            logger.info(f"✅ プロンプト拡張完了: 日付={current_date}, 学校={school_name}, クラス={class_name}, 先生={teacher_name}")
            
        except Exception as e:
            logger.error(f"プロンプト拡張エラー: {e}")
            import traceback
            logger.error(f"詳細エラー: {traceback.format_exc()}")

def create_main_conversation_agent() -> MainConversationAgent:
    """MainConversationAgentのインスタンスを生成するファクトリ関数。"""
    return MainConversationAgent()


# ADK Web UI用のroot_agent変数
root_agent = create_main_conversation_agent()
