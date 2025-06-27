import logging
import json
import os
from pathlib import Path
from typing import AsyncGenerator
from google.adk.agents import SequentialAgent, LlmAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events.event import Event
from google.adk.models.google_llm import Gemini
from google.genai.types import Content, Part
import google.genai.types as genai_types


def _load_instruction() -> str:
    """プロンプトファイルを読み込みます。"""
    current_dir = Path(os.path.dirname(__file__))
    prompt_file = current_dir / "prompts" / "orchestrator_instruction.md"
    try:
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        # フォールバック用の基本的なプロンプト
        return "あなたは学級通信作成のワークフローを管理するオーケストレーターエージェントです。プランニングフェーズと生成フェーズを調整します。"


class SimpleOrchestratorAgent(LlmAgent):
    """シンプルな2段階ワークフローオーケストレーターエージェント"""
    logger: logging.Logger
    conversation_agent: "LlmAgent"
    layout_agent: "LlmAgent"

    class Config:
        arbitrary_types_allowed = True
    
    def __init__(self, **data):
        # Ensure model is set if not provided
        if 'model' not in data:
            data['model'] = Gemini(model_name="gemini-1.5-pro-latest")
        # Ensure instruction is set if not provided
        if 'instruction' not in data:
            data['instruction'] = _load_instruction()
        super().__init__(**data)
        
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        """
        シンプルな2段階ワークフローを実行
        1. 対話エージェント → JSON生成
        2. レイアウトエージェント → HTML生成
        """
        try:
            # Stage 1: 対話エージェント実行
            self.logger.info("Stage 1: 対話エージェント開始")
            async for event in self.conversation_agent._run_async_impl(ctx):
                yield event
            
            # JSON生成確認
            artifacts_dir = Path("/tmp/adk_artifacts")
            outline_file = artifacts_dir / "outline.json"
            
            if not outline_file.exists():
                raise Exception("対話エージェントがJSONを生成できませんでした")
            
            # Stage 2: レイアウトエージェント実行
            self.logger.info("Stage 2: レイアウトエージェント開始")
            async for event in self.layout_agent._run_async_impl(ctx):
                yield event
            
            # HTML生成確認
            newsletter_file = artifacts_dir / "newsletter.html"
            if newsletter_file.exists():
                # HTMLコンテンツを読み込んでフロントエンドに送信
                try:
                    with open(newsletter_file, "r", encoding="utf-8") as f:
                        html_content = f.read()
                    
                    yield Event(
                        author=self.name,
                        content=Content(parts=[Part(text=html_content)])
                    )
                except Exception as e:
                    self.logger.error(f"HTMLファイル読み込みエラー: {e}")
            
        except Exception as e:
            self.logger.error(f"ワークフロー失敗: {e}")
            yield Event(
                author=self.name,
                content=Content(parts=[Part(text=f"申し訳ありません。エラーが発生しました: {str(e)}")])
            )
            raise
    
    
    
    def _get_timestamp(self) -> float:
        """現在のタイムスタンプを取得"""
        from datetime import datetime, timezone
        return datetime.now(timezone.utc).timestamp()


def create_orchestrator_agent() -> SequentialAgent:
    """
    学級通信作成のワークフロー（計画→生成）を実行するシーケンシャルエージェントを作成します。
    1. ConversationAgent: ユーザーと対話し、構成案（outline.json）を作成します。
    2. LayoutAgent: outline.jsonを読み込み、HTMLを生成します。
    """
    # 循環importを避けるため、関数内でimport
    from agents.conversation_agent.agent import create_conversation_agent
    from agents.layout_agent.agent import create_layout_agent
    
    return SequentialAgent(
        name="orchestrator_agent",
        sub_agents=[
            create_conversation_agent(),
            create_layout_agent(),
        ],
        description="Handles the newsletter creation workflow from planning to generation.",
    )


def create_simple_orchestrator_agent() -> SimpleOrchestratorAgent:
    """シンプルな2段階ワークフローオーケストレーターエージェントを作成"""
    # 循環importを避けるため、関数内でimport
    from agents.conversation_agent.agent import create_conversation_agent
    from agents.layout_agent.agent import create_layout_agent
    
    return SimpleOrchestratorAgent(
        name="orchestrator_agent",
        description="Handles the simple 2-stage newsletter creation workflow.",
        logger=logging.getLogger("orchestrator_agent"),
        conversation_agent=create_conversation_agent(),
        layout_agent=create_layout_agent(),
    )

# ADK Web UI用のroot_agent変数
# SimpleOrchestratorAgentでエラーが出る場合はSequentialAgentを使用
try:
    root_agent = create_simple_orchestrator_agent()
except Exception as e:
    print(f"SimpleOrchestratorAgent作成エラー、SequentialAgentにフォールバック: {e}")
    root_agent = create_orchestrator_agent()
