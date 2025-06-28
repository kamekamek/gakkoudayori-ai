import json
import logging
import os
from pathlib import Path
from typing import AsyncGenerator

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.genai.types import Content, Part

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
        logger.info(f"LayoutAgent初期化: モデル=gemini-2.5-pro")
        
        super().__init__(
            name="layout_agent",
            model=model,
            instruction=INSTRUCTION,
            description="JSONデータから美しいHTMLレイアウトを生成します。",
            tools=[],
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
            # ユーザーフレンドリーな開始メッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="学級通信のレイアウトを作成しています。少々お待ちください...")])
            )
            
            # セッション状態からJSONデータを取得（第一優先）
            json_data = None
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                json_data = ctx.session.state.get("outline")
                logger.info(f"セッション状態から取得: {bool(json_data)}")
                
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
                logger.info("セッション状態からの直接取得を試行中...")
                json_data = await self._retrieve_json_from_main_agent(ctx)

            # 最終フォールバック: ファイルシステムから読み込み（警告付き）
            if not json_data:
                logger.warning("セッション状態にoutlineが見つかりません。ファイルシステムから読み込み中...")
                json_data = await self._load_json_from_filesystem(ctx)

            if not json_data:
                error_msg = "申し訳ございません。学級通信の作成に必要な情報が見つかりませんでした。もう一度最初からお試しください。"
                logger.error("HTML生成用のデータを準備できませんでした")
                yield Event(
                    author=self.name, content=Content(parts=[Part(text=error_msg)])
                )
                return

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

            # HTMLは既に上記で保存済み
            
            # HTML完了の専用イベントを生成（フロントエンド用）
            if hasattr(ctx, "session") and hasattr(ctx.session, "state") and ctx.session.state.get("html"):
                html_content = ctx.session.state["html"]
                
                # 専用イベントタイプでHTML完了を通知
                yield Event(
                    author=self.name,
                    content=Content(parts=[Part(text=f"<html_ready>{html_content}</html_ready>")]),
                    metadata={"event_type": "html_complete", "html_length": len(html_content)}
                )
                logger.info(f"HTML完了イベントを送信: {len(html_content)}文字")
            
            # ユーザーフレンドリーな完了メッセージ
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text="学級通信が完成しました！プレビューをご確認ください。")])
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

            # ファイルシステムにもバックアップ保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            newsletter_file = artifacts_dir / "newsletter.html"

            with open(newsletter_file, "w", encoding="utf-8") as f:
                f.write(html_content)

            logger.info(f"HTMLをファイルにも保存しました: {newsletter_file}")

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

            # ファイルにも保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            newsletter_file = artifacts_dir / "newsletter.html"
            
            with open(newsletter_file, "w", encoding="utf-8") as f:
                f.write(template_html)
            
            logger.info(f"テンプレートHTMLをファイルに保存しました: {newsletter_file}")
            
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
        """ファイルシステムからJSONを読み込み（最終フォールバック）"""
        try:
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"

            if outline_file.exists():
                with open(outline_file, "r", encoding="utf-8") as f:
                    json_data = f.read()
                logger.info(f"ファイルシステムから読み込み成功: {len(json_data)} 文字")
                
                # 読み込んだデータをセッション状態に保存して次回の高速化
                if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                    ctx.session.state["outline"] = json_data
                    logger.info("ファイルデータをセッション状態に同期しました")
                
                return json_data
            else:
                logger.error("outline.jsonファイルが存在しません")
                return None
                
        except Exception as e:
            logger.error(f"ファイルシステムからのJSON読み込みエラー: {e}")
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

            # ファイルシステムにもバックアップ保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            newsletter_file = artifacts_dir / "newsletter.html"

            with open(newsletter_file, "w", encoding="utf-8") as f:
                f.write(html_content)

            logger.info(f"HTMLをファイルにも保存しました: {newsletter_file}")

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


def create_layout_agent() -> LayoutAgent:
    """LayoutAgentのインスタンスを生成するファクトリ関数。"""
    return LayoutAgent(output_key="html")


# ADK Web UI用のroot_agent変数
root_agent = create_layout_agent()
