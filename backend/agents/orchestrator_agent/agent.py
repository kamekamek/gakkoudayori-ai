import logging
from google.adk.agents import SequentialAgent, LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from agents.generator_agent.agent import create_generator_agent
from agents.planner_agent.agent import create_planner_agent
from agents.core.error_handler import error_handler, AgentErrorType, ErrorSeverity, handle_agent_errors


class EnhancedOrchestratorAgent(LlmAgent):
    """エラーハンドリング強化版オーケストレーターエージェント"""
    
    def __init__(self):
        super().__init__(
            name="orchestrator_agent",
            description="Handles the newsletter creation workflow with error recovery.",
        )
        self.logger = logging.getLogger(__name__)
        self.planner_agent = create_planner_agent()
        self.generator_agent = create_generator_agent()
        
    @handle_agent_errors(AgentErrorType.AGENT_TRANSFER_FAILED, ErrorSeverity.ERROR)
    async def _run_async_impl(self, ctx: InvocationContext):
        """
        学級通信作成のワークフローを実行
        エラーハンドリングとフォールバック戦略を含む
        """
        try:
            # セッション開始を通知
            await ctx.emit({
                "type": "workflow_start",
                "message": "学級通信作成を開始します...",
                "timestamp": self._get_timestamp()
            })
            
            # Phase 1: Planning
            await self._execute_planning_phase(ctx)
            
            # Phase 2: Generation
            await self._execute_generation_phase(ctx)
            
            # 完了通知
            await ctx.emit({
                "type": "workflow_complete",
                "message": "学級通信の作成が完了しました！",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Orchestrator workflow failed: {e}")
            # エラーハンドラが既に処理済みなので、ここでは追加処理のみ
            await ctx.emit({
                "type": "workflow_failed",
                "message": "学級通信の作成に失敗しました。エラーハンドリングシステムが復旧を試行中です。",
                "timestamp": self._get_timestamp()
            })
            raise
    
    @handle_agent_errors(AgentErrorType.AGENT_TRANSFER_FAILED, ErrorSeverity.WARNING)
    async def _execute_planning_phase(self, ctx: InvocationContext):
        """計画フェーズの実行"""
        try:
            await ctx.emit({
                "type": "phase_start",
                "phase": "planning",
                "message": "構成を計画しています...",
                "timestamp": self._get_timestamp()
            })
            
            # outline.json が既に存在する場合はスキップ
            if ctx.artifact_exists("outline.json"):
                await ctx.emit({
                    "type": "phase_skip",
                    "phase": "planning",
                    "message": "既存の構成を使用します",
                    "timestamp": self._get_timestamp()
                })
                return
            
            # プランナーエージェントに転送
            await ctx.transfer_to_agent("planner_agent")
            
            # プランニング完了の確認
            if not ctx.artifact_exists("outline.json"):
                raise Exception("Planning phase failed: outline.json not created")
            
            await ctx.emit({
                "type": "phase_complete",
                "phase": "planning",
                "message": "構成の計画が完了しました",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Planning phase failed: {e}")
            await error_handler.handle_error(
                ctx, e, AgentErrorType.AGENT_TRANSFER_FAILED, ErrorSeverity.WARNING
            )
            raise
    
    @handle_agent_errors(AgentErrorType.AGENT_TRANSFER_FAILED, ErrorSeverity.ERROR)
    async def _execute_generation_phase(self, ctx: InvocationContext):
        """生成フェーズの実行"""
        try:
            await ctx.emit({
                "type": "phase_start",
                "phase": "generation",
                "message": "学級通信を生成しています...",
                "timestamp": self._get_timestamp()
            })
            
            # outline.json の存在確認
            if not ctx.artifact_exists("outline.json"):
                raise Exception("Generation phase failed: outline.json not found")
            
            # 既にHTMLが存在する場合の処理
            if ctx.artifact_exists("newsletter.html"):
                await ctx.emit({
                    "type": "phase_update",
                    "phase": "generation",
                    "message": "既存のHTMLを更新しています...",
                    "timestamp": self._get_timestamp()
                })
            
            # ジェネレーターエージェントに転送
            await ctx.transfer_to_agent("generator_agent")
            
            # 生成完了の確認
            if not ctx.artifact_exists("newsletter.html"):
                raise Exception("Generation phase failed: newsletter.html not created")
            
            await ctx.emit({
                "type": "phase_complete",
                "phase": "generation",
                "message": "学級通信の生成が完了しました",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Generation phase failed: {e}")
            await error_handler.handle_error(
                ctx, e, AgentErrorType.AGENT_TRANSFER_FAILED, ErrorSeverity.ERROR
            )
            raise
    
    def _get_timestamp(self) -> str:
        """現在のタイムスタンプを取得"""
        from datetime import datetime
        return datetime.utcnow().isoformat()


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


def create_enhanced_orchestrator_agent() -> EnhancedOrchestratorAgent:
    """エラーハンドリング強化版のオーケストレーターエージェントを作成"""
    return EnhancedOrchestratorAgent()

# ADK Web UI用のroot_agent変数
root_agent = create_orchestrator_agent()
