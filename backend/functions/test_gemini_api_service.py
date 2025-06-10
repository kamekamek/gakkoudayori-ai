"""
Gemini API基盤テスト

T3-AI-002-A: Gemini API基盤実装
- Gemini API クライアント実装
- 基本リクエスト・レスポンス処理
- エラーハンドリング実装
- API接続テスト通過
"""

import pytest
import os
import json
from unittest.mock import Mock, patch, MagicMock
from typing import Dict, Any, Optional

# テスト対象のモジュールをインポート
try:
    from gemini_api_service import (
        get_gemini_client,
        generate_text,
        generate_text_with_context,
        check_gemini_connection,
        handle_gemini_error
    )
except ImportError:
    # まだ実装されていない場合のダミー関数
    def get_gemini_client(*args, **kwargs):
        return None
    
    def generate_text(*args, **kwargs):
        return {"error": "Not implemented"}
    
    def generate_text_with_context(*args, **kwargs):
        return {"error": "Not implemented"}
    
    def handle_gemini_error(*args, **kwargs):
        return {"error": "Not implemented", "type": "GENERAL_ERROR"}


class TestGeminiClient:
    """Gemini APIクライアントテストクラス"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        # テスト用のパス（実際のファイルは必要ない）
        self.credentials_path = "./test_credentials.json"
        self.project_id = "yutori-kyoshitu-ai"
        self.model_name = "gemini-1.5-pro"
        self.location = "us-central1"

    def test_get_gemini_client_success(self):
        """Gemini APIクライアント取得成功テスト"""
        client = get_gemini_client(
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            model_name=self.model_name,
            location=self.location
        )
        
        # クライアントが正しく初期化されていることを確認
        assert client is not None
        # クラスの型をチェックするなど、より具体的なアサーションは実装によって変わる

    def test_get_gemini_client_invalid_credentials(self):
        """Gemini APIクライアント取得失敗テスト（無効な認証情報）"""
        client = get_gemini_client(
            project_id=self.project_id,
            credentials_path="invalid/path/to/credentials.json",
            model_name=self.model_name,
            location=self.location
        )
        
        # 無効な認証情報でクライアントが取得できないことを確認
        assert client is None


class TestGeminiTextGeneration:
    """Gemini APIテキスト生成テストクラス"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        # テスト用のパス（実際のファイルは必要ない）
        self.credentials_path = "./test_credentials.json"
        self.project_id = "yutori-kyoshitu-ai"
        self.model_name = "gemini-1.5-pro"
        self.location = "us-central1"
        
        # モックレスポンス用のサンプル
        self.sample_response = {
            "text": "これはGeminiからのサンプルレスポンスです。",
            "usage": {
                "promptTokenCount": 10,
                "candidatesTokenCount": 15,
                "totalTokenCount": 25
            }
        }

    @patch('gemini_api_service.get_gemini_client')
    def test_generate_text_success(self, mock_get_client):
        """テキスト生成成功テスト"""
        # モックの設定
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = self.sample_response["text"]
        mock_response.usage.prompt_token_count = self.sample_response["usage"]["promptTokenCount"]
        mock_response.usage.candidates_token_count = self.sample_response["usage"]["candidatesTokenCount"]
        mock_response.usage.total_token_count = self.sample_response["usage"]["totalTokenCount"]
        
        mock_client.generate_content.return_value = mock_response
        mock_get_client.return_value = mock_client
        
        # テキスト生成をテスト
        result = generate_text(
            "こんにちは、Gemini。",
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            model_name=self.model_name
        )
        
        # 結果の検証
        assert result is not None
        assert "text" in result
        assert "usage" in result
        assert result["text"] == self.sample_response["text"]
        assert result["usage"]["totalTokenCount"] == self.sample_response["usage"]["totalTokenCount"]

    @patch('gemini_api_service.get_gemini_client')
    def test_generate_text_with_context(self, mock_get_client):
        """コンテキスト付きテキスト生成テスト"""
        # モックの設定
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = self.sample_response["text"]
        mock_response.usage.prompt_token_count = self.sample_response["usage"]["promptTokenCount"]
        mock_response.usage.candidates_token_count = self.sample_response["usage"]["candidatesTokenCount"]
        mock_response.usage.total_token_count = self.sample_response["usage"]["totalTokenCount"]
        
        mock_client.generate_content.return_value = mock_response
        mock_get_client.return_value = mock_client
        
        # コンテキストの準備
        context = [
            {"role": "user", "content": "こんにちは"},
            {"role": "assistant", "content": "こんにちは、どうしましたか？"}
        ]
        
        # テキスト生成をテスト
        result = generate_text_with_context(
            "学校だよりについて教えて",
            context=context,
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            model_name=self.model_name
        )
        
        # 結果の検証
        assert result is not None
        assert "text" in result
        assert "usage" in result
        assert "context" in result  # 更新されたコンテキストが含まれていることを確認

    def test_generate_text_error(self):
        """テキスト生成エラーテスト"""
        # 無効な認証情報でテスト
        result = generate_text(
            "こんにちは、Gemini。",
            project_id=self.project_id,
            credentials_path="invalid/path/to/credentials.json",
            model_name=self.model_name
        )
        
        # エラー時の結果確認
        assert result is not None
        assert "error" in result
        assert "text" not in result


