# GitHub Actions デプロイエラー修正ガイド

## 🚨 発生したエラー

### 1. シェルスクリプト構文エラー
```
813e621eb7c9be0d841a94301ca1b41610116206: command not found
Error: Process completed with exit code 127.
```

### 2. Google Cloud Build権限エラー
```
ERROR: (gcloud.builds.submit) The user is forbidden from accessing the bucket [gakkoudayori-ai_cloudbuild]. 
Please check your organization's policy or if the user has the "serviceusage.services.use" permission.
```

### 3. VPC Service Controls エラー ⭐ NEW
```
The build is running, and logs are being written to the default logs bucket.
This tool can only stream logs if you are Viewer/Owner of the project and, if applicable, allowed by your VPC-SC security policy.
The default logs bucket is always outside any VPC-SC security perimeter.
```

## 🔧 修正内容

### 1. シェルスクリプト構文エラーの修正

**問題**: LINE通知メッセージ内でコミットハッシュがバッククォート（`）で囲まれていたため、シェルがそれをコマンドとして実行しようとしていた。

**修正**: バッククォートをシングルクォートに変更

```yaml
# 修正前
MESSAGE_TEXT="コミット: `${{ github.sha }}`"

# 修正後  
MESSAGE_TEXT="コミット: '${{ github.sha }}'"
```

### 2. Google Cloud Build権限エラーの対処

**必要な権限**:
- Cloud Build Editor
- Storage Admin (Cloud Buildバケット用)
- Service Usage Consumer
- Cloud Run Admin

**対処方法**:

#### A. Google Cloud Console での権限設定
1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクト `gakkoudayori-ai` を選択
3. IAM と管理 > IAM に移動
4. GitHub Actions用サービスアカウントを選択
5. 以下の役割を追加：
   - Cloud Build Editor
   - Storage Admin
   - Service Usage Consumer
   - Cloud Run Admin

#### B. gcloud CLI での権限設定
```bash
# サービスアカウントのメールアドレスを設定
SERVICE_ACCOUNT="github-actions@gakkoudayori-ai.iam.gserviceaccount.com"

# 必要な権限を付与
gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/serviceusage.serviceUsageConsumer"

gcloud projects add-iam-policy-binding gakkoudayori-ai \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/run.admin"
```

### 3. VPC Service Controls エラーの対処 ⭐ NEW

**問題**: VPC Service Controlsのセキュリティポリシーにより、デフォルトのCloud Storageログバケットにアクセスできない。

**修正**: Cloud Buildのログストリーミングを無効化してVPC Service Controlsの制限を回避

```yaml
# 修正前
gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend-staging:latest .

# 修正後
gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend-staging:latest . \
  --suppress-logs
```

**参考**: [Google Cloud Build VPC Service Controls documentation](https://cloud.google.com/build/docs/private-pools/using-vpc-service-controls)

**代替案**:
- カスタムCloud Storageバケットを作成してVPC Service Controlsペリメーター内に配置
- プライベートプールを使用する場合は、適切なネットワーク設定を行う

## 📋 修正後の確認手順

1. **ワークフローファイルの確認**
   ```bash
   git add .github/workflows/ci-cd.yml
   git commit -m "🔧 Fix: VPC Service Controls logging issue"
   git push origin develop
   ```

2. **権限設定の確認**
   - Google Cloud Console でサービスアカウントの権限を確認
   - Cloud Build API が有効化されていることを確認

3. **デプロイテスト**
   - developブランチにプッシュしてステージング環境デプロイをテスト
   - エラーが解消されることを確認

## 🎯 今後の予防策

1. **シェルスクリプト構文チェック**
   - バッククォート（`）の使用を避ける
   - 変数展開時はシングルクォート（'）を使用

2. **権限管理**
   - サービスアカウントの権限を定期的に確認
   - 最小権限の原則に従って必要な権限のみ付与

3. **テスト環境での事前確認**
   - 本番デプロイ前にステージング環境でテスト
   - CI/CDパイプラインの動作確認

4. **VPC Service Controls対応** ⭐ NEW
   - Cloud Buildログの出力先を適切に設定
   - セキュリティポリシーに準拠したログ管理

