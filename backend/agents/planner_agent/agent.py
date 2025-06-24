import json
import os
from datetime import datetime
from pathlib import Path
from typing import AsyncGenerator

from google.adk.agents import LlmAgent
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


class PlannerAgent(LlmAgent):
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

        # ADK v1.0.0では履歴アクセス方法が変更されたため、
        # セッションイベントから最後のLLM応答を取得
        if not hasattr(ctx, 'session') or not hasattr(ctx.session, 'events'):
            return
            
        session_events = ctx.session.events
        if not session_events:
            return
            
        # 最後のイベントからLLM応答を取得
        last_event = session_events[-1]
        if not hasattr(last_event, 'author') or last_event.author != self.name:
            return
            
        if not hasattr(last_event, 'content') or not last_event.content:
            return
            
        # イベントの内容からテキストを抽出
        if isinstance(last_event.content, list) and len(last_event.content) > 0:
            if isinstance(last_event.content[0], dict) and 'text' in last_event.content[0]:
                llm_response_text = last_event.content[0]['text']
            else:
                return
        else:
            return

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

            json_str = json_str[json_start:json_end]

            # JSONとして有効か検証
            json.loads(json_str)

            # ファイルシステムベースのアーティファクト管理
            artifacts_dir = Path("/tmp/adk_artifacts")
            artifacts_dir.mkdir(exist_ok=True)
            outline_file = artifacts_dir / "outline.json"
            
            with open(outline_file, "w", encoding="utf-8") as f:
                f.write(json_str)
                
            yield Event(content={"type": "info", "message": f"構成案を保存しました: {outline_file}"})

        except (ValueError, json.JSONDecodeError) as e:
            error_msg = f"LLMの応答からJSONを抽出できませんでした: {e}\n応答: {llm_response_text}"
            yield Event(content={"type": "error", "message": error_msg})


def create_planner_agent() -> LlmAgent:
    """PlannerAgentのインスタンスを生成するファクトリ関数。"""
    return PlannerAgent()

# ADK Web UI用のroot_agent変数
root_agent = create_planner_agent()
