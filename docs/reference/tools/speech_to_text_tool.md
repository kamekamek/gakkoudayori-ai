# SpeechToTextTool API仕様

## 概要

Google Speech-to-Text API のラッパーTool。音声データをテキストに変換します。

## 基本情報

- **Tool名**: `speech_to_text_tool`
- **責務**: 音声バイナリをテキストに変換
- **外部依存**: Google Cloud Speech-to-Text API
- **認証**: Google Cloud サービスアカウント

## API仕様

### 関数シグネチャ

```python
@tool
def speech_to_text_tool(
    audio_bytes: bytes,
    language: str = "ja-JP",
    encoding: str = "WEBM_OPUS",
    sample_rate: int = 48000
) -> str
```

### 入力パラメータ

| パラメータ名 | 型 | 必須 | デフォルト | 説明 |
|-------------|---|------|-----------|------|
| audio_bytes | bytes | ✓ | - | 音声データのバイナリ |
| language | str | - | "ja-JP" | 言語コード |
| encoding | str | - | "WEBM_OPUS" | 音声エンコーディング形式 |
| sample_rate | int | - | 48000 | サンプリングレート（Hz） |

### 出力

| 型 | 説明 |
|----|------|
| str | 文字起こしされたテキスト |

### 例外

| 例外クラス | 発生条件 | 説明 |
|-----------|----------|------|
| ValueError | audio_bytes が空 | 入力音声データが無効 |
| google.api_core.exceptions.GoogleAPIError | API呼び出し失敗 | Google Cloud APIエラー |
| google.api_core.exceptions.PermissionDenied | 認証失敗 | サービスアカウント権限不足 |

## 使用例

### 基本的な使用例

```python
from tools.speech_to_text_tool import speech_to_text_tool

# 音声ファイルを読み込み
with open("sample.webm", "rb") as f:
    audio_data = f.read()

# 文字起こし実行
transcript = speech_to_text_tool(audio_bytes=audio_data)
print(transcript)  # "こんにちは、今日は良い天気ですね。"
```

### カスタム設定での使用例

```python
# 英語音声の処理
transcript_en = speech_to_text_tool(
    audio_bytes=audio_data,
    language="en-US",
    encoding="LINEAR16",
    sample_rate=16000
)
```

### Agent内での使用例

```python
class OrchestratorAgent(Agent):
    async def process_audio(self, audio_bytes: bytes) -> str:
        try:
            text = await self.use_tool(
                "speech_to_text_tool",
                audio_bytes=audio_bytes,
                language="ja-JP"
            )
            return text
        except google.api_core.exceptions.GoogleAPIError as e:
            # リトライロジックまたはフォールバック処理
            self.logger.error(f"Speech-to-Text failed: {e}")
            raise
```

## 設定

### 環境変数

| 変数名 | 必須 | 説明 |
|--------|------|------|
| GOOGLE_APPLICATION_CREDENTIALS | ✓ | サービスアカウントキーファイルパス |
| GOOGLE_CLOUD_PROJECT | ✓ | Google CloudプロジェクトID |

### サポートされる音声形式

| エンコーディング | 説明 | 推奨用途 |
|----------------|------|----------|
| WEBM_OPUS | WebM/Opus形式 | Web録音（Chrome） |
| LINEAR16 | 16-bit PCM | 高品質録音 |
| FLAC | FLAC形式 | 無圧縮高品質 |
| MP3 | MP3形式 | 汎用音声ファイル |

### サポートされる言語

| 言語コード | 言語 | 備考 |
|-----------|------|------|
| ja-JP | 日本語 | デフォルト |
| en-US | 英語（米国） | - |
| en-GB | 英語（英国） | - |
| zh-CN | 中国語（簡体字） | - |

## パフォーマンス特性

- **レスポンス時間**: 1-3秒（音声長による）
- **最大音声長**: 60秒
- **同時リクエスト数**: 10リクエスト/秒
- **精度**: 95%以上（クリアな音声）

## テスト

### 単体テスト例

```python
import pytest
from unittest.mock import patch, MagicMock
from tools.speech_to_text_tool import speech_to_text_tool

class TestSpeechToTextTool:
    def test_successful_transcription(self):
        with patch('google.cloud.speech.SpeechClient') as mock_client:
            # Mock設定
            mock_response = MagicMock()
            mock_response.results = [
                MagicMock(alternatives=[
                    MagicMock(transcript="こんにちは")
                ])
            ]
            mock_client.return_value.recognize.return_value = mock_response
            
            # テスト実行
            result = speech_to_text_tool(b"dummy_audio")
            
            # 検証
            assert result == "こんにちは"
    
    def test_empty_audio_raises_error(self):
        with pytest.raises(ValueError):
            speech_to_text_tool(b"")
    
    @patch('google.cloud.speech.SpeechClient')
    def test_api_error_propagation(self, mock_client):
        mock_client.return_value.recognize.side_effect = Exception("API Error")
        
        with pytest.raises(Exception):
            speech_to_text_tool(b"dummy_audio")
```

## 実装詳細

### 内部処理フロー

1. 入力検証（audio_bytes の存在確認）
2. Google Cloud Speech Client 初期化
3. 音声設定オブジェクト構築
4. API呼び出し実行
5. レスポンス結果の統合（複数セグメント対応）
6. テキスト返却

### エラーハンドリング方針

- Tool内では基本的に例外をそのまま投げる
- リトライ処理は呼び出し側（Agent）で実装
- ログ出力は最小限（デバッグレベル）

## 関連ドキュメント

- [UserDictTool](/reference/tools/user_dict_tool.md) - 固有名詞補正
- [OrchestratorAgent](/reference/agents/orchestrator_agent.md) - 呼び出し元Agent
- [ADKワークフローガイド](/guides/adk-workflow.md) - 全体フロー
- [Google Speech-to-Text API](https://cloud.google.com/speech-to-text/docs) - 公式ドキュメント