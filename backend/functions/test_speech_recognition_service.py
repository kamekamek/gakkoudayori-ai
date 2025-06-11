"""
音声認識サービステスト

T3-AI-005-A: 音声認識API実装
- Speech-to-Text クライアント実装テスト
- 音声ファイルアップロード処理テスト
- 文字起こし結果処理テスト
- エラーハンドリングテスト
"""

import pytest
import os
import sys
import time
from unittest.mock import Mock, patch, MagicMock

# プロジェクトのルートディレクトリをPythonパスに追加
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from speech_recognition_service import (
    initialize_speech_client,
    transcribe_audio_file,
    validate_audio_format,
    create_test_audio_content,
    get_supported_formats,
    get_default_speech_contexts
)


class TestSpeechClientInitialization:
    """Speech-to-Textクライアント初期化テスト"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        self.credentials_path = "../secrets/service-account-key.json"
        self.invalid_credentials_path = "invalid/path.json"

    def test_initialize_speech_client_success(self):
        """Speech-to-Textクライアント初期化成功テスト"""
        # Speech-to-Textクライアント初期化
        client = initialize_speech_client(self.credentials_path)
        
        # 期待値: クライアントオブジェクトが返される
        assert client is not None
        assert hasattr(client, 'recognize')

    def test_initialize_speech_client_invalid_credentials(self):
        """Speech-to-Textクライアント初期化失敗テスト（無効な認証情報）"""
        # 無効な認証情報でテスト
        client = initialize_speech_client(self.invalid_credentials_path)
        
        # 期待値: None
        assert client is None

    def test_initialize_speech_client_missing_file(self):
        """Speech-to-Textクライアント初期化失敗テスト（ファイル不存在）"""
        # 存在しないファイルパスでテスト
        client = initialize_speech_client("nonexistent/file.json")
        
        # 期待値: None
        assert client is None


class TestAudioValidation:
    """音声ファイル検証テスト"""

    def test_validate_empty_audio(self):
        """空の音声ファイル検証テスト"""
        empty_audio = b''
        result = validate_audio_format(empty_audio)
        
        assert result['valid'] is False
        assert result['error_code'] == 'EMPTY_FILE'

    def test_validate_oversized_audio(self):
        """サイズ超過音声ファイル検証テスト"""
        oversized_audio = b'x' * (11 * 1024 * 1024)  # 11MB
        result = validate_audio_format(oversized_audio)
        
        assert result['valid'] is False
        assert result['error_code'] == 'FILE_TOO_LARGE'

    def test_validate_wav_format(self):
        """WAVフォーマット検証テスト"""
        # WAVヘッダーを含む音声データ
        wav_audio = b'RIFF\x24\x08\x00\x00WAVEfmt \x10\x00\x00\x00' + b'\x00' * 100
        result = validate_audio_format(wav_audio)
        
        assert result['valid'] is True
        assert result['format'] == 'WAV'
        assert result['size_bytes'] > 0

    def test_validate_mp3_format(self):
        """MP3フォーマット検証テスト"""
        # MP3ヘッダーを含む音声データ
        mp3_audio = b'ID3\x03\x00\x00\x00' + b'\x00' * 100
        result = validate_audio_format(mp3_audio)
        
        assert result['valid'] is True
        assert result['format'] == 'MP3'

    def test_validate_unknown_format(self):
        """未知フォーマット検証テスト"""
        # 未知のヘッダーを含む音声データ
        unknown_audio = b'UNKNOWN' + b'\x00' * 100
        result = validate_audio_format(unknown_audio)
        
        assert result['valid'] is True  # サイズは問題ないため有効
        assert result['format'] == 'UNKNOWN'


class TestAudioTranscription:
    """音声文字起こしテスト"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        self.credentials_path = "../secrets/service-account-key.json"
        self.test_audio = create_test_audio_content()

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_success(self, mock_speech_client):
        """音声文字起こし成功テスト"""
        # モックレスポンスの設定
        mock_alternative = Mock()
        mock_alternative.transcript = "テスト音声の文字起こし結果です。"
        mock_alternative.confidence = 0.95
        mock_alternative.words = []
        
        mock_result = Mock()
        mock_result.alternatives = [mock_alternative]
        
        mock_response = Mock()
        mock_response.results = [mock_result]
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.return_value = mock_response
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: 成功レスポンス
        assert result['success'] is True
        assert 'data' in result
        assert result['data']['transcript'] == "テスト音声の文字起こし結果です。"
        assert result['data']['confidence'] == 0.95
        assert result['data']['processing_time_ms'] >= 0  # 処理時間は0以上
        assert len(result['data']['sections']) == 1

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_with_timestamps(self, mock_speech_client):
        """タイムスタンプ付き音声文字起こしテスト"""
        # モック単語データ
        mock_word1 = Mock()
        mock_word1.word = "テスト"
        mock_word1.start_time.total_seconds.return_value = 0.0
        mock_word1.end_time.total_seconds.return_value = 1.0
        
        mock_word2 = Mock()
        mock_word2.word = "音声"
        mock_word2.start_time.total_seconds.return_value = 1.0
        mock_word2.end_time.total_seconds.return_value = 2.0
        
        mock_alternative = Mock()
        mock_alternative.transcript = "テスト音声"
        mock_alternative.confidence = 0.92
        mock_alternative.words = [mock_word1, mock_word2]
        
        mock_result = Mock()
        mock_result.alternatives = [mock_alternative]
        
        mock_response = Mock()
        mock_response.results = [mock_result]
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.return_value = mock_response
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(
            self.test_audio, 
            self.credentials_path,
            enable_word_timestamps=True
        )
        
        # 期待値: タイムスタンプ付きレスポンス
        assert result['success'] is True
        assert 'words' in result['data']['sections'][0]
        assert len(result['data']['sections'][0]['words']) == 2
        assert result['data']['sections'][0]['words'][0]['word'] == "テスト"
        assert result['data']['sections'][0]['start_time'] == 0.0
        assert result['data']['sections'][0]['end_time'] == 2.0

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_multiple_sections(self, mock_speech_client):
        """複数セクション音声文字起こしテスト"""
        # 複数結果のモック
        mock_alternative1 = Mock()
        mock_alternative1.transcript = "最初のセクションです。"
        mock_alternative1.confidence = 0.93
        mock_alternative1.words = []
        
        mock_alternative2 = Mock()
        mock_alternative2.transcript = "二番目のセクションです。"
        mock_alternative2.confidence = 0.89
        mock_alternative2.words = []
        
        mock_result1 = Mock()
        mock_result1.alternatives = [mock_alternative1]
        
        mock_result2 = Mock()
        mock_result2.alternatives = [mock_alternative2]
        
        mock_response = Mock()
        mock_response.results = [mock_result1, mock_result2]
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.return_value = mock_response
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: 複数セクション結果
        assert result['success'] is True
        assert len(result['data']['sections']) == 2
        assert result['data']['transcript'] == "最初のセクションです。 二番目のセクションです。"
        assert result['data']['confidence'] == 0.91  # 平均値 (0.93 + 0.89) / 2

    @patch('speech_recognition_service.initialize_speech_client')
    def test_transcribe_audio_client_failure(self, mock_init_client):
        """クライアント初期化失敗テスト"""
        # クライアント初期化失敗をシミュレート
        mock_init_client.return_value = None
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: 失敗レスポンス
        assert result['success'] is False
        assert 'Failed to initialize Speech-to-Text client' in result['error']

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_permission_denied(self, mock_speech_client):
        """権限エラーテスト"""
        from google.api_core import exceptions as gcp_exceptions
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.side_effect = gcp_exceptions.PermissionDenied("Permission denied")
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: 権限エラー
        assert result['success'] is False
        assert result['error_type'] == 'permission_denied'
        assert 'Permission denied' in result['error']

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_invalid_format(self, mock_speech_client):
        """無効フォーマットエラーテスト"""
        from google.api_core import exceptions as gcp_exceptions
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.side_effect = gcp_exceptions.InvalidArgument("Invalid audio format")
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: フォーマットエラー
        assert result['success'] is False
        assert result['error_type'] == 'invalid_format'
        assert 'Invalid audio format' in result['error']

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_audio_timeout(self, mock_speech_client):
        """タイムアウトエラーテスト"""
        from google.api_core import exceptions as gcp_exceptions
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.side_effect = gcp_exceptions.DeadlineExceeded("Timeout")
        mock_speech_client.return_value = mock_client_instance
        
        # 音声文字起こし実行
        result = transcribe_audio_file(self.test_audio, self.credentials_path)
        
        # 期待値: タイムアウトエラー
        assert result['success'] is False
        assert result['error_type'] == 'timeout'
        assert 'timeout' in result['error']


