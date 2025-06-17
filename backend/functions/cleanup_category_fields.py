#!/usr/bin/env python3
"""
Firestore データベースから category フィールドを削除するスクリプト

使用方法:
1. backend/functions ディレクトリで実行
2. python cleanup_category_fields.py [--dry-run]

--dry-run オプションを付けると、実際の削除は行わず確認のみ
"""

import os
import sys
import argparse
from datetime import datetime

# Firebase Admin SDK
import firebase_admin
from firebase_admin import credentials, firestore

def initialize_firebase():
    """Firebase Admin SDK を初期化"""
    if not firebase_admin._apps:
        # 環境変数から認証情報を取得
        service_account_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
        
        if service_account_path and os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            # デフォルト認証を使用（Cloud Functions環境など）
            firebase_admin.initialize_app()
    
    return firestore.client()

def cleanup_category_fields(dry_run=False):
    """user_dictionaries コレクションから category フィールドを削除"""
    
    # Firestore クライアント初期化
    db = initialize_firebase()
    
    print("🔍 Firestore データベースのクリーンアップを開始します...")
    if dry_run:
        print("⚠️  DRY RUN モード: 実際の削除は行いません")
    
    # user_dictionaries コレクションの全ドキュメントを取得
    users_ref = db.collection('user_dictionaries')
    users = users_ref.stream()
    
    total_users = 0
    total_terms_updated = 0
    
    for user_doc in users:
        total_users += 1
        user_id = user_doc.id
        user_data = user_doc.to_dict()
        
        print(f"\n👤 ユーザー: {user_id}")
        
        # custom_terms が存在するか確認
        if 'custom_terms' not in user_data:
            print("  ℹ️  custom_terms が存在しません。スキップします。")
            continue
        
        custom_terms = user_data.get('custom_terms', {})
        terms_to_update = {}
        
        # 各用語をチェック
        for term_name, term_data in custom_terms.items():
            if isinstance(term_data, dict) and 'category' in term_data:
                print(f"  📝 用語 '{term_name}' から category フィールドを削除します")
                print(f"     削除前の category: {term_data.get('category')}")
                
                # category フィールドを除外した新しいデータを作成
                updated_term = {k: v for k, v in term_data.items() if k != 'category'}
                terms_to_update[term_name] = updated_term
                total_terms_updated += 1
        
        # 更新が必要な場合
        if terms_to_update and not dry_run:
            try:
                # custom_terms を更新
                for term_name, updated_term in terms_to_update.items():
                    field_path = f'custom_terms.{term_name}'
                    users_ref.document(user_id).update({
                        field_path: updated_term,
                        'updated_at': datetime.now()
                    })
                
                print(f"  ✅ {len(terms_to_update)} 件の用語を更新しました")
                
            except Exception as e:
                print(f"  ❌ エラー: {e}")
        elif terms_to_update and dry_run:
            print(f"  🔸 DRY RUN: {len(terms_to_update)} 件の用語が更新対象です")
        else:
            print("  ℹ️  更新対象の用語はありません")
    
    # サマリー表示
    print("\n" + "="*50)
    print("📊 クリーンアップ完了サマリー:")
    print(f"  - 処理したユーザー数: {total_users}")
    print(f"  - 更新した用語数: {total_terms_updated}")
    
    if dry_run:
        print("\n⚠️  これは DRY RUN でした。実際のデータは変更されていません。")
        print("実際に削除を実行するには、--dry-run オプションを外して再実行してください。")

def main():
    """メイン関数"""
    parser = argparse.ArgumentParser(
        description='Firestore から category フィールドを削除します'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='実際の削除を行わず、削除対象を確認するのみ'
    )
    
    args = parser.parse_args()
    
    try:
        cleanup_category_fields(dry_run=args.dry_run)
    except KeyboardInterrupt:
        print("\n\n⚠️  処理が中断されました")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ エラーが発生しました: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()