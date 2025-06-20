"""
画像アップロード機能のテスト
"""
import pytest
import tempfile
from io import BytesIO
from flask import Flask
from unittest.mock import Mock, patch
import json

# テスト対象のインポート
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app, _validate_image_file, _sanitize_filename


class TestImageUpload:
    """画像アップロード機能のテストクラス"""

    @pytest.fixture
    def client(self):
        """テスト用Flaskクライアント"""
        app.config['TESTING'] = True
        with app.test_client() as client:
            yield client

    def test_validate_image_file_valid_jpeg(self):
        """有効なJPEGファイルのバリデーション"""
        # モックファイルオブジェクト作成
        mock_file = Mock()
        mock_file.content_type = 'image/jpeg'
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 1024  # 1KB
        
        result = _validate_image_file(mock_file)
        assert result is True

    def test_validate_image_file_valid_png(self):
        """有効なPNGファイルのバリデーション"""
        mock_file = Mock()
        mock_file.content_type = 'image/png'
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 2048  # 2KB
        
        result = _validate_image_file(mock_file)
        assert result is True

    def test_validate_image_file_invalid_type(self):
        """無効なファイルタイプのバリデーション"""
        mock_file = Mock()
        mock_file.content_type = 'text/plain'
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 1024
        
        result = _validate_image_file(mock_file)
        assert result is False

    def test_validate_image_file_too_large(self):
        """サイズが大きすぎるファイルのバリデーション"""
        mock_file = Mock()
        mock_file.content_type = 'image/jpeg'
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 10 * 1024 * 1024  # 10MB
        
        result = _validate_image_file(mock_file)
        assert result is False

    def test_validate_image_file_empty(self):
        """空ファイルのバリデーション"""
        mock_file = Mock()
        mock_file.content_type = 'image/jpeg'
        mock_file.seek.return_value = None
        mock_file.tell.return_value = 0  # 0バイト
        
        result = _validate_image_file(mock_file)
        assert result is False

    def test_sanitize_filename_normal(self):
        """通常のファイル名のサニタイズ"""
        result = _sanitize_filename('test_image.jpg')
        assert result == 'test_image.jpg'

    def test_sanitize_filename_with_special_chars(self):
        """特殊文字を含むファイル名のサニタイズ"""
        result = _sanitize_filename('画像!@#$%^&*()テスト.png')
        assert result == '.png'  # 特殊文字は削除される

    def test_sanitize_filename_empty(self):
        """空のファイル名のサニタイズ"""
        result = _sanitize_filename('')
        assert result == 'image'

    def test_sanitize_filename_too_long(self):
        """長すぎるファイル名のサニタイズ"""
        long_name = 'a' * 100 + '.jpg'
        result = _sanitize_filename(long_name)
        assert len(result) <= 50
        assert result.endswith('.jpg')

    def test_upload_images_no_files(self, client):
        """ファイルなしでのアップロードテスト"""
        response = client.post('/api/v1/images/upload')
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'No image files provided' in data['error']

    @patch('main.get_storage_bucket')
    def test_upload_images_storage_unavailable(self, mock_get_bucket, client):
        """Storage利用不可時のテスト"""
        mock_get_bucket.return_value = None
        
        # ダミー画像ファイル作成
        data = {
            'user_id': 'test_user',
            'category': 'newsletter'
        }
        
        # ファイルのモック
        mock_file = BytesIO(b'fake image data')
        data['image_files'] = (mock_file, 'test.jpg')
        
        response = client.post(
            '/api/v1/images/upload',
            data=data,
            content_type='multipart/form-data'
        )
        
        assert response.status_code == 400
        response_data = json.loads(response.data)
        assert response_data['success'] is False

    def test_refresh_image_url_no_data(self, client):
        """データなしでのURL更新テスト"""
        response = client.post(
            '/api/v1/images/refresh-url',
            content_type='application/json'
        )
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'No JSON data provided' in data['error']

    def test_refresh_image_url_missing_blob_path(self, client):
        """blob_pathなしでのURL更新テスト"""
        response = client.post(
            '/api/v1/images/refresh-url',
            data=json.dumps({'user_id': 'test_user'}),
            content_type='application/json'
        )
        assert response.status_code == 400
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'Blob path is required' in data['error']

    def test_refresh_image_url_access_denied(self, client):
        """権限なしでのURL更新テスト"""
        response = client.post(
            '/api/v1/images/refresh-url',
            data=json.dumps({
                'blob_path': 'images/other_user/newsletter/test.jpg',
                'user_id': 'test_user'
            }),
            content_type='application/json'
        )
        assert response.status_code == 403
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'Access denied' in data['error']

    def test_refresh_image_url_anonymous_access(self, client):
        """匿名ユーザーでのURL更新テスト"""
        response = client.post(
            '/api/v1/images/refresh-url',
            data=json.dumps({
                'blob_path': 'images/anonymous/session123/test.jpg',
                'user_id': 'anonymous'
            }),
            content_type='application/json'
        )
        # Storage未初期化のため503エラーになることを想定
        assert response.status_code == 503

    @patch('main.get_storage_bucket')
    def test_refresh_image_url_storage_unavailable(self, mock_get_bucket, client):
        """Storage利用不可時のURL更新テスト"""
        mock_get_bucket.return_value = None
        
        response = client.post(
            '/api/v1/images/refresh-url',
            data=json.dumps({
                'blob_path': 'images/test_user/newsletter/test.jpg',
                'user_id': 'test_user'
            }),
            content_type='application/json'
        )
        assert response.status_code == 503
        
        data = json.loads(response.data)
        assert data['success'] is False
        assert 'Storage service unavailable' in data['error']


if __name__ == '__main__':
    pytest.main([__file__, '-v'])