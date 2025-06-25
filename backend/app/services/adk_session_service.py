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
# 一時的にAdkSessionを除去し、基本的な型として扱う
# from google.adk.sessions import Session as AdkSession
from google.genai import types as genai_types
from google.protobuf.json_format import MessageToDict
from google.cloud.firestore_v1.base_client import BaseClient
from google.api_core.exceptions import NotFound
from models.adk_models import (
    NewsletterGenerationRequest,
    NewsletterGenerationResponse,
    HTMLValidationRequest,
    HTMLValidationResponse,
)
from adk.agents.generation_workflow_agent import create_generation_workflow_agent
from adk.agents.validation_agent import create_validation_agent
from core.config import settings

logger = logging.getLogger(__name__)

# 一時的にBaseSessionServiceを除去し、基本動作を確保
# from google.adk.sessions import BaseSessionService

class ADKSessionService:
    """ADK セッション管理サービス"""
    
    def __init__(self):
        self.generation_agent = create_generation_workflow_agent()
        self.validation_agent = create_validation_agent()
        self.sessions: Dict[str, Dict[str, Any]] = {}
    
    def create_session(self, session_id: str) -> Dict[str, Any]:
        """新しいセッションを作成"""
        session_data = {
            "session_id": session_id,
            "created_at": None,  # 実際の実装では datetime.now()
            "status": "active",
            "conversation_history": [],
            "generation_count": 0,
            "validation_count": 0,
        }
        self.sessions[session_id] = session_data
        return session_data
    
    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """セッション情報を取得"""
        return self.sessions.get(session_id)
    
    def update_session(self, session_id: str, updates: Dict[str, Any]) -> bool:
        """セッション情報を更新"""
        if session_id in self.sessions:
            self.sessions[session_id].update(updates)
            return True
        return False
    
    def delete_session(self, session_id: str) -> bool:
        """セッションを削除"""
        if session_id in self.sessions:
            del self.sessions[session_id]
            return True
        return False
    
    async def generate_newsletter(
        self, 
        request: NewsletterGenerationRequest, 
        session_id: str
    ) -> NewsletterGenerationResponse:
        """
        ニュースレター生成
        
        Sequential Agentを使用して:
        1. プランナーが構成を計画
        2. ジェネレーターが実際のHTMLを生成
        """
        # セッション確認・作成
        if session_id not in self.sessions:
            self.create_session(session_id)
        
        # Sequential Agent実行
        try:
            result = await self.generation_agent.run(
                audio_input=request.audio_input,
                user_instruction=request.user_instruction,
                layout_preference=request.layout_preference,
                session_id=session_id
            )
            
            # セッション更新
            self.update_session(session_id, {
                "generation_count": self.sessions[session_id]["generation_count"] + 1,
                "last_generation": result
            })
            
            return NewsletterGenerationResponse(
                generated_html=result.get("generated_html", ""),
                session_id=session_id,
                status="completed",
                processing_time=result.get("processing_time", 0.0)
            )
            
        except Exception as e:
            return NewsletterGenerationResponse(
                generated_html="",
                session_id=session_id,
                status="error",
                processing_time=0.0,
                error_message=str(e)
            )
    
    async def validate_html(
        self, 
        request: HTMLValidationRequest, 
        session_id: str
    ) -> HTMLValidationResponse:
        """
        HTML検証
        
        独立したValidation Agentを使用
        """
        # セッション確認・作成
        if session_id not in self.sessions:
            self.create_session(session_id)
        
        try:
            result = await self.validation_agent.run(
                html_content=request.html_content,
                validation_rules=request.validation_rules,
                session_id=session_id
            )
            
            # セッション更新
            self.update_session(session_id, {
                "validation_count": self.sessions[session_id]["validation_count"] + 1,
                "last_validation": result
            })
            
            return HTMLValidationResponse(
                is_valid=result.get("is_valid", False),
                validation_errors=result.get("validation_errors", []),
                suggestions=result.get("suggestions", []),
                session_id=session_id,
                processing_time=result.get("processing_time", 0.0)
            )
            
        except Exception as e:
            return HTMLValidationResponse(
                is_valid=False,
                validation_errors=[f"Validation error: {str(e)}"],
                suggestions=[],
                session_id=session_id,
                processing_time=0.0
            )
    
    def get_session_stats(self, session_id: str) -> Dict[str, Any]:
        """セッション統計情報を取得"""
        session = self.get_session(session_id)
        if not session:
            return {"error": "Session not found"}
        
        return {
            "session_id": session_id,
            "status": session["status"],
            "generation_count": session["generation_count"],
            "validation_count": session["validation_count"],
            "total_operations": session["generation_count"] + session["validation_count"]
        }


# Dependency Injection用のインスタンス
_adk_session_service = None

