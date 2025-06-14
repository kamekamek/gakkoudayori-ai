#!/usr/bin/env python3
"""
Firebase/Firestore接続テストとユーザー辞書初期化スクリプト
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys
from datetime import datetime

def test_firebase_connection():
    """Firebase接続テスト"""
    print("=== Firebase/Firestore接続テスト ===")
    
    try:
        # Firebase初期化テスト
        try:
            app = firebase_admin.get_app()
            print('✅ Firebase app already initialized')
        except ValueError:
            # 新規初期化
            cred_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '../secrets/service-account-key.json')
            if os.path.exists(cred_path):
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
                print(f'✅ Firebase initialized with credentials: {cred_path}')
            else:
                firebase_admin.initialize_app()
                print('✅ Firebase initialized with default credentials')
        
        # Firestore接続テスト
        db = firestore.client()
        print('✅ Firestore client created successfully')
        
        # テストコレクションへの書き込み・読み込みテスト
        test_doc_ref = db.collection('test').document('connection_test')
        test_doc_ref.set({
            'timestamp': firestore.SERVER_TIMESTAMP, 
            'test': True,
            'message': 'Firebase connection test successful'
        })
        print('✅ Test document written to Firestore')
        
        # 読み込みテスト
        doc = test_doc_ref.get()
        if doc.exists:
            print('✅ Test document read from Firestore')
            data = doc.to_dict()
            print(f'   Data: {data}')
        else:
            print('❌ Test document not found')
            return False
        
        return True
        
    except Exception as e:
        print(f'❌ Firebase/Firestore test failed: {e}')
        import traceback
        traceback.print_exc()
        return False

def initialize_user_dictionary():
    """ユーザー辞書の初期化"""
    print("\n=== ユーザー辞書初期化 ===")
    
    try:
        db = firestore.client()
        
        # デフォルトユーザーの辞書ドキュメントを確認
        user_dict_ref = db.collection('user_dictionaries').document('default')
        user_dict_doc = user_dict_ref.get()
        
        if user_dict_doc.exists:
            print('✅ User dictionary collection exists')
            data = user_dict_doc.to_dict()
            print(f'   Keys: {list(data.keys()) if data else "Empty"}')
            
            # カスタム用語の数を確認
            custom_terms = data.get('custom_terms', {})
            usage_stats = data.get('usage_stats', {})
            print(f'   Custom terms: {len(custom_terms)}')
            print(f'   Usage stats: {len(usage_stats)}')
            
        else:
            print('⚠️  User dictionary document does not exist - creating initial document')
            # 初期データを作成
            initial_data = {
                'custom_terms': {},
                'usage_stats': {},
                'correction_history': [],
                'created_at': firestore.SERVER_TIMESTAMP,
                'updated_at': firestore.SERVER_TIMESTAMP
            }
            user_dict_ref.set(initial_data)
            print('✅ Initial user dictionary document created')
        
        # テスト用語を追加
        print("\n--- テスト用語追加 ---")
        test_term_data = {
            'custom_terms': {
                'テスト用語': {
                    'variations': ['てすとようご', 'テスト用語'],
                    'category': 'custom',
                    'confidence': 1.0,
                    'usage_count': 0,
                    'created_at': datetime.now().isoformat()
                }
            },
            'updated_at': firestore.SERVER_TIMESTAMP
        }
        
        user_dict_ref.set(test_term_data, merge=True)
        print('✅ Test term added to user dictionary')
        
        # 確認
        updated_doc = user_dict_ref.get()
        if updated_doc.exists:
            updated_data = updated_doc.to_dict()
            custom_terms = updated_data.get('custom_terms', {})
            print(f'✅ Verification: {len(custom_terms)} custom terms in dictionary')
            for term, data in custom_terms.items():
                print(f'   - {term}: {data.get("variations", [])}')
        
        return True
        
    except Exception as e:
        print(f'❌ User dictionary initialization failed: {e}')
        import traceback
        traceback.print_exc()
        return False

def test_user_dictionary_service():
    """ユーザー辞書サービスのテスト"""
    print("\n=== ユーザー辞書サービステスト ===")
    
    try:
        from user_dictionary_service import create_user_dictionary_service
        
        # サービス作成
        db = firestore.client()
        dict_service = create_user_dictionary_service(db)
        print('✅ User dictionary service created')
        
        # 辞書取得テスト
        dictionary = dict_service.get_user_dictionary('default')
        print(f'✅ Dictionary loaded: {len(dictionary)} terms')
        
        # 統計情報取得
        stats = dict_service.get_dictionary_stats('default')
        print(f'✅ Dictionary stats: {stats}')
        
        # Speech-to-Textコンテキスト生成
        contexts = dict_service.get_speech_contexts('default')
        print(f'✅ Speech contexts generated: {len(contexts)} terms')
        
        return True
        
    except Exception as e:
        print(f'❌ User dictionary service test failed: {e}')
        import traceback
        traceback.print_exc()
        return False

def main():
    """メイン実行関数"""
    print("Firebase/Firestore & User Dictionary Test")
    print("=" * 50)
    
    # 1. Firebase接続テスト
    if not test_firebase_connection():
        print("\n❌ Firebase connection test failed")
        sys.exit(1)
    
    # 2. ユーザー辞書初期化
    if not initialize_user_dictionary():
        print("\n❌ User dictionary initialization failed")
        sys.exit(1)
    
    # 3. ユーザー辞書サービステスト
    if not test_user_dictionary_service():
        print("\n❌ User dictionary service test failed")
        sys.exit(1)
    
    print("\n" + "=" * 50)
    print("✅ All tests passed successfully!")
    print("🎉 Firebase and User Dictionary are ready to use!")

if __name__ == "__main__":
    main() 