"""
Firebase SDK統合サービス

T1-FB-005-A: Firebase SDK統合コード
- Firebase初期化コード実装
- 認証ヘルパー関数実装
- Firestore接続テスト実装
- Storage接続テスト実装
- 全統合テスト通過
"""

import os
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta

# Firebase関連のインポート
import firebase_admin
from firebase_admin import credentials, auth, firestore, storage
from google.cloud.firestore_v1.base_query import FieldFilter
from google.cloud.exceptions import GoogleCloudError

# 設定
logger = logging.getLogger(__name__)


# ==============================================================================
# Firebase初期化
# ==============================================================================

def initialize_firebase() -> bool:
    """
    Firebase アプリを初期化
    
    Returns:
        bool: 初期化が成功したかどうか
    """
    try:
        # 既に初期化されているかチェック
        firebase_admin.get_app()
        logger.info("Firebase app already initialized")
        return True
    except ValueError:
        # まだ初期化されていない場合
        try:
            # Cloud Run環境では Secret Manager からサービスアカウントキーを取得
            credentials = get_credentials_from_secret_manager()
            if credentials:
                firebase_admin.initialize_app(credentials)
                logger.info("Firebase app initialized with Secret Manager credentials")
            else:
                # フォールバック: デフォルト認証
                firebase_admin.initialize_app()
                logger.info("Firebase app initialized with default credentials")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase app: {e}")
            return False


def get_credentials_from_secret_manager():
    """Secret Manager からサービスアカウントキーを取得"""
    try:
        from google.cloud import secretmanager
        from google.oauth2 import service_account
        import json
        
        # Secret Manager クライアント作成
        client = secretmanager.SecretManagerServiceClient()
        
        # シークレット名
        name = f"projects/gakkoudayori-ai/secrets/service-account-key/versions/latest"
        
        # シークレットを取得
        response = client.access_secret_version(request={"name": name})
        secret_value = response.payload.data.decode("UTF-8")
        
        # JSON から認証情報を作成
        service_account_info = json.loads(secret_value)
        credentials = service_account.Credentials.from_service_account_info(service_account_info)
        
        logger.info("Successfully retrieved credentials from Secret Manager")
        return credentials
        
    except Exception as e:
        logger.warning(f"Failed to get credentials from Secret Manager: {e}")
        return None


def initialize_firebase_with_credentials(credentials_path: str) -> bool:
    """
    サービスアカウントキーを使用してFirebaseアプリを初期化
    
    Args:
        credentials_path (str): サービスアカウントキーファイルのパス
        
    Returns:
        bool: 初期化が成功したかどうか
    """
    try:
        # 既に初期化されているかチェック
        firebase_admin.get_app()
        logger.info("Firebase app already initialized")
        return True
    except ValueError:
        # まだ初期化されていない場合
        try:
            # サービスアカウントキーから認証情報を取得
            cred = credentials.Certificate(credentials_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"Firebase app initialized with credentials: {credentials_path}")
            return True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase app with credentials: {e}")
            return False


# ==============================================================================
# 認証ヘルパー関数
# ==============================================================================

def verify_firebase_token(id_token: str) -> Optional[Dict[str, Any]]:
    """
    Firebase IDトークンを検証してデコードされた情報を返す
    
    Args:
        id_token (str): Firebase IDトークン
        
    Returns:
        Optional[Dict[str, Any]]: デコードされたトークン情報、失敗時はNone
    """
    try:
        decoded_token = auth.verify_id_token(id_token)
        logger.info(f"Token verified for user: {decoded_token.get('uid')}")
        return decoded_token
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        return None


def get_user_info(uid: str) -> Optional[auth.UserRecord]:
    """
    ユーザーUIDから詳細情報を取得
    
    Args:
        uid (str): ユーザーUID
        
    Returns:
        Optional[auth.UserRecord]: ユーザー情報、存在しない場合はNone
    """
    try:
        user_record = auth.get_user(uid)
        logger.info(f"User info retrieved for: {uid}")
        return user_record
    except Exception as e:
        logger.error(f"Failed to get user info for {uid}: {e}")
        return None


def create_custom_token(uid: str, additional_claims: Optional[Dict[str, Any]] = None) -> Optional[bytes]:
    """
    カスタムトークンを作成
    
    Args:
        uid (str): ユーザーUID
        additional_claims (Optional[Dict[str, Any]]): 追加クレーム
        
    Returns:
        Optional[bytes]: カスタムトークン、失敗時はNone
    """
    try:
        custom_token = auth.create_custom_token(uid, additional_claims)
        logger.info(f"Custom token created for user: {uid}")
        return custom_token
    except Exception as e:
        logger.error(f"Failed to create custom token for {uid}: {e}")
        return None


