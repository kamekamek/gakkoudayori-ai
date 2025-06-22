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
import json
from typing import Optional, AsyncGenerator
from datetime import datetime
import asyncio

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.responses import StreamingResponse
from google.adk.runners import Runner
from google.adk.sessions import Session as AdkSession
from google.generativeai import types
from google.protobuf.json_format import MessageToDict
from google.cloud import firestore
from google.generativeai.client import get_default_generative_client
from google.generativeai.client import get_default_generative_async_client

from models.adk_models import (
    ChatRequest, ChatResponse, SessionInfo, ErrorResponse,
    NewsletterGenerationRequest, NewsletterGenerationResponse,
    AgentEvent, ChatMessage
)
from services.adk_session_service import FirestoreSessionService
from services.firebase_service import get_firestore_client
from services.newsletter_generator import generate_newsletter_from_speech

logger = logging.getLogger(__name__)

router = APIRouter()

# グローバル変数として保持
_orchestrator_agent = None
_session_service = None
_runner = None


def get_orchestrator_agent():
    """OrchestratorAgentをセットアップして返す"""
    from adk.agents.orchestrator_agent import create_orchestrator_agent
    global _orchestrator_agent
    if _orchestrator_agent is None:
        _orchestrator_agent = create_orchestrator_agent()
    return _orchestrator_agent


def get_session_service() -> FirestoreSessionService:
    """セッションサービスのシングルトンを取得"""
    global _session_service
    if _session_service is None:
        firestore_client = get_firestore_client()
        _session_service = FirestoreSessionService(firestore_client)
    return _session_service


def get_runner() -> Runner:
    """ADK Runnerのシングルトンを取得"""
    global _runner
    if _runner is None:
        _runner = Runner(
            app_name="gakkoudayori-ai",
            agent=get_orchestrator_agent(),
            session_service=get_session_service()
        )
    return _runner


@router.post("/chat", response_model=ChatResponse, summary="エージェントとチャット")
async def chat_with_agent(request: ChatRequest) -> ChatResponse:
    """エージェントとの対話を行うエンドポイント"""
    try:
        # セッションIDの生成または使用
        session_id = request.session_id or str(uuid.uuid4())
        
        # ランナーを取得
        runner = get_runner()
        
        # ユーザーメッセージを作成
        user_message = types.Content(
            role="user",
            parts=[types.Part(text=request.message)]
        )
        
        # エージェントを非同期実行
        events_async = runner.run_async(
            session_id=session_id,
            user_id=request.user_id,
            new_message=user_message,
            metadata=request.metadata
        )
        
        # イベントを収集
        response_text = ""
        html_output = None
        event_type = "message"
        
        async for event in events_async:
            logger.info(f"Received event: {event}")
            
            # イベントの種類に応じて処理
            if hasattr(event, 'content') and event.content:
                # テキストコンテンツを抽出
                if hasattr(event.content, 'parts'):
                    for part in event.content.parts:
                        if hasattr(part, 'text'):
                            text = part.text
                            response_text += text
                            
                            # HTMLコンテンツかチェック
                            if text.strip().startswith('<!DOCTYPE html>'):
                                html_output = text
                                event_type = "complete"
            
            elif hasattr(event, 'error'):
                event_type = "error"
                response_text = str(event.error)
        
        return ChatResponse(
            message=response_text,
            session_id=session_id,
            event_type=event_type,
            html_output=html_output,
            metadata={"timestamp": datetime.utcnow().isoformat()}
        )
        
    except Exception as e:
        logger.error(f"Error in chat_with_agent: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/generate_newsletter", response_model=NewsletterGenerationResponse, summary="学級通信を生成")
async def generate_newsletter(request: NewsletterGenerationRequest) -> NewsletterGenerationResponse:
    """学級通信を生成するエンドポイント"""
    try:
        # 関数を直接呼び出す
        result = await asyncio.to_thread(
            generate_newsletter_from_speech,
            speech_text=request.speech_text,
            template_type=request.template_type,
            include_greeting=request.include_greeting,
            target_audience=request.target_audience,
            season=request.season
        )

        if result.get('success'):
            return NewsletterGenerationResponse(
                success=True,
                data=result.get('data')
            )
        else:
            raise HTTPException(
                status_code=500,
                detail=f"ニュースレターの生成に失敗しました: {result.get('error')}"
            )

    except Exception as e:
        logger.exception(f"ニュースレター生成中に予期せぬエラーが発生: {e}")
        raise HTTPException(status_code=500, detail=f"サーバー内部エラー: {str(e)}")


