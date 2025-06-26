import logging
from google.cloud import firestore
from typing import Dict

# ADK v1.0.0の公式セッションサービスを使用
from google.adk.sessions import InMemorySessionService
from adk.agents.orchestrator_agent import create_orchestrator_agent
from adk.agents.planner_agent import create_planner_agent
from adk.agents.generator_agent import create_generator_agent

logger = logging.getLogger(__name__)

# グローバル変数としてシングルトンインスタンスを保持
_session_service = None
_orchestrator_agent = None
_agent_registry = None

def get_session_service() -> InMemorySessionService:
    """InMemorySessionServiceのシングルトンインスタンスを返す（ADK v1.0.0準拠）"""
    global _session_service
    if _session_service is None:
        logger.info("Creating InMemorySessionService singleton instance for ADK v1.0.0...")
        _session_service = InMemorySessionService()
    return _session_service

def get_agent_registry() -> Dict[str, object]:
    """全てのエージェントを含むレジストリを返す"""
    global _agent_registry
    if _agent_registry is None:
        logger.info("Creating agent registry...")
        _agent_registry = {
            "orchestrator": create_orchestrator_agent(),
            "planner": create_planner_agent(), 
            "generator": create_generator_agent()
        }
        logger.info(f"Created agents: {list(_agent_registry.keys())}")
    return _agent_registry

def get_orchestrator_agent():
    """OrchestratorAgentのシングルトンインスタンスを返す"""
    global _orchestrator_agent
    if _orchestrator_agent is None:
        logger.info("Creating OrchestratorAgent singleton instance...")
        _orchestrator_agent = create_orchestrator_agent()
    return _orchestrator_agent 