# 環境変数設定ガイド

## 概要
ゆとり職員室アプリケーションで必要な環境変数の設定方法を説明します。

## バックエンド環境変数設定

### 1. .envファイルの作成
`backend/`ディレクトリに`.env`ファイルを作成し、以下の環境変数を設定してください。

```bash
# Google Cloud 設定
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=credentials/service-account-key.json

# Firestore 設定
FIRESTORE_DATABASE_ID=(default)
FIRESTORE_LOCATION=asia-northeast1

# Cloud Storage 設定
STORAGE_BUCKET_UPLOADS=your-project-id-uploads
STORAGE_BUCKET_TEMPLATES=your-project-id-templates
STORAGE_BUCKET_EXPORTS=your-project-id-exports

# AI サービス API設定
VERTEX_AI_PROJECT=your-project-id
VERTEX_AI_LOCATION=asia-northeast1
VERTEX_AI_MODEL=gemini-1.5-pro

# 音声認識サービス
SPEECH_TO_TEXT_ENABLED=true
SPEECH_LANGUAGE_CODE=ja-JP
TEXT_TO_SPEECH_ENABLED=true
TEXT_TO_SPEECH_VOICE_NAME=ja-JP-Standard-A

# LINE Messaging API
LINE_CHANNEL_ACCESS_TOKEN=your-line-channel-access-token
LINE_CHANNEL_SECRET=your-line-channel-secret

# アプリケーション設定
ENVIRONMENT=development
DEBUG=true
HOST=0.0.0.0
PORT=8000

# セキュリティ
SECRET_KEY=your-super-secret-key-here
JWT_SECRET=your-jwt-secret-key
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 2. 必須設定項目

#### Google Cloud認証
```bash
GOOGLE_CLOUD_PROJECT=yutori-kyoshitsu  # 実際のプロジェクトID
GOOGLE_APPLICATION_CREDENTIALS=credentials/service-account-key.json
```

#### AI機能
```bash
VERTEX_AI_PROJECT=yutori-kyoshitsu
VERTEX_AI_LOCATION=asia-northeast1
VERTEX_AI_MODEL=gemini-1.5-pro
```

#### 音声機能
```bash
SPEECH_TO_TEXT_ENABLED=true
SPEECH_LANGUAGE_CODE=ja-JP
```

### 3. オプション設定項目

#### LINE通知（必要に応じて）
```bash
LINE_CHANNEL_ACCESS_TOKEN=your-actual-token
LINE_CHANNEL_SECRET=your-actual-secret
```

#### Google Classroom連携（必要に応じて）
```bash
GOOGLE_CLASSROOM_ENABLED=true
GOOGLE_CLASSROOM_COURSE_ID=your-course-id
```

## フロントエンド環境変数設定

### Firebase設定
`frontend/web/`に`firebase-config.js`を作成：

```javascript
// Firebase設定（実際の値に置き換え）
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

## セキュリティ注意事項

### ⚠️ 絶対にGitにコミットしてはいけないファイル
- `.env`
- `service-account-key.json`
- `firebase-config.js`（実際の認証情報が含まれる場合）
- その他の認証情報を含むファイル

### ✅ 安全な管理方法
1. `.gitignore`で確実に除外
2. 本番環境では環境変数で設定
3. チーム共有は安全な方法（1Password等）で実施
4. 定期的なキーローテーション

## 設定確認方法

### バックエンド設定確認
```bash
cd backend
python -c "import os; print('PROJECT_ID:', os.getenv('GOOGLE_CLOUD_PROJECT'))"
```

### 認証情報確認
```bash
cd backend
python -c "
import os
from google.cloud import firestore
try:
    client = firestore.Client()
    print('✅ Firestore接続成功')
except Exception as e:
    print(f'❌ Firestore接続失敗: {e}')
"
```

## トラブルシューティング

### よくあるエラーと解決方法

1. **`GOOGLE_APPLICATION_CREDENTIALS`エラー**
   - サービスアカウントキーのパスが正しいか確認
   - ファイルが実際に存在するか確認

2. **Firestore接続エラー**
   - プロジェクトIDが正しいか確認
   - Firestore APIが有効化されているか確認

3. **CORS エラー**
   - `CORS_ORIGINS`設定を確認
   - フロントエンドのURLが含まれているか確認 