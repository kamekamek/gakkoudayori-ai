"""
Cloud Storage ファイル管理サービス
TDD Green フェーズ: テストを通すための実装
"""
from datetime import datetime, timedelta
from typing import List, Optional
from dataclasses import dataclass
import os
from pathlib import Path

from google.cloud import storage
from google.api_core.exceptions import NotFound
from config.gcloud_config import cloud_config


@dataclass
class FileMetadata:
    """ファイルメタデータ"""
    filename: str
    file_path: str
    size: int
    created_at: datetime
    content_type: str
    user_id: str
    file_type: str


@dataclass
class UploadResult:
    """ファイルアップロード結果"""
    success: bool
    file_path: Optional[str] = None
    file_url: Optional[str] = None
    error_message: Optional[str] = None


class CloudStorageService:
    """Cloud Storage ファイル管理サービス"""
    
    def __init__(self):
        """初期化"""
        self.storage_client = cloud_config.get_storage_client()
        self.bucket_name = cloud_config.get_bucket_name('uploads')
        self.bucket = self.storage_client.bucket(self.bucket_name)
    
    def upload_file(
        self,
        file_content: bytes,
        filename: str,
        user_id: str,
        file_type: str,
        content_type: Optional[str] = None
    ) -> UploadResult:
        """
        ファイルをアップロード
        
        Args:
            file_content: ファイルの内容
            filename: ファイル名
            user_id: ユーザーID
            file_type: ファイルタイプ（audio, pdf, image, template）
            content_type: MIMEタイプ（自動推定可能）
        
        Returns:
            UploadResult: アップロード結果
        """
        try:
            # 月別フォルダパス生成
            file_path = self.generate_file_path(user_id, file_type, filename)
            
            # Blobオブジェクト作成
            blob = self.bucket.blob(file_path)
            
            # Content-Type設定
            if content_type:
                blob.content_type = content_type
            else:
                blob.content_type = self._guess_content_type(filename)
            
            # ファイルアップロード
            blob.upload_from_string(file_content)
            
            # 公開URLまたは署名付きURL生成
            file_url = self.get_signed_url(file_path, expiration_minutes=60)
            
            return UploadResult(
                success=True,
                file_path=file_path,
                file_url=file_url
            )
            
        except Exception as e:
            return UploadResult(
                success=False,
                error_message=f"ファイルアップロードエラー: {str(e)}"
            )
    
    def download_file(self, file_path: str) -> bytes:
        """
        ファイルをダウンロード
        
        Args:
            file_path: ファイルパス
            
        Returns:
            bytes: ファイル内容
            
        Raises:
            FileNotFoundError: ファイルが存在しない場合
        """
        try:
            blob = self.bucket.blob(file_path)
            
            if not blob.exists():
                raise FileNotFoundError(f"ファイルが見つかりません: {file_path}")
            
            return blob.download_as_bytes()
            
        except NotFound:
            raise FileNotFoundError(f"ファイルが見つかりません: {file_path}")
        except Exception as e:
            raise Exception(f"ファイルダウンロードエラー: {str(e)}")
    
    def delete_file(self, file_path: str) -> bool:
        """
        ファイルを削除
        
        Args:
            file_path: ファイルパス
            
        Returns:
            bool: 削除成功かどうか
        """
        try:
            blob = self.bucket.blob(file_path)
            
            if not blob.exists():
                return False
            
            blob.delete()
            return True
            
        except Exception as e:
            print(f"ファイル削除エラー: {e}")
            return False
    
    def get_signed_url(
        self,
        file_path: str,
        expiration_minutes: int = 60
    ) -> str:
        """
        署名付きURLを生成
        
        Args:
            file_path: ファイルパス
            expiration_minutes: 有効期限（分）
            
        Returns:
            str: 署名付きURL
        """
        try:
            blob = self.bucket.blob(file_path)
            
            # 有効期限設定
            expiration = datetime.utcnow() + timedelta(minutes=expiration_minutes)
            
            # 署名付きURL生成
            signed_url = blob.generate_signed_url(
                expiration=expiration,
                method='GET'
            )
            
            return signed_url
            
        except Exception as e:
            raise Exception(f"署名付きURL生成エラー: {str(e)}")
    
    def list_user_files(
        self,
        user_id: str,
        file_type: Optional[str] = None,
        limit: int = 100
    ) -> List[FileMetadata]:
        """
        ユーザーのファイル一覧を取得
        
        Args:
            user_id: ユーザーID
            file_type: ファイルタイプでフィルタ（オプション）
            limit: 取得件数上限
            
        Returns:
            List[FileMetadata]: ファイルメタデータリスト
        """
        try:
            prefix = f"users/{user_id}/"
            if file_type:
                prefix += f"{file_type}/"
            
            blobs = self.bucket.list_blobs(prefix=prefix, max_results=limit)
            
            file_list = []
            for blob in blobs:
                metadata = self._blob_to_metadata(blob, user_id)
                if metadata:
                    file_list.append(metadata)
            
            return file_list
            
        except Exception as e:
            print(f"ファイル一覧取得エラー: {e}")
            return []
    
    def get_file_metadata(self, file_path: str) -> Optional[FileMetadata]:
        """
        ファイルメタデータを取得
        
        Args:
            file_path: ファイルパス
            
        Returns:
            FileMetadata: ファイルメタデータ
        """
        try:
            blob = self.bucket.blob(file_path)
            
            if not blob.exists():
                return None
            
            # リロードしてメタデータ取得
            blob.reload()
            
            # パスからuser_idとfile_typeを抽出
            path_parts = file_path.split('/')
            user_id = path_parts[1] if len(path_parts) > 1 else ""
            file_type = path_parts[2] if len(path_parts) > 2 else ""
            
            return FileMetadata(
                filename=Path(file_path).name,
                file_path=file_path,
                size=blob.size,
                created_at=blob.time_created,
                content_type=blob.content_type or "application/octet-stream",
                user_id=user_id,
                file_type=file_type
            )
            
        except Exception as e:
            print(f"メタデータ取得エラー: {e}")
            return None
    
    def generate_file_path(
        self,
        user_id: str,
        file_type: str,
        filename: str
    ) -> str:
        """
        月別フォルダパスを生成
        
        Args:
            user_id: ユーザーID
            file_type: ファイルタイプ
            filename: ファイル名
            
        Returns:
            str: ファイルパス（users/{user_id}/{file_type}/{YYYY}/{MM}/{filename}）
        """
        now = datetime.now()
        year = now.year
        month = f"{now.month:02d}"
        
        return f"users/{user_id}/{file_type}/{year}/{month}/{filename}"
    
    def _blob_to_metadata(self, blob, user_id: str) -> Optional[FileMetadata]:
        """BlobオブジェクトをFileMetadataに変換"""
        try:
            path_parts = blob.name.split('/')
            file_type = path_parts[2] if len(path_parts) > 2 else ""
            
            return FileMetadata(
                filename=Path(blob.name).name,
                file_path=blob.name,
                size=blob.size,
                created_at=blob.time_created,
                content_type=blob.content_type or "application/octet-stream",
                user_id=user_id,
                file_type=file_type
            )
        except Exception as e:
            print(f"メタデータ変換エラー: {e}")
            return None
    
    def _guess_content_type(self, filename: str) -> str:
        """ファイル名からContent-Typeを推定"""
        ext = Path(filename).suffix.lower()
        
        content_type_map = {
            '.wav': 'audio/wav',
            '.mp3': 'audio/mpeg',
            '.m4a': 'audio/mp4',
            '.pdf': 'application/pdf',
            '.jpg': 'image/jpeg',
            '.jpeg': 'image/jpeg',
            '.png': 'image/png',
            '.gif': 'image/gif',
            '.webp': 'image/webp',
            '.svg': 'image/svg+xml',
            '.html': 'text/html',
            '.css': 'text/css',
            '.js': 'text/javascript',
            '.json': 'application/json',
            '.txt': 'text/plain',
        }
        
        return content_type_map.get(ext, 'application/octet-stream')


# グローバルインスタンス
cloud_storage_service = CloudStorageService() 