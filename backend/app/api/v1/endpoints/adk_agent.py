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
from typing import Optional, AsyncGenerator, Any
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


async def consume_agent_events(events: AsyncGenerator[Any, None]):
    """非同期ジェネレータを消費するためのヘルパー関数"""
    async for _ in events:
        # イベントを消費するだけで、ここでは何もしない
        pass

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
async def generate_newsletter(request: NewsletterGenerationRequest, http_request: Request) -> NewsletterGenerationResponse:
    """学級通信の生成プロセスを開始し、セッションIDを返すエンドポイント。"""
    runner: Runner = getattr(http_request.app.state, 'adk_runner', None)
    if not runner:
        raise HTTPException(status_code=503, detail="ADK Runner is not available.")

    session_id = request.session_id or str(uuid.uuid4())
    user_id = request.user_id
    session_service = get_session_service()

    try:
        # セッションが存在するか確認し、なければ作成する
        session = await session_service.get_session(session_id=session_id, user_id=user_id, app_name=runner.app_name)
        if not session:
            await session_service.create_session(
                session_id=session_id,
                user_id=user_id,
                app_name=runner.app_name
            )

        # エージェントの実行をバックグラウンドで開始する
        events_generator = runner.run_async(
            session_id=session_id,
            user_id=user_id,
            new_message=genai_types.Content(parts=[genai_types.Part(text=request.initial_request)]),
        )
        asyncio.create_task(consume_agent_events(events_generator))

        # すぐにセッションIDと処理中ステータスを返す
        return NewsletterGenerationResponse(
            session_id=session_id,
            status="in_progress",
            html_content=None,
            json_structure=None,
            messages=[ChatMessage(role="user", content=request.initial_request)]
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

@router.post("/chat/stream", summary="ADKエージェントとストリーミングチャット")
async def chat_stream(request: ChatRequest, http_request: Request):
    """
    Server-Sent Events (SSE) を使用して、ADKエージェントからの応答をストリーミングします。
    """
    runner: Runner = getattr(http_request.app.state, 'adk_runner', None)
    if not runner:
        logger.error("ADK Runner not found in app state.")
        raise HTTPException(status_code=503, detail="ADK Runner is not available.")

    session_id = request.session_id or str(uuid.uuid4())
    user_id = request.user_id or "default_user"
    logger.info(f"Received chat stream request for session: {session_id}, user: {user_id}")


    async def event_generator():
        """SSEイベントを生成するジェネレータ"""
        logger.info(f"Starting event generator for session: {session_id}")
        try:
            # ADK Runnerの非同期実行を開始
            message_content = genai_types.Content(parts=[genai_types.Part(text=request.message)])
            events_async = runner.run_async(
                session_id=session_id,
                user_id=user_id,
                new_message=message_content,
            )
            logger.info(f"ADK runner.run_async called for session: {session_id}")

            # イベントストリームをループし、クライアントに送信
            async for event in events_async:
                logger.debug(f"SSE Event for session {session_id}: {event}")
                if hasattr(event, "type") and event.type == "emit":
                    if hasattr(event, "data") and isinstance(event.data, dict):
                        # dataがJSONシリアライズ可能であることを確認
                        try:
                            json_data = json.dumps(event.data)
                            yield {
                                "event": "message",
                                "data": json_data
                            }
                            logger.debug(f"Sent event to client for session {session_id}: {json_data}")
                        except TypeError as e:
                            logger.error(f"Failed to serialize event data for SSE: {e} - data: {event.data}")

            logger.info(f"Event stream finished for session: {session_id}")

        except Exception as e:
            logger.error(f"Agent execution error in session {session_id}: {e}", exc_info=True)
            error_data = json.dumps({"type": "error", "message": str(e)})
            yield {
                "event": "error",
                "data": error_data
            }
        finally:
            logger.info(f"Closing event generator for session: {session_id}")


    return EventSourceResponse(event_generator())