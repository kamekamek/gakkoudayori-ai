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

from typing import Optional, List, Dict, Any, Literal
from pydantic import BaseModel, Field
from datetime import datetime


class ChatMessage(BaseModel):
    """チャットメッセージモデル"""
    role: Literal["user", "assistant", "system"] = Field(..., description="メッセージの送信者")
    content: str = Field(..., description="メッセージ内容")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="メッセージのタイムスタンプ")


class ChatRequest(BaseModel):
    """エージェントへのチャットリクエスト"""
    message: str = Field(..., description="ユーザーからのメッセージ")
    session_id: Optional[str] = Field(None, description="セッションID（継続的な会話用）")
    user_id: str = Field(..., description="ユーザーID")
    metadata: Optional[Dict[str, Any]] = Field(None, description="追加のメタデータ")


class ChatResponse(BaseModel):
    """エージェントからのチャットレスポンス"""
    message: str = Field(..., description="エージェントからの応答")
    session_id: str = Field(..., description="セッションID")
    event_type: Literal["message", "thinking", "tool_use", "error", "complete"] = Field(
        "message", description="イベントタイプ"
    )
    metadata: Optional[Dict[str, Any]] = Field(None, description="追加のメタデータ")
    html_output: Optional[str] = Field(None, description="生成されたHTML（最終出力の場合）")


class SessionInfo(BaseModel):
    """セッション情報モデル"""
    session_id: str = Field(..., description="セッションID")
    user_id: str = Field(..., description="ユーザーID")
    created_at: datetime = Field(..., description="セッション作成日時")
    updated_at: datetime = Field(..., description="最終更新日時")
    messages: List[ChatMessage] = Field(default_factory=list, description="メッセージ履歴")
    status: Literal["active", "completed", "error"] = Field("active", description="セッションステータス")
    agent_state: Optional[Dict[str, Any]] = Field(None, description="エージェントの内部状態")


class ErrorResponse(BaseModel):
    """エラーレスポンスモデル"""
    error: str = Field(..., description="エラータイプ")
    message: str = Field(..., description="エラーメッセージ")
    details: Optional[Dict[str, Any]] = Field(None, description="詳細なエラー情報")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="エラー発生時刻")


class AgentEvent(BaseModel):
    """エージェントイベントモデル（WebSocket用）"""
    event_id: str = Field(..., description="イベントID")
    event_type: Literal[
        "agent_started", "agent_thinking", "tool_called", "tool_result", 
        "message", "error", "complete"
    ] = Field(..., description="イベントタイプ")
    data: Dict[str, Any] = Field(..., description="イベントデータ")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="イベント発生時刻")


class NewsletterGenerationRequest(BaseModel):
    """学級通信生成リクエスト"""
    initial_request: str = Field(..., description="初期リクエスト（学級通信を作りたいなど）")
    user_id: str = Field(..., description="ユーザーID")
    session_id: Optional[str] = Field(None, description="既存のセッションID")


class NewsletterGenerationResponse(BaseModel):
    """学級通信生成レスポンス"""
    session_id: str = Field(..., description="セッションID")
    status: Literal["in_progress", "completed", "error"] = Field(..., description="生成ステータス")
    html_content: Optional[str] = Field(None, description="生成されたHTML")
    json_structure: Optional[Dict[str, Any]] = Field(None, description="中間のJSON構造")
    messages: List[ChatMessage] = Field(default_factory=list, description="会話履歴")