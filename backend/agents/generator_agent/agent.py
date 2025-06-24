import os
from pathlib import Path
from typing import AsyncGenerator

from google.adk.agents import Agent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool

from ..tools.html_validator import validate_html


def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "generator_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "You are a helpful assistant that generates HTML from JSON."

class GeneratorAgent(Agent):
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
        if not await ctx.artifact_exists("outline.json"):
            error_msg = "HTML生成に必要な構成案（outline.json）が見つかりません。"
            await ctx.emit({"type": "error", "message": error_msg})
            return

        artifact_data = await ctx.load_artifact("outline.json")
        json_content = artifact_data.decode("utf-8")

        # LLMを直接呼び出してHTMLを生成
        llm_response = await self.model.generate(
            prompt=self.instruction, user_input=json_content
        )
        html = llm_response.text.strip()
        # LLMがMarkdownのコードブロックを付与してしまう場合があるため、除去する
        if html.startswith("```html"):
            html = html[7:]
        if html.endswith("```"):
            html = html[:-3]

        await ctx.emit({"type": "html", "html": html})

        # 生成されたHTMLを検証
        validation_result = await self.call_tool("validate_html", html=html)
        await ctx.emit({"type": "audit", "data": validation_result})

        # 生成したHTMLをアーティファクトとして保存
        await ctx.save_artifact("newsletter.html", html.encode("utf-8"))

        # 最終的な結果を含むイベントを生成
        # ADK v1.0.0対応: llm_response.textを使用
        yield Event(author=self.name, content=[{"text": html}])

def create_generator_agent() -> Agent:
    """GeneratorAgentのインスタンスを生成するファクトリ関数。"""
    return GeneratorAgent()
