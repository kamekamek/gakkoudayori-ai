import json
import logging
import os
from typing import AsyncGenerator, Optional

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.genai.types import Content, Part

from .deliver_html_tool import html_delivery_tool
from .prompt import INSTRUCTION

# ロガーの設定
logger = logging.getLogger(__name__)


class LayoutAgent(LlmAgent):
    """
    JSONデータからHTMLレイアウトを生成するエージェント。
    layout.mdの内容をベースにした美しいHTMLを生成します。
    """

    def __init__(self, output_key: str = "html"):
        # 環境変数からGCPプロジェクト情報を取得
        project_id = os.environ.get("GCP_PROJECT_ID")
        location = os.environ.get("GCP_REGION")

        model_config = {
            "model_name": "gemini-2.5-pro",
        }

        # google-genaiがVertex AIを使うための設定
        if os.environ.get("GOOGLE_GENAI_USE_VERTEXAI") == "true":
            if not project_id or not location:
                raise ValueError("LayoutAgent: Vertex AIを使用するにはGCP_PROJECT_IDとGCP_REGION環境変数が必要です。")
            model_config["vertexai"] = True
            model_config["project"] = project_id
            model_config["location"] = location
            logger.info(f"LayoutAgent: Vertex AIモードでGeminiを構成: project={project_id}, location={location}")
        else:
            # APIキー（ローカル用）
            api_key = os.environ.get("GOOGLE_API_KEY")
            if not api_key:
                logger.warning("LayoutAgent: GOOGLE_API_KEY環境変数が見つかりません。ローカル実行に失敗する可能性があります。")
            else:
                model_config["api_key"] = api_key
                logger.info("LayoutAgent: APIキーモードでGeminiを構成（ローカル開発用）")
        
        super().__init__(
            name="layout_agent",
            model=Gemini(**model_config),
            instruction=INSTRUCTION,
            description="学級通信の情報が揃い、ユーザーが「作成してください」「お願いします」「完成させて」等の要求をした際に、美しいHTMLレイアウトを生成してフロントエンドに配信する専門エージェントです。",
            tools=[html_delivery_tool.create_adk_function_tool()],
            output_key=output_key,
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジックをオーバーライドし、
        セッション状態からJSONデータを読み込んでHTMLを生成します。
        AgentTool経由での呼び出しに対応します。
        """
        try:
            # セッションIDを取得してHTML配信ツールに設定
            session_id = self._extract_session_id(ctx)
            if session_id:
                html_delivery_tool.set_session_id(session_id)
                logger.info(f"LayoutAgent: セッションID設定完了 - {session_id}")
            else:
                logger.warning("LayoutAgent: セッションIDの取得に失敗しました")

            # ユーザーフレンドリーな開始メッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="学級通信のレイアウトを作成しています。少々お待ちください...")])
            )

            # セッション状態から基本情報を取得
            basic_info = self._get_basic_info_from_session(ctx)
            
            if not basic_info:
                logger.error("❌ 基本情報が見つかりません")
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text="❌ 学級通信の基本情報が不足しています。もう一度、学校名・学年・先生名などの基本情報をお聞かせください。")])
                )
                return

            # 会話履歴から学級通信の内容を抽出
            conversation_content = self._extract_content_from_conversation(ctx)

            logger.info(f"基本情報取得成功: {basic_info['school_name']} {basic_info['class_name']} {basic_info['teacher_name']}")
            logger.info(f"会話内容: {conversation_content[:100]}...")

            # ユーザーフレンドリーな進行中メッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="美しいデザインで仕上げています...")])
            )

            # 学級通信のHTMLを生成するためのプロンプト作成
            enhanced_prompt = f"""
以下の情報から学級通信のHTMLを生成してください。

基本情報:
- 学校名: {basic_info['school_name']}
- クラス名: {basic_info['class_name']}
- 担任の先生: {basic_info['teacher_name']}
- 発行日: {basic_info['current_date']}

学級通信の内容:
{conversation_content}

要件:
- 美しくレスポンシブなデザインにしてください
- 完全なHTMLドキュメントとして出力してください
- 日本の学級通信らしい温かみのあるデザインにしてください
- HTMLのみを出力してください（説明は不要）
            """

            # 一時的にプロンプトを更新してLLMを実行
            original_instruction = self.instruction
            self.instruction = enhanced_prompt

            # LLM実行（イベントを保存してHTMLを抽出）
            llm_events = []
            async for event in super()._run_async_impl(ctx):
                llm_events.append(event)

            # LLMイベントからHTMLを抽出してセッション状態に保存
            await self._save_html_from_llm_events(ctx, llm_events)

            # プロンプトを元に戻す
            self.instruction = original_instruction

            # HTMLが正常に生成された場合、配信ツールを自動実行
            if hasattr(ctx, "session") and hasattr(ctx.session, "state") and ctx.session.state.get("html"):
                html_content = ctx.session.state["html"]
                logger.info(f"HTML生成完了: {len(html_content)}文字")

                # HTML配信ツールを自動実行
                try:
                    metadata_json = json.dumps({"auto_generated": True, "agent": "layout_agent"})
                    delivery_result = await html_delivery_tool.deliver_html_to_frontend(
                        html_content=html_content,
                        artifact_type="newsletter",
                        metadata_json=metadata_json
                    )

                    yield Event(
                        author=self.name,
                        content=Content(parts=[Part(text=delivery_result)])
                    )

                except Exception as tool_error:
                    logger.error(f"HTML配信エラー: {tool_error}")
                    yield Event(
                        author=self.name,
                        content=Content(parts=[Part(text=f"❌ HTML配信中にエラーが発生しました: {str(tool_error)}")])
                    )
            else:
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text="❌ HTMLの生成に失敗しました。もう一度お試しください。")])
                )

        except Exception as e:
            # 技術的エラーをユーザーフレンドリーなメッセージに変換
            user_friendly_msg = "申し訳ございません。レイアウト作成中に問題が発生しました。もう一度お試しください。"
            logger.error(f"レイアウト生成中にエラーが発生しました: {str(e)}")
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text=user_friendly_msg)])
            )

    async def _save_html_from_llm_events(self, ctx: InvocationContext, llm_events):
        """LLMイベントからHTMLを抽出してセッション状態に保存"""
        try:
            # イベントからテキストを結合
            llm_response_text = ""
            for event in llm_events:
                event_text = self._extract_text_from_event(event)
                llm_response_text += event_text

            if not llm_response_text.strip():
                logger.warning("LLMイベントからテキストを抽出できません")
                return

            logger.info(f"LLMイベントから抽出したテキスト長: {len(llm_response_text)}")

            # HTMLの抽出
            html_content = self._extract_html_from_response(llm_response_text)

            # セッション状態に保存（ADK標準）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["html"] = html_content
                logger.info("HTMLをセッション状態に保存しました")

            # セッション状態のみでデータ保存
            logger.info("HTMLをセッション状態に保存")

        except Exception as e:
            logger.error(f"LLMイベントからのHTML保存エラー: {e}")


    async def _generate_html_from_template(self, ctx: InvocationContext, json_obj):
        """JSONデータからテンプレートベースでHTMLを確実に生成"""
        try:
            school_name = json_obj.get('school_name', 'ERROR')
            grade = json_obj.get('grade', 'ERROR')
            author_name = json_obj.get('author', {}).get('name', 'ERROR')
            author_title = json_obj.get('author', {}).get('title', 'ERROR')
            issue_date = json_obj.get('issue_date', 'ERROR')
            main_title = json_obj.get('main_title', 'ERROR')

            color_scheme = json_obj.get('color_scheme', {})
            primary_color = color_scheme.get('primary', '#FFFF99')
            secondary_color = color_scheme.get('secondary', '#FFCC99')
            accent_color = color_scheme.get('accent', '#FF9966')

            sections = json_obj.get('sections', [])
            main_content = ""
            for section in sections:
                content = section.get('content', '')
                # 改行を<p>タグに変換
                paragraphs = content.split('\n')
                for paragraph in paragraphs:
                    if paragraph.strip():
                        main_content += f"    <p>{paragraph.strip()}</p>\n"

            # 確実なHTMLテンプレート生成
            template_html = f'''<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{school_name} {grade} {json_obj.get('issue', '学級通信')}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500;700&display=swap');
    
    body {{
      font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #ffffff;
      color: #333333;
      line-height: 1.6;
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
    }}
    .container {{
      max-width: 800px;
      margin: 0 auto;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }}
    .header {{
      background-color: {primary_color};
      padding: 20px;
      text-align: center;
      border-bottom: 3px solid {accent_color};
    }}
    .header h1 {{
      margin: 0;
      color: #333333;
      font-size: 24px;
      font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
      font-weight: 500;
    }}
    .header p {{
      margin: 10px 0 0 0;
      color: #333333;
    }}
    .main-content {{
      padding: 30px;
    }}
    .main-content h2 {{
      color: {accent_color};
      border-left: 4px solid {secondary_color};
      padding-left: 15px;
      margin-bottom: 20px;
      font-family: 'Noto Sans JP', 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', 'Yu Gothic', 'Meiryo', sans-serif;
      font-weight: 500;
    }}
    .footer {{
      background-color: {secondary_color};
      padding: 15px;
      text-align: center;
      color: #333333;
    }}
    @media print {{
      body {{ margin: 0; }}
      .container {{ box-shadow: none; }}
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>{school_name} {grade}</h1>
      <p>{json_obj.get('issue', '学級通信')} - {issue_date}</p>
      <p>発行者: {author_title} {author_name}</p>
    </div>
    <div class="main-content">
      <h2>{main_title}</h2>
{main_content}
    </div>
    <div class="footer">
      <p>{school_name} {grade}</p>
    </div>
  </div>
</body>
</html>'''

            # セッション状態に保存
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["html"] = template_html
                logger.info("テンプレートHTMLをセッション状態に保存しました")

            # セッション状態のみでデータ保存
            logger.info("テンプレートHTMLをセッション状態に保存")

        except Exception as e:
            logger.error(f"テンプレートHTML生成エラー: {e}")

    def _get_basic_info_from_session(self, ctx: InvocationContext) -> dict:
        """セッション状態から基本情報を取得"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.error("セッション状態にアクセスできません")
                return None
            
            state = ctx.session.state
            basic_info = {
                "school_name": state.get("school_name", "○○小学校"),
                "class_name": state.get("class_name", "3年2組"),
                "teacher_name": state.get("teacher_name", "田中先生"),
                "current_date": state.get("current_date", "2025-06-30")
            }
            
            # 基本情報が揃っているかチェック
            if not basic_info["school_name"] or not basic_info["class_name"] or not basic_info["teacher_name"]:
                logger.warning(f"基本情報不足: {basic_info}")
                return None
                
            return basic_info
            
        except Exception as e:
            logger.error(f"基本情報取得エラー: {e}")
            return None

    def _extract_content_from_conversation(self, ctx: InvocationContext) -> str:
        """会話履歴から学級通信の内容を抽出"""
        try:
            # セッションから会話履歴を取得
            if not hasattr(ctx, "session"):
                return "学級通信の内容がここに入ります。"
            
            # 新しいメッセージから内容を抽出
            content = ""
            if hasattr(ctx, 'new_message') and ctx.new_message:
                if hasattr(ctx.new_message, 'parts'):
                    for part in ctx.new_message.parts:
                        if hasattr(part, 'text') and part.text:
                            content += part.text + "\n"
            
            if not content.strip():
                content = "今日は素晴らしい一日でした。子どもたちは元気に活動し、たくさんのことを学びました。"
            
            return content.strip()
            
        except Exception as e:
            logger.error(f"会話内容抽出エラー: {e}")
            return "学級通信の内容がここに入ります。"

    def _extract_session_id(self, ctx: InvocationContext) -> Optional[str]:
        """InvocationContextからセッションIDを抽出"""
        try:
            # ADKセッションからセッションIDを取得
            if hasattr(ctx, "session") and hasattr(ctx.session, "session_id"):
                session_id = ctx.session.session_id
                logger.info(f"セッションID抽出成功: {session_id}")
                return session_id

            # 代替手段: セッション情報から推測
            if hasattr(ctx, "session") and hasattr(ctx.session, "user_id"):
                # user_id から session_id を推測（フォールバック）
                user_id = ctx.session.user_id
                session_id = f"{user_id}:default"
                logger.warning(f"セッションIDをuser_idから推測: {session_id}")
                return session_id

            logger.error("セッションIDの抽出に失敗: sessionオブジェクトが見つかりません")
            return None

        except Exception as e:
            logger.error(f"セッションID抽出エラー: {e}")
            return None


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

    def _extract_html_from_response(self, response_text: str) -> str:
        """LLM応答からHTMLを抽出"""
        logger.info(f"LLM応答テキスト長: {len(response_text)}")

        # HTMLコードブロックが含まれている場合は抽出
        if "```html" in response_text:
            logger.info("HTMLコードブロック(```html)を検出、抽出中...")
            html_start = response_text.find("```html") + 7
            html_end = response_text.find("```", html_start)
            if html_end != -1:
                return response_text[html_start:html_end].strip()

        # <!DOCTYPE html>から始まるHTMLを検出
        if "<!DOCTYPE html>" in response_text:
            logger.info("DOCTYPE宣言を検出、HTML抽出中...")
            html_start = response_text.find("<!DOCTYPE html>")
            # </html>の終了を検出
            html_end = response_text.rfind("</html>") + 7
            if html_end > html_start:
                return response_text[html_start:html_end]

        # <html>タグから始まるHTMLを検出
        if "<html" in response_text:
            logger.info("<html>タグを検出、HTML抽出中...")
            html_start = response_text.find("<html")
            html_end = response_text.rfind("</html>") + 7
            if html_end > html_start:
                return response_text[html_start:html_end]

        # HTMLが検出されない場合は全体を返す
        logger.warning(
            "明確なHTMLブロックが検出されませんでした。応答全体を使用します。"
        )
        return response_text



    async def _validate_json_data(self, json_data: str) -> bool:
        """JSONデータの基本的な有効性検証（新しいデータ構造に対応）"""
        try:
            if not json_data or not json_data.strip():
                logger.warning("JSONデータが空です")
                return False

            # JSON形式として解析可能かチェック
            parsed = json.loads(json_data)
            
            # 新しいデータ構造対応: newsletter_infoフィールドをチェック
            newsletter_info = parsed.get('newsletter_info', {})
            if not newsletter_info:
                logger.warning("newsletter_infoフィールドが見つかりません")
                return False

            # 基本的な必須フィールドの存在確認（新しい構造）
            required_fields = ['school_name', 'class_name', 'teacher_name']
            for field in required_fields:
                if field not in newsletter_info or not newsletter_info[field]:
                    logger.warning(f"newsletter_info内の必須フィールド '{field}' が見つかりません")
                    return False

            school_name = newsletter_info.get('school_name', '')
            class_name = newsletter_info.get('class_name', '')
            teacher_name = newsletter_info.get('teacher_name', '')
            
            logger.info(f"JSON検証成功: 学校={school_name}, クラス={class_name}, 先生={teacher_name}")
            return True

        except json.JSONDecodeError as e:
            logger.error(f"JSON解析エラー: {e}")
            return False
        except Exception as e:
            logger.error(f"JSON検証エラー: {e}")
            return False


def create_layout_agent() -> LayoutAgent:
    """LayoutAgentのインスタンスを生成するファクトリ関数。"""
    return LayoutAgent(output_key="html")


# ADK Web UI用のroot_agent変数
root_agent = create_layout_agent()
