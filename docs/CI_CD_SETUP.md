# 🚀 CI/CD セットアップ手順書

学級通信エディタのCI/CDパイプライン設定手順です。

## 📋 概要

### 🔄 ワークフロー
- **develop** ブランチ → ステージング環境自動デプロイ
- **main** ブランチ → 本番環境自動デプロイ  
- **プルリクエスト** → プレビュー環境自動デプロイ（7日間有効）

### 🧪 テスト・品質チェック
- Flutter静的解析 (`flutter analyze`)
- Flutterテスト実行 (`flutter test`)
- Python静的解析 (`flake8`)
- Pythonテスト実行 (`pytest`)

## ⚙️ 必要なシークレット設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下を設定：

### 🔑 必須シークレット

```bash
# Google Cloud Platform認証
GCP_SA_KEY='{
  "type": "service_account",
  "project_id": "gakkoudayori-ai",
  ...
}'

# Firebase認証トークン
FIREBASE_TOKEN="1//0xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 📝 シークレット取得方法

#### 1. GCP_SA_KEY の取得

```bash
# サービスアカウント作成
gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions"

# 必要な権限を付与
gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:github-actions@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:github-actions@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:github-actions@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

# キーファイル生成
gcloud iam service-accounts keys create github-actions-key.json \
    --iam-account=github-actions@gakkoudayori-ai.iam.gserviceaccount.com

# ファイル内容をGCP_SA_KEYに設定
cat github-actions-key.json
```

#### 2. FIREBASE_TOKEN の取得

```bash
# Firebase CLI でログイン
firebase login:ci

# 表示されたトークンをFIREBASE_TOKENに設定
```

## 🌍 環境設定

### 📱 フロントエンド環境変数

| 環境 | API_BASE_URL |
|------|--------------|
| 開発 | `http://localhost:8081/api/v1/ai` |
| ステージング | `https://staging-yutori-backend.asia-northeast1.run.app/api/v1/ai` |
| 本番 | `https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai` |

### 🔧 バックエンド環境

| 環境 | Cloud Run サービス名 | イメージ名 |
|------|---------------------|-----------|
| ステージング | `yutori-backend-staging` | `gcr.io/gakkoudayori-ai/yutori-backend-staging` |
| 本番 | `yutori-backend` | `gcr.io/gakkoudayori-ai/yutori-backend` |

## 🚀 デプロイURL

### 🌐 フロントエンド
- **本番**: https://gakkoudayori-ai.web.app
- **ステージング**: https://gakkoudayori-ai--staging.web.app
- **プレビュー**: https://gakkoudayori-ai--pr-{PR番号}.web.app

### 🔧 バックエンド
- **本番**: https://yutori-backend-944053509139.asia-northeast1.run.app
- **ステージング**: https://staging-yutori-backend.asia-northeast1.run.app

## 📋 ローカル開発コマンド

```bash
# 開発環境起動
make dev

# ステージング環境起動
make staging

# ステージング環境デプロイ
make deploy-staging

# テスト実行
make test

# 静的解析
make lint

# コードフォーマット
make format

# CI環境でのテスト
make ci-test
```

## 🔄 デプロイフロー

### 1. 開発フロー
```bash
# 機能ブランチで開発
git checkout -b feature/new-feature
git commit -m "新機能追加"
git push origin feature/new-feature

# プルリクエスト作成
# → プレビュー環境に自動デプロイ

# developブランチにマージ
# → ステージング環境に自動デプロイ
```

### 2. リリースフロー
```bash
# developからmainにマージ
git checkout main
git merge develop
git push origin main

# → 本番環境に自動デプロイ
# → リリースタグ自動作成
```

## 🛠️ トラブルシューティング

### ❌ よくあるエラー

#### 1. GCP認証エラー
```
Error: google-github-actions/auth failed
```
**解決方法**: `GCP_SA_KEY`の形式を確認。JSON全体をシークレットに設定。

#### 2. Firebase認証エラー
```
Error: HTTP Error: 401, Request had invalid authentication credentials
```
**解決方法**: `FIREBASE_TOKEN`を再取得して設定。

#### 3. ビルドエラー
```
Error: Failed to compile application for the Web
```
**解決方法**: 
```bash
make reset-dev  # 開発環境リセット
make ci-test    # ローカルでCI環境テスト
```

### 🔍 デバッグ方法

1. **GitHub Actions ログ確認**
   - Actions タブでワークフロー実行ログを確認

2. **ローカルでCI環境再現**
   ```bash
   make ci-test
   ```

3. **手動デプロイテスト**
   ```bash
   make deploy-preview
   ```

## 📊 監視・メトリクス

### 🎯 成功指標
- ✅ テスト成功率: 100%
- ✅ デプロイ成功率: 95%以上
- ✅ ビルド時間: 5分以内

### 📈 監視項目
- GitHub Actions実行状況
- Firebase Hosting配信状況
- Cloud Run稼働状況

## 🔄 継続的改善

### 📝 定期レビュー項目
- [ ] 依存関係の更新
- [ ] セキュリティパッチ適用
- [ ] パフォーマンス最適化
- [ ] テストカバレッジ向上

---

## 🆘 サポート

問題が発生した場合は、以下を確認してください：

1. [GitHub Actions ログ](https://github.com/your-repo/actions)
2. [Firebase Console](https://console.firebase.google.com/)
3. [Google Cloud Console](https://console.cloud.google.com/)

それでも解決しない場合は、Issueを作成してください。 