# ==============================================================================
# Firestore操作
# ==============================================================================

def get_firestore_client():
    """Firestoreクライアントを取得"""
    return firestore.client()


def create_document(collection_name: str, data: Dict[str, Any]) -> Optional[str]:
    """
    Firestoreにドキュメントを作成
    
    Args:
        collection_name (str): コレクション名
        data (Dict[str, Any]): ドキュメントデータ
        
    Returns:
        Optional[str]: 作成されたドキュメントID、失敗時はNone
    """
    try:
        db = get_firestore_client()
        _, doc_ref = db.collection(collection_name).add(data)
        logger.info(f"Document created in {collection_name}: {doc_ref.id}")
        return doc_ref.id
    except Exception as e:
        logger.error(f"Failed to create document in {collection_name}: {e}")
        return None


def get_document(collection_name: str, document_id: str) -> Optional[Dict[str, Any]]:
    """
    Firestoreからドキュメントを取得
    
    Args:
        collection_name (str): コレクション名
        document_id (str): ドキュメントID
        
    Returns:
        Optional[Dict[str, Any]]: ドキュメントデータ、存在しない場合はNone
    """
    try:
        db = get_firestore_client()
        doc_ref = db.collection(collection_name).document(document_id)
        doc_snapshot = doc_ref.get()
        
        if doc_snapshot.exists:
            logger.info(f"Document retrieved from {collection_name}: {document_id}")
            return doc_snapshot.to_dict()
        else:
            logger.warning(f"Document not found in {collection_name}: {document_id}")
            return None
    except Exception as e:
        logger.error(f"Failed to get document from {collection_name}/{document_id}: {e}")
        return None


def update_document(collection_name: str, document_id: str, data: Dict[str, Any]) -> bool:
    """
    Firestoreのドキュメントを更新
    
    Args:
        collection_name (str): コレクション名
        document_id (str): ドキュメントID
        data (Dict[str, Any]): 更新データ
        
    Returns:
        bool: 更新が成功したかどうか
    """
    try:
        db = get_firestore_client()
        doc_ref = db.collection(collection_name).document(document_id)
        doc_ref.update(data)
        logger.info(f"Document updated in {collection_name}: {document_id}")
        return True
    except Exception as e:
        logger.error(f"Failed to update document in {collection_name}/{document_id}: {e}")
        return False


def delete_document(collection_name: str, document_id: str) -> bool:
    """
    Firestoreからドキュメントを削除
    
    Args:
        collection_name (str): コレクション名
        document_id (str): ドキュメントID
        
    Returns:
        bool: 削除が成功したかどうか
    """
    try:
        db = get_firestore_client()
        doc_ref = db.collection(collection_name).document(document_id)
        doc_ref.delete()
        logger.info(f"Document deleted from {collection_name}: {document_id}")
        return True
    except Exception as e:
        logger.error(f"Failed to delete document from {collection_name}/{document_id}: {e}")
        return False


def query_documents(
    collection_name: str,
    filters: Optional[List[Tuple[str, str, Any]]] = None,
    order_by: Optional[str] = None,
    limit: Optional[int] = None
) -> List[Dict[str, Any]]:
    """
    条件付きでドキュメントを検索
    
    Args:
        collection_name (str): コレクション名
        filters (Optional[List[Tuple[str, str, Any]]]): フィルター条件 [(field, operator, value), ...]
        order_by (Optional[str]): ソートフィールド
        limit (Optional[int]): 取得上限数
        
    Returns:
        List[Dict[str, Any]]: 検索結果のドキュメントリスト
    """
    try:
        db = get_firestore_client()
        query = db.collection(collection_name)
        
        # フィルター適用
        if filters:
            for field, operator, value in filters:
                query = query.where(field, operator, value)
        
        # ソート適用
        if order_by:
            query = query.order_by(order_by)
        
        # 制限適用
        if limit:
            query = query.limit(limit)
        
        # 実行
        docs = query.stream()
        results = []
        for doc in docs:
            doc_data = doc.to_dict()
            doc_data['id'] = doc.id
            results.append(doc_data)
        
        logger.info(f"Query executed on {collection_name}: {len(results)} documents found")
        return results
    except Exception as e:
        logger.error(f"Failed to query documents from {collection_name}: {e}")
        return []


# ==============================================================================
# Storage操作
# ==============================================================================

def get_storage_bucket():
    """Storageバケットを取得"""
    return storage.bucket()


