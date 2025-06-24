from google.adk.agents import SequentialAgent
from generator_agent.agent import create_generator_agent
from planner_agent.agent import create_planner_agent


class NewsletterOrchestrator(SequentialAgent):
    """
    学級通信作成のワークフロー（計画→生成）を実行するエージェント。
    SequentialAgentを継承し、定義された順序でエージェントを実行します。
    """

    def __init__(self):
        """
        エージェントのシーケンスを定義します。
        1. PlannerAgent: ユーザーと対話し、構成案（outline.json）を作成します。
        2. GeneratorAgent: outline.jsonを読み込み、HTMLを生成します。
        """
        super().__init__(
            name="orchestrator_agent",
            agents=[
                create_planner_agent(),
                create_generator_agent(),
            ],
            description="Handles the newsletter creation workflow from planning to generation.",
        )


def create_orchestrator_agent() -> SequentialAgent:
    """
    NewsletterOrchestratorのインスタンスを作成して返します。
    """
    return NewsletterOrchestrator()


# ADK Web UI用のroot_agent変数
root_agent = create_orchestrator_agent()
