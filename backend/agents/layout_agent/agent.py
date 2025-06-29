import json
import logging

# from pathlib import Path  # 本番環境対応: ファイルシステム使用無効化
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
        # 明示的にgemini-2.5-proを指定してモデル不整合を解決
        model = Gemini(model_name="gemini-2.5-pro")
        logger.info("LayoutAgent初期化: モデル=gemini-2.5-pro")

        super().__init__(
            name="layout_agent",
            model=model,
            instruction=INSTRUCTION,
            description="JSONデータから美しいHTMLレイアウトを生成し、フロントエンドに配信します。",
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

            # ADK推奨パターン: transfer_to_agentでの堅牢なJSON取得
            json_data = None
            logger.info("=== LayoutAgent JSON取得開始 (ADK推奨パターン) ===")

            # セッション状態詳細確認
            await self._log_session_state_details(ctx)

            # ADK推奨: outline キーからの取得（第一優先）
            json_data = await self._get_json_from_adk_output_key(ctx)

            if json_data:
                logger.info(f"✅ ADK output_key取得成功: {len(json_data)} 文字")

                # JSON検証
                if await self._validate_json_data(json_data):
                    logger.info("✅ JSON検証成功: 有効なデータです")
                else:
                    logger.warning("❌ JSON検証失敗: フォールバック処理を実行")
                    json_data = None
            else:
                logger.warning("❌ ADK output_key取得失敗: outline キーが見つかりません")

                # セッション状態のデータ検証
                if json_data:
                    try:
                        import json as json_module
                        json_obj = json_module.loads(json_data)
                        required_fields = ['school_name', 'grade', 'author', 'main_title']
                        missing_fields = [field for field in required_fields if not json_obj.get(field)]

                        if missing_fields:
                            logger.warning(f"セッション状態のJSONに必須フィールドが不足: {missing_fields}")
                            json_data = None  # 不完全なデータは使用しない
                        else:
                            logger.info(f"セッション状態のJSONデータ検証完了: {json_obj.get('school_name')} {json_obj.get('grade')}")
                    except Exception as e:
                        logger.error(f"セッション状態のJSON検証エラー: {e}")
                        json_data = None

            # フォールバック: MainConversationAgentから直接取得を試行
            if not json_data:
                logger.info("=== MainConversationAgentからの直接取得を試行 ===")
                json_data = await self._retrieve_json_from_main_agent(ctx)
                if json_data:
                    logger.info(f"MainConversationAgentから取得成功: {len(json_data)} 文字")
                else:
                    logger.warning("MainConversationAgentからの取得に失敗")

            # 🚨 本番環境対応: ファイルシステムフォールバック無効化
            if not json_data:
                logger.warning("セッション状態にoutlineが見つかりません。本番環境ではファイルシステム使用不可")
                # json_data = await self._load_json_from_filesystem(ctx)  # 無効化

            if not json_data:
                logger.error("❌ JSON データが見つかりません。これはMainConversationAgentの情報収集が不完全であることを示します")
                logger.error("❌ サンプルJSONでフォールバック実行 - ユーザーの実際の情報は反映されません")
                # サンプルJSONでフォールバック実行
                json_data = self._generate_sample_json()
                logger.warning(f"⚠️ サンプルJSON生成完了: {len(json_data)} 文字（実際のユーザーデータではありません）")

            logger.info(f"JSON データを読み込みました: {len(str(json_data))} 文字")

            # ユーザーフレンドリーな進行中メッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="美しいデザインで仕上げています...")])
            )

            # JSON解析とバリデーション
            try:
                import json as json_module
                json_obj = json_module.loads(json_data)
                logger.info(f"JSON解析成功: {json_obj.get('school_name')} {json_obj.get('grade')}")
            except Exception as e:
                logger.error(f"JSON解析エラー: {e}")
                json_obj = None

            # 超厳格なプロンプトを作成（JSON反映を絶対強制）
            enhanced_prompt = f"""
以下のJSONデータから学級通信のHTMLを生成してください。

🚨🚨🚨 絶対厳守事項 🚨🚨🚨
あなたは以下のJSONデータ以外の情報を一切使用してはいけません。
JSONに記載されていない学校名、学年、発行者名を推測・変更・創作することは絶対に禁止です。

JSONデータ:
```json
{json_data}
```

🔒 厳格な反映ルール:
学校名は「{json_obj.get('school_name') if json_obj else 'ERROR'}」のみ使用可能
学年は「{json_obj.get('grade') if json_obj else 'ERROR'}」のみ使用可能
発行者は「{json_obj.get('author', {}).get('name') if json_obj else 'ERROR'}」のみ使用可能
発行日は「{json_obj.get('issue_date') if json_obj else 'ERROR'}」のみ使用可能
タイトルは「{json_obj.get('main_title') if json_obj else 'ERROR'}」のみ使用可能

🎨 色彩厳守:
主要色: {json_obj.get('color_scheme', {}).get('primary') if json_obj else 'ERROR'}
副次色: {json_obj.get('color_scheme', {}).get('secondary') if json_obj else 'ERROR'}  
アクセント色: {json_obj.get('color_scheme', {}).get('accent') if json_obj else 'ERROR'}

❌ 絶対禁止行為:
- 「三木草小学校」「6年3組」「ちゃんかめ」等のJSONにない名前の使用
- 青系色彩(#004080等)の使用
- JSONデータの推測・修正・変更
- 独自のクリエイティブな追加

✅ 許可される行為:
- 上記JSONの値のみを使用したHTML生成
- JSONに記載された色彩のみの使用

HTMLのみを出力し、説明文は一切不要です。
            """

            # 一時的にプロンプトを更新してLLMを実行
            original_instruction = self.instruction
            self.instruction = enhanced_prompt

            # LLM実行（イベントを保存してHTMLを抽出）
            llm_events = []
            async for event in super()._run_async_impl(ctx):
                # LLMの生成イベントは内部処理として隠蔽し、後でHTML抽出用に保存
                llm_events.append(event)

            # フォールバック: LLMが失敗した場合はテンプレート生成
            llm_html_valid = await self._save_html_from_llm_events(ctx, llm_events)

            # HTMLとJSONの一致検証
            is_consistent = await self._validate_html_json_consistency(ctx, json_obj)

            # 不整合がある場合はテンプレート生成でフォールバック
            if not is_consistent and json_obj:
                logger.warning("LLM生成HTMLに不整合があります。テンプレート生成にフォールバック...")
                await self._generate_html_from_template(ctx, json_obj)

            # プロンプトを元に戻す
            self.instruction = original_instruction

            # HTMLが正常に生成された場合、配信ツールを自動実行
            if hasattr(ctx, "session") and hasattr(ctx.session, "state") and ctx.session.state.get("html"):
                html_content = ctx.session.state["html"]
                logger.info(f"HTML生成完了: {len(html_content)}文字")

                # HTML生成完了フラグを設定
                ctx.session.state["html_generated"] = True
                from datetime import datetime
                ctx.session.state["html_generation_timestamp"] = datetime.now().strftime("%Y-%m-%d")
                logger.info("HTML生成完了フラグを設定しました")

                # HTML配信ツールを自動実行
                try:
                    import json
                    metadata_json = json.dumps({"auto_generated": True, "agent": "layout_agent"})
                    delivery_result = await html_delivery_tool.deliver_html_to_frontend(
                        html_content=html_content,
                        artifact_type="newsletter",
                        metadata_json=metadata_json
                    )

                    # 配信結果をユーザーに通知
                    yield Event(
                        author=self.name,
                        content=Content(parts=[Part(text=delivery_result)])
                    )

                except Exception as tool_error:
                    error_msg = f"❌ HTML配信中にエラーが発生しました: {str(tool_error)}"
                    logger.error(f"HTML配信ツールエラー: {tool_error}")
                    yield Event(
                        author=self.name,
                        content=Content(parts=[Part(text=error_msg)])
                    )
            else:
                # HTMLが生成されなかった場合
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

            # 🚨 本番環境対応: ファイルシステム保存を無効化
            # Cloud Runでは/tmpが一時的なため、セッション状態のみに依存
            logger.info("HTMLをセッション状態に保存（本番環境ではファイル保存無効）")

        except Exception as e:
            logger.error(f"LLMイベントからのHTML保存エラー: {e}")

    async def _validate_html_json_consistency(self, ctx: InvocationContext, json_obj):
        """HTMLとJSONデータの一致を検証"""
        try:
            if not json_obj:
                logger.warning("JSON検証スキップ: JSONオブジェクトがありません")
                return

            # セッション状態からHTMLを取得
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                html_content = ctx.session.state.get("html", "")

                if html_content:
                    # 主要フィールドの一致確認
                    validations = [
                        ("学校名", json_obj.get('school_name'), html_content),
                        ("学年", json_obj.get('grade'), html_content),
                        ("発行者", json_obj.get('author', {}).get('name'), html_content),
                        ("色scheme", json_obj.get('color_scheme', {}).get('primary'), html_content)
                    ]

                    inconsistencies = []
                    for field, json_value, html_text in validations:
                        if json_value and str(json_value) not in html_text:
                            inconsistencies.append(f"{field}: JSON={json_value}")

                    if inconsistencies:
                        logger.warning(f"HTML-JSON不整合検出: {', '.join(inconsistencies)}")
                        return False
                    else:
                        logger.info("HTML-JSON整合性検証: 正常")
                        return True
                else:
                    logger.warning("HTML検証スキップ: HTMLコンテンツがありません")
                    return False
        except Exception as e:
            logger.error(f"HTML-JSON検証エラー: {e}")
            return False

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
    body {{
      font-family: 'Hiragino Sans', 'Yu Gothic', sans-serif;
      margin: 0;
      padding: 20px;
      background-color: #ffffff;
      color: #333333;
      line-height: 1.6;
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

            # 🚨 本番環境対応: ファイルシステム保存を無効化
            # Cloud Runでは/tmpが一時的なため、セッション状態のみに依存
            logger.info("テンプレートHTMLをセッション状態に保存（本番環境ではファイル保存無効）")

        except Exception as e:
            logger.error(f"テンプレートHTML生成エラー: {e}")

    async def _retrieve_json_from_main_agent(self, ctx: InvocationContext) -> str:
        """MainConversationAgentのセッション状態から直接JSONを取得"""
        try:
            # セッションイベントからMainConversationAgentの最新の保存されたJSONを探す
            if hasattr(ctx, "session") and hasattr(ctx.session, "events"):
                session_events = ctx.session.events

                # 最新のイベントから情報を抽出
                for event in reversed(session_events):
                    if hasattr(event, "author") and "main_conversation_agent" in str(event.author):
                        event_text = self._extract_text_from_event(event)

                        # 内部的に保存されたJSONがあるかチェック
                        if hasattr(event, "metadata") and event.metadata:
                            if "internal_json" in event.metadata:
                                logger.info("MainConversationAgentの内部JSONを発見")
                                return event.metadata["internal_json"]

                # セッション状態の他のキーもチェック
                state_keys = ['json_data', 'outline_data', 'conversation_json']
                for key in state_keys:
                    if key in ctx.session.state and ctx.session.state[key]:
                        logger.info(f"セッション状態の{key}から取得")
                        return ctx.session.state[key]

            logger.warning("MainConversationAgentからのJSON取得に失敗")
            return None

        except Exception as e:
            logger.error(f"MainConversationAgentからのJSON取得エラー: {e}")
            return None

    async def _load_json_from_filesystem(self, ctx: InvocationContext) -> str:
        """ファイルシステムからJSONを読み込み（レガシー・本番環境では無効）"""
        # 🚨 本番環境（Cloud Run）ではファイルシステム使用不可
        # セッション状態のみに依存する設計に変更
        logger.warning("ファイルシステムフォールバックは本番環境で利用不可 - セッション状態のみ使用")
        return None

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

    async def _save_html_from_response(self, ctx: InvocationContext):
        """LLM応答からHTMLを抽出してセッション状態に保存"""
        try:
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "events"):
                logger.warning("セッション履歴にアクセスできません")
                return

            session_events = ctx.session.events
            if not session_events:
                logger.warning("セッションイベントが空です")
                return

            # レイアウトエージェントが作成した最後のイベントを探す
            layout_event = None
            for event in reversed(session_events):
                if hasattr(event, "author") and event.author == self.name:
                    layout_event = event
                    break

            if layout_event is None:
                logger.warning(f"{self.name}による最後のイベントが見つかりません")
                return

            # イベントの内容からテキストを抽出
            llm_response_text = self._extract_text_from_event(layout_event)

            if not llm_response_text.strip():
                logger.warning("コンテンツからテキストを抽出できません")
                return

            # HTMLの抽出
            html_content = self._extract_html_from_response(llm_response_text)

            # セッション状態に保存（ADK標準）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                ctx.session.state["html"] = html_content
                logger.info("HTMLをセッション状態に保存しました")

            # 🚨 本番環境対応: ファイルシステム保存を無効化
            # Cloud Runでは/tmpが一時的なため、セッション状態のみに依存
            logger.info("HTMLをセッション状態に保存（本番環境ではファイル保存無効）")

        except Exception as e:
            logger.error(f"HTML保存エラー: {e}")

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

    def _generate_sample_json(self) -> str:
        """AgentTool用のサンプルJSONを生成します。"""
        from datetime import datetime
        current_date = datetime.now().strftime("%Y-%m-%d")
        sample_json = {
            "schema_version": "2.4",
            "school_name": "○○小学校",
            "grade": "1年1組",
            "issue": "12月号",
            "issue_date": current_date,
            "author": {"name": "担任", "title": "担任"},
            "main_title": "1年1組だより12月号",
            "sub_title": None,
            "season": "冬",
            "theme": "学級の様子",
            "color_scheme": {
                "primary": "#4A90E2",
                "secondary": "#7ED321",
                "accent": "#F5A623",
                "background": "#ffffff",
            },
            "color_scheme_source": "冬の季節に合わせた爽やかな色合い",
            "sections": [
                {
                    "type": "main_content",
                    "title": "最近の学級の様子",
                    "content": "みなさん、いつも元気に過ごしていますね。最近の学習や生活の様子をお伝えします。",
                    "estimated_length": "medium",
                    "section_visual_hint": "children_activities",
                }
            ],
            "photo_placeholders": {
                "count": 1,
                "suggested_positions": [
                    {
                        "section_type": "main_content",
                        "position": "top-right",
                        "caption_suggestion": "学習の様子",
                    }
                ],
            },
            "enhancement_suggestions": [
                "季節の行事について追加",
                "お知らせやお願い事項の追加",
            ],
            "has_editor_note": False,
            "editor_note": None,
            "layout_suggestion": {
                "page_count": 1,
                "columns": 2,
                "column_ratio": "1:1",
                "blocks": ["header", "main_content", "photos", "footer"],
            },
            "force_single_page": True,
            "max_pages": 1,
        }
        return json.dumps(sample_json, ensure_ascii=False, indent=2)

    async def _log_session_state_details(self, ctx: InvocationContext):
        """セッション状態の詳細ログ出力"""
        try:
            logger.info("LayoutAgent InvocationContext詳細:")
            logger.info(f"  - hasattr(ctx, 'session'): {hasattr(ctx, 'session')}")
            if hasattr(ctx, "session"):
                logger.info(f"  - session type: {type(ctx.session)}")
                logger.info(f"  - hasattr(session, 'state'): {hasattr(ctx.session, 'state')}")
                logger.info(f"  - hasattr(session, 'session_id'): {hasattr(ctx.session, 'session_id')}")
                if hasattr(ctx.session, "session_id"):
                    logger.info(f"  - session_id: {ctx.session.session_id}")
                if hasattr(ctx.session, "state"):
                    logger.info(f"  - state type: {type(ctx.session.state)}")
                    logger.info(f"  - state keys: {list(ctx.session.state.keys()) if ctx.session.state else 'None'}")

                    # 各キーの値も確認
                    if ctx.session.state:
                        for key, value in ctx.session.state.items():
                            value_preview = str(value)[:100] + "..." if len(str(value)) > 100 else str(value)
                            logger.info(f"  - {key}: {value_preview}")
        except Exception as e:
            logger.error(f"セッション状態詳細ログエラー: {e}")

    async def _get_json_from_adk_output_key(self, ctx: InvocationContext) -> str:
        """ADK output_keyから確実にJSONを取得（強化版・冗長化対応）"""
        try:
            if not hasattr(ctx, "session") or not hasattr(ctx.session, "state"):
                logger.warning("セッション状態が利用できません")
                return None

            # セッション状態の詳細ログ出力
            logger.info("=== セッション状態詳細確認（強化版） ===")
            session_keys = list(ctx.session.state.keys()) if ctx.session.state else []
            logger.info(f"セッション状態のキー一覧: {session_keys}")

            # 複数のキーから順次取得を試行（優先順位順・拡張）
            json_keys_priority = ["outline", "newsletter_json", "user_data_json", "json_data"]

            for key in json_keys_priority:
                json_data = ctx.session.state.get(key)
                if json_data:
                    logger.info(f"✅ {key} キーから取得成功: {len(str(json_data))} 文字")
                    logger.info(f"取得データ(先頭200文字): {str(json_data)[:200]}...")

                    # JSON形式として有効かチェック
                    try:
                        import json as json_module
                        parsed = json_module.loads(str(json_data))
                        school_name = parsed.get('school_name', 'UNKNOWN')
                        grade = parsed.get('grade', 'UNKNOWN')
                        author_name = parsed.get('author', {}).get('name', 'UNKNOWN')

                        # サンプルデータ判定を強化
                        if (school_name in ['○○小学校', 'ERROR', 'UNKNOWN', '学校名'] or
                            grade in ['1年1組', 'ERROR', 'UNKNOWN', '学年'] or
                            author_name in ['担任', 'ERROR', 'UNKNOWN']):
                            logger.warning(f"⚠️ {key} キーにサンプルデータを検出: {school_name}/{grade}/{author_name}")
                            continue  # サンプルデータの場合は次のキーを試す

                        logger.info(f"✅ JSONデータ確認成功: {school_name} {grade} {author_name}")
                        return str(json_data)

                    except Exception as parse_error:
                        logger.warning(f"❌ {key} キーのJSONが不正: {parse_error}")
                        continue  # 次のキーを試す
                else:
                    logger.info(f"❌ {key} キーは存在しないか空です")

            # 標準キーで失敗した場合、追加キーも確認
            additional_keys = [k for k in session_keys if 'json' in k.lower() or 'outline' in k.lower()]
            logger.info(f"追加JSON候補キー: {additional_keys}")

            for key in additional_keys:
                if key not in json_keys_priority:  # 既に確認済みのキーはスキップ
                    json_data = ctx.session.state.get(key)
                    if json_data and len(str(json_data)) > 50:  # 十分な長さがある場合のみ
                        try:
                            import json as json_module
                            parsed = json_module.loads(str(json_data))
                            if 'school_name' in parsed and 'grade' in parsed:
                                logger.info(f"✅ 追加キー {key} からJSONを発見")
                                return str(json_data)
                        except:
                            continue

            # 全てのキーで取得に失敗
            logger.error("❌ 全てのJSONキーから取得に失敗しました")

            # デバッグ情報：セッション状態の全体を出力
            logger.info("=== セッション状態デバッグ情報 ===")
            for key, value in ctx.session.state.items():
                value_type = type(value).__name__
                value_length = len(str(value)) if value else 0
                value_preview = str(value)[:100] + "..." if len(str(value)) > 100 else str(value)
                logger.info(f"  {key} ({value_type}, {value_length}文字): {value_preview}")

            return None

        except Exception as e:
            logger.error(f"ADK output_key取得エラー: {e}")
            import traceback
            logger.error(f"取得エラー詳細: {traceback.format_exc()}")
            return None

    async def _validate_json_data(self, json_data: str) -> bool:
        """JSONデータの有効性検証"""
        try:
            if not json_data or not json_data.strip():
                logger.warning("JSONデータが空です")
                return False

            # JSON形式として解析可能かチェック
            parsed = json.loads(json_data)

            # 必須フィールドの存在確認
            required_fields = ['school_name', 'grade', 'author']
            for field in required_fields:
                if field not in parsed:
                    logger.warning(f"必須フィールド '{field}' が見つかりません")
                    return False

            # サンプルデータでないことを確認
            school_name = parsed.get('school_name', '')
            if 'サンプル' in school_name or '○○' in school_name or 'ERROR' in school_name:
                logger.warning(f"サンプルデータを検出: school_name={school_name}")
                return False

            logger.info(f"JSON検証成功: school_name={parsed.get('school_name')}")
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