def upload_file_to_storage(file_path: str, file_content: bytes, content_type: str = 'application/octet-stream') -> bool:
    """
    ファイルをCloud Storageにアップロード
    
    Args:
        file_path (str): ストレージ内のファイルパス
        file_content (bytes): ファイル内容
        content_type (str): MIMEタイプ
        
    Returns:
        bool: アップロードが成功したかどうか
    """
    try:
        bucket = get_storage_bucket()
        blob = bucket.blob(file_path)
        blob.upload_from_string(file_content, content_type=content_type)
        logger.info(f"File uploaded to storage: {file_path}")
        return True
    except Exception as e:
        logger.error(f"Failed to upload file to storage {file_path}: {e}")
        return False


def download_file_from_storage(file_path: str) -> Optional[bytes]:
    """
    Cloud Storageからファイルをダウンロード
    
    Args:
        file_path (str): ストレージ内のファイルパス
        
    Returns:
        Optional[bytes]: ファイル内容、存在しない場合はNone
    """
    try:
        bucket = get_storage_bucket()
        blob = bucket.blob(file_path)
        
        if blob.exists():
            file_content = blob.download_as_bytes()
            logger.info(f"File downloaded from storage: {file_path}")
            return file_content
        else:
            logger.warning(f"File not found in storage: {file_path}")
            return None
    except Exception as e:
        logger.error(f"Failed to download file from storage {file_path}: {e}")
        return None


def delete_file_from_storage(file_path: str) -> bool:
    """
    Cloud Storageからファイルを削除
    
    Args:
        file_path (str): ストレージ内のファイルパス
        
    Returns:
        bool: 削除が成功したかどうか
    """
    try:
        bucket = get_storage_bucket()
        blob = bucket.blob(file_path)
        blob.delete()
        logger.info(f"File deleted from storage: {file_path}")
        return True
    except Exception as e:
        logger.error(f"Failed to delete file from storage {file_path}: {e}")
        return False


def generate_download_url(file_path: str, expiration_hours: int = 1) -> Optional[str]:
    """
    ファイルの署名付きダウンロードURLを生成
    
    Args:
        file_path (str): ストレージ内のファイルパス
        expiration_hours (int): URL有効期限（時間）
        
    Returns:
        Optional[str]: 署名付きURL、失敗時はNone
    """
    try:
        bucket = get_storage_bucket()
        blob = bucket.blob(file_path)
        
        # 有効期限を設定
        expiration = datetime.utcnow() + timedelta(hours=expiration_hours)
        
        # 署名付きURLを生成
        signed_url = blob.generate_signed_url(expiration=expiration, method='GET')
        
        logger.info(f"Signed URL generated for: {file_path}")
        return signed_url
    except Exception as e:
        logger.error(f"Failed to generate signed URL for {file_path}: {e}")
        return None


# ==============================================================================
# ヘルパー関数
# ==============================================================================

def health_check() -> Dict[str, Any]:
    """
    Firebase接続の健全性チェック
    
    Returns:
        Dict[str, Any]: ヘルスチェック結果
    """
    result = {
        'firebase_initialized': False,
        'firestore_accessible': False,
        'storage_accessible': False,
        'timestamp': datetime.utcnow().isoformat()
    }
    
    try:
        # Firebase初期化チェック
        firebase_admin.get_app()
        result['firebase_initialized'] = True
        
        # Firestoreアクセスチェック
        db = get_firestore_client()
        test_doc = db.collection('__health_check__').document('test')
        test_doc.set({'check': True, 'timestamp': datetime.utcnow()})
        test_doc.delete()
        result['firestore_accessible'] = True
        
        # Storageアクセスチェック
        bucket = get_storage_bucket()
        test_blob = bucket.blob('__health_check__/test.txt')
        test_blob.upload_from_string(b'health check', content_type='text/plain')
        test_blob.delete()
        result['storage_accessible'] = True
        
        logger.info("Health check passed")
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        result['error'] = str(e)
    
    return result


def get_firebase_config() -> Dict[str, Any]:
    """
    Firebase設定情報を取得
    
    Returns:
        Dict[str, Any]: 設定情報
    """
    try:
        app = firebase_admin.get_app()
        project_id = app.project_id if hasattr(app, 'project_id') else 'unknown'
        
        return {
            'project_id': project_id,
            'initialized': True,
            'services': {
                'auth': True,
                'firestore': True,
                'storage': True
            }
        }
    except Exception as e:
        logger.error(f"Failed to get Firebase config: {e}")
        return {
            'initialized': False,
            'error': str(e)
        } 