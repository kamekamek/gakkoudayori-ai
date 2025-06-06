import os
import json
from functools import wraps
from typing import Optional, Dict, Any

import firebase_admin
from firebase_admin import credentials, auth
from fastapi import HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials


class FirebaseAuth:
    """Firebase Authentication管理クラス"""
    
    def __init__(self):
        self._app = None
        self.security = HTTPBearer()
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Firebase Admin SDKを初期化"""
        try:
            # 既に初期化済みの場合はスキップ
            if firebase_admin._apps:
                self._app = firebase_admin.get_app()
                return
            
            # サービスアカウント認証情報を取得
            cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            if cred_path and os.path.exists(cred_path):
                # サービスアカウントファイルから初期化
                cred = credentials.Certificate(cred_path)
            else:
                # 環境変数から認証情報を取得
                service_account_info = {
                    "type": "service_account",
                    "project_id": os.getenv('FIREBASE_PROJECT_ID', 'yutori-kyoshitu'),
                    "private_key_id": os.getenv('FIREBASE_PRIVATE_KEY_ID'),
                    "private_key": os.getenv('FIREBASE_PRIVATE_KEY', '').replace('\\n', '\n'),
                    "client_email": os.getenv('FIREBASE_CLIENT_EMAIL'),
                    "client_id": os.getenv('FIREBASE_CLIENT_ID'),
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
                    "client_x509_cert_url": os.getenv('FIREBASE_CLIENT_CERT_URL')
                }
                
                # 必須フィールドの確認
                required_fields = ['private_key', 'client_email', 'project_id']
                missing_fields = [field for field in required_fields if not service_account_info.get(field)]
                
                if missing_fields:
                    raise ValueError(f"Missing Firebase environment variables: {missing_fields}")
                
                cred = credentials.Certificate(service_account_info)
            
            # Firebase Admin SDKを初期化
            self._app = firebase_admin.initialize_app(cred)
            print("Firebase Admin SDK initialized successfully")
            
        except Exception as e:
            print(f"Firebase initialization error: {e}")
            raise
    
    async def verify_token(self, credentials: HTTPAuthorizationCredentials) -> Dict[str, Any]:
        """
        Firebase IDトークンを検証
        
        Args:
            credentials: HTTPAuthorizationCredentials from FastAPI security
            
        Returns:
            Dict containing user information
            
        Raises:
            HTTPException: 認証失敗時
        """
        try:
            # IDトークンを検証（無効化されたトークンもチェック）
            decoded_token = auth.verify_id_token(credentials.credentials, check_revoked=True)
            
            # ユーザー情報を返す
            return {
                'uid': decoded_token['uid'],
                'email': decoded_token.get('email'),
                'email_verified': decoded_token.get('email_verified', False),
                'name': decoded_token.get('name'),
                'picture': decoded_token.get('picture'),
                'firebase_claims': decoded_token
            }
            
        except auth.InvalidIdTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except auth.ExpiredIdTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except Exception as e:
            print(f"Token verification error: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication failed",
                headers={"WWW-Authenticate": "Bearer"},
            )
    
    async def get_user_by_uid(self, uid: str) -> Optional[Dict[str, Any]]:
        """
        UIDからFirebaseユーザー情報を取得
        
        Args:
            uid: Firebase ユーザーUID
            
        Returns:
            ユーザー情報の辞書、またはNone
        """
        try:
            user_record = auth.get_user(uid)
            return {
                'uid': user_record.uid,
                'email': user_record.email,
                'email_verified': user_record.email_verified,
                'display_name': user_record.display_name,
                'photo_url': user_record.photo_url,
                'disabled': user_record.disabled,
                'metadata': {
                    'creation_timestamp': user_record.user_metadata.creation_timestamp,
                    'last_sign_in_timestamp': user_record.user_metadata.last_sign_in_timestamp,
                }
            }
        except auth.UserNotFoundError:
            return None
        except Exception as e:
            print(f"Error getting user by UID: {e}")
            return None
    
    async def create_custom_token(self, uid: str, additional_claims: Optional[Dict] = None) -> str:
        """
        カスタムトークンを作成（特別な権限付与など）
        
        Args:
            uid: Firebase ユーザーUID
            additional_claims: 追加のクレーム
            
        Returns:
            カスタムトークン文字列
        """
        try:
            custom_token = auth.create_custom_token(uid, additional_claims)
            return custom_token.decode('utf-8')
        except Exception as e:
            print(f"Error creating custom token: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create custom token"
            )


# グローバルFirebaseAuth インスタンス
firebase_auth = FirebaseAuth()


async def get_current_user(request: Request) -> Dict[str, Any]:
    """
    リクエストから現在のユーザー情報を取得
    FastAPI Dependencyとして使用
    
    Args:
        request: FastAPI Request object
        
    Returns:
        現在のユーザー情報
        
    Raises:
        HTTPException: 認証失敗時
    """
    credentials = await firebase_auth.security(request)
    user_info = await firebase_auth.verify_token(credentials)
    return user_info


def require_auth(func):
    """
    認証が必要なエンドポイント用デコレータ
    
    使用例:
        @app.get("/protected")
        @require_auth
        async def protected_endpoint(current_user: dict = Depends(get_current_user)):
            return {"message": f"Hello {current_user['email']}"}
    """
    @wraps(func)
    async def wrapper(*args, **kwargs):
        current_user = kwargs.get("current_user")
        if current_user is None:
            raise HTTPException(status_code=401, detail="Authentication required")
        return await func(*args, **kwargs)
    return wrapper


def require_admin(func):
    """
    管理者権限が必要なエンドポイント用デコレータ
    
    注意: 現在はシンプルな実装。将来的にFirestore でadmin フラグを確認
    """
    @wraps(func)
    async def wrapper(*args, **kwargs):
        # 現在のユーザー情報を取得
        current_user = kwargs.get('current_user')
        if not current_user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication required"
            )
        
        # 管理者権限の確認（現在は特定のメールドメインで判定）
        email = current_user.get('email', '')
        admin_domains = ['@example.com']  # 実際の管理者ドメインに変更
        
        is_admin = any(email.endswith(domain) for domain in admin_domains)
        if not is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin privileges required"
            )
        
        return await func(*args, **kwargs)
    return wrapper


# 使用例用のミドルウェア関数
async def optional_auth(request: Request) -> Optional[Dict[str, Any]]:
    """
    オプショナル認証（認証されていなくてもOK）
    
    Args:
        request: FastAPI Request object
        
    Returns:
        ユーザー情報またはNone
    """
    try:
        authorization = request.headers.get("Authorization")
        if not authorization or not authorization.startswith("Bearer "):
            return None
        
        token = authorization.split(" ")[1]
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
        user_info = await firebase_auth.verify_token(credentials)
        return user_info
    except HTTPException:
        return None
    except Exception as e:
        print(f"Optional auth error: {e}")
        return None 