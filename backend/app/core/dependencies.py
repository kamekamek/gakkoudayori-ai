import logging
from google.cloud import firestore

# ADK v1.0.0の公式セッションサービスを使用
from google.adk.sessions import InMemorySessionService
from adk.agents.orchestrator_agent import create_orchestrator_agent

logger = logging.getLogger(__name__)

# グローバル変数としてシングルトンインスタンスを保持
_session_service = None
_orchestrator_agent = None

def get_session_service() -> InMemorySessionService:
    """InMemorySessionServiceのシングルトンインスタンスを返す（ADK v1.0.0準拠）"""
    global _session_service
    if _session_service is None:
        logger.info("Creating InMemorySessionService singleton instance for ADK v1.0.0...")
        _session_service = InMemorySessionService()
    return _session_service

def get_orchestrator_agent():
    """OrchestratorAgentのシングルトンインスタンスを返す"""
    global _orchestrator_agent
    if _orchestrator_agent is None:
        logger.info("Creating OrchestratorAgent singleton instance...")
        _orchestrator_agent = create_orchestrator_agent()
    return _orchestrator_agent 