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
from fastapi import APIRouter, Depends, HTTPException, WebSocket

from app.models.adk_models import (
    NewsletterGenerationRequest,
    NewsletterGenerationResponse,
    HTMLValidationRequest,
    HTMLValidationResponse,
)
from app.services.newsletter_service import (
    NewsletterService,
    get_newsletter_service,
)

logger = logging.getLogger(__name__)
router = APIRouter()


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