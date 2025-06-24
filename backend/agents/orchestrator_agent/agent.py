from google.adk.agents import SequentialAgent
from google.adk.agents.invocation_context import InvocationContext

# サブエージェントのファクトリ関数を絶対パスでインポートします。
from backend.agents.planner_agent.agent import create_planner_agent
from backend.agents.generator_agent.agent import create_generator_agent


class NewsletterOrchestrator(SequentialAgent):
    """
    学級通信の作成プロセス全体を管理するオーケストレーターエージェント。
    ユーザーの指示に基づいて、PlannerAgentとGeneratorAgentを制御します。
    """
    def __init__(self):
        super().__init__(
            name="orchestrator_agent",
            description="学級通信の作成プロセス全体を管理し、サブエージェントにタスクを委任します。",
            sub_agents=[
                create_planner_agent(),
                create_generator_agent(),
            ]
        )

    async def _run_async_impl(self, ctx: InvocationContext):
        """
        エージェントの実行ロジック。
        ユーザー入力やアーティファクトの状態に基づき、サブエージェントに処理を移譲します。
        """
        user_message = ctx.get_user_message().strip()

        # 1. /create コマンドで開始 → planner_agent へ
        if user_message.startswith("/create"):
            await ctx.transfer_to_agent("planner_agent")
            return

        # 2. planner完了後 (outline.json が存在する) → generator_agent へ
        if ctx.artifact_exists("outline.json") and not ctx.artifact_exists("newsletter.html"):
            await ctx.transfer_to_agent("generator_agent")
            return

        # 3. /send コマンドの処理 (ツールは未定義のためプレースホルダー)
        if user_message.startswith("/send"):
            if ctx.artifact_exists("newsletter.html"):
                html_content = ctx.load_artifact("newsletter.html").decode("utf-8")
                # `classroom_sender`ツールは未実装のため、ダミーの応答を返します。
                # course_id = user_message.split()[1]
                # await self.call_tool("classroom_sender", course_id=course_id, html=html_content)
                await ctx.emit({"type": "classroom_ack", "status": "Sent (mocked)"})
            else:
                await ctx.emit({"type": "error", "message": "送信する学級通信(newsletter.html)が見つかりません。"})
            return

        # デフォルトの動作: 意図しないループを防ぐため、何もしない。
        # または、必要に応じてヘルプメッセージを返す。
        # await ctx.emit({"type": "info", "message": "`/create`で作成を開始、または`/send`で配信します。"})


def create_orchestrator_agent() -> SequentialAgent:
    """
    NewsletterOrchestratorのインスタンスを生成するファクトリ関数。
    """
    return NewsletterOrchestrator()
