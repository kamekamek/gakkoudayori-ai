import json
import os
from pathlib import Path
from typing import AsyncGenerator
import logging

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini

# ロガーの設定
logger = logging.getLogger(__name__)


def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "layout_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        # フォールバック用の基本的なプロンプト
        return "あなたはJSONデータを受け取り、美しいHTMLレイアウトを生成するエージェントです。"


class LayoutAgent(LlmAgent):
    """
    JSONデータからHTMLレイアウトを生成するエージェント。
    layout.mdの内容をベースにした美しいHTMLを生成します。
    """
    def __init__(self):
        super().__init__(
            name="layout_agent",
            model=Gemini(model_name="gemini-2.5-pro"),
            instruction=_load_instruction(),
            description="JSONデータから美しいHTMLレイアウトを生成します。",
            tools=[],
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジックをオーバーライドし、
        JSONファイルを読み込んでHTMLを生成します。
        """
        try:
            # JSONファイルの読み込み
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"
            
            if not outline_file.exists():
                error_msg = "outline.jsonが見つかりません。先に対話エージェントを実行してください。"
                logger.error(error_msg)
                yield Event(
                    author=self.name,
                    content=error_msg
                )
                return
            
            # JSONデータを読み込み
            with open(outline_file, "r", encoding="utf-8") as f:
                json_data = f.read()
                
            logger.info(f"JSON データを読み込みました: {len(json_data)} 文字")
            
            # JSONデータを含むプロンプトを作成
            enhanced_prompt = f"""
            以下のJSONデータを使用して、美しい学級通信のHTMLを生成してください。

            JSONデータ:
            ```json
            {json_data}
            ```

            上記のJSONデータのすべてのフィールドを適切に反映し、レスポンシブで印刷にも対応した美しいHTMLを生成してください。
            HTMLのみを出力し、説明文は不要です。
            """
            
            # 一時的にプロンプトを更新してLLMを実行
            original_instruction = self.instruction
            self.instruction = enhanced_prompt
            
            # LLM実行
            async for event in super()._run_async_impl(ctx):
                yield event
            
            # プロンプトを元に戻す
            self.instruction = original_instruction
            
            # 生成されたHTMLを保存
            await self._save_html_from_response(ctx)
            
        except Exception as e:
            error_msg = f"レイアウト生成中にエラーが発生しました: {str(e)}"
            logger.error(error_msg)
            yield Event(
                author=self.name,
                content=error_msg
            )

    async def _save_html_from_response(self, ctx: InvocationContext):
        """LLM応答からHTMLを抽出して保存"""
        try:
            # セッションイベントから最後のエージェント応答を取得
            if not hasattr(ctx, 'session') or not hasattr(ctx.session, 'events'):
                logger.warning("セッション履歴にアクセスできません")
                return
                
            session_events = ctx.session.events
            if not session_events:
                logger.warning("セッションイベントが空です")
                return
            
            # レイアウトエージェントが作成した最後のイベントを探す
            layout_event = None
            for event in reversed(session_events):
                if hasattr(event, 'author') and event.author == self.name:
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
            
            # HTMLファイルとして保存
            artifacts_dir = Path("/tmp/adk_artifacts")
            newsletter_file = artifacts_dir / "newsletter.html"
            
            with open(newsletter_file, "w", encoding="utf-8") as f:
                f.write(html_content)
                
            logger.info(f"HTMLを保存しました: {newsletter_file}")

        except Exception as e:
            logger.error(f"HTML保存エラー: {e}")

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

    def _extract_html_from_response(self, response_text: str) -> str:
        """LLM応答からHTMLを抽出"""
        logger.info(f"LLM応答テキスト長: {len(response_text)}")
        
        # HTMLコードブロックが含まれている場合は抽出
        if '```html' in response_text:
            logger.info("HTMLコードブロック(```html)を検出、抽出中...")
            html_start = response_text.find('```html') + 7
            html_end = response_text.find('```', html_start)
            if html_end != -1:
                return response_text[html_start:html_end].strip()
        
        # <!DOCTYPE html>から始まるHTMLを検出
        if '<!DOCTYPE html>' in response_text:
            logger.info("DOCTYPE宣言を検出、HTML抽出中...")
            html_start = response_text.find('<!DOCTYPE html>')
            # </html>の終了を検出
            html_end = response_text.rfind('</html>') + 7
            if html_end > html_start:
                return response_text[html_start:html_end]
        
        # <html>タグから始まるHTMLを検出
        if '<html' in response_text:
            logger.info("<html>タグを検出、HTML抽出中...")
            html_start = response_text.find('<html')
            html_end = response_text.rfind('</html>') + 7
            if html_end > html_start:
                return response_text[html_start:html_end]
        
        # HTMLが検出されない場合は全体を返す
        logger.warning("明確なHTMLブロックが検出されませんでした。応答全体を使用します。")
        return response_text


def create_layout_agent() -> LayoutAgent:
    """LayoutAgentのインスタンスを生成するファクトリ関数。"""
    return LayoutAgent()

# ADK Web UI用のroot_agent変数
root_agent = create_layout_agent()