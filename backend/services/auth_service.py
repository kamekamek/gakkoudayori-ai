"""
認証サービス
Firebase Authentication連携とセキュリティ機能を管理
"""

import re
import html
from datetime import datetime, timedelta
from typing import Dict, Optional, Any
import logging

import firebase_admin
from firebase_admin import auth
from google.cloud.firestore_v1.base_query import FieldFilter

from .firestore_service import firestore_service, User


class AuthService:
    """Firebase Authentication認証サービス"""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
        # Firebase Admin SDK初期化チェック
        try:
            firebase_admin.get_app()
        except ValueError:
            # アプリが初期化されていない場合は初期化
            firebase_admin.initialize_app()
    
    async def verify_token(self, id_token: str) -> Optional[Dict[str, Any]]:
        """Firebase ID トークンを検証する"""
        try:
            decoded_token = auth.verify_id_token(id_token)
            self.logger.info(f"Token verified for user: {decoded_token.get('uid')}")
            return decoded_token
        except Exception as e:
            self.logger.error(f"Token verification failed: {str(e)}")
            return None
    
    async def create_or_update_user(self, user: User) -> str:
        """ユーザーを作成または更新する"""
        try:
            # 既存ユーザーをチェック
            existing_user = await firestore_service.get_user(user.uid)
            
            if existing_user:
                # 既存ユーザーの場合は最終ログイン時間を更新
                await firestore_service.update_user(user.uid, {
                    'last_login': datetime.now(),
                    'display_name': user.display_name,
                    'email': user.email
                })
                self.logger.info(f"User updated: {user.uid}")
            else:
                # 新規ユーザーの場合は作成
                user.created_at = datetime.now()
                user.updated_at = datetime.now()
                await firestore_service.create_user(user)
                self.logger.info(f"New user created: {user.uid}")
            
            return user.uid
        except Exception as e:
            self.logger.error(f"User creation/update failed: {str(e)}")
            raise Exception(f"ユーザー作成/更新エラー: {str(e)}")
    
    async def get_user(self, uid: str) -> Optional[User]:
        """ユーザー情報を取得する"""
        try:
            return await firestore_service.get_user(uid)
        except Exception as e:
            self.logger.error(f"User retrieval failed: {str(e)}")
            return None
    
    def extract_user_from_token(self, token_data: Dict[str, Any]) -> User:
        """Firebase トークンからユーザー情報を抽出する"""
        return User(
            uid=token_data['uid'],
            email=token_data.get('email', ''),
            display_name=token_data.get('name', token_data.get('email', 'Anonymous'))
        )
    
    async def check_document_permission(
        self, 
        user_id: str, 
        document_id: str, 
        permission_type: str = 'read'
    ) -> bool:
        """ドキュメントへのアクセス権限をチェックする"""
        try:
            document = await firestore_service.get_document(document_id)
            
            if not document:
                self.logger.warning(f"Document not found: {document_id}")
                return False
            
            # 所有者チェック
            if document.user_id == user_id:
                return True
            
            # 将来的には共有機能やロールベースアクセス制御を実装
            # 現在は所有者のみアクセス可能
            self.logger.warning(f"Permission denied for user {user_id} on document {document_id}")
            return False
            
        except Exception as e:
            self.logger.error(f"Permission check failed: {str(e)}")
            return False
    
    def check_admin_permission(self, token_data: Dict[str, Any]) -> bool:
        """管理者権限をチェックする"""
        try:
            # カスタムクレームで管理者権限をチェック
            if token_data.get('admin', False):
                return True
            
            # 特定のメールアドレスで管理者権限をチェック
            admin_emails = ['admin@yutorikyoshitu.com']
            if token_data.get('email') in admin_emails:
                return True
            
            return False
        except Exception as e:
            self.logger.error(f"Admin permission check failed: {str(e)}")
            return False
    
    def check_token_expiry(self, token_data: Dict[str, Any]) -> bool:
        """トークンの有効期限をチェックする"""
        try:
            exp_timestamp = token_data.get('exp')
            if not exp_timestamp:
                return False
            
            exp_datetime = datetime.fromtimestamp(exp_timestamp)
            current_datetime = datetime.now()
            
            return exp_datetime > current_datetime
        except Exception as e:
            self.logger.error(f"Token expiry check failed: {str(e)}")
            return False
    
    async def sanitize_input(self, input_text: str) -> str:
        """入力値のサニタイゼーション"""
        try:
            # HTMLエスケープ
            sanitized = html.escape(input_text)
            
            # SQL インジェクション対策（基本的なパターン）
            sql_patterns = [
                r'(\s*(union|select|insert|update|delete|drop|create|alter|exec|execute)\s)',
                r'(\s*;\s*)',
                r'(\s*--\s*)',
                r'(\s*/\*.*?\*/\s*)'
            ]
            
            for pattern in sql_patterns:
                sanitized = re.sub(pattern, '', sanitized, flags=re.IGNORECASE)
            
            # JavaScriptコード削除
            js_patterns = [
                r'<script[^>]*>.*?</script>',
                r'javascript:',
                r'on\w+\s*=',
                r'<iframe[^>]*>.*?</iframe>'
            ]
            
            for pattern in js_patterns:
                sanitized = re.sub(pattern, '', sanitized, flags=re.IGNORECASE | re.DOTALL)
            
            return sanitized.strip()
        except Exception as e:
            self.logger.error(f"Input sanitization failed: {str(e)}")
            return ""
    
    async def create_custom_token(self, uid: str, additional_claims: Dict[str, Any] = None) -> str:
        """カスタムトークンを作成する（管理用）"""
        try:
            claims = additional_claims or {}
            custom_token = auth.create_custom_token(uid, claims)
            self.logger.info(f"Custom token created for user: {uid}")
            return custom_token.decode('utf-8')
        except Exception as e:
            self.logger.error(f"Custom token creation failed: {str(e)}")
            raise Exception(f"カスタムトークン作成エラー: {str(e)}")
    
    async def revoke_refresh_tokens(self, uid: str) -> bool:
        """ユーザーのリフレッシュトークンを無効化する"""
        try:
            auth.revoke_refresh_tokens(uid)
            self.logger.info(f"Refresh tokens revoked for user: {uid}")
            return True
        except Exception as e:
            self.logger.error(f"Token revocation failed: {str(e)}")
            return False
    
    async def set_custom_user_claims(self, uid: str, custom_claims: Dict[str, Any]) -> bool:
        """ユーザーにカスタムクレームを設定する"""
        try:
            auth.set_custom_user_claims(uid, custom_claims)
            self.logger.info(f"Custom claims set for user: {uid}")
            return True
        except Exception as e:
            self.logger.error(f"Setting custom claims failed: {str(e)}")
            return False
    
    async def validate_session(self, user_id: str, session_token: str) -> bool:
        """セッションの有効性を検証する"""
        try:
            # セッション検証ロジック
            # 実際の実装では、セッションストアとの照合を行う
            token_data = await self.verify_token(session_token)
            
            if not token_data:
                return False
            
            if token_data.get('uid') != user_id:
                return False
            
            if not self.check_token_expiry(token_data):
                return False
            
            return True
        except Exception as e:
            self.logger.error(f"Session validation failed: {str(e)}")
            return False
    
    async def log_security_event(
        self, 
        user_id: str, 
        event_type: str, 
        details: Dict[str, Any]
    ) -> None:
        """セキュリティイベントをログに記録する"""
        try:
            log_entry = {
                'user_id': user_id,
                'event_type': event_type,
                'details': details,
                'timestamp': datetime.now(),
                'ip_address': details.get('ip_address'),
                'user_agent': details.get('user_agent')
            }
            
            # 実際の実装では、セキュリティログ専用のコレクションに保存
            self.logger.warning(f"Security event: {event_type} for user {user_id}")
            
            # 重要なセキュリティイベントの場合は管理者に通知
            if event_type in ['failed_login_attempt', 'unauthorized_access', 'token_theft']:
                await self._notify_security_team(log_entry)
                
        except Exception as e:
            self.logger.error(f"Security event logging failed: {str(e)}")
    
    async def _notify_security_team(self, log_entry: Dict[str, Any]) -> None:
        """セキュリティチームに通知を送信する"""
        # 実際の実装では、メール送信やSlack通知などを行う
        self.logger.critical(f"SECURITY ALERT: {log_entry}")
    
    def validate_password_strength(self, password: str) -> tuple[bool, str]:
        """パスワード強度を検証する"""
        if len(password) < 8:
            return False, "パスワードは8文字以上である必要があります"
        
        if not re.search(r'[A-Z]', password):
            return False, "パスワードには大文字を含める必要があります"
        
        if not re.search(r'[a-z]', password):
            return False, "パスワードには小文字を含める必要があります"
        
        if not re.search(r'[0-9]', password):
            return False, "パスワードには数字を含める必要があります"
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            return False, "パスワードには特殊文字を含める必要があります"
        
        return True, "パスワードは適切な強度です"


# サービスインスタンス
auth_service = AuthService() 