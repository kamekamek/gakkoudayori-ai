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

import logging
from fastapi import APIRouter, Depends, HTTPException, WebSocket, Request

from models.adk_models import (
    NewsletterGenerationRequest,
    NewsletterGenerationResponse,
    HTMLValidationRequest,
    HTMLValidationResponse,
)
from services.newsletter_service import (
    NewsletterService,
    get_newsletter_service,
)

logger = logging.getLogger(__name__)
router = APIRouter()


from fastapi.responses import StreamingResponse, Response
from models.adk_models import AdkChatRequest, NewsletterGenerationRequest
from services.pdf_generator import generate_pdf_from_html_bytes
from google.genai import types
import json

@router.post("/generate/newsletter", summary="学級通信HTMLをPDFに変換")
async def generate_newsletter_pdf(req: Request):
    body = await req.json()
    html_content = body.get("html_content")
    if not html_content:
        raise HTTPException(status_code=400, detail="html_content is required")
    try:
        pdf_bytes = generate_pdf_from_html_bytes(html_content)
        return Response(content=pdf_bytes, media_type="application/pdf")
    except Exception as e:
        logger.exception(f"Error in generate_newsletter_pdf: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat/stream", summary="ADKチャットストリーミング")
async def adk_chat_stream(request: Request, body: AdkChatRequest):
    """ADK Runnerを使用してチャットストリームを処理します。"""
    runner = request.app.state.adk_runner
    try:
        # ADK Runnerの正しいAPIを使用
        async def generate_response():
            session_id = body.session_id or f"session_{body.user_id}"
            try:
                logger.info(f"Starting ADK chat stream for user {body.user_id}, session {session_id}")
                
                # ADK Runnerの正しいパラメータでイベントストリームを取得
                events = runner.run_async(
                    user_id=body.user_id,
                    session_id=session_id,
                    new_message=types.Content(parts=[types.Part(text=body.message)])
                )
                
                # イベントストリームを処理
                event_count = 0
                async for event in events:
                    event_count += 1
                    logger.info(f"Received event {event_count}: {type(event).__name__}")
                    
                    if hasattr(event, 'agent_content') and event.agent_content:
                        content = event.agent_content.parts[0].text if event.agent_content.parts else ""
                        response_data = {
                            'type': 'message',
                            'content': content,
                            'session_id': session_id
                        }
                        yield f"data: {json.dumps(response_data)}\n\n"
                        
                    elif hasattr(event, 'finish_reason'):
                        response_data = {
                            'type': 'done',
                            'session_id': session_id
                        }
                        yield f"data: {json.dumps(response_data)}\n\n"
                        break
                        
                # イベントがない場合のフォールバック
                if event_count == 0:
                    response_data = {
                        'type': 'message',
                        'content': 'こんにちは！何かお手伝いできることはありますか？',
                        'session_id': session_id
                    }
                    yield f"data: {json.dumps(response_data)}\n\n"
                    
                    response_data = {
                        'type': 'done',
                        'session_id': session_id
                    }
                    yield f"data: {json.dumps(response_data)}\n\n"
                        
            except Exception as e:
                logger.exception(f"Error in ADK stream: {e}")
                error_data = {
                    'type': 'error',
                    'content': f'エラーが発生しました: {str(e)}',
                    'session_id': session_id
                }
                yield f"data: {json.dumps(error_data)}\n\n"
        
        return StreamingResponse(
            generate_response(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
            }
        )
    except Exception as e:
        logger.exception(f"Error in adk_chat_stream: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/generate",
    response_model=NewsletterGenerationResponse,
    summary="学級通信の生成ワークフローを開始",
    description="ユーザーの初期リクエストに基づき、構成案の作成からHTMLの生成までを一貫して行います。",
)
def generate_newsletter(
    request: NewsletterGenerationRequest,
    service: NewsletterService = Depends(get_newsletter_service),
) -> NewsletterGenerationResponse:
    """
    学級通信の生成プロセスを開始します。
    Serviceレイヤーに処理を委譲し、最終的なHTMLコンテンツを含むレスポンスを返します。
    """
    try:
        return service.generate_newsletter(request)
    except Exception as e:
        logger.exception(f"Error in generate_newsletter: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post(
    "/validate",
    response_model=HTMLValidationResponse,
    summary="HTMLの品質を検証",
    description="提供されたHTMLコンテンツを多角的に分析し、品質レポートを返します。",
)
def validate_html(
    request: HTMLValidationRequest,
    service: NewsletterService = Depends(get_newsletter_service),
) -> HTMLValidationResponse:
    """
    HTMLの品質を検証します。
    Serviceレイヤーに処理を委譲し、検証結果のレポートを返します。
    """
    try:
        return service.validate_html(request)
    except Exception as e:
        logger.exception(f"Error in validate_html: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# -----------------------------------------------------------------------------
# Deprecated Endpoints
# -----------------------------------------------------------------------------
# 以下のエンドポイントは新しいアーキテクチャでは非推奨であり、将来的に削除されます。
# これらは下位互換性のために一時的に残されていますが、使用は推奨されません。
# -----------------------------------------------------------------------------

@router.post("/chat", deprecated=True, summary="[非推奨] 旧チャットエンドポイント")
async def chat_with_agent_deprecated():
    """このエンドポイントは非推奨です。`/generate` を使用してください。"""
    raise HTTPException(
        status_code=410,
        detail="This endpoint is deprecated. Please use /generate instead.",
    )


@router.websocket("/ws/{session_id}")
async def websocket_endpoint_deprecated(websocket: WebSocket, session_id: str):
    """このWebSocketエンドポイントは非推奨です。"""
    await websocket.accept()
    await websocket.close(
        code=1011,
        reason="This endpoint is deprecated and will be removed."
    )