"""
認証機能のテスト
Firebase Authentication関連機能の動作確認
"""

import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime, timedelta
import jwt

from backend.services.firestore_service import firestore_service, User, DocumentStatus
from backend.services.auth_service import AuthService


class TestAuthService:
    """認証サービスのテストクラス"""
    
    @pytest.fixture
    def auth_service(self):
        """AuthServiceのフィクスチャ"""
        return AuthService()
    
    @pytest.fixture
    def mock_user_data(self):
        """テスト用ユーザーデータ"""
        return {
            'uid': 'test_user_123',
            'email': 'teacher@example.com',
            'display_name': '田中太郎',
            'email_verified': True
        }
    
    @pytest.fixture
    def mock_jwt_token(self):
        """テスト用JWTトークン"""
        payload = {
            'iss': 'https://securetoken.google.com/test-project',
            'aud': 'test-project',
            'auth_time': int(datetime.now().timestamp()),
            'user_id': 'test_user_123',
            'sub': 'test_user_123',
            'iat': int(datetime.now().timestamp()),
            'exp': int((datetime.now() + timedelta(hours=1)).timestamp()),
            'email': 'teacher@example.com',
            'email_verified': True,
            'firebase': {
                'identities': {
                    'google.com': ['123456789'],
                    'email': ['teacher@example.com']
                },
                'sign_in_provider': 'google.com'
            }
        }
        return jwt.encode(payload, 'secret', algorithm='HS256')

    @pytest.mark.asyncio
    async def test_verify_token_success(self, auth_service, mock_jwt_token):
        """有効なJWTトークンの検証テスト"""
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            # モックの設定
            mock_verify.return_value = {
                'uid': 'test_user_123',
                'email': 'teacher@example.com',
                'email_verified': True
            }
            
            # テスト実行
            result = await auth_service.verify_token(mock_jwt_token)
            
            # 検証
            assert result is not None
            assert result['uid'] == 'test_user_123'
            assert result['email'] == 'teacher@example.com'
            mock_verify.assert_called_once_with(mock_jwt_token)

    @pytest.mark.asyncio
    async def test_verify_token_invalid(self, auth_service):
        """無効なJWTトークンの検証テスト"""
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            # 無効なトークンのエラーを設定
            mock_verify.side_effect = Exception("Invalid token")
            
            # テスト実行
            result = await auth_service.verify_token("invalid_token")
            
            # 検証
            assert result is None

    @pytest.mark.asyncio
    async def test_create_user_success(self, auth_service, mock_user_data):
        """ユーザー作成の成功テスト"""
        with patch.object(firestore_service, 'create_user', new_callable=AsyncMock) as mock_create:
            mock_create.return_value = mock_user_data['uid']
            
            # テスト実行
            user = User(
                uid=mock_user_data['uid'],
                email=mock_user_data['email'],
                display_name=mock_user_data['display_name']
            )
            result = await auth_service.create_or_update_user(user)
            
            # 検証
            assert result == mock_user_data['uid']
            mock_create.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_user_success(self, auth_service, mock_user_data):
        """ユーザー取得の成功テスト"""
        with patch.object(firestore_service, 'get_user', new_callable=AsyncMock) as mock_get:
            expected_user = User(
                uid=mock_user_data['uid'],
                email=mock_user_data['email'],
                display_name=mock_user_data['display_name']
            )
            mock_get.return_value = expected_user
            
            # テスト実行
            result = await auth_service.get_user(mock_user_data['uid'])
            
            # 検証
            assert result is not None
            assert result.uid == mock_user_data['uid']
            assert result.email == mock_user_data['email']
            mock_get.assert_called_once_with(mock_user_data['uid'])

    @pytest.mark.asyncio
    async def test_check_document_permission_owner(self, auth_service):
        """ドキュメント権限チェック（所有者）"""
        user_id = 'test_user_123'
        document_id = 'test_doc_456'
        
        with patch.object(firestore_service, 'get_document', new_callable=AsyncMock) as mock_get:
            mock_document = Mock()
            mock_document.user_id = user_id
            mock_get.return_value = mock_document
            
            # テスト実行
            result = await auth_service.check_document_permission(user_id, document_id, 'write')
            
            # 検証
            assert result is True
            mock_get.assert_called_once_with(document_id)

    @pytest.mark.asyncio
    async def test_check_document_permission_not_owner(self, auth_service):
        """ドキュメント権限チェック（非所有者）"""
        user_id = 'test_user_123'
        document_id = 'test_doc_456'
        
        with patch.object(firestore_service, 'get_document', new_callable=AsyncMock) as mock_get:
            mock_document = Mock()
            mock_document.user_id = 'other_user_789'  # 別のユーザーのドキュメント
            mock_get.return_value = mock_document
            
            # テスト実行
            result = await auth_service.check_document_permission(user_id, document_id, 'write')
            
            # 検証
            assert result is False

    @pytest.mark.asyncio
    async def test_check_document_permission_not_found(self, auth_service):
        """ドキュメント権限チェック（ドキュメント不存在）"""
        user_id = 'test_user_123'
        document_id = 'nonexistent_doc'
        
        with patch.object(firestore_service, 'get_document', new_callable=AsyncMock) as mock_get:
            mock_get.return_value = None  # ドキュメントが存在しない
            
            # テスト実行
            result = await auth_service.check_document_permission(user_id, document_id, 'read')
            
            # 検証
            assert result is False

    def test_extract_user_from_token(self, auth_service):
        """トークンからユーザー情報抽出テスト"""
        token_data = {
            'uid': 'test_user_123',
            'email': 'teacher@example.com',
            'name': '田中太郎',
            'email_verified': True
        }
        
        # テスト実行
        user = auth_service.extract_user_from_token(token_data)
        
        # 検証
        assert isinstance(user, User)
        assert user.uid == token_data['uid']
        assert user.email == token_data['email']
        assert user.display_name == token_data['name']

    @pytest.mark.asyncio
    async def test_refresh_token_validation(self, auth_service, mock_jwt_token):
        """トークンリフレッシュの検証テスト"""
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            mock_verify.return_value = {
                'uid': 'test_user_123',
                'email': 'teacher@example.com',
                'email_verified': True,
                'auth_time': int(datetime.now().timestamp())
            }
            
            # テスト実行
            result = await auth_service.verify_token(mock_jwt_token)
            
            # 検証
            assert result is not None
            assert 'auth_time' in result

    @pytest.mark.asyncio
    async def test_admin_permission_check(self, auth_service):
        """管理者権限チェックテスト"""
        # 管理者ユーザー
        admin_token_data = {
            'uid': 'admin_user',
            'email': 'admin@yutorikyoshitu.com',
            'admin': True
        }
        
        # 一般ユーザー
        regular_token_data = {
            'uid': 'regular_user',
            'email': 'teacher@example.com'
        }
        
        # テスト実行
        admin_result = auth_service.check_admin_permission(admin_token_data)
        regular_result = auth_service.check_admin_permission(regular_token_data)
        
        # 検証
        assert admin_result is True
        assert regular_result is False

    @pytest.mark.asyncio
    async def test_session_timeout_check(self, auth_service):
        """セッションタイムアウトチェックテスト"""
        # 期限切れのトークン
        expired_token_data = {
            'uid': 'test_user_123',
            'exp': int((datetime.now() - timedelta(hours=1)).timestamp())
        }
        
        # 有効なトークン
        valid_token_data = {
            'uid': 'test_user_123',
            'exp': int((datetime.now() + timedelta(hours=1)).timestamp())
        }
        
        # テスト実行
        expired_result = auth_service.check_token_expiry(expired_token_data)
        valid_result = auth_service.check_token_expiry(valid_token_data)
        
        # 検証
        assert expired_result is False
        assert valid_result is True


