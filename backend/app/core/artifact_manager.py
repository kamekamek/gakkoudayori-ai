"""
HTML Artifact 管理サービス
LayoutAgentからのHTML成果物を管理し、WebSocket経由でフロントエンドに配信
"""
import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, Optional, Set
from dataclasses import dataclass, asdict
from fastapi import WebSocket

logger = logging.getLogger(__name__)


@dataclass
class HtmlArtifact:
    """HTML Artifact データ構造"""
    session_id: str
    content: str
    artifact_type: str = "newsletter"
    created_at: str = None
    metadata: Optional[Dict] = None

    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now().isoformat()

    def to_dict(self) -> Dict:
        return asdict(self)


class WebSocketManager:
    """WebSocket接続管理"""
    
    def __init__(self):
        # セッションID -> WebSocketのマッピング
        self._connections: Dict[str, WebSocket] = {}
        # アクティブな接続を追跡
        self._active_sessions: Set[str] = set()

    async def connect(self, session_id: str, websocket: WebSocket):
        """WebSocket接続を確立"""
        await websocket.accept()
        self._connections[session_id] = websocket
        self._active_sessions.add(session_id)
        logger.info(f"WebSocket connected for session: {session_id}")

    async def disconnect(self, session_id: str):
        """WebSocket接続を切断"""
        if session_id in self._connections:
            del self._connections[session_id]
        if session_id in self._active_sessions:
            self._active_sessions.remove(session_id)
        logger.info(f"WebSocket disconnected for session: {session_id}")

    async def send_artifact(self, session_id: str, artifact: HtmlArtifact):
        """指定セッションにHTML Artifactを送信"""
        if session_id not in self._connections:
            logger.warning(f"No WebSocket connection for session: {session_id}")
            return False

        try:
            websocket = self._connections[session_id]
            message = {
                "type": "html_artifact",
                "data": artifact.to_dict()
            }
            await websocket.send_text(json.dumps(message))
            logger.info(f"HTML artifact sent to session: {session_id}")
            return True
        except Exception as e:
            logger.error(f"Failed to send artifact to {session_id}: {e}")
            # 接続エラーの場合は接続を削除
            await self.disconnect(session_id)
            return False

    def is_connected(self, session_id: str) -> bool:
        """セッションがWebSocketで接続中かチェック"""
        return session_id in self._active_sessions


class ArtifactManager:
    """HTML Artifact 管理サービス"""
    
    def __init__(self):
        # セッションID -> 最新のArtifactのマッピング
        self._artifacts: Dict[str, HtmlArtifact] = {}
        self._websocket_manager = WebSocketManager()

    @property
    def websocket_manager(self) -> WebSocketManager:
        return self._websocket_manager

    async def store_html_artifact(
        self, 
        session_id: str, 
        html_content: str, 
        artifact_type: str = "newsletter",
        metadata: Optional[Dict] = None
    ) -> HtmlArtifact:
        """HTML Artifactを保存し、WebSocket経由で配信"""
        
        # Artifactオブジェクト作成
        artifact = HtmlArtifact(
            session_id=session_id,
            content=html_content,
            artifact_type=artifact_type,
            metadata=metadata or {}
        )
        
        # 内部ストレージに保存
        self._artifacts[session_id] = artifact
        logger.info(f"HTML artifact stored for session: {session_id}, size: {len(html_content)} chars")
        
        # WebSocket経由で即座に配信
        if self._websocket_manager.is_connected(session_id):
            success = await self._websocket_manager.send_artifact(session_id, artifact)
            if success:
                logger.info(f"HTML artifact delivered via WebSocket to: {session_id}")
            else:
                logger.warning(f"Failed to deliver artifact via WebSocket to: {session_id}")
        else:
            logger.info(f"WebSocket not connected for session: {session_id}, artifact stored for polling")
        
        return artifact

    def get_artifact(self, session_id: str) -> Optional[HtmlArtifact]:
        """指定セッションの最新Artifactを取得"""
        return self._artifacts.get(session_id)

    def get_all_artifacts(self) -> Dict[str, HtmlArtifact]:
        """全てのArtifactを取得（デバッグ用）"""
        return self._artifacts.copy()

    def clear_session_artifacts(self, session_id: str):
        """指定セッションのArtifactをクリア"""
        if session_id in self._artifacts:
            del self._artifacts[session_id]
            logger.info(f"Artifacts cleared for session: {session_id}")


# グローバルシングルトンインスタンス
artifact_manager = ArtifactManager()