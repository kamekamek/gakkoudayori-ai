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

**修正**: Cloud Buildのログ出力先をCloud Loggingに変更

```yaml
# 修正前
gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend-staging:latest .

# 修正後
gcloud builds submit --tag gcr.io/gakkoudayori-ai/yutori-backend-staging:latest . \
  --logging=CLOUD_LOGGING_ONLY
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