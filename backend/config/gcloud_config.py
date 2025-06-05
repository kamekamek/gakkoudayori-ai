"""
Google Cloud 設定管理
"""
import os
import json
from pathlib import Path
from google.cloud import firestore, storage
from google.oauth2 import service_account
from typing import Optional

class CloudConfig:
    """Google Cloud サービス設定管理クラス"""
    
    def __init__(self):
        self.project_id = self._get_project_id()
        self.credentials = self._load_credentials()
        self.location = "asia-northeast1"
        
    def _get_project_id(self) -> str:
        """プロジェクトIDを取得"""
        # 環境変数から取得
        project_id = os.getenv('GOOGLE_CLOUD_PROJECT')
        if project_id:
            return project_id
            
        # サービスアカウントキーから取得
        credentials_path = self._get_credentials_path()
        if credentials_path and credentials_path.exists():
            with open(credentials_path, 'r') as f:
                creds_data = json.load(f)
                return creds_data.get('project_id', 'yutori-kyoshitsu')
        
        return 'yutori-kyoshitsu'  # デフォルト
    
    def _get_credentials_path(self) -> Optional[Path]:
        """認証情報ファイルのパスを取得"""
        # 環境変数から取得
        creds_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
        if creds_path:
            return Path(creds_path)
            
        # デフォルトパス
        default_path = Path(__file__).parent.parent / 'credentials' / 'service-account-key.json'
        return default_path if default_path.exists() else None
    
    def _load_credentials(self) -> Optional[service_account.Credentials]:
        """認証情報を読み込み"""
        credentials_path = self._get_credentials_path()
        if not credentials_path:
            return None
            
        try:
            return service_account.Credentials.from_service_account_file(
                str(credentials_path)
            )
        except Exception as e:
            import logging
            logging.warning(f"認証情報の読み込みに失敗: {e}")
            # Consider raising exception in production environments
            # raise RuntimeError(f"Failed to load credentials: {e}")
            return None

    def get_firestore_client(self) -> firestore.Client:
        """Firestoreクライアントを取得"""
        if self.credentials:
            return firestore.Client(
                project=self.project_id,
                credentials=self.credentials
            )
        else:
            # デフォルト認証を使用（Cloud Run等の場合）
            return firestore.Client(project=self.project_id)
    
    def get_storage_client(self) -> storage.Client:
        """Cloud Storageクライアントを取得"""
        if self.credentials:
            return storage.Client(
                project=self.project_id,
                credentials=self.credentials
            )
        else:
            return storage.Client(project=self.project_id)
    
    def get_bucket_name(self, bucket_type: str) -> str:
        """バケット名を取得"""
        bucket_names = {
            'uploads': f'{self.project_id}-uploads',
            'templates': f'{self.project_id}-templates',
            'exports': f'{self.project_id}-exports'
        }
        return bucket_names.get(bucket_type, f'{self.project_id}-{bucket_type}')


# グローバル設定インスタンス
cloud_config = CloudConfig()


def test_connections(dry_run: bool = True):
    """
    接続テスト関数
    
    Args:
        dry_run (bool): Trueの場合は実際の操作をスキップしてモック操作を実行。
                       Falseの場合は実際のGoogle Cloudリソースに対して操作を実行。
    """
    print(f"🔧 Google Cloud 接続テスト開始...")
    print(f"📋 プロジェクトID: {cloud_config.project_id}")
    
    if dry_run:
        print("🔒 DRY RUN モード: 実際のリソース操作はスキップされます")
    else:
        print("⚠️  警告: 実際のGoogle Cloudリソースに対して操作を実行します")
        print("⚠️  これにより実際のリソースの作成・削除が行われます")
        
        # ユーザー確認プロンプト
        try:
            confirmation = input("続行しますか？ (yes/no): ").lower().strip()
            if confirmation not in ['yes', 'y']:
                print("❌ 操作がキャンセルされました")
                return
        except (EOFError, KeyboardInterrupt):
            print("\n❌ 操作がキャンセルされました")
            return
    
    # Firestore テスト
    try:
        db = cloud_config.get_firestore_client()
        
        if dry_run:
            print("🔍 [DRY RUN] Firestore クライアント初期化チェック")
            if db:
                print("✅ [DRY RUN] Firestore 接続設定成功 (実際の操作はスキップ)")
            else:
                print("❌ [DRY RUN] Firestore 接続設定失敗")
        else:
            # テスト用ドキュメント作成
            test_ref = db.collection('health_check').document('test')
            test_ref.set({
                'timestamp': firestore.SERVER_TIMESTAMP,
                'status': 'success',
                'message': 'Firestore connection successful'
            })
            
            # ドキュメント読み取り
            doc = test_ref.get()
            if doc.exists:
                print("✅ Firestore 接続成功")
                # テストドキュメント削除
                test_ref.delete()
            else:
                print("❌ Firestore 接続失敗")
            
    except Exception as e:
        if dry_run:
            print(f"❌ [DRY RUN] Firestore 設定エラー: {e}")
        else:
            print(f"❌ Firestore エラー: {e}")
    
    # Cloud Storage テスト
    try:
        storage_client = cloud_config.get_storage_client()
        bucket_name = cloud_config.get_bucket_name('uploads')
        bucket = storage_client.bucket(bucket_name)
        
        if dry_run:
            print("🔍 [DRY RUN] Cloud Storage クライアント初期化チェック")
            if storage_client:
                print("✅ [DRY RUN] Cloud Storage 接続設定成功 (実際の操作はスキップ)")
                print(f"🔍 [DRY RUN] 対象バケット: {bucket_name}")
            else:
                print("❌ [DRY RUN] Cloud Storage 接続設定失敗")
        else:
            # バケット存在確認
            if bucket.exists():
                print("✅ Cloud Storage 接続成功")
                
                # テストファイルアップロード
                blob = bucket.blob('test/connection_test.txt')
                blob.upload_from_string('Hello from ゆとり職員室!')
                
                # ファイルダウンロードテスト
                content = blob.download_as_text()
                if content == 'Hello from ゆとり職員室!':
                    print("✅ Cloud Storage ファイル操作成功")
                
                # テストファイル削除
                blob.delete()
                
            else:
                print(f"❌ Cloud Storage バケット '{bucket_name}' が見つかりません")
            
    except Exception as e:
        if dry_run:
            print(f"❌ [DRY RUN] Cloud Storage 設定エラー: {e}")
        else:
            print(f"❌ Cloud Storage エラー: {e}")
    
    mode_str = "[DRY RUN]" if dry_run else ""
    print(f"🎉 {mode_str} 接続テスト完了")


if __name__ == "__main__":
    # デフォルトはdry_runモードで安全にテスト
    # 実際のリソース操作を行う場合は test_connections(dry_run=False) を呼び出す
    test_connections() 