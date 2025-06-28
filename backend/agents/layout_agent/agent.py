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
            
            # セッション状態からJSONデータを取得（優先）
            json_data = None
            if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                json_data = ctx.session.state.get("outline")
                logger.info(f"セッション状態から取得: {bool(json_data)}")
                if hasattr(ctx.session, "state"):
                    logger.info(f"セッション状態のキー: {list(ctx.session.state.keys())}")

            # セッション状態に無い場合は、ファイルシステムから強制読み込み
            if not json_data:
                logger.warning("セッション状態にoutlineが見つかりません。ファイルシステムから読み込み...")
                artifacts_dir = Path("/tmp/adk_artifacts")
                outline_file = artifacts_dir / "outline.json"

                if outline_file.exists():
                    with open(outline_file, "r", encoding="utf-8") as f:
                        json_data = f.read()
                    logger.info(f"ファイルシステムから読み込み成功: {len(json_data)} 文字")
                    
                    # ファイルデータをセッション状態に即座に同期
                    if hasattr(ctx, "session") and hasattr(ctx.session, "state"):
                        ctx.session.state["outline"] = json_data
                        logger.info("ファイルデータをセッション状態に同期しました")
                else:
                    logger.error("outline.jsonファイルが存在しません")

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

            # 強化されたプロンプトを作成（JSON反映を強調）
            enhanced_prompt = f"""
以下のJSONデータから学級通信のHTMLを生成してください。

🚨 重要指示: JSONデータの内容を100%正確に反映してください 🚨

JSONデータ:
```json
{json_data}
```

必須反映事項:
1. 学校名: {json_obj.get('school_name') if json_obj else 'JSONから取得'}
2. 学年: {json_obj.get('grade') if json_obj else 'JSONから取得'}  
3. 発行者: {json_obj.get('author', {}).get('name') if json_obj else 'JSONから取得'}
4. 発行日: {json_obj.get('issue_date') if json_obj else 'JSONから取得'}
5. タイトル: {json_obj.get('main_title') if json_obj else 'JSONから取得'}
6. 主要色: {json_obj.get('color_scheme', {}).get('primary') if json_obj else 'JSONから取得'}

絶対に守ること:
- JSONのデータを変更・推測・追加しないこと
- 上記の値を正確にHTMLに反映すること
- 独自のデザインや色を使用しないこと

HTMLのみを出力し、説明文は不要です。
            """

            # 一時的にプロンプトを更新してLLMを実行
            original_instruction = self.instruction
            self.instruction = enhanced_prompt

            # LLM実行（イベントを保存してHTMLを抽出）
            llm_events = []
            async for event in super()._run_async_impl(ctx):
                # LLMの生成イベントは内部処理として隠蔽し、後でHTML抽出用に保存
                llm_events.append(event)
            
            # 生成されたイベントからHTMLを抽出して保存
            await self._save_html_from_llm_events(ctx, llm_events)
            
            # HTMLとJSONの一致検証
            await self._validate_html_json_consistency(ctx, json_obj)

            # プロンプトを元に戻す
            self.instruction = original_instruction

            # HTMLは既に上記で保存済み
            
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
                    else:
                        logger.info("HTML-JSON整合性検証: 正常")
                else:
                    logger.warning("HTML検証スキップ: HTMLコンテンツがありません")
        except Exception as e:
            logger.error(f"HTML-JSON検証エラー: {e}")

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
