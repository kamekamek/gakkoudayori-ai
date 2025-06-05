# Google Cloud 設定テスト機能

## 概要

`gcloud_config.py`の`test_connections`関数は、Google Cloud（Firestore、Cloud Storage）への接続をテストするための機能です。

## 安全な接続テスト機能

### 新機能: Dry Run モード

バージョンアップにより、本番環境での誤操作を防ぐため、以下の安全機能が追加されました：

#### 1. `dry_run` パラメータ

```python
def test_connections(dry_run: bool = True):
```

- **デフォルト**: `dry_run=True` （安全モード）
- **True**: 実際のリソース操作をスキップし、接続設定のみをチェック
- **False**: 実際のGoogle Cloudリソースに対して操作を実行

#### 2. ユーザー確認プロンプト

`dry_run=False`の場合、実際のリソース操作前に確認プロンプトが表示されます：

```
⚠️  警告: 実際のGoogle Cloudリソースに対して操作を実行します
⚠️  これにより実際のリソースの作成・削除が行われます
続行しますか？ (yes/no):
```

## 使用方法

### 1. 安全なテスト（推奨）

```python
from gcloud_config import test_connections

# デフォルトでdry_runモード
test_connections()

# 明示的にdry_runモードを指定
test_connections(dry_run=True)
```

### 2. 実際のリソース操作が必要な場合

```python
# 実際のGoogle Cloudリソースに対して操作
# ユーザー確認プロンプトが表示されます
test_connections(dry_run=False)
```

### 3. デモスクリプト

```bash
# 安全なテストのデモ
python test_gcloud_config.py
```

## テスト内容

### Dry Run モード (`dry_run=True`)
- ✅ Firestoreクライアントの初期化チェック
- ✅ Cloud Storageクライアントの初期化チェック
- ✅ バケット名の確認
- ❌ 実際のドキュメント作成・削除なし
- ❌ 実際のファイルアップロード・削除なし

### Live モード (`dry_run=False`)
- ✅ Firestoreへのテストドキュメント作成・読み取り・削除
- ✅ Cloud Storageへのテストファイルアップロード・ダウンロード・削除
- ⚠️ 実際のリソース操作が実行される

## 安全性の考慮事項

1. **デフォルトは安全モード**: 誤操作を防ぐため、デフォルトで`dry_run=True`
2. **明示的な確認**: Live モードでは必ずユーザー確認を要求
3. **操作の可視化**: どのモードで実行されているかを明確に表示
4. **エラーハンドリング**: 各モードに応じた適切なエラー表示

## トラブルシューティング

### よくある問題

1. **認証エラー**
   - サービスアカウントキーファイルの配置を確認
   - 環境変数 `GOOGLE_APPLICATION_CREDENTIALS` の設定を確認

2. **バケットが見つからない**
   - プロジェクトIDの設定を確認
   - バケットが作成されていることを確認

3. **権限エラー**
   - サービスアカウントに適切な権限が付与されているか確認
   - Firestore、Cloud Storageの有効化を確認

### デバッグ

```python
# 設定確認
from gcloud_config import cloud_config
print(f"Project ID: {cloud_config.project_id}")
print(f"Credentials: {cloud_config.credentials}")
``` 