class TestGeminiConnection:
    """Gemini API接続テストクラス"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        # テスト用のパス（実際のファイルは必要ない）
        self.credentials_path = "./test_credentials.json"
        self.project_id = "yutori-kyoshitu-ai"
        self.model_name = "gemini-1.5-pro"
        self.location = "us-central1"

    @patch('gemini_api_service.get_gemini_client')
    def test_gemini_connection_success(self, mock_get_client):
        """Gemini API接続テスト成功"""
        # モックの設定
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.text = "Hello, test connection"
        mock_client.generate_content.return_value = mock_response
        mock_get_client.return_value = mock_client
        
        result = check_gemini_connection(
            project_id=self.project_id,
            credentials_path=self.credentials_path,
            model_name=self.model_name,
            location=self.location
        )
        
        # 接続テスト結果の確認
        assert result is not None
        assert "success" in result
        assert result["success"] is True
        assert "model_info" in result
        assert "response_time" in result

    @patch('gemini_api_service.get_gemini_client')
    def test_gemini_connection_failure(self, mock_get_client):
        """Gemini API接続テスト失敗"""
        # クライアントがNoneを返すようにモック設定
        mock_get_client.return_value = None
        
        result = check_gemini_connection(
            project_id=self.project_id,
            credentials_path="invalid/path/to/credentials.json",
            model_name=self.model_name,
            location=self.location
        )
        
        # 失敗時の結果確認
        assert result is not None
        assert "success" in result
        assert result["success"] is False
        assert "error" in result
        assert "response_time" in result


class TestGeminiErrorHandling:
    """Gemini APIエラーハンドリングテストクラス"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        pass

    def test_handle_quota_exceeded_error(self):
        """クォータ超過エラーハンドリングテスト"""
        error_msg = "Quota exceeded for quota metric 'gemini-api-requests'"
        error = Exception(error_msg)
        
        result = handle_gemini_error(error)
        
        assert result is not None
        assert "error" in result
        assert "type" in result
        assert result["type"] == "QUOTA_EXCEEDED"
        assert error_msg in result["error"]

    def test_handle_permission_denied_error(self):
        """権限不足エラーハンドリングテスト"""
        error_msg = "Permission denied"
        error = Exception(error_msg)
        
        result = handle_gemini_error(error)
        
        assert result is not None
        assert "error" in result
        assert "type" in result
        assert result["type"] == "PERMISSION_DENIED"
        assert error_msg in result["error"]

    def test_handle_model_not_found_error(self):
        """モデル未発見エラーハンドリングテスト"""
        error_msg = "Model not found: gemini-1.5-pro"
        error = Exception(error_msg)
        
        result = handle_gemini_error(error)
        
        assert result is not None
        assert "error" in result
        assert "type" in result
        assert result["type"] == "MODEL_NOT_FOUND"
        assert error_msg in result["error"]

    def test_handle_general_error(self):
        """一般エラーハンドリングテスト"""
        error_msg = "Unknown error occurred"
        error = Exception(error_msg)
        
        result = handle_gemini_error(error)
        
        assert result is not None
        assert "error" in result
        assert "type" in result
        assert result["type"] == "GENERAL_ERROR"
        assert error_msg in result["error"]


if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v"])
