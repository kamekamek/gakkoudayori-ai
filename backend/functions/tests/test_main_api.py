"""
統合APIエンドポイントテスト

音声認識→Gemini HTML生成→学級通信生成の完全フローテスト
"""

import pytest
import os
import json
import io
from unittest.mock import Mock, patch, MagicMock
from main import app

# Flaskアプリのテストクライアント設定
app.testing = True

class TestMainAPIEndpoints:
    """メインAPIエンドポイントテストクラス"""

    def setup_method(self):
        """各テストの前に実行される初期化"""
        self.client = app.test_client()
        self.test_credentials_path = "./test_credentials.json"
        self.test_project_id = "gakkoudayori-ai"

    def test_health_endpoint(self):
        """ヘルスチェックエンドポイントテスト"""
        response = self.client.get('/health')
        
        assert response.status_code in [200, 503]  # healthy or unhealthy
        
        data = response.get_json()
        assert 'status' in data
        assert data['status'] in ['healthy', 'unhealthy', 'error']

    def test_config_endpoint(self):
        """設定情報取得エンドポイントテスト"""
        response = self.client.get('/config')
        
        assert response.status_code in [200, 500]
        
        data = response.get_json()
        # エラーの場合でも構造は確認
        assert 'error' in data or 'firebase_initialized' in data

    @patch('main.generate_constrained_html')
    def test_generate_html_endpoint_success(self, mock_generate_html):
        """HTML生成エンドポイント成功テスト"""
        # モックレスポンス設定
        mock_generate_html.return_value = {
            'success': True,
            'data': {
                'html_content': '<h1>テスト学級通信</h1><p>今日の出来事について</p>',
                'processing_time_ms': 1500,
                'ai_metadata': {
                    'model': 'gemini-2.5-pro-preview-03-25',
                    'word_count': 10,
                    'usage': {
                        'total_token_count': 100
                    }
                }
            },
            'timestamp': '2025-01-13T10:00:00'
        }
        
        # テストリクエスト
        response = self.client.post(
            '/api/v1/ai/generate-html',
            json={
                'transcribed_text': 'テスト用音声テキスト',
                'custom_instruction': 'テスト指示',
                'season_theme': 'spring',
                'document_type': 'class_newsletter'
            },
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        
        data = response.get_json()
        assert data['success'] is True
        assert 'html_content' in data['data']
        assert mock_generate_html.called

    def test_generate_html_endpoint_missing_text(self):
        """HTML生成エンドポイント - 必須パラメータ欠損テスト"""
        response = self.client.post(
            '/api/v1/ai/generate-html',
            json={
                'custom_instruction': 'テスト指示のみ'
            },
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 400
        
        data = response.get_json()
        assert data['success'] is False
        assert data['error_code'] == 'MISSING_TRANSCRIBED_TEXT'

    @patch('main.generate_constrained_html')
    def test_generate_newsletter_endpoint_success(self, mock_generate_html):
        """学級通信生成エンドポイント成功テスト"""
        # モックレスポンス設定
        mock_generate_html.return_value = {
            'success': True,
            'data': {
                'html_content': '<h1>学級通信</h1><p>運動会の練習頑張りました</p>',
                'processing_time_ms': 2000,
                'ai_metadata': {
                    'model': 'gemini-2.5-pro-preview-03-25',
                    'word_count': 15,
                    'usage': {
                        'total_token_count': 150
                    }
                }
            },
            'timestamp': '2025-01-13T10:00:00'
        }
        
        # テストリクエスト
        response = self.client.post(
            '/api/v1/ai/generate-newsletter',
            json={
                'transcribed_text': '今日は運動会の練習をしました。子どもたちは頑張っていました。',
                'template_type': 'daily_report',
                'include_greeting': True,
                'target_audience': 'parents',
                'season': 'autumn'
            },
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        
        data = response.get_json()
        assert data['success'] is True
        assert 'newsletter_html' in data['data']
        assert 'original_speech' in data['data']
        assert data['data']['template_type'] == 'daily_report'
        assert data['data']['season'] == 'autumn'

    @patch('main._detect_season_from_text')
    @patch('main.generate_constrained_html')
    def test_generate_newsletter_auto_season(self, mock_generate_html, mock_detect_season):
        """学級通信生成 - 季節自動判定テスト"""
        # モック設定
        mock_detect_season.return_value = 'spring'
        mock_generate_html.return_value = {
            'success': True,
            'data': {
                'html_content': '<h1>春の学級通信</h1>',
                'processing_time_ms': 1000,
                'ai_metadata': {'model': 'gemini-2.5-pro-preview-03-25'}
            },
            'timestamp': '2025-01-13T10:00:00'
        }
        
        response = self.client.post(
            '/api/v1/ai/generate-newsletter',
            json={
                'transcribed_text': '桜が咲いて新学期が始まりました',
                'season': 'auto'
            },
            headers={'Content-Type': 'application/json'}
        )
        
        assert response.status_code == 200
        
        data = response.get_json()
        assert data['data']['season'] == 'spring'
        assert mock_detect_season.called

    def test_generate_newsletter_no_json(self):
        """学級通信生成 - JSONデータなしテスト"""
        response = self.client.post('/api/v1/ai/generate-newsletter')
        
        assert response.status_code == 400
        
        data = response.get_json()
        assert data['success'] is False
        assert data['error_code'] == 'MISSING_DATA'

    def test_transcribe_audio_no_file(self):
        """音声認識 - ファイルなしテスト"""
        response = self.client.post('/api/v1/ai/transcribe')
        
        assert response.status_code == 400
        
        data = response.get_json()
        assert data['success'] is False
        assert data['error_code'] == 'MISSING_FILE'

    @patch('main.transcribe_audio_file')
    @patch('main.validate_audio_format')
    def test_transcribe_audio_success(self, mock_validate, mock_transcribe):
        """音声認識成功テスト"""
        # モック設定
        mock_validate.return_value = {
            'valid': True,
            'format': 'wav',
            'duration': 5.0
        }
        
        mock_transcribe.return_value = {
            'success': True,
            'data': {
                'transcript': 'テスト音声認識結果',
                'confidence': 0.95,
                'processing_time_ms': 3000,
                'sections': ['テスト音声認識結果'],
                'audio_info': {
                    'duration': 5.0,
                    'format': 'wav'
                }
            }
        }
        
        # テスト用音声ファイル（ダミーデータ）
        audio_data = b'dummy_audio_data'
        
        response = self.client.post(
            '/api/v1/ai/transcribe',
            data={
                'audio_file': (io.BytesIO(audio_data), 'test.wav'),
                'language': 'ja-JP'
            }
        )
        
        assert response.status_code == 200
        
        data = response.get_json()
        assert data['success'] is True
        assert 'transcript' in data['data']
        assert mock_transcribe.called
        assert mock_validate.called

    def test_not_found_endpoint(self):
        """存在しないエンドポイントテスト"""
        response = self.client.get('/api/v1/nonexistent')
        
        assert response.status_code == 404
        
        data = response.get_json()
        assert 'error' in data
        assert data['error'] == 'Not Found'

    def test_get_audio_formats_endpoint(self):
        """音声フォーマット取得エンドポイントテスト"""
        with patch('main.get_supported_formats') as mock_formats, \
             patch('main.get_default_speech_contexts') as mock_contexts:
            
            mock_formats.return_value = ['wav', 'mp3', 'm4a']
            mock_contexts.return_value = ['運動会', '学習発表会']
            
            response = self.client.get('/api/v1/ai/formats')
            
            assert response.status_code == 200
            
            data = response.get_json()
            assert data['success'] is True
            assert 'supported_formats' in data['data']
            assert 'default_contexts' in data['data']


class TestSeasonDetection:
    """季節判定機能テストクラス"""

    def setup_method(self):
        """テスト初期化"""
        from main import _detect_season_from_text
        self.detect_season = _detect_season_from_text

    def test_spring_keywords(self):
        """春キーワード判定テスト"""
        text = "桜が咲いて新学期が始まりました"
        season = self.detect_season(text)
        assert season == "spring"

    def test_summer_keywords(self):
        """夏キーワード判定テスト"""
        text = "運動会の練習が始まりました。とても暑い日でした。"
        season = self.detect_season(text)
        assert season == "summer"

    def test_autumn_keywords(self):
        """秋キーワード判定テスト"""
        text = "紅葉が美しく、学習発表会の準備をしています"
        season = self.detect_season(text)
        assert season == "autumn"

    def test_winter_keywords(self):
        """冬キーワード判定テスト"""
        text = "雪が降って寒い日が続いています"
        season = self.detect_season(text)
        assert season == "winter"

    @patch('main.datetime')
    def test_month_based_fallback(self, mock_datetime):
        """月ベースの季節判定テスト"""
        # 4月（春）に設定
        mock_datetime.now.return_value = Mock()
        mock_datetime.now.return_value.month = 4
        
        text = "特に季節的なキーワードがないテキスト"
        season = self.detect_season(text)
        assert season == "spring"


if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v"])