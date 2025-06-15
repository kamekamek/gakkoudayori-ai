# 🔐 環境変数・APIキー設定詳細ガイド

このドキュメントでは、学級通信エディタプロジェクトで使用する環境変数とAPIキーの詳細な設定方法を説明します。

## 📋 必要なAPIキー一覧

| API | 用途 | 取得方法 |
|-----|------|----------|
| Gemini AI API | 学級通信の自動生成 | Google AI Studio |
| Speech-to-Text API | 音声の文字起こし | Google Cloud Console |

## 🔑 APIキーの取得手順

### 1. Gemini AI APIキー

#### Google AI Studioでの取得（推奨）
```bash
# 1. https://aistudio.google.com/app/apikey にアクセス
# 2. Googleアカウントでログイン
# 3. 「Create API Key」をクリック
# 4. プロジェクトを選択（gakkoudayori-ai）
# 5. 生成されたAPIキーをコピー
```

#### Google Cloud Consoleでの取得
```bash
# 1. https://console.cloud.google.com/apis/credentials にアクセス
# 2. プロジェクト「gakkoudayori-ai」を選択
# 3. 「認証情報を作成」→「APIキー」
# 4. 生成されたAPIキーをコピー
# 5. APIキーの制限を設定（推奨）
```

### 2. Speech-to-Text APIキー

```bash
# 1. https://console.cloud.google.com/apis/credentials にアクセス
# 2. プロジェクト「gakkoudayori-ai」を選択
# 3. 「認証情報を作成」→「APIキー」
# 4. 生成されたAPIキーをコピー
# 5. APIの制限で「Cloud Speech-to-Text API」を選択
```

## 📁 環境変数ファイルの作成

### フロントエンド環境変数

#### 開発環境用（frontend/.env.development）
```env
# 環境識別子
ENVIRONMENT=development

# APIエンドポイント（開発環境用）
API_BASE_URL=https://yutori-api-dev.a.run.app

# Gemini AI APIキー
GEMINI_API_KEY=AIzaSyC-your-actual-api-key-here

# Speech-to-Text APIキー
SPEECH_TO_TEXT_API_KEY=AIzaSyC-your-actual-api-key-here

# デバッグ設定
DEBUG_MODE=true
LOG_LEVEL=debug
```

#### 本番環境用（frontend/.env.production）
```env
# 環境識別子
ENVIRONMENT=production

# APIエンドポイント（本番用）
API_BASE_URL=https://yutori-api.a.run.app

# Gemini AI APIキー
GEMINI_API_KEY=AIzaSyC-your-actual-api-key-here

# Speech-to-Text APIキー
SPEECH_TO_TEXT_API_KEY=AIzaSyC-your-actual-api-key-here

# 本番設定
DEBUG_MODE=false
LOG_LEVEL=error
```

#### ステージング環境用（frontend/.env.staging）
```env
# 環境識別子
ENVIRONMENT=staging

# APIエンドポイント（ステージング用）
API_BASE_URL=https://yutori-api-dev.a.run.app

# Gemini AI APIキー
GEMINI_API_KEY=AIzaSyC-your-actual-api-key-here

# Speech-to-Text APIキー
SPEECH_TO_TEXT_API_KEY=AIzaSyC-your-actual-api-key-here

# ステージング設定
DEBUG_MODE=true
LOG_LEVEL=info
```

### バックエンド環境変数

#### 開発環境用（backend/functions/.env.development）
```env
# Gemini AI APIキー
GEMINI_API_KEY=AIzaSyC-your-actual-api-key-here

# Speech-to-Text APIキー
SPEECH_TO_TEXT_API_KEY=AIzaSyC-your-actual-api-key-here

# CORS設定（開発用）
CORS_ORIGINS=http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000

# ポート設定
PORT=8081

# ログレベル
LOG_LEVEL=debug
```

