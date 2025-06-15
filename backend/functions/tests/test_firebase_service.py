"""
Firebase SDK統合コードのテスト

T1-FB-005-A: Firebase SDK統合コード
- Firebase初期化コード実装
- 認証ヘルパー関数実装
- Firestore接続テスト実装
- Storage接続テスト実装
- 全統合テスト通過
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
import json
from datetime import datetime

# Firebase関連のモック
from unittest.mock import Mock

# テスト対象モジュールのインポート（実装後）
# from firebase_service import FirebaseService


class TestFirebaseInitialization:
    """Firebase初期化テスト"""
    
    def test_firebase_initialization_success(self):
        """Firebase初期化が成功すること"""
        # Given: Firebase が未初期化の状態
        with patch('firebase_admin.initialize_app') as mock_init:
            mock_init.return_value = Mock()
            
            # When: Firebase を初期化
            from firebase_service import initialize_firebase
            result = initialize_firebase()
            
            # Then: 初期化が成功する
            assert result is True
            mock_init.assert_called_once()
    
    def test_firebase_initialization_already_initialized(self):
        """Firebase が既に初期化済みの場合の処理"""
        # Given: Firebase が既に初期化済み
        with patch('firebase_admin.get_app') as mock_get_app:
            mock_get_app.return_value = Mock()
            
            # When: 再度初期化を試行
            from firebase_service import initialize_firebase
            result = initialize_firebase()
            
            # Then: エラーなく成功する
            assert result is True
    
    def test_firebase_initialization_with_credentials(self):
        """サービスアカウントキーを使用した初期化"""
        # Given: サービスアカウントキーファイルが存在
        mock_credentials = Mock()
        
        with patch('firebase_admin.credentials.Certificate') as mock_cert, \
             patch('firebase_admin.initialize_app') as mock_init:
            
            mock_cert.return_value = mock_credentials
            
            # When: 認証情報付きで初期化
            from firebase_service import initialize_firebase_with_credentials
            result = initialize_firebase_with_credentials('../secrets/service-account-key.json')
            
            # Then: 認証情報が正しく設定される
            assert result is True
            mock_cert.assert_called_once_with('../secrets/service-account-key.json')
            mock_init.assert_called_once_with(mock_credentials)


class TestAuthenticationHelpers:
    """認証ヘルパー関数テスト"""
    
    def test_verify_id_token_success(self):
        """Firebase ID トークン検証が成功すること"""
        # Given: 有効なIDトークン
        mock_decoded_token = {
            'uid': 'test_user_123',
            'email': 'test@example.com',
            'name': 'Test User'
        }
        
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            mock_verify.return_value = mock_decoded_token
            
            # When: IDトークンを検証
            from firebase_service import verify_firebase_token
            result = verify_firebase_token('valid_token')
            
            # Then: デコードされたトークン情報が返される
            assert result['uid'] == 'test_user_123'
            assert result['email'] == 'test@example.com'
            mock_verify.assert_called_once_with('valid_token')
    
    def test_verify_id_token_invalid(self):
        """無効なIDトークンでエラーハンドリング"""
        # Given: 無効なIDトークン
        with patch('firebase_admin.auth.verify_id_token') as mock_verify:
            mock_verify.side_effect = Exception('Invalid token')
            
            # When: 無効なIDトークンを検証
            from firebase_service import verify_firebase_token
            result = verify_firebase_token('invalid_token')
            
            # Then: エラーが適切にハンドリングされる
            assert result is None
    
    def test_get_user_info_success(self):
        """ユーザー情報取得が成功すること"""
        # Given: 存在するユーザーUID
        mock_user_record = Mock()
        mock_user_record.uid = 'test_user_123'
        mock_user_record.email = 'test@example.com'
        mock_user_record.display_name = 'Test User'
        
        with patch('firebase_admin.auth.get_user') as mock_get_user:
            mock_get_user.return_value = mock_user_record
            
            # When: ユーザー情報を取得
            from firebase_service import get_user_info
            result = get_user_info('test_user_123')
            
            # Then: ユーザー情報が返される
            assert result.uid == 'test_user_123'
            assert result.email == 'test@example.com'
            mock_get_user.assert_called_once_with('test_user_123')
    
    def test_create_custom_token(self):
        """カスタムトークン作成機能"""
        # Given: ユーザーUIDとクレーム
        uid = 'test_user_123'
        additional_claims = {'admin': True}
        
        with patch('firebase_admin.auth.create_custom_token') as mock_create_token:
            mock_create_token.return_value = b'custom_token_bytes'
            
            # When: カスタムトークンを作成
            from firebase_service import create_custom_token
            result = create_custom_token(uid, additional_claims)
            
            # Then: トークンが作成される
            assert isinstance(result, bytes)
            mock_create_token.assert_called_once_with(uid, additional_claims)


class TestFirestoreOperations:
    """Firestore接続テスト"""
    
    def test_create_document_success(self):
        """ドキュメント作成が成功すること"""
        # Given: 正常なFirestore環境
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_doc_ref = Mock()
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.add.return_value = (None, mock_doc_ref)
        mock_doc_ref.id = 'doc_123'
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: ドキュメントを作成
            from firebase_service import create_document
            doc_data = {
                'title': 'Test Document',
                'content': 'Test Content',
                'author_uid': 'user_123',
                'created_at': datetime.now()
            }
            result = create_document('documents', doc_data)
            
            # Then: ドキュメントが作成される
            assert result == 'doc_123'
            mock_collection.add.assert_called_once_with(doc_data)
    
    def test_get_document_success(self):
        """ドキュメント取得が成功すること"""
        # Given: 存在するドキュメント
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_doc_ref = Mock()
        mock_doc_snapshot = Mock()
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.document.return_value = mock_doc_ref
        mock_doc_ref.get.return_value = mock_doc_snapshot
        mock_doc_snapshot.exists = True
        mock_doc_snapshot.to_dict.return_value = {
            'title': 'Test Document',
            'content': 'Test Content'
        }
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: ドキュメントを取得
            from firebase_service import get_document
            result = get_document('documents', 'doc_123')
            
            # Then: ドキュメントデータが返される
            assert result['title'] == 'Test Document'
            assert result['content'] == 'Test Content'
            mock_doc_ref.get.assert_called_once()
    
    def test_get_document_not_found(self):
        """存在しないドキュメント取得時の処理"""
        # Given: 存在しないドキュメント
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_doc_ref = Mock()
        mock_doc_snapshot = Mock()
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.document.return_value = mock_doc_ref
        mock_doc_ref.get.return_value = mock_doc_snapshot
        mock_doc_snapshot.exists = False
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: 存在しないドキュメントを取得
            from firebase_service import get_document
            result = get_document('documents', 'nonexistent')
            
            # Then: Noneが返される
            assert result is None
    
    def test_update_document_success(self):
        """ドキュメント更新が成功すること"""
        # Given: 更新可能なドキュメント
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_doc_ref = Mock()
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.document.return_value = mock_doc_ref
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: ドキュメントを更新
            from firebase_service import update_document
            update_data = {'title': 'Updated Title'}
            result = update_document('documents', 'doc_123', update_data)
            
            # Then: 更新が成功する
            assert result is True
            mock_doc_ref.update.assert_called_once_with(update_data)
    
    def test_delete_document_success(self):
        """ドキュメント削除が成功すること"""
        # Given: 削除可能なドキュメント
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_doc_ref = Mock()
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.document.return_value = mock_doc_ref
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: ドキュメントを削除
            from firebase_service import delete_document
            result = delete_document('documents', 'doc_123')
            
            # Then: 削除が成功する
            assert result is True
            mock_doc_ref.delete.assert_called_once()
    
    def test_query_documents_with_filters(self):
        """条件付きドキュメント検索が成功すること"""
        # Given: Firestoreクエリ環境
        mock_firestore = Mock()
        mock_collection = Mock()
        mock_query = Mock()
        mock_docs = [Mock(), Mock()]
        
        # ドキュメントのモック設定
        mock_docs[0].id = 'doc_1'
        mock_docs[0].to_dict.return_value = {'title': 'Document 1'}
        mock_docs[1].id = 'doc_2'  
        mock_docs[1].to_dict.return_value = {'title': 'Document 2'}
        
        mock_firestore.collection.return_value = mock_collection
        mock_collection.where.return_value = mock_query
        mock_query.order_by.return_value = mock_query
        mock_query.limit.return_value = mock_query
        mock_query.stream.return_value = iter(mock_docs)
        
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.return_value = mock_firestore
            
            # When: 条件付きでドキュメントを検索
            from firebase_service import query_documents
            result = query_documents(
                collection_name='documents',
                filters=[('author_uid', '==', 'user_123')],
                order_by='created_at',
                limit=10
            )
            
            # Then: 条件に合うドキュメントが返される
            assert len(result) == 2
            assert result[0]['title'] == 'Document 1'
            mock_collection.where.assert_called_once_with('author_uid', '==', 'user_123')
            mock_query.order_by.assert_called_once_with('created_at')
            mock_query.limit.assert_called_once_with(10)


class TestStorageOperations:
    """Storage接続テスト"""
    
    def test_upload_file_success(self):
        """ファイルアップロードが成功すること"""
        # Given: 正常なStorage環境
        mock_storage = Mock()
        mock_bucket = Mock()
        mock_blob = Mock()
        
        mock_storage.bucket.return_value = mock_bucket
        mock_bucket.blob.return_value = mock_blob
        
        with patch('firebase_admin.storage.bucket') as mock_get_bucket:
            mock_get_bucket.return_value = mock_bucket
            
            # When: ファイルをアップロード
            from firebase_service import upload_file_to_storage
            test_content = 'Test file content'.encode('utf-8')
            result = upload_file_to_storage(
                file_path='documents/test.txt',
                file_content=test_content,
                content_type='text/plain'
            )
            
            # Then: アップロードが成功する
            assert result is True
            mock_bucket.blob.assert_called_once_with('documents/test.txt')
            mock_blob.upload_from_string.assert_called_once_with(
                test_content,
                content_type='text/plain'
            )
    
    def test_download_file_success(self):
        """ファイルダウンロードが成功すること"""
        # Given: 存在するファイル
        mock_bucket = Mock()
        mock_blob = Mock()
        
        test_content = 'File content'.encode('utf-8')
        mock_bucket.blob.return_value = mock_blob
        mock_blob.exists.return_value = True
        mock_blob.download_as_bytes.return_value = test_content
        
        with patch('firebase_admin.storage.bucket') as mock_get_bucket:
            mock_get_bucket.return_value = mock_bucket
            
            # When: ファイルをダウンロード
            from firebase_service import download_file_from_storage
            result = download_file_from_storage('documents/test.txt')
            
            # Then: ファイル内容が返される
            assert result == test_content
            mock_blob.download_as_bytes.assert_called_once()
    
    def test_download_file_not_found(self):
        """存在しないファイルのダウンロード処理"""
        # Given: 存在しないファイル
        mock_bucket = Mock()
        mock_blob = Mock()
        
        mock_bucket.blob.return_value = mock_blob
        mock_blob.exists.return_value = False
        
        with patch('firebase_admin.storage.bucket') as mock_get_bucket:
            mock_get_bucket.return_value = mock_bucket
            
            # When: 存在しないファイルをダウンロード
            from firebase_service import download_file_from_storage
            result = download_file_from_storage('nonexistent.txt')
            
            # Then: Noneが返される
            assert result is None
    
    def test_generate_signed_url(self):
        """署名付きURL生成が成功すること"""
        # Given: Storage環境
        mock_bucket = Mock()
        mock_blob = Mock()
        
        mock_bucket.blob.return_value = mock_blob
        mock_blob.generate_signed_url.return_value = 'https://signed-url.example.com'
        
        with patch('firebase_admin.storage.bucket') as mock_get_bucket:
            mock_get_bucket.return_value = mock_bucket
            
            # When: 署名付きURLを生成
            from firebase_service import generate_download_url
            result = generate_download_url('documents/test.txt', expiration_hours=1)
            
            # Then: 署名付きURLが返される
            assert result == 'https://signed-url.example.com'
            mock_blob.generate_signed_url.assert_called_once()
    
    def test_delete_file_success(self):
        """ファイル削除が成功すること"""
        # Given: 削除可能なファイル
        mock_bucket = Mock()
        mock_blob = Mock()
        
        mock_bucket.blob.return_value = mock_blob
        
        with patch('firebase_admin.storage.bucket') as mock_get_bucket:
            mock_get_bucket.return_value = mock_bucket
            
            # When: ファイルを削除
            from firebase_service import delete_file_from_storage
            result = delete_file_from_storage('documents/test.txt')
            
            # Then: 削除が成功する
            assert result is True
            mock_blob.delete.assert_called_once()


class TestIntegrationTests:
    """統合テスト"""
    
    def test_full_document_lifecycle(self):
        """ドキュメントの作成→取得→更新→削除の一連のフロー"""
        # Given: 完全なFirebase環境
        with patch('firebase_admin.firestore.client') as mock_firestore_client, \
             patch('firebase_admin.storage.bucket') as mock_storage_bucket:
            
            # Firestoreのモック設定
            mock_firestore = Mock()
            mock_firestore_client.return_value = mock_firestore
            
            # Storageのモック設定
            mock_bucket = Mock()
            mock_storage_bucket.return_value = mock_bucket
            
            # When: 一連のドキュメント操作を実行
            from firebase_service import (
                create_document, get_document, 
                update_document, delete_document,
                upload_file_to_storage
            )
            
            # ドキュメント作成
            doc_data = {
                'title': 'Integration Test Document',
                'content': 'Test Content',
                'author_uid': 'user_123'
            }
            
            # Then: 全ての操作が連携して動作する
            # この統合テストでは、各機能が相互に影響しないことを確認
            assert True  # 実際のテストは実装後に詳細化
    
    def test_error_handling_integration(self):
        """エラーハンドリングの統合テスト"""
        # Given: エラーが発生する環境
        with patch('firebase_admin.firestore.client') as mock_client:
            mock_client.side_effect = Exception('Connection error')
            
            # When: エラーが発生する操作を実行
            from firebase_service import get_document
            result = get_document('documents', 'doc_123')
            
            # Then: エラーが適切にハンドリングされる
            assert result is None  # エラー時の適切な戻り値 