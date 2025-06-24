from typing import AsyncGenerator
from google.adk.agents import Agent, SequentialAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from backend.agents.planner_agent.agent import create_planner_agent
from backend.agents.generator_agent.agent import create_generator_agent

class NewsletterOrchestrator(Agent):
    """
    学級通信の作成プロセス全体を管理するオーケストレーターエージェント。
    ユーザーの指示に基づいて、PlannerAgentとGeneratorAgentを制御します。
    """
    def __init__(self):
        super().__init__(
            name="orchestrator_agent",
            description="学級通信の作成プロセス全体を管理し、サブエージェントにタスクを委任します。",
        )
        self.planner_agent = create_planner_agent()
        self.generator_agent = create_generator_agent()

    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """
        エージェントの実行ロジック。
        ユーザーのメッセージに応じて、PlannerまたはGeneratorに処理を移譲します。
        """
        # 親の _run_async_impl は呼び出さず、独自のディスパッチロジックを実装
        # ユーザーの最新のメッセージを取得
        user_message = ctx.get_history()[-1].content.parts[0].text.lower()

        # 今後、より複雑なルーティングロジックをここに追加できる
        if ctx.artifact_exists("outline.json"):
            await ctx.emit({"type": "info", "message": "構成案が見つかったため、HTML生成エージェントを呼び出します。"})
            # ToDo: GeneratorAgentに処理を委譲するロジックを実装
            # await ctx.transfer_to_agent(self.generator_agent.name, ctx)
            pass
        else:
            # 構成案がなければPlannerAgentに委譲
            await ctx.emit({"type": "info", "message": "構成案を作成するため、対話型プランナーを呼び出します。"})
            # ToDo: PlannerAgentに処理を委譲するロジックを実装
            # await ctx.transfer_to_agent(self.planner_agent.name, ctx)
            async for event in self.planner_agent.run_async(ctx=ctx):
                yield event


def create_orchestrator_agent() -> Agent:
    """OrchestratorAgentのインスタンスを生成するファクトリ関数。"""
    return NewsletterOrchestrator()
