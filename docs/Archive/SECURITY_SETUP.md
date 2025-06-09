# 🔐 セキュリティ設定ガイド

## 概要

`ゆとり職員室`では、API キーやシークレット情報を安全に管理するため、環境変数ベースの設定システムを導入しています。

## ⚠️ 重要：機密情報の取り扱い

### 絶対にGitにコミットしてはいけないファイル
- `scripts/env/*.env` （テンプレート以外）
- `frontend/web/config.js`
- Firebase サービスアカウントキー
- API キー・トークン類

## 🚀 初期設定手順

### 1. 環境変数ファイルの作成

#### 開発環境
```bash
cd scripts/env
cp development.env.example development.env
# development.env を編集して実際の値を設定
```

#### 本番環境
```bash
cd scripts/env  
cp production.env.example production.env
# production.env を編集して実際の値を設定
```

### 2. 必要な情報の取得

#### Firebase設定
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト設定 > 全般 > マイアプリ
3. Web アプリの設定から以下の値をコピー：
   - `FIREBASE_API_KEY`
   - `FIREBASE_APP_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_AUTH_DOMAIN`
   - `FIREBASE_STORAGE_BUCKET`

#### Google OAuth設定
1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. APIs & Services > 認証情報
3. OAuth 2.0 クライアント ID から `GOOGLE_CLIENT_ID` をコピー

### 3. 設定値の記入

```bash
# scripts/env/development.env の例
FIREBASE_API_KEY=AIzaSyAROJC6oomnN4tl1Sv27fcE5yaB_vIzXxc
FIREBASE_APP_ID=1:309920383305:web:fa0ae9890d4e7bf2355a98
FIREBASE_MESSAGING_SENDER_ID=309920383305
FIREBASE_PROJECT_ID=yutori-kyoshitu-dev
FIREBASE_AUTH_DOMAIN=yutori-kyoshitu-dev.firebaseapp.com
FIREBASE_STORAGE_BUCKET=yutori-kyoshitu-dev.firebasestorage.app
GOOGLE_CLIENT_ID=309920383305-m7aeebhvo71kd7ri8tsp3t3hjl89rakg.apps.googleusercontent.com
ENVIRONMENT=development
```

## 📦 ビルド方法

### セキュアビルドスクリプトの使用

```bash
# 開発環境でビルド
./scripts/build.sh development

# 本番環境でビルド  
./scripts/build.sh production
```

### 手動ビルド（開発用）

```bash
cd frontend

# 環境変数を指定してビルド
flutter build web \
  --dart-define=FIREBASE_API_KEY="your_api_key" \
  --dart-define=GOOGLE_CLIENT_ID="your_client_id" \
  # ... 他の環境変数
```

## 🔧 デプロイ設定

### Firebase Hosting

```bash
# 本番ビルド
./scripts/build.sh production

# Firebase へデプロイ
cd frontend
firebase deploy --only hosting
```

### CI/CD環境での設定

GitHub Actions などの CI/CD 環境では、Secrets に環境変数を設定：

```yaml
# .github/workflows/deploy.yml
env:
  FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  GOOGLE_CLIENT_ID: ${{ secrets.GOOGLE_CLIENT_ID }}
  # ... 他の設定
```

## 🛡️ セキュリティベストプラクティス

### 1. 環境分離
- 開発・ステージング・本番で異なるプロジェクト/API キーを使用
- 本番用の設定は厳重に管理

### 2. アクセス制限
- Firebase プロジェクトのアクセス権限を最小限に制限
- Google OAuth の承認済みドメインを適切に設定

### 3. 定期ローテーション
- API キーは定期的にローテーション
- 不要になったキーは即座に削除

### 4. 監視・ログ
- API使用量の監視
- 不審なアクセスの検知

## 🚨 トラブルシューティング

### よくあるエラー

#### 環境変数ファイルが見つからない
```
❌ 環境変数ファイルが見つかりません: scripts/env/development.env
```
**解決策**: テンプレートファイルをコピーして設定

#### 必須環境変数が未設定
```
❌ 必須環境変数が設定されていません
```
**解決策**: `.env` ファイルで必要な値を設定

#### Firebase 初期化エラー
```
FirebaseError: Failed to initialize app
```
**解決策**: Firebase 設定値が正しいか確認

## ⚡ 開発Tips

### VS Code での開発
`.vscode/launch.json` で環境変数を設定：

```json
{
  "version": "0.2.0", 
  "configurations": [
    {
      "name": "Flutter Dev",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=FIREBASE_API_KEY=${env:FIREBASE_API_KEY}"
      ]
    }
  ]
}
```

### 環境変数の確認
```bash
# 現在の設定を確認
flutter run --dart-define=FIREBASE_API_KEY="test" -d chrome
```

## 📚 参考資料

- [Flutter Web 環境変数設定](https://flutter.dev/docs/deployment/web)
- [Firebase Web Setup](https://firebase.google.com/docs/web/setup)
- [Google Identity Services](https://developers.google.com/identity/gsi/web/guides/overview) 