import logging
from google.cloud import firestore

from ..services.adk_session_service import FirestoreSessionService
from ..services.firebase_service import get_firestore_client

logger = logging.getLogger(__name__)

# グローバル変数としてシングルトンインスタンスを保持
_session_service = None

def get_session_service() -> FirestoreSessionService:
    """FirestoreSessionServiceのシングルトンインスタンスを返す"""
    global _session_service
    if _session_service is None:
        logger.info("Creating FirestoreSessionService singleton instance...")
        firestore_client = get_firestore_client()
        _session_service = FirestoreSessionService(firestore_client)
    return _session_service 