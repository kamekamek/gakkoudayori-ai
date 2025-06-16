# 🚀 CI/CD セットアップ手順書

学校だよりAIのCI/CDパイプライン設定手順です。

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

# Firebase認証（サービスアカウントJSON）
FIREBASE_SERVICE_ACCOUNT_JSON='{
  "type": "service_account",
  "project_id": "gakkoudayori-ai",
  ...
}'

# LINE通知（本番環境のみ）
LINE_CHANNEL_ACCESS_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
LINE_TARGET_GROUP_ID="Cxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### 📝 シークレット取得方法

#### 1. GCP_SA_KEY の取得と権限設定

```bash
# サービスアカウント作成
gcloud iam service-accounts create gcp-sa-key \
    --display-name="GitHub Actions Service Account"

# 🔑 必須権限の付与
gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/serviceusage.serviceUsageConsumer"

# 🚨 重要: Cloud Run Service Agentがサービスアカウントのトークンを取得する権限
gcloud iam service-accounts add-iam-policy-binding gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com \
    --member="serviceAccount:service-944053509139@serverless-robot-prod.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountTokenCreator"

# キーファイル生成
gcloud iam service-accounts keys create gcp-sa-key.json \
    --iam-account=gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com

# ファイル内容をGCP_SA_KEYに設定
cat gcp-sa-key.json
```

#### 2. FIREBASE_SERVICE_ACCOUNT_JSON の取得

```bash
# Firebase プロジェクトのサービスアカウントキー生成
# Firebase Console > Project Settings > Service accounts > Generate new private key
# 生成されたJSONファイルの内容をFIREBASE_SERVICE_ACCOUNT_JSONに設定
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
**解決方法**: `FIREBASE_SERVICE_ACCOUNT_JSON`を再取得して設定。

#### 3. ビルドエラー
```
Error: Failed to compile application for the Web
```
**解決方法**: 
```bash
make reset-dev  # 開発環境リセット
make ci-test    # ローカルでCI環境テスト
```

#### 4. 🚨 Cloud Run デプロイ権限エラー（重要）
```
ERROR: (gcloud.run.deploy) [gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com] does not have permission to access namespaces instance [gakkoudayori-ai] (or it may not exist): The caller does not have permission
```

**原因**: Cloud Run Service Agentがサービスアカウントのアクセストークンを取得する権限がない

**解決方法**:
```bash
# 1. Cloud Run Service Agentにトークン作成権限を付与
gcloud iam service-accounts add-iam-policy-binding gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com \
    --member="serviceAccount:service-944053509139@serverless-robot-prod.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountTokenCreator"

# 2. サービスアカウントにCloud Run Admin権限を付与
gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com" \
    --role="roles/run.admin"
```

**📝 詳細説明**:
- `service-{PROJECT_NUMBER}@serverless-robot-prod.iam.gserviceaccount.com` は Google が管理する Cloud Run Service Agent
- このエージェントがユーザーのサービスアカウントのトークンを取得してCloud Runサービスを作成する
- `roles/iam.serviceAccountTokenCreator` 権限が必要

#### 5. 🔄 VPC Service Controls ログストリーミングエラー
```
ERROR: The build is running, and logs are being written to the default logs bucket.
This tool can only stream logs if you are Viewer/Owner of the project and, if applicable, allowed by your VPC-SC security policy.
```

**原因**: VPC Service Controlsがログストリーミングをブロック（ビルド自体は成功）

**解決方法**: 非同期ビルドとポーリング処理を使用
```yaml
# GitHub Actions ワークフロー内
- name: 🚀 バックエンドイメージビルド
  id: build_staging
  run: |
    BUILD_ID=$(gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend-staging:latest . --async --format="value(id)")
    echo "BUILD_ID=$BUILD_ID" >> $GITHUB_OUTPUT

- name: ⏳ バックエンドビルド完了待機
  run: |
    BUILD_ID=${{ steps.build_staging.outputs.BUILD_ID }}
    while true; do
      STATUS=$(gcloud builds describe $BUILD_ID --format="value(status)")
      if [[ "$STATUS" == "SUCCESS" ]]; then
        echo "Build succeeded."
        break
      elif [[ "$STATUS" == "FAILURE" || "$STATUS" == "INTERNAL_ERROR" || "$STATUS" == "TIMEOUT" ]]; then
        echo "Build failed with status: $STATUS"
        exit 1
      fi
      echo "Current build status: $STATUS. Waiting 10 seconds..."
      sleep 10
    done
