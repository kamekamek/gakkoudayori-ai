"""
Cloud Storage サービスのテスト
TDD Red フェーズ: 失敗するテストを作成
"""
import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
import tempfile
import os

from services.cloud_storage_service import CloudStorageService, FileMetadata, UploadResult
from config.gcloud_config import cloud_config


class TestCloudStorageService:
    """Cloud Storage サービステストクラス"""

    @pytest.fixture
    def mock_storage_client(self):
        """Mock Storage Client"""
        with patch('services.cloud_storage_service.storage') as mock_storage:
            mock_client = Mock()
            mock_storage.Client.return_value = mock_client
            yield mock_client

    @pytest.fixture
    def cloud_storage_service(self, mock_storage_client):
        """CloudStorageService インスタンス"""
        with patch('services.cloud_storage_service.cloud_config') as mock_config:
            mock_config.get_storage_client.return_value = mock_storage_client
            mock_config.get_bucket_name.return_value = "test-bucket"
            service = CloudStorageService()
            service.storage_client = mock_storage_client
            service.bucket = mock_storage_client.bucket.return_value
            return service

    def test_upload_file_success(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイルアップロード成功テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        test_file_content = b"test audio content"
        test_filename = "test_audio.wav"
        user_id = "user123"
        
        # Mock の設定
        mock_blob.upload_from_string.return_value = None
        mock_blob.public_url = f"https://storage.googleapis.com/bucket/{test_filename}"
        mock_blob.name = f"users/{user_id}/audio/2025/01/{test_filename}"

        # Act
        result = cloud_storage_service.upload_file(
            file_content=test_file_content,
            filename=test_filename,
            user_id=user_id,
            file_type="audio"
        )

        # Assert
        assert isinstance(result, UploadResult)
        assert result.success is True
        assert result.file_url is not None
        assert result.file_path.startswith(f"users/{user_id}/audio/")
        assert "2025/01" in result.file_path  # 月別フォルダ確認
        mock_blob.upload_from_string.assert_called_once_with(test_file_content)

    def test_upload_file_failure(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイルアップロード失敗テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        # アップロードでエラーを発生させる
        mock_blob.upload_from_string.side_effect = Exception("Upload failed")
        
        test_file_content = b"test content"
        test_filename = "test_file.pdf"
        user_id = "user123"

        # Act
        result = cloud_storage_service.upload_file(
            file_content=test_file_content,
            filename=test_filename,
            user_id=user_id,
            file_type="pdf"
        )

        # Assert
        assert isinstance(result, UploadResult)
        assert result.success is False
        assert result.error_message is not None
        assert "Upload failed" in result.error_message

    def test_generate_monthly_folder_path(self, cloud_storage_service):
        """🔴 Red: 月別フォルダパス生成テスト"""
        # Arrange
        user_id = "user123"
        file_type = "audio"
        filename = "recording.wav"
        
        # Act
        result_path = cloud_storage_service.generate_file_path(
            user_id=user_id,
            file_type=file_type,
            filename=filename
        )

        # Assert
        current_date = datetime.now()
        expected_pattern = f"users/{user_id}/{file_type}/{current_date.year}/{current_date.month:02d}/{filename}"
        assert result_path == expected_pattern

    def test_download_file_success(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイルダウンロード成功テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        test_content = b"downloaded file content"
        mock_blob.download_as_bytes.return_value = test_content
        mock_blob.exists.return_value = True
        
        file_path = "users/user123/pdf/2025/01/document.pdf"

        # Act
        content = cloud_storage_service.download_file(file_path)

        # Assert
        assert content == test_content
        mock_blob.download_as_bytes.assert_called_once()

    def test_download_file_not_found(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイルダウンロード（ファイル不存在）テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        mock_blob.exists.return_value = False
        
        file_path = "users/user123/pdf/2025/01/nonexistent.pdf"

        # Act & Assert
        with pytest.raises(FileNotFoundError):
            cloud_storage_service.download_file(file_path)

    def test_delete_file_success(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイル削除成功テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        mock_blob.exists.return_value = True
        mock_blob.delete.return_value = None
        
        file_path = "users/user123/audio/2025/01/old_recording.wav"

        # Act
        result = cloud_storage_service.delete_file(file_path)

        # Assert
        assert result is True
        mock_blob.delete.assert_called_once()

    def test_delete_file_not_found(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイル削除（ファイル不存在）テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        mock_blob.exists.return_value = False
        
        file_path = "users/user123/audio/2025/01/nonexistent.wav"

        # Act
        result = cloud_storage_service.delete_file(file_path)

        # Assert
        assert result is False

    def test_get_signed_url(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: 署名付きURL生成テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        expected_url = "https://storage.googleapis.com/signed-url-example"
        mock_blob.generate_signed_url.return_value = expected_url
        
        file_path = "users/user123/pdf/2025/01/document.pdf"
        expiration_minutes = 60

        # Act
        signed_url = cloud_storage_service.get_signed_url(
            file_path=file_path,
            expiration_minutes=expiration_minutes
        )

        # Assert
        assert signed_url == expected_url
        mock_blob.generate_signed_url.assert_called_once()

    def test_list_user_files(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ユーザーファイル一覧取得テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        
        # Mock blobs
        mock_blob1 = Mock()
        mock_blob1.name = "users/user123/audio/2025/01/recording1.wav"
        mock_blob1.size = 1024
        mock_blob1.time_created = datetime.now()
        
        mock_blob2 = Mock()
        mock_blob2.name = "users/user123/pdf/2025/01/document1.pdf"
        mock_blob2.size = 2048
        mock_blob2.time_created = datetime.now()
        
        mock_bucket.list_blobs.return_value = [mock_blob1, mock_blob2]
        
        user_id = "user123"

        # Act
        files = cloud_storage_service.list_user_files(user_id)

        # Assert
        assert len(files) == 2
        assert all(isinstance(f, FileMetadata) for f in files)
        assert files[0].filename == "recording1.wav"
        assert files[1].filename == "document1.pdf"

    def test_get_file_metadata(self, cloud_storage_service, mock_storage_client):
        """🔴 Red: ファイルメタデータ取得テスト"""
        # Arrange
        mock_bucket = Mock()
        mock_blob = Mock()
        mock_storage_client.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        mock_blob.exists.return_value = True
        mock_blob.name = "users/user123/audio/2025/01/recording.wav"
        mock_blob.size = 1024
        mock_blob.time_created = datetime.now()
        mock_blob.content_type = "audio/wav"
        
        file_path = "users/user123/audio/2025/01/recording.wav"

        # Act
        metadata = cloud_storage_service.get_file_metadata(file_path)

        # Assert
        assert isinstance(metadata, FileMetadata)
        assert metadata.filename == "recording.wav"
        assert metadata.size == 1024
        assert metadata.content_type == "audio/wav" 