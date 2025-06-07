"""
WebSocket Chat API for Real-time Editing
リアルタイム編集用のWebSocketチャット機能
"""

from fastapi import WebSocket, WebSocketDisconnect, Depends
from fastapi.routing import APIRouter
from typing import Dict, List, Optional
import json
import logging
from datetime import datetime
import asyncio

from ..auth import get_current_user_from_websocket
from ..services.gemini_service import GeminiService

# ログ設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter()

class ConnectionManager:
    """WebSocket接続管理クラス"""
    
    def __init__(self):
        # アクティブな接続を管理
        self.active_connections: Dict[str, List[WebSocket]] = {}
        # ドキュメントセッション管理
        self.document_sessions: Dict[str, Dict] = {}
        
    async def connect(self, websocket: WebSocket, document_id: str, user_id: str):
        """WebSocket接続を受け入れ"""
        await websocket.accept()
        
        # ドキュメントIDごとに接続を管理
        if document_id not in self.active_connections:
            self.active_connections[document_id] = []
        
        self.active_connections[document_id].append(websocket)
        
        # セッション情報を初期化
        if document_id not in self.document_sessions:
            self.document_sessions[document_id] = {
                "users": {},
                "content": "",
                "last_updated": datetime.now().isoformat(),
                "edit_history": []
            }
        
        # ユーザー情報を追加
        self.document_sessions[document_id]["users"][user_id] = {
            "websocket": websocket,
            "joined_at": datetime.now().isoformat(),
            "last_activity": datetime.now().isoformat()
        }
        
        logger.info(f"User {user_id} connected to document {document_id}")
        
        # 他のユーザーに参加通知
        await self.broadcast_to_document(document_id, {
            "type": "user_joined",
            "user_id": user_id,
            "timestamp": datetime.now().isoformat()
        }, exclude_user=user_id)
        
    def disconnect(self, websocket: WebSocket, document_id: str, user_id: str):
        """WebSocket接続を切断"""
        if document_id in self.active_connections:
            if websocket in self.active_connections[document_id]:
                self.active_connections[document_id].remove(websocket)
                
            # セッションからユーザーを削除
            if document_id in self.document_sessions:
                if user_id in self.document_sessions[document_id]["users"]:
                    del self.document_sessions[document_id]["users"][user_id]
                    
                # 接続がなくなったらセッションを削除
                if not self.active_connections[document_id]:
                    del self.active_connections[document_id]
                    del self.document_sessions[document_id]
                    
        logger.info(f"User {user_id} disconnected from document {document_id}")
        
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """個人メッセージを送信"""
        try:
            await websocket.send_text(json.dumps(message))
        except Exception as e:
            logger.error(f"Error sending personal message: {e}")
            
    async def broadcast_to_document(self, document_id: str, message: dict, exclude_user: Optional[str] = None):
        """ドキュメント内の全ユーザーにブロードキャスト"""
        if document_id not in self.active_connections:
            return
            
        message_text = json.dumps(message)
        disconnected_connections = []
        
        for websocket in self.active_connections[document_id]:
            try:
                # 除外ユーザーのチェック
                if exclude_user:
                    user_websocket = None
                    if document_id in self.document_sessions:
                        for uid, user_info in self.document_sessions[document_id]["users"].items():
                            if user_info["websocket"] == websocket and uid == exclude_user:
                                user_websocket = websocket
                                break
                    if user_websocket:
                        continue
                        
                await websocket.send_text(message_text)
            except Exception as e:
                logger.error(f"Error broadcasting message: {e}")
                disconnected_connections.append(websocket)
                
        # 切断された接続を削除
        for websocket in disconnected_connections:
            if websocket in self.active_connections[document_id]:
                self.active_connections[document_id].remove(websocket)

# グローバル接続マネージャー
manager = ConnectionManager()