#### 本番環境用（backend/functions/.env.production）
```env
# Gemini AI APIキー
GEMINI_API_KEY=AIzaSyC-your-actual-api-key-here

# Speech-to-Text APIキー
SPEECH_TO_TEXT_API_KEY=AIzaSyC-your-actual-api-key-here

# CORS設定（本番用）
CORS_ORIGINS=https://gakkoudayori-ai.web.app

# ポート設定
PORT=8080

# ログレベル
LOG_LEVEL=error
```

## 🔒 Google Cloud Secret Managerの設定

### 1. Secretの作成

```bash
# プロジェクトの設定
gcloud config set project gakkoudayori-ai

# Gemini APIキーをSecretに保存
echo "AIzaSyC-your-actual-gemini-api-key-here" | gcloud secrets create gemini-api-key --data-file=-

# Speech-to-Text APIキーをSecretに保存
echo "AIzaSyC-your-actual-speech-api-key-here" | gcloud secrets create speech-api-key --data-file=-

# Secretsの確認
gcloud secrets list
```

### 2. Secretのアクセス権限設定

```bash
# Cloud Runサービスアカウントに権限付与
gcloud secrets add-iam-policy-binding gemini-api-key \
    --member="serviceAccount:944053509139-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding speech-api-key \
    --member="serviceAccount:944053509139-compute@developer.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### 3. Cloud RunでのSecret使用

```bash
# Cloud Runサービスの更新（Secretを使用）
gcloud run services update yutori-backend \
    --region asia-northeast1 \
    --set-secrets GEMINI_API_KEY=gemini-api-key:latest,SPEECH_TO_TEXT_API_KEY=speech-api-key:latest
```

## 🛡️ セキュリティのベストプラクティス

### 1. APIキーの制限設定

#### Gemini AI APIキーの制限
```bash
# Google Cloud Consoleで以下を設定：
# 1. アプリケーションの制限: HTTPリファラー
# 2. 許可するリファラー:
#    - https://gakkoudayori-ai.web.app/*
#    - https://gakkoudayori-ai--staging.web.app/*
#    - http://localhost:3000/* (開発用)
# 3. APIの制限: Generative Language API
```

#### Speech-to-Text APIキーの制限
```bash
# Google Cloud Consoleで以下を設定：
# 1. アプリケーションの制限: HTTPリファラー
# 2. 許可するリファラー:
#    - https://gakkoudayori-ai.web.app/*
#    - https://gakkoudayori-ai--staging.web.app/*
#    - http://localhost:3000/* (開発用)
# 3. APIの制限: Cloud Speech-to-Text API
```

### 2. 環境変数ファイルの管理

#### .gitignoreの設定
```gitignore
# 環境変数ファイル
.env
.env.local
.env.development
.env.production
.env.staging

# バックエンド環境変数
backend/functions/.env*
backend/.env*

# APIキーファイル
**/api-keys.json
**/service-account-key.json
```

#### ファイル権限の設定
```bash
# 環境変数ファイルの権限を制限
chmod 600 frontend/.env.*
chmod 600 backend/functions/.env.*
```

## 🔧 環境変数の読み込み確認

### フロントエンドでの確認

#### lib/config/environment.dart
```dart
class Environment {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8081/api/v1/ai');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String speechApiKey = String.fromEnvironment('SPEECH_TO_TEXT_API_KEY', defaultValue: '');
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  // デバッグ用（本番では使用しない）
  static void printConfig() {
    if (isDevelopment) {
      print('Environment: $environment');
      print('API Base URL: $apiBaseUrl');
      print('Gemini API Key: ${geminiApiKey.isNotEmpty ? "設定済み" : "未設定"}');
      print('Speech API Key: ${speechApiKey.isNotEmpty ? "設定済み" : "未設定"}');
    }
  }
}
```

### バックエンドでの確認

#### functions/config.py
```python
import os
from dotenv import load_dotenv

