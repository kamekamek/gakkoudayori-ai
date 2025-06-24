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
from typing import Optional, AsyncGenerator, Dict, Any
from datetime import datetime
import asyncio

from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect, Request
from fastapi.responses import StreamingResponse
from google.adk.sessions import Session as AdkSession
from google.genai import types as genai_types
from google.protobuf.json_format import MessageToDict
from google.cloud import firestore
# from google.generativeai.client import get_default_generative_client # 不要
# from google.generativeai.client import get_default_generative_async_client # 不要

# main.pyからapp_contextをインポート
# from main import app_context

from models.adk_models import (
    ChatRequest, ChatResponse, SessionInfo, ErrorResponse,
    NewsletterGenerationRequest, NewsletterGenerationResponse,
    AgentEvent, ChatMessage, HTMLValidationRequest, HTMLValidationResponse,
    ValidationResult
)
# services.adk_session_serviceはcore.dependencies経由で呼ばれるので直接は不要
from services.newsletter_generator import generate_newsletter_from_speech
# core.dependenciesから必要な関数をインポート
from core.dependencies import get_session_service, get_orchestrator_agent

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/chat", response_model=ChatResponse, summary="エージェントとチャット")
async def chat_with_agent(request: Request, chat_request: ChatRequest) -> ChatResponse:
    """エージェントとの対話を行うエンドポイント"""
    try:
        # セッションIDの生成または使用
        session_id = chat_request.session_id or str(uuid.uuid4())
        
        # request.app.stateからRunnerを取得
        runner = getattr(request.app.state, 'adk_runner', None)
        if not runner:
            raise HTTPException(status_code=503, detail="ADK Runner is not available. Please ensure the server is started with ADK support.")

        # ユーザーメッセージを作成
        user_message = genai_types.Content(
            role="user",
            parts=[genai_types.Part(text=chat_request.message)]
        )
        
        # エージェントを非同期実行
        events_async = runner.run_async(
            session_id=session_id,
            user_id=chat_request.user_id,
            new_message=user_message,
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


@router.websocket("/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: str):
    """WebSocketを使用したリアルタイムエージェント通信"""
    await websocket.accept()
    
    try:
        runner = getattr(websocket.app.state, 'adk_runner', None)
        if not runner:
            await websocket.send_json({"error": "ADK Runner is not available. Please ensure the server is started with ADK support."})
            await websocket.close()
            return
        
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
            user_message = genai_types.Content(
                role="user",
                parts=[genai_types.Part(text=message)]
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


@router.post("/validate", response_model=HTMLValidationResponse, summary="HTML品質検証")
async def validate_html(request: Request, validation_request: HTMLValidationRequest) -> HTMLValidationResponse:
    """HTMLコードの品質を検証し、改善提案を返すエンドポイント"""
    try:
        # セッションIDの生成または使用
        session_id = validation_request.session_id or str(uuid.uuid4())
        
        # request.app.stateからRunnerを取得
        runner = getattr(request.app.state, 'adk_runner', None)
        if not runner:
            raise HTTPException(status_code=503, detail="ADK Runner is not available. Please ensure the server is started with ADK support.")

        # 検証用メッセージを作成（HTMLコンテンツを含む）
        validation_message = f"以下のHTMLコードを検証してください:\n\n{validation_request.html_content}"
        
        user_message = genai_types.Content(
            role="user",
            parts=[genai_types.Part(text=validation_message)]
        )
        
        # エージェントを非同期実行
        events_async = runner.run_async(
            session_id=session_id,
            user_id=validation_request.user_id,
            new_message=user_message,
        )
        
        # イベントを収集
        response_text = ""
        validation_results = None
        
        async for event in events_async:
            logger.info(f"Validation event: {event}")
            
            # イベントの種類に応じて処理
            if hasattr(event, 'content') and event.content:
                # テキストコンテンツを抽出
                if hasattr(event.content, 'parts'):
                    for part in event.content.parts:
                        if hasattr(part, 'text'):
                            text = part.text
                            response_text += text
                            
                            # JSON形式の検証結果があるかチェック
                            try:
                                if '{' in text and '}' in text:
                                    # JSONの開始と終了を見つけて抽出を試行
                                    start_idx = text.find('{')
                                    end_idx = text.rfind('}') + 1
                                    if start_idx >= 0 and end_idx > start_idx:
                                        json_str = text[start_idx:end_idx]
                                        validation_data = json.loads(json_str)
                                        if 'overall_score' in validation_data:
                                            validation_results = validation_data
                            except (json.JSONDecodeError, KeyError):
                                # JSONパースに失敗した場合は無視
                                pass
        
        # レスポンスを構築
        if validation_results:
            # 検証結果からレスポンスモデルを構築
            return _build_validation_response(session_id, validation_results, response_text)
        else:
            # フォールバック：直接ツールを使って検証
            from adk.tools.html_validation_tool import validate_html_structure
            direct_results = validate_html_structure(validation_request.html_content)
            return _build_validation_response(session_id, direct_results, response_text)
        
    except Exception as e:
        logger.error(f"Error in validate_html: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


def _build_validation_response(session_id: str, validation_data: Dict[str, Any], response_text: str) -> HTMLValidationResponse:
    """検証データからレスポンスモデルを構築"""
    try:
        # グレードを計算
        score = validation_data.get('overall_score', 0)
        if score >= 90:
            grade = "A（優秀）"
        elif score >= 80:
            grade = "B（良好）"
        elif score >= 70:
            grade = "C（普通）"
        elif score >= 60:
            grade = "D（要改善）"
        else:
            grade = "F（要大幅改善）"
        
        # 各カテゴリの結果を構築
        def build_validation_result(category_data: Dict[str, Any]) -> ValidationResult:
            return ValidationResult(
                score=category_data.get('score', 0),
                issues=category_data.get('issues', []),
                recommendations=category_data.get('recommendations', [])
            )
        
        return HTMLValidationResponse(
            session_id=session_id,
            overall_score=score,
            grade=grade,
            summary=f"HTMLの総合スコアは{score}点です。{len(validation_data.get('recommendations', []))}個の改善点があります。",
            structure=build_validation_result(validation_data.get('structure', {})),
            accessibility=build_validation_result(validation_data.get('accessibility', {})),
            performance=build_validation_result(validation_data.get('performance', {})),
            seo=build_validation_result(validation_data.get('seo', {})),
            printing=build_validation_result(validation_data.get('printing', {})),
            priority_actions=validation_data.get('recommendations', [])[:5],
            compliance_status={
                "wcag_aa": validation_data.get('accessibility', {}).get('score', 0) >= 80,
                "print_ready": validation_data.get('printing', {}).get('score', 0) >= 70,
                "seo_optimized": validation_data.get('seo', {}).get('score', 0) >= 80,
                "performance_optimized": validation_data.get('performance', {}).get('score', 0) >= 80
            },
            detailed_report=response_text if response_text else None
        )
        
    except Exception as e:
        logger.error(f"Error building validation response: {e}")
        # フォールバックレスポンス
        return HTMLValidationResponse(
            session_id=session_id,
            overall_score=0,
            grade="F（検証エラー）",
            summary="検証処理中にエラーが発生しました。",
            structure=ValidationResult(score=0, issues=["検証エラー"], recommendations=[]),
            accessibility=ValidationResult(score=0, issues=["検証エラー"], recommendations=[]),
            performance=ValidationResult(score=0, issues=["検証エラー"], recommendations=[]),
            seo=ValidationResult(score=0, issues=["検証エラー"], recommendations=[]),
            printing=ValidationResult(score=0, issues=["検証エラー"], recommendations=[]),
            priority_actions=["検証処理の確認が必要です"],
            compliance_status={},
            detailed_report=response_text if response_text else str(e)
        )


@router.post("/chat/stream", summary="ストリーミングチャット")
async def chat_with_agent_stream(request: Request, chat_request: ChatRequest):
    """Server-Sent Eventsを使用したストリーミングチャット"""
    session_id = chat_request.session_id or str(uuid.uuid4())
    logger.info(f"[/chat/stream] New request. session_id: {session_id}, user_id: {chat_request.user_id}")
    logger.info(f"Message: {chat_request.message}")
    
    async def generate() -> AsyncGenerator[str, None]:
        try:
            # ADK Runnerの取得を安全に行う
            runner = getattr(request.app.state, 'adk_runner', None)
            if not runner:
                raise RuntimeError("ADK Runner is not initialized. Please ensure the server is started with ADK support.")

            # ユーザーメッセージを作成
            user_message = genai_types.Content(
                role="user",
                parts=[genai_types.Part(text=chat_request.message)]
            )
            
            # セッションが存在しない場合は事前に作成
            session_service = get_session_service()
            existing_session = await session_service.get_session(
                session_id=session_id,
                app_name="gakkoudayori-ai",
                user_id=chat_request.user_id
            )
            
            if not existing_session:
                logger.info(f"Creating new session: {session_id}")
                await session_service.create_session(
                    session_id=session_id,
                    app_name="gakkoudayori-ai",
                    user_id=chat_request.user_id,
                    state={}
                )
            
            # ADK Runnerはセッションサービスを通じてセッションを自動的に管理します。
            events_async = runner.run_async(
                session_id=session_id,
                user_id=chat_request.user_id,
                new_message=user_message,
            )
            
            # イベントをストリーミング
            html_buffer = ""
            async for event in events_async:
                logger.debug(f"ADK Event received: {event}")

                # イベントの内容を解析
                if event and event.content and event.content.parts:
                    for part in event.content.parts:
                        logger.debug(f"Processing part: {part}")
                        
                        # part.textが存在し、Noneでないことを確認
                        if part.text:
                            # HTMLコンテンツの処理
                            if part.text.strip().startswith('<!DOCTYPE html>') or html_buffer:
                                html_buffer += part.text
                                if '</html>' in html_buffer:
                                    logger.info("Detected complete HTML content.")
                                    yield f"data: {json.dumps({'session_id': session_id, 'type': 'complete', 'data': html_buffer})}\n\n"
                                    html_buffer = ""
                            # 通常のテキストストリーム
                            else:
                                logger.debug(f"Streaming text part: {part.text}")
                                yield f"data: {json.dumps({'session_id': session_id, 'type': 'text', 'data': part.text})}\n\n"
                        # ツール呼び出しなど、テキスト以外のパートをログに出力
                        else:
                            logger.info(f"Received non-text part: {part}")

        except Exception as e:
            logger.error(f"Streaming error: {e}", exc_info=True)
            error_data = {
                "session_id": session_id,
                "type": "error",
                "data": str(e)
            }
            logger.error(f"Sending SSE error: {error_data}")
            yield f"data: {json.dumps(error_data)}\n\n"
    
    # BodyとRequestを両方受け取るため、リクエストモデルを手動で注入
    # StreamingResponseのコンストラクタ内で直接リクエストボディを扱うことはできない
    return StreamingResponse(generate(), media_type="text/event-stream")