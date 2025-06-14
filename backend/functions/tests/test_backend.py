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

@patch('gemini_api_service.generate_text')
@patch('audio_to_json_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_convert_speech_to_json_loads_correct_prompt(mock_generate_text):
    """
    audio_to_json_serviceがstyleに応じて正しいプロンプトを読み込むかテスト
    """
    mock_generate_text.return_value = {"success": True, "text": '{"title": "Test"}'}

    audio_to_json_service.convert_speech_to_json(
        transcribed_text="テスト",
        project_id="test",
        credentials_path="test",
        style="classic"
    )

    # generate_textが呼び出された際の引数を取得
    called_prompt = mock_generate_text.call_args[1]['prompt']
    assert "これはテスト用のクラシック添削プロンプトです。" in called_prompt

@patch('gemini_api_service.generate_text')
@patch('json_to_graphical_record_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_convert_json_to_graphical_record_loads_correct_prompt(mock_generate_text):
    """
    json_to_graphical_record_serviceがtemplateに応じて正しいプロンプトを読み込むかテスト
    """
    mock_generate_text.return_value = {"success": True, "html_content": "<h1>Test</h1>"}

    json_to_graphical_record_service.convert_json_to_graphical_record(
        json_data={"title": "Test"},
        project_id="test",
        credentials_path="test",
        template="classic"
    )
    
    called_prompt = mock_generate_text.call_args[1]['prompt']
    assert "これはテスト用のクラシックレイアウトプロンプトです。" in called_prompt

@patch('gemini_api_service.generate_text')
@patch('json_to_graphical_record_service.PROMPT_DIR', TEST_PROMPT_DIR)
def test_json_to_graphical_record_fallback_to_classic(mock_generate_text):
    """
    未知のtemplateが指定された場合にclassicにフォールバックする機能のテスト
    """
    mock_generate_text.return_value = {"success": True, "html_content": "<h1>Test</h1>"}

    # 'classic'へのフォールバックをモック
    with patch('json_to_graphical_record_service.load_prompt', wraps=json_to_graphical_record_service.load_prompt) as mock_load_prompt:
      json_to_graphical_record_service.convert_json_to_graphical_record(
          json_data={"title": "Test"},
          project_id="test",
          credentials_path="test",
          template="unknown_template" # 存在しないテンプレート
      )
      # 'unknown_template'で呼び出され、その後'classic'で呼び出されることを確認
      assert mock_load_prompt.call_count >= 1
      assert mock_load_prompt.call_args.args[0] == 'classic'
    
    called_prompt = mock_generate_text.call_args[1]['prompt']
    assert "これはテスト用のクラシックレイアウトプロンプトです。" in called_prompt

# ==============================================================================
# API（統合）テスト
# ==============================================================================

@patch('main.convert_speech_to_json')
def test_speech_to_json_api(mock_service_call, client):
    """
    /api/v1/ai/speech-to-json エンドポイントのテスト
    """
    mock_service_call.return_value = {"success": True, "data": {"title": "API Test"}}
    
    response = client.post(
        '/api/v1/ai/speech-to-json',
        data=json.dumps({'transcribed_text': 'api test', 'style': 'classic'}),
        content_type='application/json'
    )
    
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success']
    assert json_data['data']['title'] == "API Test"
    
    # サービスが正しいstyleで呼ばれたか確認
    mock_service_call.assert_called_once()
    call_args = mock_service_call.call_args[1]
    assert call_args['style'] == 'classic'
    assert call_args['transcribed_text'] == 'api test'


@patch('main.convert_json_to_graphical_record')
def test_json_to_graphical_record_api(mock_service_call, client):
    """
    /api/v1/ai/json-to-graphical-record エンドポイントのテスト
    """
    mock_service_call.return_value = {"success": True, "html_content": "<h1>API Test</h1>"}

    response = client.post(
        '/api/v1/ai/json-to-graphical-record',
        data=json.dumps({'json_data': {'title': 'test'}, 'template': 'classic'}),
        content_type='application/json'
    )
    
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data['success']
    assert json_data['html_content'] == "<h1>API Test</h1>"
    
    # サービスが正しいtemplateで呼ばれたか確認
    mock_service_call.assert_called_once()
    call_args = mock_service_call.call_args[1]
    assert call_args['template'] == 'classic'
    assert call_args['json_data'] == {'title': 'test'} 