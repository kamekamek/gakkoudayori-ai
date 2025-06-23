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

import pytest
import json
from unittest.mock import Mock, patch, AsyncMock
from fastapi.testclient import TestClient
from fastapi import FastAPI

from ..api.v1.endpoints.adk_agent import router as adk_router
from ..models.adk_models import ChatRequest, NewsletterGenerationRequest


# テスト用のFastAPIアプリを作成
app = FastAPI()
app.include_router(adk_router, prefix="/adk")


@pytest.fixture
def client():
    """テストクライアントを返す"""
    return TestClient(app)


@pytest.fixture
def mock_orchestrator_agent():
    """モックされたオーケストレーターエージェントを返す"""
    agent = Mock()
    agent.name = "test_orchestrator_agent"
    agent.description = "Test agent"
    return agent


@pytest.fixture
def mock_session_service():
    """モックされたセッションサービスを返す"""
    service = Mock()
    service.get = AsyncMock(return_value=None)
    service.save = AsyncMock()
    service.delete = AsyncMock()
    return service


@pytest.fixture
def mock_runner():
    """モックされたADKランナーを返す"""
    runner = Mock()
    
    # AsyncGeneratorのモック作成
    async def mock_run_async(*args, **kwargs):
        # テスト用のイベントを生成
        test_events = [
            Mock(content=Mock(parts=[Mock(text="こんにちは！")])),
            Mock(content=Mock(parts=[Mock(text="学級通信を作成します。")])),
            Mock(content=Mock(parts=[Mock(text="<!DOCTYPE html><html><body>Test HTML</body></html>")])),
        ]
        for event in test_events:
            yield event
    
    runner.run_async = AsyncMock(side_effect=mock_run_async)
    return runner


class TestAdkAgentEndpoints:
    """ADKエージェントエンドポイントのテスト"""
    
    @patch('api.v1.endpoints.adk_agent.get_runner')
    @patch('api.v1.endpoints.adk_agent.get_session_service')
    def test_chat_with_agent_success(self, mock_get_session_service, mock_get_runner, client, mock_runner, mock_session_service):
        """正常なチャットリクエストのテスト"""
        mock_get_runner.return_value = mock_runner
        mock_get_session_service.return_value = mock_session_service
        
        request_data = {
            "message": "学級通信を作りたいです",
            "user_id": "test_user_123"
        }
        
        response = client.post("/adk/chat", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "session_id" in data
        assert "event_type" in data
        assert data["event_type"] in ["message", "complete"]
    
    @patch('api.v1.endpoints.adk_agent.get_runner')
    @patch('api.v1.endpoints.adk_agent.get_session_service')
    def test_generate_newsletter_success(self, mock_get_session_service, mock_get_runner, client, mock_runner, mock_session_service):
        """学級通信生成リクエストのテスト"""
        mock_get_runner.return_value = mock_runner
        mock_get_session_service.return_value = mock_session_service
        
        # mock_session_service.get の戻り値を設定
        mock_session = Mock()
        mock_session.history = [
            {"role": "user", "content": "学級通信を作りたいです"},
            {"role": "assistant", "content": "承知いたしました！"}
        ]
        mock_session_service.get.return_value = mock_session
        
        request_data = {
            "initial_request": "運動会のお知らせの学級通信を作りたいです",
            "user_id": "test_user_123"
        }
        
        response = client.post("/adk/newsletter/generate", json=request_data)
        
        assert response.status_code == 200
        data = response.json()
        assert "session_id" in data
        assert "status" in data
        assert data["status"] in ["in_progress", "completed"]
        assert "messages" in data
    
    def test_chat_request_validation(self, client):
        """チャットリクエストのバリデーションテスト"""
        # 必須フィールドが不足している場合
        invalid_request = {
            "message": "test message"
            # user_id が不足
        }
        
        response = client.post("/adk/chat", json=invalid_request)
        assert response.status_code == 422  # Validation error
    
    def test_newsletter_request_validation(self, client):
        """学級通信生成リクエストのバリデーションテスト"""
        # 必須フィールドが不足している場合
        invalid_request = {
            "initial_request": "test request"
            # user_id が不足
        }
        
        response = client.post("/adk/newsletter/generate", json=invalid_request)
        assert response.status_code == 422  # Validation error
    
    @patch('api.v1.endpoints.adk_agent.get_session_service')
    def test_get_session_not_found(self, mock_get_session_service, client, mock_session_service):
        """存在しないセッションの取得テスト"""
        mock_get_session_service.return_value = mock_session_service
        mock_session_service.get.return_value = None
        
        response = client.get("/adk/sessions/nonexistent_session")
        assert response.status_code == 404
    
    @patch('api.v1.endpoints.adk_agent.get_session_service')
    def test_delete_session_success(self, mock_get_session_service, client, mock_session_service):
        """セッション削除の成功テスト"""
        mock_get_session_service.return_value = mock_session_service
        
        response = client.delete("/adk/sessions/test_session_123")
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "Session deleted successfully"
        
        # delete メソッドが呼ばれたことを確認
        mock_session_service.delete.assert_called_once_with("test_session_123")


class TestAdkModels:
    """ADKモデルのテスト"""
    
    def test_chat_request_model(self):
        """ChatRequestモデルのテスト"""
        valid_data = {
            "message": "テストメッセージ",
            "user_id": "test_user_123",
            "session_id": "test_session_456",
            "metadata": {"source": "test"}
        }
        
        request = ChatRequest(**valid_data)
        assert request.message == "テストメッセージ"
        assert request.user_id == "test_user_123"
        assert request.session_id == "test_session_456"
        assert request.metadata == {"source": "test"}
    
    def test_newsletter_generation_request_model(self):
        """NewsletterGenerationRequestモデルのテスト"""
        valid_data = {
            "initial_request": "運動会のお知らせを作りたいです",
            "user_id": "test_user_123"
        }
        
        request = NewsletterGenerationRequest(**valid_data)
        assert request.initial_request == "運動会のお知らせを作りたいです"
        assert request.user_id == "test_user_123"
        assert request.session_id is None  # Optional field
    
    def test_chat_request_missing_required_field(self):
        """必須フィールドが不足している場合のテスト"""
        invalid_data = {
            "message": "テストメッセージ"
            # user_id が不足
        }
        
        with pytest.raises(ValueError):
            ChatRequest(**invalid_data)


@pytest.mark.asyncio
class TestSessionService:
    """セッションサービスのテスト"""
    
    @patch('services.adk_session_service.firestore')
    async def test_session_creation_and_retrieval(self, mock_firestore):
        """セッションの作成と取得のテスト"""
        from ..services.adk_session_service import FirestoreSessionService
        
        # Firestoreクライアントのモック
        mock_client = Mock()
        mock_firestore.client.return_value = mock_client
        
        service = FirestoreSessionService(mock_client)
        
        # テスト用のセッションデータ
        session_data = {
            'session_id': 'test_session_123',
            'history': [],
            'metadata': {'user_id': 'test_user'}
        }
        
        # モックされたドキュメント
        mock_doc = Mock()
        mock_doc.exists = True
        mock_doc.to_dict.return_value = session_data
        
        mock_client.collection.return_value.document.return_value.get.return_value = mock_doc
        
        # セッションを取得
        session = await service.get('test_session_123')
        
        assert session is not None
        assert session.session_id == 'test_session_123'


if __name__ == "__main__":
    pytest.main([__file__])