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
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

# main_local.pyからappをインポート
# テスト実行前に、PYTHONPATHがプロジェクトルートに設定されていることを想定
from app.main_local import app
from app.services.newsletter_service import get_newsletter_service, NewsletterService
from app.models.adk_models import (
    NewsletterGenerationResponse,
    HTMLValidationResponse
)

# TestClientをインスタンス化
client = TestClient(app)


# モックの設定
@pytest.fixture
def mock_newsletter_service():
    """NewsletterServiceのモックを生成するpytestフィクスチャ"""
    mock_service = MagicMock(spec=NewsletterService)
    
    # generate_newsletterのモック設定
    mock_service.generate_newsletter.return_value = NewsletterGenerationResponse(
        session_id="test-session-generate",
        status="completed",
        html_content="<!DOCTYPE html><html><body><h1>Test</h1></body></html>",
    )

    # validate_htmlのモック設定
    mock_service.validate_html.return_value = HTMLValidationResponse(
        session_id="test-session-validate",
        overall_score=95,
        grade="A",
        summary="Excellent quality.",
        structure={"score": 100, "issues": [], "recommendations": []},
        accessibility={"score": 90, "issues": [], "recommendations": []},
        performance={"score": 95, "issues": [], "recommendations": []},
        seo={"score": 98, "issues": [], "recommendations": []},
        printing={"score": 92, "issues": [], "recommendations": []},
        priority_actions=[],
        compliance_status={"wcag_aa": True},
    )
    return mock_service


@pytest.fixture(autouse=True)
def override_get_newsletter_service(mock_newsletter_service):
    """
    FastAPIの依存性注入をオーバーライドし、常にモックサービスを返すようにする
    autouse=Trueにより、このモジュールの全テストで自動的に適用される
    """
    app.dependency_overrides[get_newsletter_service] = lambda: mock_newsletter_service
    yield
    # テスト終了後にオーバーライドをクリア
    app.dependency_overrides.clear()


# --- テストケース ---

def test_generate_newsletter_endpoint(mock_newsletter_service: MagicMock):
    """
    POST /api/v1/adk/generate エンドポイントのテスト
    """
    # テスト用のリクエストボディ
    request_data = {
        "initial_request": "今月の学級通信を作ってください",
        "user_id": "test-user-123"
    }
    
    # エンドポイントを叩く
    response = client.post("/api/v1/adk/generate", json=request_data)
    
    # アサーション
    assert response.status_code == 200, f"Expected 200 OK, but got {response.status_code}"
    
    # サービスが正しい引数で1回呼び出されたことを確認
    mock_newsletter_service.generate_newsletter.assert_called_once()
    
    # レスポンスボディの検証
    response_json = response.json()
    assert response_json["session_id"] == "test-session-generate"
    assert response_json["status"] == "completed"
    assert "Test" in response_json["html_content"]


def test_validate_html_endpoint(mock_newsletter_service: MagicMock):
    """
    POST /api/v1/adk/validate エンドポイントのテスト
    """
    # テスト用のリクエストボディ
    request_data = {
        "html_content": "<p>This is a test.</p>",
        "user_id": "test-user-456"
    }
    
    # エンドポイントを叩く
    response = client.post("/api/v1/adk/validate", json=request_data)
    
    # アサーション
    assert response.status_code == 200
    
    # サービスが正しい引数で1回呼び出されたことを確認
    mock_newsletter_service.validate_html.assert_called_once()
    
    # レスポンスボディの検証
    response_json = response.json()
    assert response_json["session_id"] == "test-session-validate"
    assert response_json["overall_score"] == 95
    assert response_json["grade"] == "A"


def test_deprecated_chat_endpoint():
    """
    POST /api/v1/adk/chat が非推奨として正しく機能することを確認するテスト
    """
    response = client.post("/api/v1/adk/chat", json={})
    assert response.status_code == 410 # Gone
    assert "deprecated" in response.json()["detail"] 