## 📝 関連ドキュメント

- [Google Cloud Build IAM 権限](https://cloud.google.com/build/docs/iam-roles-permissions)
- [GitHub Actions シークレット管理](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Firebase Hosting GitHub Actions](https://github.com/FirebaseExtended/action-hosting-deploy)
- [VPC Service Controls with Cloud Build](https://cloud.google.com/build/docs/private-pools/using-vpc-service-controls) ⭐ NEW

# 🔧 GitHub Actions Firebase Hosting デプロイエラー修正

## 📅 発生日時
2025-06-15

## 🚨 エラー概要

Firebase Hosting デプロイ時に以下のエラーが発生：

### 1. GitHub Token権限エラー
```
RequestError [HttpError]: Resource not accessible by integration
status: 403
url: 'https://api.github.com/repos/kamekamek/yutorikyoshitu/check-runs'
x-accepted-github-permissions: 'checks=write'
```

### 2. channelID必須エラー
```
Error: channelID is currently required
The process '/usr/local/bin/npx' failed with exit code 1
```

## 🔍 原因分析

### 1. **GitHub Token権限不足**
- Firebase Hosting Deployアクションが`checks:write`権限を必要とする
- ワークフローに`permissions`セクションが設定されていなかった
- デフォルトの`GITHUB_TOKEN`では権限が不足

### 2. **channelId設定問題**
- プレビューデプロイで`channelId: pr-17`が設定されているが、Firebase CLIコマンドに正しく渡されていない
- **本番デプロイで`channelId`が未設定**（最新版では必須パラメータ）
- `entryPoint`パラメータが明示的に設定されていなかった

## ✅ 修正内容

### 1. permissions追加
各デプロイジョブに以下を追加：

```yaml
permissions:
  contents: read
  checks: write
  pull-requests: write  # プレビューデプロイのみ
```

### 2. channelId設定とentryPoint明示設定
Firebase Hosting Deployアクションに以下を追加：

**プレビューデプロイ**:
```yaml
- name: 👀 プレビューデプロイ
  uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}'
    channelId: pr-${{ github.event.number }}
    expires: 7d
    projectId: gakkoudayori-ai
    entryPoint: .  # 追加
```

**本番デプロイ**:
```yaml
- name: 🌐 フロントエンドデプロイ（本番）
  uses: FirebaseExtended/action-hosting-deploy@v0
  with:
    repoToken: '${{ secrets.GITHUB_TOKEN }}'
    firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}'
    projectId: gakkoudayori-ai
    channelId: live  # 本番環境用に追加
    entryPoint: .    # 追加
```

## 🎯 修正後の期待動作

1. **ステージングデプロイ**: `develop`ブランチプッシュ時に自動実行
2. **本番デプロイ**: `main`ブランチプッシュ時に自動実行  
3. **プレビューデプロイ**: プルリクエスト作成時に自動実行
4. **権限エラー解消**: `checks:write`権限でGitHub APIアクセス可能
5. **channelId正常動作**: プレビューチャンネルが正しく作成される

## 📋 確認チェックリスト

- [x] `permissions`セクション追加（全デプロイジョブ）
- [x] `entryPoint: .`設定追加
- [x] プレビューデプロイに`pull-requests: write`権限追加
- [x] 本番デプロイに`channelId: live`追加
- [ ] 次回デプロイ時の動作確認
- [ ] プレビューURL生成確認
- [ ] LINE通知動作確認

## 🔗 関連リンク

- [Firebase Hosting Deploy Action](https://github.com/FirebaseExtended/action-hosting-deploy)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/using-jobs/assigning-permissions-to-jobs)
- [Firebase CLI Channel Deploy](https://firebase.google.com/docs/hosting/multisites#deploy_to_a_preview_channel)

## 📝 今後の対策

1. **定期的なアクション更新**: Firebase Hosting Deployアクションの最新版確認
2. **権限設定の標準化**: 新しいワークフロー作成時の権限設定チェックリスト作成
3. **エラーモニタリング**: デプロイ失敗時の自動通知設定
4. **ドキュメント更新**: トラブルシューティング事例の蓄積 