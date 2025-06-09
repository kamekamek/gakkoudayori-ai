# セキュリティチェックリスト

## 機密情報管理チェックリスト

### ✅ .gitignore設定完了項目

#### Google Cloud・Firebase関連
- [x] `service-account-key.json` - サービスアカウントキー
- [x] `*-service-account-*.json` - 各種サービスアカウントキー
- [x] `firebase-config.js` - Firebase設定
- [x] `.firebaserc` - Firebase設定ファイル
- [x] `firebase-debug.log` - Firebaseデバッグログ

#### 環境変数・設定ファイル
- [x] `.env` - 環境変数ファイル
- [x] `.env.*` - 環境別設定ファイル
- [x] `config.json` - 設定ファイル
- [x] `secrets.json` - 機密設定ファイル
- [x] `*.key`, `*.pem`, `*.p12`, `*.pfx` - 各種キーファイル

#### APIキー・認証情報
- [x] `*-api-key.txt` - 各種APIキーファイル
- [x] `google-credentials.json` - Google API認証情報
- [x] `line-channel-secret.txt` - LINE APIシークレット
- [x] `webhook-secrets.txt` - Webhook認証情報

#### バックエンド機密情報
- [x] `backend/credentials/` - 認証情報ディレクトリ
- [x] `backend/secrets/` - 機密情報ディレクトリ
- [x] `backend/.env*` - 環境変数ファイル
- [x] `backend/config/production.yml` - 本番設定
- [x] `backend/config/secrets.yml` - 機密設定

### 🔍 定期確認事項

#### 1. 機密情報ファイルの追跡状況確認
```bash
# Gitで追跡されている機密情報ファイルがないかチェック
git ls-files | grep -E "(credentials|\.env|secret|key\.json|firebase-config)"
```
**期待する結果**: 何も出力されない（機密情報ファイルが追跡されていない）

#### 2. .gitignoreの動作確認
```bash
# 特定のファイルがignoreされているかチェック
git check-ignore backend/credentials/service-account-key.json
git check-ignore backend/.env
git check-ignore frontend/web/firebase-config.js
```
**期待する結果**: 各ファイルパスが出力される（ignoreされている）

#### 3. 機密情報ファイルの存在確認
```bash
# 機密情報ファイルを検索
find . -name "*.env" -o -name "*secret*" -o -name "*key*.json" -o -name "*credentials*"
```

### ⚠️ 発見時の対応手順

#### 機密情報ファイルが誤ってコミットされた場合

1. **即座にリポジトリから削除**
```bash
git rm --cached path/to/secret-file
git commit -m "Remove secret file from tracking"
```

2. **履歴からも削除（必要に応じて）**
```bash
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret-file' \
  --prune-empty --tag-name-filter cat -- --all
```

3. **キーの無効化・再生成**
   - Google Cloud: サービスアカウントキーを削除・再生成
   - Firebase: プロジェクト設定でキーをリセット
   - LINE API: チャンネルシークレットを再生成

### 🛡️ セキュリティベストプラクティス

#### 開発時
1. **機密情報はすべて環境変数で管理**
2. **例示ファイル（.example）を活用**
3. **チーム共有は安全な方法で実施**
4. **定期的なキーローテーション**

#### デプロイ時
1. **本番環境では環境変数で設定**
2. **Cloud Run Secret Managerの使用**
3. **最小権限の原則**
4. **ログに機密情報を出力しない**

### 📋 月次チェック項目

- [ ] 機密情報ファイルの追跡状況確認
- [ ] .gitignoreの効果確認
- [ ] 不要なAPIキーの削除
- [ ] アクセス権限の見直し
- [ ] ログファイルの機密情報確認

### 🚨 緊急時連絡先

**機密情報漏洩を発見した場合**
1. 即座にキー・トークンを無効化
2. セキュリティインシデント報告
3. 影響範囲の調査・対応

### 🔗 参考リンク

- [Google Cloud セキュリティベストプラクティス](https://cloud.google.com/security/best-practices)
- [Firebase セキュリティルール](https://firebase.google.com/docs/rules)
- [Git Secrets ツール](https://github.com/awslabs/git-secrets) 