"""
Firebase Admin SDKの初期化とFirestoreクライアントの提供
"""
import os
import json
import logging
import firebase_admin
from firebase_admin import credentials, firestore, storage
from typing import Optional, Dict, Any
from google.cloud import secretmanager

# --- Globals ---
firebase_initialized = False
logger = logging.getLogger(__name__)

def get_credentials_from_secret_manager():
    if 'K_SERVICE' not in os.environ: # ローカル環境なら何もしない
        logger.info("Local environment: Skipping Secret Manager credential retrieval.")
        return None
    try:
        """Google Secret Managerからサービスアカウントキーを取得する"""
        client = secretmanager.SecretManagerServiceClient()
        secret_name = "projects/944053509139/secrets/FIREBASE_SERVICE_ACCOUNT_KEY/versions/latest"
        response = client.access_secret_version(request={"name": secret_name})
        payload = response.payload.data.decode("UTF-8")
        return json.loads(payload)
    except Exception as e:
        logger.error(f"Failed to retrieve credentials from Secret Manager: {e}", exc_info=True)
        return None

def initialize_firebase():
    """
    Firebase Admin SDKを初期化する。
    - Secret Managerの認証情報を優先的に使用
    - Cloud Run環境でSecret Managerに失敗した場合、ADCにフォールバック
    - ローカル環境でSecret Managerに失敗した場合はエラー
    """
    global firebase_initialized
    if firebase_initialized:
        return True

    try:
        # 既に初期化済みの場合は何もしない
        if firebase_admin._apps:
             logger.warning("Firebase app already initialized.")
             firebase_initialized = True
             return True

        project_id = 'gakkoudayori-ai'
        options = {'projectId': project_id}
        
        # Secret Managerから認証情報を取得試行
        creds_json = get_credentials_from_secret_manager()
        
        if creds_json:
            creds = credentials.Certificate(creds_json)
            firebase_admin.initialize_app(creds, options)
            logger.info("Firebase app initialized successfully with Secret Manager credentials.")
        else:
            # Secret Manager failed, try Application Default Credentials
            logger.warning("Failed to retrieve credentials from Secret Manager. Attempting to use Application Default Credentials.")
            try:
                cred = credentials.ApplicationDefault()
                firebase_admin.initialize_app(credential=cred, options=options)
                logger.info("Firebase app initialized successfully with Application Default Credentials.")
            except Exception as adc_e:
                logger.error(f"Failed to initialize Firebase with Application Default Credentials: {adc_e}", exc_info=True)
                logger.error("Ensure GOOGLE_APPLICATION_CREDENTIALS is set or you have run 'gcloud auth application-default login'.")
                return False # ADC also failed
            
        firebase_initialized = True
        return True

    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}", exc_info=True)
        firebase_initialized = False
        return False

def get_firestore_client():
    """
    Firestoreクライアントを取得する。
    Firebaseが初期化されていない場合は初期化を試みる。
    """
    if not firebase_initialized:
        if not initialize_firebase():
            logger.error("Cannot get Firestore client because Firebase initialization failed.")
            return None
    
    try:
        return firestore.client()
    except Exception as e:
        logger.error(f"Error getting Firestore client after initialization: {e}", exc_info=True)
        return None


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
        'secret_manager_accessible': False,
        'old_credentials_exist': False,
        'timestamp': datetime.utcnow().isoformat()
    }
    
    # Secret Manager アクセスチェック
    try:
        secret_credentials = get_credentials_from_secret_manager()
        result['secret_manager_accessible'] = secret_credentials is not None
    except Exception as e:
        logger.error(f"Secret Manager check failed: {e}")
        
    # 古い認証ファイルチェック
    old_credentials_path = '/app/secrets/service-account-key.json'
    result['old_credentials_exist'] = os.path.exists(old_credentials_path)
    
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