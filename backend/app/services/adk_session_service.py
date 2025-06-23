# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import uuid
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta, timezone
from google.cloud import firestore
from google.adk.sessions import Session as AdkSession
from google.genai import types as genai_types
from google.protobuf.json_format import MessageToDict
from models.adk_models import SessionInfo, ChatMessage
from firebase_admin import firestore

logger = logging.getLogger(__name__)


from google.adk.sessions import BaseSessionService

class FirestoreSessionService(BaseSessionService):
    """Google ADK用のFirestoreベースのセッションサービス"""
    
    def __init__(self, firestore_client: firestore.Client, collection_name: str = "adk_sessions", ttl_hours: int = 24):
        self.db = firestore_client
        self.collection_name = collection_name
        self.ttl_hours = ttl_hours
    
    async def get_session(self, session_id: str, app_name: Optional[str] = None, user_id: Optional[str] = None) -> Optional[AdkSession]:
        """セッションを取得"""
        try:
            doc_ref = self.db.collection(self.collection_name).document(session_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                # ADK標準の動作：セッションが見つからない場合はNoneを返す
                logger.info(f"Session {session_id} not found")
                return None
            
            data = doc.to_dict()
            
            # TTLチェック
            if 'updated_at' in data:
                updated_at = data['updated_at']
                if isinstance(updated_at, datetime):
                    if datetime.now(timezone.utc) - updated_at > timedelta(hours=self.ttl_hours):
                        await self.delete_session(session_id)
                        return None
            
            # AdkSessionモデルに定義されているフィールドのみを抽出
            session_fields = AdkSession.model_fields.keys()
            session_data_for_validation = {
                k: v for k, v in data.items() if k in session_fields
            }
            
            # Pydanticモデルの標準的な方法でデシリアライズ
            return AdkSession.model_validate(session_data_for_validation)
        except Exception as e:
            logger.error(f"Error getting session {session_id}: {e}", exc_info=True)
            return None
    
    async def save_session(self, session: AdkSession) -> None:
        """セッションを保存"""
        try:
            # Pydanticモデルの標準的な方法でシリアライズ
            session_data = session.model_dump(mode='json')
            session_data['updated_at'] = datetime.now(timezone.utc)
            
            doc_ref = self.db.collection(self.collection_name).document(session.id)
            
            doc = doc_ref.get()
            if not doc.exists:
                session_data['created_at'] = datetime.now(timezone.utc)
            
            doc_ref.set(session_data, merge=True)
            logger.info(f"Session {session.id} saved successfully.")
        except Exception as e:
            logger.error(f"Error saving session {getattr(session, 'id', 'unknown')}: {e}", exc_info=True)
            raise
    
    async def create_session(self, session_id: str, app_name: str, user_id: str, state: Optional[Dict[str, Any]] = None) -> AdkSession:
        """新しいセッションを作成"""
        try:
            
            # ADKのSessionオブジェクトを作成
            session = AdkSession(
                id=session_id,
                app_name=app_name,
                user_id=user_id,
                state=state or {},
                events=[]
            )
            
            # Firestoreに保存
            await self.save_session(session)
            
            logger.info(f"Session {session_id} created successfully")
            return session
        except Exception as e:
            logger.error(f"Error creating session: {e}", exc_info=True)
            raise

    async def delete_session(self, session_id: str, app_name: Optional[str] = None, user_id: Optional[str] = None) -> None:
        """セッションを削除"""
        try:
            doc_ref = self.db.collection(self.collection_name).document(session_id)
            doc_ref.delete()
            logger.info(f"Session {session_id} deleted successfully")
        except Exception as e:
            logger.error(f"Error deleting session {session_id}: {e}")
            raise
    
    async def list_sessions(self, user_id: str, app_name: Optional[str] = None) -> List[AdkSession]:
        """ユーザーのセッション一覧を取得"""
        try:
            query = self.db.collection(self.collection_name).where('user_id', '==', user_id)
            docs = query.stream()
            
            sessions = []
            session_fields = AdkSession.model_fields.keys()
            for doc in docs:
                data = doc.to_dict()
                
                # TTLチェック
                updated_at = data.get('updated_at', datetime.now(timezone.utc))
                if isinstance(updated_at, datetime):
                    if datetime.now(timezone.utc) - updated_at <= timedelta(hours=self.ttl_hours):
                        # AdkSessionモデルに定義されているフィールドのみを抽出
                        session_data_for_validation = {
                            k: v for k, v in data.items() if k in session_fields
                        }
                        # AdkSessionオブジェクトを作成
                        session = AdkSession.model_validate(session_data_for_validation)
                        sessions.append(session)
            
            return sessions
        except Exception as e:
            logger.error(f"Error listing sessions for user {user_id}: {e}")
            return []

    async def append_event(self, session: AdkSession, event) -> None:
        """セッションにイベントを追加"""
        try:
            # セッションのeventsリストにイベントを追加
            session.events.append(event)
            
            # セッションを保存
            await self.save_session(session)
            
            logger.info(f"Event appended to session {session.id}")
        except Exception as e:
            logger.error(f"Error appending event to session {session.id}: {e}", exc_info=True)
            raise

    async def list_events(self, session_id: str) -> List:
        """セッションのイベント一覧を取得"""
        try:
            session = await self.get_session(session_id)
            if session:
                return session.events
            return []
        except Exception as e:
            logger.error(f"Error listing events for session {session_id}: {e}")
            return []

    async def close_session(self, session_id: str) -> None:
        """セッションを閉じる（削除と同じ）"""
        try:
            await self.delete_session(session_id)
            logger.info(f"Session {session_id} closed successfully")
        except Exception as e:
            logger.error(f"Error closing session {session_id}: {e}")
            raise
    
    def _convert_history_to_messages(self, history: List[Dict[str, Any]]) -> List[ChatMessage]:
        """ADKのhistoryをChatMessageリストに変換"""
        messages = []
        for item in history:
            if 'role' in item and 'content' in item:
                messages.append(ChatMessage(
                    role=item['role'],
                    content=self._extract_text_content(item['content']),
                    timestamp=item.get('timestamp', datetime.now(timezone.utc))
                ))
        return messages
    
    def _extract_text_content(self, content: Any) -> str:
        """コンテンツからテキストを抽出"""
        if isinstance(content, str):
            return content
        elif isinstance(content, dict):
            # ADKのコンテンツ形式からテキストを抽出
            if 'parts' in content:
                text_parts = []
                for part in content['parts']:
                    if isinstance(part, dict) and 'text' in part:
                        text_parts.append(part['text'])
                    elif isinstance(part, str):
                        text_parts.append(part)
                return '\n'.join(text_parts)
            elif 'text' in content:
                return content['text']
        elif isinstance(content, list):
            # 複数のパートがある場合
            text_parts = []
            for item in content:
                text_parts.append(self._extract_text_content(item))
            return '\n'.join(text_parts)
        
        return str(content)


def create_session_service(firestore_client: firestore.Client) -> FirestoreSessionService:
    """セッションサービスのファクトリー関数"""
    return FirestoreSessionService(firestore_client)