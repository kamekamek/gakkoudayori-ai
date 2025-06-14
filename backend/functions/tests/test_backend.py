import pytest
import json
from unittest.mock import patch, MagicMock
import os
import sys

# プロジェクトのルートをシステムパスに追加
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# テスト対象のモジュールとアプリケーションをインポート
from main import app
import audio_to_json_service
import json_to_graphical_record_service

# テスト用のプロンプトディレクトリのパスを設定
TESTS_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_PROMPT_DIR = os.path.join(TESTS_DIR, "prompts")

# ==============================================================================
# モックオブジェクトの準備
# ==============================================================================

# speech-to-json用の完全なレスポンスを模倣するモック
MOCK_JSON_TEXT = json.dumps({
    "school_name": "Test School",
    "title": "Mocked Test",
    "date": "2025-01-01",
    "publisher": "Test Publisher",
    "target_audience": "Test Audience",
    "sections": []
})

# json-to-graphical-record用の完全なHTMLレスポンス
MOCK_HTML_TEXT = "<html><body><h1>API Test</h1></body></html>"

mock_gemini_response = MagicMock()
mock_gemini_response.text = MOCK_JSON_TEXT
mock_gemini_response.parts = [MagicMock()]
mock_gemini_response.parts[0].text = MOCK_JSON_TEXT

# Geminiクライアントのモック
mock_gemini_client = MagicMock()
mock_gemini_client.generate_content.return_value = mock_gemini_response

# テンプレート定義を返すモック
mock_templates = {
    "classic": {"description": "Test classic template"},
    "modern": {"description": "Test modern template"}
}

# ==============================================================================
# テストのセットアップとフィクスチャ
# ==============================================================================

@pytest.fixture
def client():
    """Flaskテストクライアントのフィクスチャ"""
    with app.test_client() as client:
        yield client

# ==============================================================================
# サービス層のユニットテスト
# ==============================================================================

@patch('gemini_api_service.get_gemini_client', return_value=mock_gemini_client)
@patch('audio_to_json_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_convert_speech_to_json_loads_correct_prompt(mock_get_client, *_):
    """
    audio_to_json_serviceがstyleに応じて正しいプロンプトを読み込むかテスト
    """
    audio_to_json_service.convert_speech_to_json(
        transcribed_text="テスト",
        project_id="test",
        credentials_path="test",
        style="classic"
    )
    mock_get_client.assert_called_once()
    called_prompt = mock_gemini_client.generate_content.call_args[0][0]
    assert "これはテスト用のクラシック添削プロンプトです。" in called_prompt

@patch('json_to_graphical_record_service.get_graphical_record_templates', return_value=mock_templates)
@patch('gemini_api_service.get_gemini_client', return_value=mock_gemini_client)
@patch('json_to_graphical_record_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_convert_json_to_graphical_record_loads_correct_prompt(mock_get_client, *_):
    """
    json_to_graphical_record_serviceがtemplateに応じて正しいプロンプトを読み込むかテスト
    """
    json_to_graphical_record_service.convert_json_to_graphical_record(
        json_data={"title": "Test"},
        project_id="test",
        credentials_path="test",
        template="classic"
    )
    mock_get_client.assert_called_once()
    called_prompt = mock_gemini_client.generate_content.call_args[0][0]
    assert "これはテスト用のクラシックレイアウトプロンプトです。" in called_prompt

@patch('json_to_graphical_record_service.get_graphical_record_templates', return_value=mock_templates)
@patch('gemini_api_service.get_gemini_client', return_value=mock_gemini_client)
@patch('json_to_graphical_record_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_json_to_graphical_record_fallback_to_classic(mock_get_client, *_):
    """
    未知のtemplateが指定された場合にclassicにフォールバックする機能のテスト
    """
    json_to_graphical_record_service.convert_json_to_graphical_record(
        json_data={"title": "Test"},
        project_id="test",
        credentials_path="test",
        template="unknown_template"
    )
    mock_get_client.assert_called_once()
    called_prompt = mock_gemini_client.generate_content.call_args[0][0]
    assert "これはテスト用のクラシックレイアウトプロンプトです。" in called_prompt

# ==============================================================================
# API（統合）テスト
# ==============================================================================

@patch('gemini_api_service.get_gemini_client', return_value=mock_gemini_client)
def test_speech_to_json_api(mock_get_client, client):
    """
    /api/v1/ai/speech-to-json エンドポイントのテスト
    """
    # APIからのレスポンスを完全なJSONに
    mock_gemini_response.text = MOCK_JSON_TEXT
    mock_gemini_response.parts[0].text = MOCK_JSON_TEXT
    mock_gemini_client.generate_content.return_value = mock_gemini_response

    response = client.post(
        '/api/v1/ai/speech-to-json',
        data=json.dumps({'transcribed_text': 'api test', 'style': 'classic'}),
        content_type='application/json'
    )
    
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success']
    assert json.loads(json_data['data']['text'])['title'] == 'Mocked Test'
    mock_get_client.assert_called_once()

@patch('json_to_graphical_record_service.get_graphical_record_templates', return_value=mock_templates)
@patch('gemini_api_service.get_gemini_client', return_value=mock_gemini_client)
def test_json_to_graphical_record_api(mock_get_client, mock_get_templates, client):
    """
    /api/v1/ai/json-to-graphical-record エンドポイントのテスト
    """
    mock_gemini_response.text = MOCK_HTML_TEXT
    mock_gemini_response.parts[0].text = MOCK_HTML_TEXT
    mock_gemini_client.generate_content.return_value = mock_gemini_response

    response = client.post(
        '/api/v1/ai/json-to-graphical-record',
        data=json.dumps({'json_data': {'title': 'test'}, 'template': 'classic'}),
        content_type='application/json'
    )
    
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success']
    assert json_data['data']['text'] == MOCK_HTML_TEXT
    mock_get_client.assert_called_once() 