# image_processing_service.py
"""
画像処理サービス - Firebase Storage統合・圧縮・リサイズ・メタデータ管理
学校だよりAI用の包括的画像処理システム
"""

import io
import logging
import mimetypes
import os
import tempfile
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Union

from PIL import Image, ImageOps
from google.cloud import storage
from firebase_admin import firestore

# ロギング設定
logger = logging.getLogger(__name__)

class ImageProcessingService:
    """画像処理・Firebase Storage統合サービス"""
    
    # 設定定数
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
    ALLOWED_FORMATS = {'JPEG', 'PNG', 'WebP', 'GIF'}
    ALLOWED_MIME_TYPES = {
        'image/jpeg', 'image/png', 'image/webp', 'image/gif'
    }
    
    # 圧縮設定
    COMPRESSION_SETTINGS = {
        'high_quality': {'max_size': (1920, 1080), 'quality': 85},
        'medium_quality': {'max_size': (1280, 720), 'quality': 75},
        'thumbnail': {'max_size': (300, 300), 'quality': 70}
    }
    
    def __init__(self, bucket_name: str = None):
        """初期化"""
        self.bucket_name = bucket_name or os.getenv('FIREBASE_STORAGE_BUCKET', 'gakkoudayori-ai.appspot.com')
        self.storage_client = storage.Client()
        self.bucket = self.storage_client.bucket(self.bucket_name)
        self.db = firestore.client()
        
        logger.info(f"ImageProcessingService initialized with bucket: {self.bucket_name}")
    
    def validate_image(self, file_data: bytes, filename: str) -> Dict[str, Union[bool, str]]:
        """画像ファイルの検証"""
        try:
            # ファイルサイズチェック
            if len(file_data) > self.MAX_FILE_SIZE:
                return {
                    'valid': False,
                    'error': f'ファイルサイズが制限を超えています。最大{self.MAX_FILE_SIZE // (1024*1024)}MBまで。'
                }
            
            # MIME型チェック
            mime_type, _ = mimetypes.guess_type(filename)
            if mime_type not in self.ALLOWED_MIME_TYPES:
                return {
                    'valid': False,
                    'error': f'サポートされていないファイル形式です。対応形式: {", ".join(self.ALLOWED_FORMATS)}'
                }
            
            # PIL画像として読み込み可能かチェック
            try:
                with Image.open(io.BytesIO(file_data)) as img:
                    img.verify()  # 画像の整合性確認
                    
                    # 画像情報取得
                    img_info = {
                        'width': img.width,
                        'height': img.height,
                        'format': img.format,
                        'mode': img.mode
                    }
                    
            except Exception as e:
                return {
                    'valid': False,
                    'error': f'画像ファイルが破損しているか、サポートされていない形式です: {str(e)}'
                }
            
            return {
                'valid': True,
                'image_info': img_info,
                'mime_type': mime_type,
                'file_size': len(file_data)
            }
            
        except Exception as e:
            logger.error(f"Image validation error: {e}")
            return {
                'valid': False,
                'error': f'画像検証中にエラーが発生しました: {str(e)}'
            }
    
    def compress_image(self, file_data: bytes, quality_level: str = 'medium_quality') -> bytes:
        """画像の圧縮・リサイズ"""
        try:
            settings = self.COMPRESSION_SETTINGS.get(quality_level, self.COMPRESSION_SETTINGS['medium_quality'])
            
            with Image.open(io.BytesIO(file_data)) as img:
                # RGBA画像をRGBに変換（JPEG対応）
                if img.mode in ('RGBA', 'LA', 'P'):
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'P':
                        img = img.convert('RGBA')
                    background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                    img = background
                
                # 自動回転（EXIF情報を考慮）
                img = ImageOps.exif_transpose(img)
                
                # リサイズ（アスペクト比維持）
                max_size = settings['max_size']
                img.thumbnail(max_size, Image.Resampling.LANCZOS)
                
                # 圧縮保存
                output = io.BytesIO()
                img.save(
                    output,
                    format='JPEG',
                    quality=settings['quality'],
                    optimize=True,
                    progressive=True
                )
                
                compressed_data = output.getvalue()
                
                # 圧縮効果ログ
                original_size = len(file_data)
                compressed_size = len(compressed_data)
                compression_ratio = (1 - compressed_size / original_size) * 100
                
                logger.info(f"Image compressed: {original_size}B → {compressed_size}B ({compression_ratio:.1f}% reduction)")
                
                return compressed_data
                
        except Exception as e:
            logger.error(f"Image compression error: {e}")
            raise Exception(f"画像圧縮中にエラーが発生しました: {str(e)}")
    
    def upload_to_storage(
        self,
        file_data: bytes,
        filename: str,
        user_id: str,
        metadata: Optional[Dict] = None
    ) -> Dict[str, str]:
        """Firebase Storageにアップロード"""
        try:
            # ユニークファイル名生成
            file_extension = os.path.splitext(filename)[1].lower()
            unique_filename = f"{uuid.uuid4().hex}{file_extension}"
            storage_path = f"images/{user_id}/{unique_filename}"
            
            # Storageにアップロード
            blob = self.bucket.blob(storage_path)
            
            # メタデータ設定
            if metadata:
                blob.metadata = metadata
            
            # コンテンツタイプ設定
            content_type = mimetypes.guess_type(filename)[0] or 'application/octet-stream'
            
            blob.upload_from_string(
                file_data,
                content_type=content_type
            )
            
            # 署名付きURL生成（24時間有効）
            expiration = datetime.utcnow() + timedelta(hours=24)
            signed_url = blob.generate_signed_url(expiration=expiration)
            
            # 公開URL生成
            public_url = f"https://storage.googleapis.com/{self.bucket_name}/{storage_path}"
            
            logger.info(f"Image uploaded successfully: {storage_path}")
            
            return {
                'storage_path': storage_path,
                'signed_url': signed_url,
                'public_url': public_url,
                'filename': unique_filename,
                'original_filename': filename
            }
            
        except Exception as e:
            logger.error(f"Storage upload error: {e}")
            raise Exception(f"ファイルアップロード中にエラーが発生しました: {str(e)}")
    
    def save_image_metadata(
        self,
        image_id: str,
        user_id: str,
        storage_info: Dict,
        image_info: Dict,
        metadata: Optional[Dict] = None
    ) -> str:
        """画像メタデータをFirestoreに保存"""
        try:
            doc_data = {
                'id': image_id,
                'user_id': user_id,
                'original_filename': storage_info['original_filename'],
                'storage_path': storage_info['storage_path'],
                'signed_url': storage_info['signed_url'],
                'public_url': storage_info['public_url'],
                'width': image_info['width'],
                'height': image_info['height'],
                'format': image_info['format'],
                'file_size': image_info.get('file_size', 0),
                'created_at': firestore.SERVER_TIMESTAMP,
                'updated_at': firestore.SERVER_TIMESTAMP,
                'status': 'active'
            }
            
            # 追加メタデータマージ
            if metadata:
                doc_data.update(metadata)
            
            # Firestore保存
            doc_ref = self.db.collection('images').document(image_id)
            doc_ref.set(doc_data)
            
            logger.info(f"Image metadata saved: {image_id}")
            
            return image_id
            
        except Exception as e:
            logger.error(f"Metadata save error: {e}")
            raise Exception(f"画像メタデータ保存中にエラーが発生しました: {str(e)}")
    
    def process_and_upload(
        self,
        file_data: bytes,
        filename: str,
        user_id: str,
        quality_level: str = 'medium_quality',
        metadata: Optional[Dict] = None
    ) -> Dict[str, Union[str, Dict]]:
        """画像の検証・圧縮・アップロード・メタデータ保存の統合処理"""
        try:
            # 1. 画像検証
            validation_result = self.validate_image(file_data, filename)
            if not validation_result['valid']:
                return {
                    'success': False,
                    'error': validation_result['error']
                }
            
            # 2. 画像圧縮
            compressed_data = self.compress_image(file_data, quality_level)
            
            # 3. Storage アップロード
            storage_info = self.upload_to_storage(
                compressed_data,
                filename,
                user_id,
                metadata
            )
            
            # 4. メタデータ保存
            image_id = str(uuid.uuid4())
            metadata_id = self.save_image_metadata(
                image_id,
                user_id,
                storage_info,
                validation_result['image_info'],
                metadata
            )
            
            return {
                'success': True,
                'image_id': image_id,
                'storage_info': storage_info,
                'image_info': validation_result['image_info'],
                'compressed': True,
                'quality_level': quality_level
            }
            
        except Exception as e:
            logger.error(f"Image processing error: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_image_metadata(self, image_id: str, user_id: str) -> Optional[Dict]:
        """画像メタデータ取得"""
        try:
            doc_ref = self.db.collection('images').document(image_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return None
            
            data = doc.to_dict()
            
            # ユーザー権限チェック
            if data.get('user_id') != user_id:
                logger.warning(f"Unauthorized access attempt: {user_id} -> {image_id}")
                return None
            
            return data
            
        except Exception as e:
            logger.error(f"Get metadata error: {e}")
            return None
    
    def delete_image(self, image_id: str, user_id: str) -> bool:
        """画像削除（Storage + Firestore）"""
        try:
            # メタデータ取得
            metadata = self.get_image_metadata(image_id, user_id)
            if not metadata:
                return False
            
            # Storage削除
            storage_path = metadata.get('storage_path')
            if storage_path:
                blob = self.bucket.blob(storage_path)
                if blob.exists():
                    blob.delete()
                    logger.info(f"Storage file deleted: {storage_path}")
            
            # Firestore削除
            doc_ref = self.db.collection('images').document(image_id)
            doc_ref.delete()
            
            logger.info(f"Image deleted successfully: {image_id}")
            return True
            
        except Exception as e:
            logger.error(f"Delete image error: {e}")
            return False
    
    def list_user_images(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict]:
        """ユーザーの画像一覧取得"""
        try:
            query = (
                self.db.collection('images')
                .where('user_id', '==', user_id)
                .where('status', '==', 'active')
                .order_by('created_at', direction=firestore.Query.DESCENDING)
                .limit(limit)
                .offset(offset)
            )
            
            docs = query.stream()
            images = []
            
            for doc in docs:
                data = doc.to_dict()
                images.append(data)
            
            logger.info(f"Retrieved {len(images)} images for user: {user_id}")
            return images
            
        except Exception as e:
            logger.error(f"List images error: {e}")
            return []

# サービスインスタンス作成関数
def create_image_processing_service(bucket_name: str = None) -> ImageProcessingService:
    """ImageProcessingServiceインスタンス作成"""
    return ImageProcessingService(bucket_name)

# エクスポート用
__all__ = [
    'ImageProcessingService',
    'create_image_processing_service'
]