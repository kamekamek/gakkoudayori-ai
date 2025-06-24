from typing import AsyncGenerator

from google.adk.agents import Agent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event

from backend.agents.generator_agent.agent import create_generator_agent
from backend.agents.planner_agent.agent import create_planner_agent


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
        # サブエージェントは _run_async_impl 内で必要に応じて作成します

    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """
        オーケストレーターのメイン処理。
        ユーザーのメッセージに基づいて、適切なサブエージェントにタスクを委任します。
        """
        user_message = ctx.new_message.parts[0].text.lower()

        # ユーザーの意図に基づいてエージェントを選択
        if any(keyword in user_message for keyword in ["計画", "構成", "プラン", "企画"]):
            # 企画・計画段階 → PlannerAgent
            planner_agent = create_planner_agent()
            async for event in planner_agent._run_async_impl(ctx):
                yield event
        elif any(keyword in user_message for keyword in ["生成", "作成", "制作", "書いて"]):
            # 生成段階 → GeneratorAgent
            generator_agent = create_generator_agent()
            async for event in generator_agent._run_async_impl(ctx):
                yield event
        else:
            # デフォルトは計画段階から開始
            planner_agent = create_planner_agent()
            async for event in planner_agent._run_async_impl(ctx):
                yield event

def create_orchestrator_agent() -> NewsletterOrchestrator:
    """
    NewsletterOrchestratorのインスタンスを作成して返します。
    """
    return NewsletterOrchestrator()