```

#### 6. シェルスクリプト構文エラー
```
813e621eb7c9be0d841a94301ca1b41610116206: command not found
```

**原因**: LINE通知メッセージ内でバッククォート（`）を使用

**解決方法**: バッククォートをシングルクォート（'）に変更
```yaml
# ❌ 間違い
MESSAGE_TEXT="コミット: `${{ github.sha }}`"

# ✅ 正しい
MESSAGE_TEXT="コミット: '${{ github.sha }}'"
```

#### 7. 権限設定の確認方法
```bash
# サービスアカウントの権限確認
gcloud iam service-accounts get-iam-policy gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com

# プロジェクトレベルの権限確認
gcloud projects get-iam-policy gakkoudayori-ai \
    --flatten="bindings[].members" \
    --format="table(bindings.role)" \
    --filter="bindings.members:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com"
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

4. **Cloud Build ログ確認**
   ```bash
   # ビルドID取得後
   gcloud builds describe BUILD_ID
   gcloud builds log BUILD_ID
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

## 🗄️ データベース環境分離設定

### 🎯 概要
同一Firebaseプロジェクト内でコレクション名プレフィックスによる環境分離を実装。
追加費用なしで完全なデータ分離を実現。

### 🔧 実装方法

#### 1. 環境変数設定
```yaml
# .github/workflows/ci-cd.yml
env:
  ENVIRONMENT: prod    # prod/staging/dev
```

#### 2. firebase_service.py 修正
```python
def get_collection_name(base_name: str) -> str:
    """環境別コレクション名を生成"""
    env = os.getenv('ENVIRONMENT', 'dev')
    return f"{env}_{base_name}"
```

#### 3. 各サービスでの使用例
```python
# user_dictionary_service.py
doc_ref = self.db.collection(get_collection_name('user_dictionaries')).document(user_id)

# 他のサービスでも同様に適用
```

### 📊 コレクション構造
```
# 本番環境
prod_user_dictionaries/{user_id}
prod_documents/{doc_id}

# ステージング環境  
staging_user_dictionaries/{user_id}
staging_documents/{doc_id}

# 開発環境
dev_user_dictionaries/{user_id}
dev_documents/{doc_id}
```

### ✅ メリット
- ✅ **費用ゼロ**: 追加課金なし
- ✅ **完全分離**: 環境間でデータ汚染なし
- ✅ **実装簡単**: 環境変数1つで制御
- ✅ **権限管理**: 環境別セキュリティルール可能
- ✅ **バックアップ**: 環境別データ管理

### 🚨 注意事項
- 全てのFirestore操作で `get_collection_name()` を使用必須
- 環境変数 `ENVIRONMENT` が未設定の場合は 'dev' がデフォルト
- 既存データの移行が必要な場合は別途マイグレーション実装

### 📋 実装チェックリスト
- [ ] firebase_service.py に `get_collection_name()` 関数追加
- [ ] user_dictionary_service.py のコレクション名修正
- [ ] 他のサービスファイルのコレクション名修正
- [ ] CI/CD設定に環境変数追加
- [ ] テスト環境での動作確認
- [ ] 本番環境へのデプロイ

## 🔄 継続的改善

### 📝 定期レビュー項目
- [ ] 依存関係の更新
- [ ] セキュリティパッチ適用
- [ ] パフォーマンス最適化
- [ ] テストカバレッジ向上

### 🔐 セキュリティベストプラクティス

#### サービスアカウント権限の最小化
現在設定されている権限（必要最小限）:
```bash
# 確認済み権限リスト
roles/cloudbuild.builds.editor      # Cloud Build実行
roles/run.admin                     # Cloud Run管理
roles/storage.admin                 # Container Registry/Artifact Registry
roles/iam.serviceAccountUser        # サービスアカウント使用
roles/serviceusage.serviceUsageConsumer  # API使用
roles/iam.serviceAccountTokenCreator     # トークン作成（Service Agent用）
```

#### 定期的な権限監査
```bash
# 月次実行推奨
gcloud projects get-iam-policy gakkoudayori-ai \
    --flatten="bindings[].members" \
    --filter="bindings.members:gcp-sa-key@gakkoudayori-ai.iam.gserviceaccount.com"
```

---

## 🆘 サポート

問題が発生した場合は、以下を確認してください：

1. [GitHub Actions ログ](https://github.com/your-repo/actions)
2. [Firebase Console](https://console.firebase.google.com/)
3. [Google Cloud Console](https://console.cloud.google.com/)
4. [Cloud Build履歴](https://console.cloud.google.com/cloud-build/builds)

それでも解決しない場合は、Issueを作成してください。 