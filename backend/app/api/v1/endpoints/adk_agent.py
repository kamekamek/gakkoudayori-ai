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

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect, Request
from fastapi.responses import StreamingResponse
from google.adk.sessions import Session as AdkSession
from google.genai import types as genai_types
from google.protobuf.json_format import MessageToDict
from google.cloud import firestore
from sse_starlette.sse import EventSourceResponse
from google.adk.runners import Runner
# from google.generativeai.client import get_default_generative_client # 不要
# from google.generativeai.client import get_default_generative_async_client # 不要

# main.pyからapp_contextをインポート
# from main import app_context

from models.adk_models import (
    ChatRequest, ChatResponse, SessionInfo, ErrorResponse,
    NewsletterGenerationRequest, NewsletterGenerationResponse,
    AgentEvent, ChatMessage
)
# services.adk_session_serviceはcore.dependencies経由で呼ばれるので直接は不要
from services.newsletter_generator import generate_newsletter_from_speech
# core.dependenciesから必要な関数をインポート
from core.dependencies import get_session_service, get_orchestrator_agent

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str, user_id: str = "default_user"):
    """
    WebSocketを使用してエージェントとリアルタイムで双方向通信を行います。
    接続が確立されると、クライアントはJSONメッセージを送信してエージェントと対話でき、
    エージェントからのイベント（HTML、監査結果など）をリアルタイムで受信します。
    """
    await websocket.accept()
    runner: Runner = getattr(websocket.app.state, 'adk_runner', None)

    if not runner:
        await websocket.send_json({"type": "error", "message": "ADK Runner is not available."})
        await websocket.close()
        return

    try:
        while True:
            # クライアントからのメッセージを待機
            received_data = await websocket.receive_text()
            data = json.loads(received_data)
            message = data.get("message")

            if not message:
                await websocket.send_json({"type": "error", "message": "'message' field is required."})
                continue

            try:
                # ADK Runnerの非同期実行を開始
                events_async = runner.run_async(
                    session_id=session_id,
                    user_id=user_id,
                    input=message,
                )

                # イベントストリームをループし、クライアントに送信
                async for event in events_async:
                    logger.debug(f"Event for session {session_id}: {event}")

                    if hasattr(event, "type") and event.type == "emit":
                        if hasattr(event, "data") and isinstance(event.data, dict):
                            await websocket.send_json(event.data)

            except Exception as e:
                logger.error(f"Agent execution error in session {session_id}: {e}", exc_info=True)
                await websocket.send_json({"type": "error", "message": str(e)})

    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for session {session_id}")
    except Exception as e:
        logger.error(f"Unexpected error in WebSocket endpoint for session {session_id}: {e}", exc_info=True)
        try:
            # クライアントにエラーを通知しようと試みる
            await websocket.send_json({"type": "error", "message": "An unexpected server error occurred."})
        except Exception:
            pass # すでに接続が切れている場合は何もしない
        finally:
            await websocket.close()


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
        session = await session_service.get_session(session_id)
        
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
        
        # sessionオブジェクトがPydanticモデルであることを想定
        metadata = session.metadata or {}
        return SessionInfo(
            session_id=session_id,
            user_id=metadata.get('user_id', ''),
            created_at=metadata.get('created_at', datetime.utcnow()),
            updated_at=metadata.get('updated_at', datetime.utcnow()),
            messages=messages,
            status=metadata.get('status', 'active'),
            agent_state=metadata.get('agent_state')
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
        await session_service.delete_session(session_id)
        return {"message": "Session deleted successfully"}
        
    except Exception as e:
        logger.error(f"Error in delete_session: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))