@router.get("/sessions/{session_id}", response_model=SessionInfo, summary="セッション情報を取得")
async def get_session(session_id: str) -> SessionInfo:
    """セッション情報を取得するエンドポイント"""
    try:
        session_service = get_session_service()
        session = await session_service.get(session_id)
        
        if not session:
            raise HTTPException(status_code=404, detail="Session not found")
        
        # SessionInfoに変換
        messages = []
        if hasattr(session, 'history'):
            for item in session.history:
                messages.append(ChatMessage(
                    role=item.get('role', 'assistant'),
                    content=str(item.get('content', '')),
                    timestamp=datetime.utcnow()
                ))
        
        return SessionInfo(
            session_id=session_id,
            user_id=session.metadata.get('user_id', ''),
            created_at=session.metadata.get('created_at', datetime.utcnow()),
            updated_at=session.metadata.get('updated_at', datetime.utcnow()),
            messages=messages,
            status=session.metadata.get('status', 'active'),
            agent_state=session.metadata.get('agent_state')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_session: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/sessions/{session_id}", summary="セッションを削除")
async def delete_session(session_id: str):
    """セッションを削除するエンドポイント"""
    try:
        session_service = get_session_service()
        await session_service.delete(session_id)
        return {"message": "Session deleted successfully"}
        
    except Exception as e:
        logger.error(f"Error in delete_session: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.websocket("/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    """WebSocketを使用したリアルタイムエージェント通信"""
    await websocket.accept()
    
    try:
        runner = get_runner()
        
        while True:
            # クライアントからメッセージを受信
            data = await websocket.receive_json()
            user_id = data.get('user_id')
            message = data.get('message')
            
            if not user_id or not message:
                await websocket.send_json({
                    "error": "user_id and message are required"
                })
                continue
            
            # ユーザーメッセージを作成
            user_message = types.Content(
                role="user",
                parts=[types.Part(text=message)]
            )
            
            # エージェントを非同期実行
            events_async = runner.run_async(
                session_id=session_id,
                user_id=user_id,
                new_message=user_message
            )
            
            # イベントをストリーミング
            async for event in events_async:
                event_data = {
                    "event_id": str(uuid.uuid4()),
                    "event_type": "message",
                    "data": {},
                    "timestamp": datetime.utcnow().isoformat()
                }
                
                # イベントの内容を解析
                if hasattr(event, 'content') and event.content:
                    if hasattr(event.content, 'parts'):
                        text_parts = []
                        for part in event.content.parts:
                            if hasattr(part, 'text'):
                                text_parts.append(part.text)
                        
                        if text_parts:
                            full_text = '\n'.join(text_parts)
                            event_data['data']['content'] = full_text
                            
                            # HTMLかチェック
                            if full_text.strip().startswith('<!DOCTYPE html>'):
                                event_data['event_type'] = 'complete'
                                event_data['data']['html'] = full_text
                
                elif hasattr(event, 'tool_calls'):
                    event_data['event_type'] = 'tool_called'
                    event_data['data']['tools'] = str(event.tool_calls)
                
                elif hasattr(event, 'error'):
                    event_data['event_type'] = 'error'
                    event_data['data']['error'] = str(event.error)
                
                # クライアントに送信
                await websocket.send_json(event_data)
                
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for session {session_id}")
    except Exception as e:
        logger.error(f"WebSocket error: {e}", exc_info=True)
        await websocket.send_json({
            "event_type": "error",
            "data": {"error": str(e)},
            "timestamp": datetime.utcnow().isoformat()
        })
        await websocket.close()


@router.post("/chat/stream", summary="ストリーミングチャット")
async def chat_with_agent_stream(request: ChatRequest):
    """Server-Sent Eventsを使用したストリーミングチャット"""
    session_id = request.session_id or str(uuid.uuid4())
    logger.info(f"[/chat/stream] New request. session_id: {session_id}, user_id: {request.user_id}")
    logger.info(f"Message: {request.message}")
    
    async def generate() -> AsyncGenerator[str, None]:
        try:
            runner = get_runner()

            # セッションを取得・更新
            session_service = get_session_service()
            session = await session_service.get(session_id)
            
            if session:
                logger.info(f"Session history before processing: {[MessageToDict(c._pb) for c in session.history]}")
                # メタデータを更新
                if request.metadata:
                    session.metadata.update(request.metadata)
                    await session_service.save(session)
            else:
                logger.info("No existing session found. Creating a new one.")
                # メタデータを持つ新しいセッションを作成
                session_metadata = request.metadata or {}
                session_metadata['user_id'] = request.user_id # ユーザーIDをメタデータに含める

                session = AdkSession( # エイリアスを使ってインスタンス化
                    session_id=session_id,
                    metadata=session_metadata
                )
                await session_service.save(session)

            # ユーザーメッセージを作成
            user_message = types.Content(
                role="user",
                parts=[types.Part(text=request.message)]
            )
            
            # エージェントを非同期実行
            events_async = runner.run_async(
                session_id=session_id,
                user_id=request.user_id,
                new_message=user_message
            )
            
            # イベントをストリーミング
            async for event in events_async:
                logger.debug(f"ADK Event received: {event}")

                event_data = {
                    "session_id": session_id,
                    "type": "message",
                    "data": ""
                }
                
                # イベントの内容を解析
                if hasattr(event, 'content') and event.content:
                    if hasattr(event.content, 'parts'):
                        for part in event.content.parts:
                            if hasattr(part, 'text'):
                                event_data['data'] = part.text
                                
                                # HTMLかチェック
                                if part.text.strip().startswith('<!DOCTYPE html>'):
                                    event_data['type'] = 'complete'
                
                # SSE形式で送信
                logger.info(f"Sending SSE data: {event_data}")
                yield f"data: {json.dumps(event_data)}\n\n"
                
        except Exception as e:
            logger.error(f"Streaming error: {e}", exc_info=True)
            error_data = {
                "session_id": session_id,
                "type": "error",
                "data": str(e)
            }
            logger.error(f"Sending SSE error: {error_data}")
            yield f"data: {json.dumps(error_data)}\n\n"
    
    return StreamingResponse(generate(), media_type="text/event-stream")