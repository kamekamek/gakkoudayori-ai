import os
import json
from pathlib import Path
from datetime import datetime
from typing import AsyncGenerator

from google.adk.agents import Agent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.adk.tools import FunctionTool


def get_current_date() -> str:
    """現在の日付を'YYYY-MM-DD'形式で返します。"""
    return datetime.now().strftime("%Y-%m-%d")

def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "planner_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        # フォールバック用の基本的なプロンプト
        return "あなたはユーザーの要求をJSON形式で要約するアシスタントです。"


class PlannerAgent(Agent):
    """
    ユーザーと対話して学級通信の構成を計画し、JSON形式で出力するエージェント。
    """
    def __init__(self):
        super().__init__(
            name="planner_agent",
            model=Gemini(model_name="gemini-1.5-pro-latest"),
            instruction=_load_instruction(),
            description="ユーザーと対話して学級通信の構成を計画し、JSON形式で出力します。",
            tools=[FunctionTool(get_current_date)],
        )

    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジックをオーバーライドし、
        LLMの最終応答を `outline.json` として保存します。
        """
        # 親クラスの`_run_async_impl`を呼び出して、通常のLLM対話を実行
        async for event in super()._run_async_impl(ctx):
            # イベントをそのままクライアントにストリーミング
            yield event

        # 対話履歴から最後のLLMの応答を取得
        last_message = ctx.get_history()[-1]
        if last_message.author != self.model.name:
            # 最後のメッセージがLLMのものでなければ何もしない
            return
            
        llm_response_text = last_message.content.parts[0].text

        # LLMの応答からJSON部分を抽出
        try:
            json_str = llm_response_text
            # 応答にMarkdownのコードブロックが含まれている場合、それを取り除く
            if '```json' in json_str:
                json_str = json_str.split('```json', 1)[1].rsplit('```', 1)[0]
            elif '```' in json_str:
                # 'json'指定子がない場合も考慮
                json_str = json_str.split('```', 1)[1].rsplit('```', 1)[0]
            
            # 応答に含まれる最初の'{'から最後の'}'までをJSONとみなす
            json_start = json_str.find('{')
            json_end = json_str.rfind('}') + 1
            if json_start == -1 or json_end == 0:
                raise ValueError("JSONの開始または終了が見つかりません。")

            # JSONとして有効か検証
            json.loads(json_str)

            # アーティファクトとして保存
            ctx.save_artifact("outline.json", json_str.encode("utf-8"))
            await ctx.emit({"type": "info", "message": "構成案(outline.json)を作成しました。"})

        except (ValueError, json.JSONDecodeError) as e:
            error_msg = f"LLMの応答からJSONを抽出できませんでした: {e}\n応答: {llm_response_text}"
            await ctx.emit({"type": "error", "message": error_msg})


def create_planner_agent() -> Agent:
    """PlannerAgentのインスタンスを生成するファクトリ関数。"""
    return PlannerAgent()
