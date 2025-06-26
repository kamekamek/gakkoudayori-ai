import logging
from typing import AsyncGenerator
from google.adk.agents import SequentialAgent, LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
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
        
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """
        学級通信作成のワークフローを実行
        ジェネレーター形式でイベントをストリーミング
        """
        try:
            # セッション開始を通知
            await ctx.emit({
                "type": "workflow_start",
                "message": "学級通信作成を開始します...",
                "timestamp": self._get_timestamp()
            })
            
            # Phase 1: Planning
            async for event in self._execute_planning_phase(ctx):
                yield event
            
            # Phase 2: Generation
            async for event in self._execute_generation_phase(ctx):
                yield event
            
            # 完了通知
            await ctx.emit({
                "type": "workflow_complete",
                "message": "学級通信の作成が完了しました！",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Orchestrator workflow failed: {e}")
            await ctx.emit({
                "type": "workflow_failed",
                "message": f"学級通信の作成に失敗しました: {str(e)}",
                "timestamp": self._get_timestamp()
            })
            raise
    
    async def _execute_planning_phase(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """計画フェーズの実行"""
        from pathlib import Path
        
        try:
            await ctx.emit({
                "type": "phase_start",
                "phase": "planning",
                "message": "構成を計画しています...",
                "timestamp": self._get_timestamp()
            })
            
            # ファイルシステムベースでoutline.jsonの存在確認
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"
            
            if outline_file.exists():
                await ctx.emit({
                    "type": "phase_skip",
                    "phase": "planning",
                    "message": "既存の構成を使用します",
                    "timestamp": self._get_timestamp()
                })
                return
            
            # プランナーエージェントを直接実行
            self.logger.info("プランナーエージェントを実行中...")
            async for event in self.planner_agent._run_async_impl(ctx):
                yield event
            
            # プランニング完了の確認
            if not outline_file.exists():
                raise Exception("Planning phase failed: outline.json not created")
            
            await ctx.emit({
                "type": "phase_complete",
                "phase": "planning",
                "message": "構成の計画が完了しました",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Planning phase failed: {e}")
            raise
    
    async def _execute_generation_phase(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """生成フェーズの実行"""
        from pathlib import Path
        
        try:
            await ctx.emit({
                "type": "phase_start",
                "phase": "generation",
                "message": "学級通信を生成しています...",
                "timestamp": self._get_timestamp()
            })
            
            # ファイルシステムベースでファイル存在確認
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"
            newsletter_file = artifacts_dir / "newsletter.html"
            
            # outline.json の存在確認
            if not outline_file.exists():
                raise Exception("Generation phase failed: outline.json not found")
            
            # 既にHTMLが存在する場合の処理
            if newsletter_file.exists():
                await ctx.emit({
                    "type": "phase_update",
                    "phase": "generation",
                    "message": "既存のHTMLを更新しています...",
                    "timestamp": self._get_timestamp()
                })
            
            # ジェネレーターエージェントを直接実行
            self.logger.info("ジェネレーターエージェントを実行中...")
            async for event in self.generator_agent._run_async_impl(ctx):
                yield event
            
            # 生成完了の確認
            if not newsletter_file.exists():
                raise Exception("Generation phase failed: newsletter.html not created")
            
            # HTMLコンテンツを読み込んでフロントエンドに送信
            try:
                with open(newsletter_file, "r", encoding="utf-8") as f:
                    html_content = f.read()
                
                await ctx.emit({
                    "type": "html_generated",
                    "html_content": html_content,
                    "message": "学級通信の生成が完了しました",
                    "timestamp": self._get_timestamp()
                })
            except Exception as e:
                self.logger.error(f"HTMLファイル読み込みエラー: {e}")
            
            await ctx.emit({
                "type": "phase_complete",
                "phase": "generation",
                "message": "学級通信の生成が完了しました",
                "timestamp": self._get_timestamp()
            })
            
        except Exception as e:
            self.logger.error(f"Generation phase failed: {e}")
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