class TestAuthIntegration:
    """認証機能の統合テスト"""
    
    @pytest.mark.asyncio
    async def test_full_auth_flow(self):
        """完全な認証フローのテスト"""
        auth_service = AuthService()
        
        # 1. トークン検証
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            mock_verify.return_value = {
                'uid': 'integration_test_user',
                'email': 'integration@example.com',
                'name': '統合テストユーザー',
                'email_verified': True
            }
            
            token_result = await auth_service.verify_token("valid_token")
            assert token_result is not None
            
            # 2. ユーザー作成/更新
            user = auth_service.extract_user_from_token(token_result)
            
            with patch.object(firestore_service, 'create_user', new_callable=AsyncMock) as mock_create:
                mock_create.return_value = user.uid
                
                create_result = await auth_service.create_or_update_user(user)
                assert create_result == user.uid
            
            # 3. 権限チェック
            with patch.object(firestore_service, 'get_document', new_callable=AsyncMock) as mock_get_doc:
                mock_document = Mock()
                mock_document.user_id = user.uid
                mock_get_doc.return_value = mock_document
                
                permission_result = await auth_service.check_document_permission(
                    user.uid, 'test_doc', 'read'
                )
                assert permission_result is True

    @pytest.mark.asyncio
    async def test_security_validation(self):
        """セキュリティ検証テスト"""
        auth_service = AuthService()
        
        # SQLインジェクション対策テスト
        malicious_input = "'; DROP TABLE users; --"
        result = await auth_service.sanitize_input(malicious_input)
        assert "DROP TABLE" not in result
        
        # XSS対策テスト
        xss_input = "<script>alert('xss')</script>"
        result = await auth_service.sanitize_input(xss_input)
        assert "<script>" not in result


if __name__ == "__main__":
    # テスト実行
    pytest.main([__file__, "-v"]) 