def get_adk_session_service() -> ADKSessionService:
    """ADKSessionServiceのシングルトンインスタンスを取得"""
    global _adk_session_service
    if _adk_session_service is None:
        _adk_session_service = ADKSessionService()
    return _adk_session_service

class FirestoreSessionService:
    """Google ADK用のFirestoreベースのセッションサービス"""
    
    def __init__(self, firestore_client: firestore.Client, collection_name: str = "adk_sessions", ttl_hours: int = 24):
        self.db = firestore_client
        self.collection_name = collection_name
        self.ttl_hours = ttl_hours
    
    async def get_session(self, session_id: str, app_name: Optional[str] = None, user_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
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
            
            # 基本的なセッションデータを返す
            return {
                'id': session_id,
                'app_name': data.get('app_name'),
                'user_id': data.get('user_id'),
                'state': data.get('state', {}),
                'events': data.get('events', []),
                'last_update_time': data.get('updated_at'),
                'created_at': data.get('created_at')
            }
        except Exception as e:
            logger.error(f"Error getting session {session_id}: {e}", exc_info=True)
            return None
    
    async def save_session(self, session: Dict[str, Any]) -> None:
        """セッションを保存"""
        try:
            # セッションデータを直接使用
            session_data = session.copy()
            session_data['updated_at'] = datetime.now(timezone.utc)
            
            doc_ref = self.db.collection(self.collection_name).document(session['id'])
            
            doc = doc_ref.get()
            if not doc.exists:
                session_data['created_at'] = datetime.now(timezone.utc)
            
            doc_ref.set(session_data, merge=True)
            logger.info(f"Session {session['id']} saved successfully.")
        except Exception as e:
            logger.error(f"Error saving session {session.get('id', 'unknown')}: {e}", exc_info=True)
            raise
    
    async def create_session(self, session_id: str, app_name: str, user_id: str, state: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """新しいセッションを作成"""
        try:
            # 基本セッションオブジェクトを作成
            session = {
                'id': session_id,
                'app_name': app_name,
                'user_id': user_id,
                'state': state or {},
                'events': [],
                'created_at': datetime.now(timezone.utc)
            }
            
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
    
    async def list_sessions(self, user_id: str, app_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """ユーザーのセッション一覧を取得"""
        try:
            query = self.db.collection(self.collection_name).where('user_id', '==', user_id)
            docs = query.stream()
            
            sessions = []
            for doc in docs:
                data = doc.to_dict()
                
                # TTLチェック
                updated_at = data.get('updated_at', datetime.now(timezone.utc))
                if isinstance(updated_at, datetime):
                    if datetime.now(timezone.utc) - updated_at <= timedelta(hours=self.ttl_hours):
                        # 基本セッションデータを作成
                        session = {
                            'id': doc.id,
                            'app_name': data.get('app_name'),
                            'user_id': data.get('user_id'),
                            'state': data.get('state', {}),
                            'events': data.get('events', []),
                            'last_update_time': data.get('updated_at'),
                            'created_at': data.get('created_at')
                        }
                        sessions.append(session)
            
            return sessions
        except Exception as e:
            logger.error(f"Error listing sessions for user {user_id}: {e}")
            return []

    async def append_event(self, session: Dict[str, Any], event) -> None:
        """セッションにイベントを追加"""
        try:
            # セッションのeventsリストにイベントを追加
            session['events'].append(event)
            
            # セッションを保存
            await self.save_session(session)
            
            logger.info(f"Event appended to session {session['id']}")
        except Exception as e:
            logger.error(f"Error appending event to session {session['id']}: {e}", exc_info=True)
            raise

    async def list_events(self, session_id: str) -> List:
        """セッションのイベント一覧を取得"""
        try:
            session = await self.get_session(session_id)
            if session:
                return session.get('events', [])
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
    
    def _convert_history_to_messages(self, history: List[Dict[str, Any]]) -> List['ChatMessage']:
        """ADKのhistoryをChatMessageリストに変換"""
        messages = []
        for item in history:
            if 'role' in item and 'content' in item:
                # Simplified message structure without external dependencies
                messages.append({
                    'role': item['role'],
                    'content': self._extract_text_content(item['content']),
                    'timestamp': item.get('timestamp', datetime.now(timezone.utc))
                })
        return messages

    def _extract_text_content(self, content: Any) -> str:
        """コンテンツからテキストを抽出"""
        if isinstance(content, str):
            return content
        elif isinstance(content, dict):
            # Google GenAI形式の場合
            if 'parts' in content:
                parts = content['parts']
                if isinstance(parts, list) and len(parts) > 0:
                    first_part = parts[0]
                    if isinstance(first_part, dict) and 'text' in first_part:
                        return first_part['text']
            # プレーンテキストが格納されている場合
            return content.get('text', str(content))
        else:
            return str(content)


def create_session_service(firestore_client: firestore.Client) -> FirestoreSessionService:
    """FirestoreSessionServiceを作成する"""
    return FirestoreSessionService(firestore_client) 