class TestUtilityFunctions:
    """ユーティリティ関数テスト"""

    def test_create_test_audio_content(self):
        """テスト音声データ作成テスト"""
        audio_content = create_test_audio_content()
        
        assert isinstance(audio_content, bytes)
        assert len(audio_content) > 0
        assert audio_content.startswith(b'RIFF')  # WAVヘッダー

    def test_get_supported_formats(self):
        """サポートフォーマット一覧取得テスト"""
        formats = get_supported_formats()
        
        assert isinstance(formats, list)
        assert len(formats) > 0
        
        # 各フォーマットが適切な構造を持つか確認
        for fmt in formats:
            assert 'format' in fmt
            assert 'description' in fmt
            assert 'quality' in fmt
            assert 'file_size' in fmt

    def test_get_default_speech_contexts(self):
        """デフォルト音声コンテキスト取得テスト"""
        contexts = get_default_speech_contexts()
        
        assert isinstance(contexts, list)
        assert len(contexts) > 0
        assert '運動会' in contexts
        assert '学習発表会' in contexts
        assert '子どもたち' in contexts


class TestConfigurationOptions:
    """設定オプションテスト"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        self.credentials_path = "../secrets/service-account-key.json"
        self.test_audio = create_test_audio_content()

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_with_custom_language(self, mock_speech_client):
        """カスタム言語設定テスト"""
        mock_alternative = Mock()
        mock_alternative.transcript = "English transcription"
        mock_alternative.confidence = 0.90
        mock_alternative.words = []
        
        mock_result = Mock()
        mock_result.alternatives = [mock_alternative]
        
        mock_response = Mock()
        mock_response.results = [mock_result]
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.return_value = mock_response
        mock_speech_client.return_value = mock_client_instance
        
        # 英語で音声文字起こし実行
        result = transcribe_audio_file(
            self.test_audio, 
            self.credentials_path,
            language_code="en-US"
        )
        
        # 期待値: 英語認識結果
        assert result['success'] is True
        assert result['data']['audio_info']['language'] == "en-US"

    @patch('speech_recognition_service.speech.SpeechClient')
    def test_transcribe_with_custom_contexts(self, mock_speech_client):
        """カスタム音声コンテキストテスト"""
        mock_alternative = Mock()
        mock_alternative.transcript = "カスタムコンテキストテスト"
        mock_alternative.confidence = 0.95
        mock_alternative.words = []
        
        mock_result = Mock()
        mock_result.alternatives = [mock_alternative]
        
        mock_response = Mock()
        mock_response.results = [mock_result]
        
        mock_client_instance = Mock()
        mock_client_instance.recognize.return_value = mock_response
        mock_speech_client.return_value = mock_client_instance
        
        # カスタムコンテキストで音声文字起こし実行
        custom_contexts = ["特別な用語", "専門用語"]
        result = transcribe_audio_file(
            self.test_audio,
            self.credentials_path,
            speech_contexts=custom_contexts
        )
        
        # 期待値: 成功（コンテキストは内部で使用される）
        assert result['success'] is True


# ==============================================================================
# 統合テスト
# ==============================================================================

class TestSpeechRecognitionIntegration:
    """音声認識統合テスト"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        self.credentials_path = "../secrets/service-account-key.json"

    @pytest.mark.integration
    def test_full_speech_recognition_workflow(self):
        """音声認識フルワークフローテスト"""
        # テスト音声データ作成
        test_audio = create_test_audio_content()
        
        # フォーマット検証
        validation_result = validate_audio_format(test_audio)
        assert validation_result['valid'] is True
        
        # 注意: 実際のAPIテストは課金が発生する可能性があるため、
        # 環境変数でテストの実行を制御
        if os.getenv('RUN_SPEECH_API_TESTS') == 'true':
            # 音声文字起こし実行
            transcription_result = transcribe_audio_file(test_audio, self.credentials_path)
            
            # 基本的な成功確認（実際の音声内容は検証困難）
            assert 'success' in transcription_result
            assert 'processing_time_ms' in transcription_result.get('data', {})

    def test_error_handling_chain(self):
        """エラーハンドリング連鎖テスト"""
        # 1. 不正なファイル
        invalid_audio = b'invalid audio data'
        validation_result = validate_audio_format(invalid_audio)
        
        # フォーマット不明でも基本検証はパス（サイズが問題ないため）
        assert validation_result['valid'] is True
        assert validation_result['format'] == 'UNKNOWN'
        
        # 2. 空ファイル
        empty_audio = b''
        validation_result = validate_audio_format(empty_audio)
        assert validation_result['valid'] is False
        
        # 3. 不正な認証情報
        transcription_result = transcribe_audio_file(
            create_test_audio_content(),
            "invalid/path.json"
        )
        assert transcription_result['success'] is False


if __name__ == "__main__":
    # テスト実行
    print("Running Speech Recognition Service Tests...")
    
    # 基本テストのみ実行（統合テストは除外）
    pytest_args = [
        __file__,
        "-v",
        "-m", "not integration",
        "--tb=short"
    ]
    
    pytest.main(pytest_args) 