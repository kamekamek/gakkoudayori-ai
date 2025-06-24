import os
import json
from pathlib import Path
from typing import AsyncGenerator

from google.adk.agents import LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool

from tools.html_validator import validate_html


def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "generator_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "You are a helpful assistant that generates HTML from JSON."

class GeneratorAgent(LlmAgent):
    """
    JSONデータを受け取り、HTML形式の学級通信を生成・検証するエージェント。
    """
    def __init__(self):
        super().__init__(
            name="generator_agent",
            model=Gemini(model_name="gemini-1.5-pro-latest"),
            instruction=_load_instruction(),
            description="JSONデータを受け取り、HTML形式の学級通信を生成します。",
            tools=[FunctionTool(func=validate_html)],
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジック。
        `outline.json`を読み込み、HTMLを生成、検証、保存します。
        """
        # ファイルシステムベースのアーティファクト管理
        artifacts_dir = Path("/tmp/adk_artifacts")
        artifacts_dir.mkdir(exist_ok=True)
        outline_file = artifacts_dir / "outline.json"
        
        if not outline_file.exists():
            error_msg = "HTML生成に必要な構成案（outline.json）が見つかりません。"
            yield Event(content={"type": "error", "message": error_msg})
            return

        # JSONファイルを読み込み
        with open(outline_file, "r", encoding="utf-8") as f:
            json_content = f.read()

        # ユーザーメッセージとしてJSONコンテンツを設定
        import google.genai.types as genai_types
        ctx.user_content = genai_types.to_content(f"以下のJSONデータからHTMLを生成してください:\\n\\n{json_content}")

        # LlmAgentの標準フローを使用してHTMLを生成
        async for event in super()._run_async_impl(ctx):
            # イベントをそのままクライアントにストリーミング
            yield event

        # セッション履歴から最後のLLM応答を取得
        if not hasattr(ctx, 'session') or not hasattr(ctx.session, 'events') or not ctx.session.events:
            return
            
        last_event = ctx.session.events[-1]
        if not hasattr(last_event, 'author') or last_event.author != self.name:
            return
            
        if not hasattr(last_event, 'content') or not last_event.content:
            return
            
        html = ""
        if isinstance(last_event.content, list) and len(last_event.content) > 0:
            if isinstance(last_event.content[0], dict) and 'text' in last_event.content[0]:
                html = last_event.content[0]['text'].strip()

        if not html:
            return

        # Markdownコードブロックを除去
        if html.startswith("```html"):
            html = html[7:]
        if html.endswith("```"):
            html = html[:-3]
        
        yield Event(content={"type": "html", "html": html})
        
        # 生成されたHTMLを検証
        validation_result = await self.call_tool("validate_html", html=html)
        yield Event(content={"type": "audit", "data": validation_result})
        
        # 生成したHTMLをファイルとして保存
        newsletter_file = artifacts_dir / "newsletter.html"
        with open(newsletter_file, "w", encoding="utf-8") as f:
            f.write(html)
        
        yield Event(content={"type": "info", "message": f"HTMLファイルを保存しました: {newsletter_file}"})

def create_generator_agent() -> LlmAgent:
    """GeneratorAgentのインスタンスを生成するファクトリ関数。"""
    return GeneratorAgent()

# ADK Web UI用のroot_agent変数
root_agent = create_generator_agent()