# 環境変数ファイルの読み込み
load_dotenv()

class Config:
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
    SPEECH_TO_TEXT_API_KEY = os.getenv('SPEECH_TO_TEXT_API_KEY', '')
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', 'http://localhost:3000').split(',')
    PORT = int(os.getenv('PORT', 8081))
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'info')
    
    @classmethod
    def validate(cls):
        """設定の検証"""
        errors = []
        
        if not cls.GEMINI_API_KEY:
            errors.append('GEMINI_API_KEY が設定されていません')
        
        if not cls.SPEECH_TO_TEXT_API_KEY:
            errors.append('SPEECH_TO_TEXT_API_KEY が設定されていません')
        
        if errors:
            raise ValueError('\n'.join(errors))
        
        return True
    
    @classmethod
    def print_config(cls):
        """設定の表示（デバッグ用）"""
        print(f"Gemini API Key: {'設定済み' if cls.GEMINI_API_KEY else '未設定'}")
        print(f"Speech API Key: {'設定済み' if cls.SPEECH_TO_TEXT_API_KEY else '未設定'}")
        print(f"CORS Origins: {cls.CORS_ORIGINS}")
        print(f"Port: {cls.PORT}")
        print(f"Log Level: {cls.LOG_LEVEL}")
```

## 🧪 環境変数のテスト

### 設定確認スクリプト

#### check_env.sh
```bash
#!/bin/bash

echo "🔍 環境変数設定確認スクリプト"
echo "================================"

# フロントエンド環境変数の確認
echo "📱 フロントエンド環境変数:"
if [ -f "frontend/.env.development" ]; then
    echo "✅ .env.development ファイル存在"
else
    echo "❌ .env.development ファイルが見つかりません"
fi

if [ -f "frontend/.env.production" ]; then
    echo "✅ .env.production ファイル存在"
else
    echo "❌ .env.production ファイルが見つかりません"
fi

# バックエンド環境変数の確認
echo ""
echo "🐍 バックエンド環境変数:"
if [ -f "backend/functions/.env" ]; then
    echo "✅ .env ファイル存在"
else
    echo "❌ .env ファイルが見つかりません"
fi

# Google Cloud認証確認
echo ""
echo "☁️ Google Cloud認証:"
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "✅ Google Cloud認証済み"
    gcloud config get-value project
else
    echo "❌ Google Cloud認証が必要です"
fi

# Firebase認証確認
echo ""
echo "🔥 Firebase認証:"
if firebase projects:list > /dev/null 2>&1; then
    echo "✅ Firebase認証済み"
else
    echo "❌ Firebase認証が必要です"
fi

echo ""
echo "🎯 確認完了"
```

### 実行方法
```bash
# スクリプトに実行権限を付与
chmod +x check_env.sh

# 実行
./check_env.sh
```

## 📞 トラブルシューティング

### よくある問題

#### 1. 環境変数が読み込まれない
```bash
# 原因: ファイル名の間違い
# 解決: ファイル名を確認
ls -la frontend/.env*
ls -la backend/functions/.env*

# 原因: dart-defineオプションの不足
# 解決: ビルド時にオプションを指定
flutter build web --dart-define=GEMINI_API_KEY=your_key_here
```

#### 2. APIキーが無効
```bash
# 原因: APIキーの制限設定
# 解決: Google Cloud Consoleで制限を確認・修正

# 原因: APIが有効化されていない
# 解決: 必要なAPIを有効化
gcloud services enable generativelanguage.googleapis.com
gcloud services enable speech.googleapis.com
```

#### 3. CORS エラー
```bash
# 原因: CORS_ORIGINSの設定不足
# 解決: バックエンドの環境変数を更新
CORS_ORIGINS=https://gakkoudayori-ai.web.app,http://localhost:3000
```

---

**重要**: APIキーは機密情報です。絶対にGitリポジトリにコミットしたり、公開したりしないでください。 