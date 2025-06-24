from google.adk.agents import SequentialAgent
from generator_agent.agent import create_generator_agent
from planner_agent.agent import create_planner_agent


def create_orchestrator_agent() -> SequentialAgent:
    """
    学級通信作成のワークフロー（計画→生成）を実行するシーケンシャルエージェントを作成します。
    1. PlannerAgent: ユーザーと対話し、構成案（outline.json）を作成します。
    2. GeneratorAgent: outline.jsonを読み込み、HTMLを生成します。
    """
    return SequentialAgent(
        name="orchestrator_agent",
        sub_agents=[
            create_planner_agent(),
            create_generator_agent(),
        ],
        description="Handles the newsletter creation workflow from planning to generation.",
    )

# ADK Web UI用のroot_agent変数
root_agent = create_orchestrator_agent()
