# image_metadata_service.py
"""
画像メタデータ管理サービス - Firestore統合・分析・検索
学校だよりAI用の画像メタデータ専用管理システム
"""

import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Union, Any

from firebase_admin import firestore
from google.cloud.firestore import FieldFilter, Query

# ロギング設定
logger = logging.getLogger(__name__)

class ImageMetadataService:
    """画像メタデータ専用管理サービス"""
    
    def __init__(self):
        """初期化"""
        self.db = firestore.client()
        self.collection_name = 'images'
        
        logger.info("ImageMetadataService initialized")
    
    def create_metadata_record(
        self,
        image_id: str,
        user_id: str,
        basic_info: Dict[str, Any],
        storage_info: Dict[str, str],
        additional_metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """メタデータレコード作成"""
        try:
            # 基本メタデータ構造
            metadata = {
                'id': image_id,
                'user_id': user_id,
                'created_at': firestore.SERVER_TIMESTAMP,
                'updated_at': firestore.SERVER_TIMESTAMP,
                'status': 'active',
                
                # 基本画像情報
                'original_filename': basic_info.get('original_filename', ''),
                'width': basic_info.get('width', 0),
                'height': basic_info.get('height', 0),
                'format': basic_info.get('format', ''),
                'file_size': basic_info.get('file_size', 0),
                'aspect_ratio': self._calculate_aspect_ratio(
                    basic_info.get('width', 0),
                    basic_info.get('height', 0)
                ),
                
                # Storage情報
                'storage_path': storage_info.get('storage_path', ''),
                'signed_url': storage_info.get('signed_url', ''),
                'public_url': storage_info.get('public_url', ''),
                
                # 使用状況トラッキング
                'usage_count': 0,
                'last_used_at': None,
                'newsletters_used_in': [],
                
                # 検索・分類用
                'tags': [],
                'category': 'general',
                'description': '',
                'alt_text': '',
                
                # 技術情報
                'compression_applied': False,
                'quality_level': 'original',
                'processing_history': []
            }
            
            # 追加メタデータマージ
            if additional_metadata:
                metadata.update(additional_metadata)
            
            # Firestore保存
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            doc_ref.set(metadata)
            
            logger.info(f"Metadata record created: {image_id}")
            return True
            
        except Exception as e:
            logger.error(f"Create metadata error: {e}")
            return False
    
    def update_metadata(
        self,
        image_id: str,
        user_id: str,
        updates: Dict[str, Any]
    ) -> bool:
        """メタデータ更新"""
        try:
            # 権限チェック
            if not self._check_user_permission(image_id, user_id):
                logger.warning(f"Unauthorized update attempt: {user_id} -> {image_id}")
                return False
            
            # 更新データ準備
            update_data = updates.copy()
            update_data['updated_at'] = firestore.SERVER_TIMESTAMP
            
            # Firestore更新
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            doc_ref.update(update_data)
            
            logger.info(f"Metadata updated: {image_id}")
            return True
            
        except Exception as e:
            logger.error(f"Update metadata error: {e}")
            return False
    
    def get_metadata(self, image_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """メタデータ取得"""
        try:
            doc_ref = self.db.collection(self.collection_name).document(image_id)
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
    
    def search_images(
        self,
        user_id: str,
        filters: Optional[Dict[str, Any]] = None,
        sort_by: str = 'created_at',
        sort_order: str = 'desc',
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """画像検索・フィルタリング"""
        try:
            # 基本クエリ
            query = self.db.collection(self.collection_name)
            query = query.where('user_id', '==', user_id)
            query = query.where('status', '==', 'active')
            
            # フィルター適用
            if filters:
                # カテゴリフィルター
                if 'category' in filters:
                    query = query.where('category', '==', filters['category'])
                
                # サイズフィルター
                if 'min_width' in filters:
                    query = query.where('width', '>=', filters['min_width'])
                if 'max_width' in filters:
                    query = query.where('width', '<=', filters['max_width'])
                
                # 日付フィルター
                if 'created_after' in filters:
                    query = query.where('created_at', '>=', filters['created_after'])
                if 'created_before' in filters:
                    query = query.where('created_at', '<=', filters['created_before'])
                
                # フォーマットフィルター
                if 'format' in filters:
                    query = query.where('format', '==', filters['format'])
            
            # ソート
            sort_direction = Query.DESCENDING if sort_order == 'desc' else Query.ASCENDING
            query = query.order_by(sort_by, direction=sort_direction)
            
            # ページネーション
            query = query.limit(limit).offset(offset)
            
            # 実行
            docs = query.stream()
            results = []
            
            for doc in docs:
                data = doc.to_dict()
                results.append(data)
            
            logger.info(f"Image search completed: {len(results)} results for user {user_id}")
            return results
            
        except Exception as e:
            logger.error(f"Search images error: {e}")
            return []
    
    def get_usage_statistics(self, user_id: str) -> Dict[str, Any]:
        """使用統計取得"""
        try:
            # 全画像取得
            docs = (
                self.db.collection(self.collection_name)
                .where('user_id', '==', user_id)
                .where('status', '==', 'active')
                .stream()
            )
            
            stats = {
                'total_images': 0,
                'total_file_size': 0,
                'formats': {},
                'categories': {},
                'average_usage': 0,
                'most_used_images': [],
                'recent_uploads': []
            }
            
            images = []
            for doc in docs:
                data = doc.to_dict()
                images.append(data)
            
            stats['total_images'] = len(images)
            
            for img in images:
                # ファイルサイズ合計
                stats['total_file_size'] += img.get('file_size', 0)
                
                # フォーマット統計
                format_type = img.get('format', 'unknown')
                stats['formats'][format_type] = stats['formats'].get(format_type, 0) + 1
                
                # カテゴリ統計
                category = img.get('category', 'general')
                stats['categories'][category] = stats['categories'].get(category, 0) + 1
            
            # 使用頻度統計
            if images:
                total_usage = sum(img.get('usage_count', 0) for img in images)
                stats['average_usage'] = total_usage / len(images)
                
                # 最も使用されている画像（上位5件）
                most_used = sorted(
                    images,
                    key=lambda x: x.get('usage_count', 0),
                    reverse=True
                )[:5]
                stats['most_used_images'] = [
                    {
                        'id': img['id'],
                        'filename': img.get('original_filename', ''),
                        'usage_count': img.get('usage_count', 0)
                    }
                    for img in most_used
                ]
                
                # 最近のアップロード（上位10件）
                recent = sorted(
                    images,
                    key=lambda x: x.get('created_at', datetime.min),
                    reverse=True
                )[:10]
                stats['recent_uploads'] = [
                    {
                        'id': img['id'],
                        'filename': img.get('original_filename', ''),
                        'created_at': img.get('created_at')
                    }
                    for img in recent
                ]
            
            logger.info(f"Usage statistics generated for user: {user_id}")
            return stats
            
        except Exception as e:
            logger.error(f"Get usage statistics error: {e}")
            return {}
    
    def track_image_usage(
        self,
        image_id: str,
        user_id: str,
        newsletter_id: Optional[str] = None
    ) -> bool:
        """画像使用トラッキング"""
        try:
            # 権限チェック
            if not self._check_user_permission(image_id, user_id):
                return False
            
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            
            # トランザクションで使用回数更新
            @firestore.transactional
            def update_usage(transaction):
                doc = doc_ref.get(transaction=transaction)
                if not doc.exists:
                    return False
                
                data = doc.to_dict()
                
                # 使用回数増加
                usage_count = data.get('usage_count', 0) + 1
                
                # 使用した学級通信ID追加
                newsletters_used = data.get('newsletters_used_in', [])
                if newsletter_id and newsletter_id not in newsletters_used:
                    newsletters_used.append(newsletter_id)
                
                # 更新
                transaction.update(doc_ref, {
                    'usage_count': usage_count,
                    'last_used_at': firestore.SERVER_TIMESTAMP,
                    'newsletters_used_in': newsletters_used,
                    'updated_at': firestore.SERVER_TIMESTAMP
                })
                
                return True
            
            transaction = self.db.transaction()
            success = update_usage(transaction)
            
            if success:
                logger.info(f"Image usage tracked: {image_id}")
            
            return success
            
        except Exception as e:
            logger.error(f"Track usage error: {e}")
            return False
    
    def add_tags(self, image_id: str, user_id: str, tags: List[str]) -> bool:
        """タグ追加"""
        try:
            if not self._check_user_permission(image_id, user_id):
                return False
            
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return False
            
            current_tags = doc.to_dict().get('tags', [])
            new_tags = list(set(current_tags + tags))  # 重複除去
            
            doc_ref.update({
                'tags': new_tags,
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            logger.info(f"Tags added to image {image_id}: {tags}")
            return True
            
        except Exception as e:
            logger.error(f"Add tags error: {e}")
            return False
    
    def soft_delete(self, image_id: str, user_id: str) -> bool:
        """ソフト削除（status変更）"""
        try:
            if not self._check_user_permission(image_id, user_id):
                return False
            
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            doc_ref.update({
                'status': 'deleted',
                'deleted_at': firestore.SERVER_TIMESTAMP,
                'updated_at': firestore.SERVER_TIMESTAMP
            })
            
            logger.info(f"Image soft deleted: {image_id}")
            return True
            
        except Exception as e:
            logger.error(f"Soft delete error: {e}")
            return False
    
    def _check_user_permission(self, image_id: str, user_id: str) -> bool:
        """ユーザー権限チェック"""
        try:
            doc_ref = self.db.collection(self.collection_name).document(image_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                return False
            
            data = doc.to_dict()
            return data.get('user_id') == user_id
            
        except Exception as e:
            logger.error(f"Permission check error: {e}")
            return False
    
    def _calculate_aspect_ratio(self, width: int, height: int) -> float:
        """アスペクト比計算"""
        if height == 0:
            return 0.0
        return round(width / height, 2)

# サービスインスタンス作成関数
def create_image_metadata_service() -> ImageMetadataService:
    """ImageMetadataServiceインスタンス作成"""
    return ImageMetadataService()

# エクスポート用
__all__ = [
    'ImageMetadataService',
    'create_image_metadata_service'
]