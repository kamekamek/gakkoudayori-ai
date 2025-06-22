# Tools API リファレンス

## 概要

学校だよりAIで使用するToolsのAPI仕様書一覧です。各Toolは単一の責任を持ち、外部APIのラッパーまたは単純な処理を実行します。

## Tool一覧

### 音声・テキスト処理

| Tool名 | 説明 | 状態 |
|--------|------|------|
| [SpeechToTextTool](speech_to_text_tool.md) | Google Speech-to-Text APIラッパー | ✅ 実装済み |
| [UserDictTool](user_dict_tool.md) | 固有名詞・専門用語の置換処理 | ✅ 実装済み |

### HTML・PDF処理

| Tool名 | 説明 | 状態 |
|--------|------|------|
| [TemplateTool](template_tool.md) | HTMLテンプレートへのデータ充填 | 🚧 計画中 |
| [HtmlToPdfTool](html_to_pdf_tool.md) | wkhtmltopdf実行ラッパー | 🚧 計画中 |

### 配信・通知

| Tool名 | 説明 | 状態 |
|--------|------|------|
| [ClassroomTool](classroom_tool.md) | Google Classroom API投稿 | 🚧 計画中 |
| [LineNotifyTool](line_notify_tool.md) | LINE Notify API送信 | 🚧 計画中 |

### ファイル・メディア

| Tool名 | 説明 | 状態 |
|--------|------|------|
| [ImageUploadTool](image_upload_tool.md) | Firebase Storageへの画像アップロード | 🚧 計画中 |
| [FileValidationTool](file_validation_tool.md) | ファイル形式・サイズ検証 | 🚧 計画中 |

## Tool設計原則

### 単一責任原則
各Toolは1つの機能のみを担当し、副作用を最小限に抑えます。

```python
# ✅ 良い例：単一機能に集中
@tool
def speech_to_text_tool(audio_bytes: bytes) -> str:
    """音声データをテキストに変換"""
    return convert_speech_to_text(audio_bytes)

# ❌ 悪い例：複数機能を含む
@tool
def process_audio_tool(audio_bytes: bytes, user_id: str) -> dict:
    """音声処理＋ユーザー設定＋ログ保存"""
    text = convert_speech_to_text(audio_bytes)
    settings = get_user_settings(user_id)  # 別の責任
    save_log(user_id, text)  # 別の責任
    return {"text": text, "settings": settings}
```

### 純粋関数に近づける
状態を持たず、同じ入力に対して同じ出力を返すよう設計します。

```python
# ✅ 良い例：純粋関数的
@tool
def user_dict_tool(text: str, dict_path: str) -> str:
    dict_data = load_dict(dict_path)  # 毎回読み込み
    return apply_replacements(text, dict_data)

# ❌ 悪い例：状態を持つ
class UserDictTool:
    def __init__(self):
        self.dict_cache = {}  # インスタンス状態
    
    @tool
    def replace_words(self, text: str) -> str:
        # キャッシュ状態に依存
        return self.apply_cached_dict(text)
```

### エラーハンドリング
Toolレベルでは基本的に例外をそのまま投げ、リトライ処理は呼び出し側（Agent）で実装します。

```python
@tool
def api_call_tool(endpoint: str, data: dict) -> dict:
    try:
        response = requests.post(endpoint, json=data)
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        # リトライ処理はAgent側で実装
        # Tool側では例外をそのまま投げる
        raise e
```

## Tool実装テンプレート

```python
from adk import tool
from typing import Optional

@tool
def example_tool(
    required_param: str,
    optional_param: Optional[str] = None
) -> str:
    """
    Tool の簡潔な説明
    
    Args:
        required_param: 必須パラメータの説明
        optional_param: オプションパラメータの説明
    
    Returns:
        戻り値の説明
    
    Raises:
        ValueError: 入力値が無効な場合
        ExternalAPIError: 外部API呼び出しエラー
    """
    # 入力検証
    if not required_param:
        raise ValueError("required_param is empty")
    
    # メイン処理
    try:
        result = process_data(required_param, optional_param)
        return result
    except Exception as e:
        # 適切な例外の再発生
        raise e
```

## テスト戦略

### 単体テスト
各Toolは独立してテスト可能でなければなりません。

```python
class TestExampleTool:
    def test_successful_case(self):
        result = example_tool("valid_input")
        assert result == "expected_output"
    
    def test_error_case(self):
        with pytest.raises(ValueError):
            example_tool("")
    
    @patch('external_api.call')
    def test_external_api_mock(self, mock_api):
        mock_api.return_value = "mocked_response"
        result = example_tool("input")
        assert result == "processed_mocked_response"
```

### 統合テスト
Agent内でのTool使用パターンをテストします。

```python
class TestAgentToolIntegration:
    async def test_orchestrator_uses_tools(self):
        agent = OrchestratorAgent()
        result = await agent.process_workflow(test_input)
        
        # 期待されるTool呼び出し順序の検証
        assert "speech_to_text_tool" in agent.used_tools
        assert "user_dict_tool" in agent.used_tools
```

## パフォーマンス考慮事項

### レスポンス時間目標

| Tool種別 | 目標時間 | 備考 |
|----------|----------|------|
| ローカル処理 | <10ms | UserDictTool等 |
| 軽量API | <500ms | LINE Notify等 |
| 重量API | <3秒 | Speech-to-Text等 |
| ファイル処理 | <5秒 | PDF生成等 |

### メモリ使用量
- 大きなファイルはストリーミング処理
- キャッシュサイズの制限設定
- メモリリークの防止

## 関連ドキュメント

- [Agent API リファレンス](/reference/agents/) - Tool呼び出し元
- [ADKワークフローガイド](/guides/adk-workflow.md) - 全体設計
- [ローカル開発ガイド](/guides/local-dev.md) - 開発環境
- [テスト戦略](/guides/testing-strategy.md) - テスト方針