@router.websocket("/ws/chat/{document_id}")
async def websocket_chat_endpoint(
    websocket: WebSocket,
    document_id: str,
    user_id: str = Depends(get_current_user_from_websocket)
):
    """WebSocketチャットエンドポイント"""
    await manager.connect(websocket, document_id, user_id)
    
    try:
        while True:
            # メッセージを受信
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # メッセージタイプに応じて処理
            await handle_message(document_id, user_id, message_data, websocket)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket, document_id, user_id)
        # 他のユーザーに離脱通知
        await manager.broadcast_to_document(document_id, {
            "type": "user_left",
            "user_id": user_id,
            "timestamp": datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, document_id, user_id)

async def handle_message(document_id: str, user_id: str, message_data: dict, websocket: WebSocket):
    """受信メッセージの処理"""
    message_type = message_data.get("type")
    
    if message_type == "chat_message":
        await handle_chat_message(document_id, user_id, message_data, websocket)
    elif message_type == "edit_request":
        await handle_edit_request(document_id, user_id, message_data, websocket)
    elif message_type == "content_update":
        await handle_content_update(document_id, user_id, message_data)
    elif message_type == "typing":
        await handle_typing_indicator(document_id, user_id, message_data)
    else:
        logger.warning(f"Unknown message type: {message_type}")

async def handle_chat_message(document_id: str, user_id: str, message_data: dict, websocket: WebSocket):
    """チャットメッセージの処理"""
    content = message_data.get("content", "")
    
    # メッセージをブロードキャスト
    broadcast_message = {
        "type": "chat_message",
        "user_id": user_id,
        "content": content,
        "timestamp": datetime.now().isoformat()
    }
    
    await manager.broadcast_to_document(document_id, broadcast_message)
    
    # AI編集提案が必要かチェック
    if should_trigger_ai_suggestion(content):
        await generate_ai_suggestion(document_id, user_id, content, websocket)

async def handle_edit_request(document_id: str, user_id: str, message_data: dict, websocket: WebSocket):
    """編集リクエストの処理"""
    edit_type = message_data.get("edit_type")  # "accept", "reject", "modify"
    suggestion_id = message_data.get("suggestion_id")
    
    if edit_type == "accept":
        # 編集提案を受諾
        await apply_edit_suggestion(document_id, user_id, suggestion_id)
    elif edit_type == "reject":
        # 編集提案を拒否
        await reject_edit_suggestion(document_id, user_id, suggestion_id)
    elif edit_type == "modify":
        # 編集提案を修正
        modified_content = message_data.get("modified_content", "")
        await modify_edit_suggestion(document_id, user_id, suggestion_id, modified_content)

async def handle_content_update(document_id: str, user_id: str, message_data: dict):
    """コンテンツ更新の処理"""
    new_content = message_data.get("content", "")
    
    # セッションのコンテンツを更新
    if document_id in manager.document_sessions:
        manager.document_sessions[document_id]["content"] = new_content
        manager.document_sessions[document_id]["last_updated"] = datetime.now().isoformat()
        
        # 履歴に追加
        manager.document_sessions[document_id]["edit_history"].append({
            "user_id": user_id,
            "content": new_content,
            "timestamp": datetime.now().isoformat()
        })
        
        # 他のユーザーに更新を通知
        await manager.broadcast_to_document(document_id, {
            "type": "content_updated",
            "content": new_content,
            "user_id": user_id,
            "timestamp": datetime.now().isoformat()
        }, exclude_user=user_id)

async def handle_typing_indicator(document_id: str, user_id: str, message_data: dict):
    """タイピングインジケーターの処理"""
    is_typing = message_data.get("is_typing", False)
    
    await manager.broadcast_to_document(document_id, {
        "type": "typing_indicator",
        "user_id": user_id,
        "is_typing": is_typing,
        "timestamp": datetime.now().isoformat()
    }, exclude_user=user_id)

def should_trigger_ai_suggestion(content: str) -> bool:
    """AI提案をトリガーするかどうかの判定"""
    # 編集指示のキーワードを検出
    edit_keywords = [
        "直して", "修正", "変更", "編集", "書き直し",
        "もっと", "より", "簡潔に", "詳しく", "わかりやすく"
    ]
    
    return any(keyword in content for keyword in edit_keywords)

async def generate_ai_suggestion(document_id: str, user_id: str, request_content: str, websocket: WebSocket):
    """AI編集提案の生成"""
    try:
        # 現在のドキュメントコンテンツを取得
        current_content = ""
        if document_id in manager.document_sessions:
            current_content = manager.document_sessions[document_id]["content"]
        
        # Geminiサービスを使用して編集提案を生成
        gemini_service = GeminiService()
        
        prompt = f"""
        現在のコンテンツ:
        {current_content}
        
        編集リクエスト:
        {request_content}
        
        上記のリクエストに基づいて、コンテンツの改善提案をしてください。
        HTMLタグを保持し、学級通信として適切な内容にしてください。
        """
        
        suggestion = await gemini_service.generate_content_async(prompt)
        
        # 提案をユーザーに送信
        suggestion_message = {
            "type": "ai_suggestion",
            "suggestion_id": f"suggestion_{datetime.now().timestamp()}",
            "original_content": current_content,
            "suggested_content": suggestion,
            "request": request_content,
            "timestamp": datetime.now().isoformat()
        }
        
        await manager.send_personal_message(suggestion_message, websocket)
        
    except Exception as e:
        logger.error(f"Error generating AI suggestion: {e}")
        await manager.send_personal_message({
            "type": "error",
            "message": "AI提案の生成に失敗しました",
            "timestamp": datetime.now().isoformat()
        }, websocket)

async def apply_edit_suggestion(document_id: str, user_id: str, suggestion_id: str):
    """編集提案の適用"""
    # TODO: 提案を適用してドキュメントを更新
    await manager.broadcast_to_document(document_id, {
        "type": "suggestion_applied",
        "suggestion_id": suggestion_id,
        "user_id": user_id,
        "timestamp": datetime.now().isoformat()
    })

async def reject_edit_suggestion(document_id: str, user_id: str, suggestion_id: str):
    """編集提案の拒否"""
    await manager.broadcast_to_document(document_id, {
        "type": "suggestion_rejected",
        "suggestion_id": suggestion_id,
        "user_id": user_id,
        "timestamp": datetime.now().isoformat()
    })

async def modify_edit_suggestion(document_id: str, user_id: str, suggestion_id: str, modified_content: str):
    """編集提案の修正"""
    await manager.broadcast_to_document(document_id, {
        "type": "suggestion_modified",
        "suggestion_id": suggestion_id,
        "modified_content": modified_content,
        "user_id": user_id,
        "timestamp": datetime.now().isoformat()
    }) 