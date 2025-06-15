# 🏗️ 学校だよりAI システム設計書

**技術アーキテクチャ・API設計・データベース設計統合ドキュメント**

---

## 🎯 システム概要

### アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────┐
│                    学校だよりAI システム                      │
├─────────────────────────────────────────────────────────────┤
│  Frontend (Flutter Web)                                    │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   音声入力UI    │   エディタUI    │   PDF出力UI     │    │
│  │  - 録音ボタン   │  - Quill.js     │  - プレビュー   │    │
│  │  - 波形表示     │  - 季節テーマ   │  - ダウンロード │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
│                           ↓ HTTPS API                      │
├─────────────────────────────────────────────────────────────┤
│  Backend (FastAPI)                                         │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   音声処理      │   AI文章生成    │   PDF生成       │    │
│  │  - STT API      │  - Gemini Pro   │  - WeasyPrint   │    │
│  │  - ユーザー辞書 │  - プロンプト   │  - 日本語フォント│    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
│                           ↓                                │
├─────────────────────────────────────────────────────────────┤
│  Google Cloud Platform                                     │
│  ┌─────────────────┬─────────────────┬─────────────────┐    │
│  │   Vertex AI     │   Firebase      │   Cloud Storage │    │
│  │  - Gemini 1.5   │  - Auth         │  - ファイル保存 │    │
│  │  - Speech-to-   │  - Firestore    │  - 月別管理     │    │
│  │    Text         │  - Storage      │                 │    │
│  └─────────────────┴─────────────────┴─────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ 技術スタック

### フロントエンド
- **Flutter Web 3.32.2** - メインフレームワーク
- **Quill.js** - リッチテキストエディタ
- **Web Audio API** - 音声録音機能
- **Material Design 3** - UI/UXデザインシステム

### バックエンド
- **FastAPI** - Python Webフレームワーク
- **Uvicorn** - ASGI サーバー
- **WeasyPrint** - PDF生成エンジン
- **Pydantic** - データバリデーション

### Google Cloud Platform
- **Vertex AI Gemini 1.5 Pro** - AI文章生成
- **Speech-to-Text API** - 音声認識
- **Firebase Authentication** - ユーザー認証
- **Firestore** - NoSQLデータベース
- **Firebase Storage** - ファイルストレージ

---

## 📊 データベース設計

### Firestore コレクション構造

```javascript
// users コレクション
users/{userId} {
  email: string,
  displayName: string,
  schoolName: string,
  className: string,
  createdAt: timestamp,
  lastLoginAt: timestamp,
  preferences: {
    defaultTheme: string, // 'spring' | 'summer' | 'autumn' | 'winter'
    voiceSettings: {
      language: string,
      sampleRate: number
    }
  }
}

// newsletters コレクション  
newsletters/{newsletterId} {
  userId: string,
  title: string,
  content: {
    deltaJson: object,    // Quill.js Delta形式
    htmlContent: string,  // HTML形式
    plainText: string     // プレーンテキスト
  },
  metadata: {
    theme: string,
    createdAt: timestamp,
    updatedAt: timestamp,
    wordCount: number,
    estimatedReadingTime: number
  },
  status: string, // 'draft' | 'published' | 'archived'
  pdfUrl?: string,
  shareSettings: {
    isPublic: boolean,
    allowComments: boolean
  }
}

// user_dictionaries コレクション
user_dictionaries/{userId} {
  customTerms: {
    [termName]: {
      reading: string,
      category: string, // 'student_name' | 'school_term' | 'custom'
      frequency: number,
      lastUsed: timestamp
    }
  },
  defaultTerms: object, // 153語の学校用語辞書
  statistics: {
    totalTerms: number,
    mostUsedTerms: array,
    recognitionAccuracy: number
  }
}

// voice_recordings コレクション（一時保存）
voice_recordings/{recordingId} {
  userId: string,
  audioData: string, // Base64エンコード
  duration: number,
  createdAt: timestamp,
  transcription?: {
    text: string,
    confidence: number,
    language: string
  },
  status: string, // 'processing' | 'completed' | 'error'
  expiresAt: timestamp // 24時間後に自動削除
}
```

---

## 🔌 API設計

### エンドポイント一覧

#### 音声処理API
```http
POST /api/v1/speech/transcribe
Content-Type: multipart/form-data

# リクエスト
{
  "audio_file": File,
  "user_id": string,
  "language": string,
  "use_user_dictionary": boolean
}

# レスポンス
{
  "transcription": string,
  "confidence": number,
  "processing_time": number,
  "user_dictionary_matches": array
}
```

#### AI文章生成API
```http
POST /api/v1/ai/generate
Content-Type: application/json

# リクエスト
{
  "input_text": string,
  "user_id": string,
  "generation_type": string, // 'newsletter' | 'rewrite' | 'expand'
  "custom_instructions": string,
  "theme": string
}

# レスポンス
{
  "generated_content": {
    "title": string,
    "content": string,
    "html_content": string,
    "delta_json": object
  },
  "metadata": {
    "word_count": number,
    "generation_time": number,
    "theme_applied": string
  }
}
```

#### PDF生成API
```http
POST /api/v1/pdf/generate
Content-Type: application/json

# リクエスト
{
  "html_content": string,
  "theme": string,
  "options": {
    "page_size": string, // 'A4' | 'A3' | 'Letter'
    "orientation": string, // 'portrait' | 'landscape'
    "include_header": boolean,
    "include_footer": boolean
  }
}

# レスポンス
{
  "pdf_data": string, // Base64エンコード
  "file_size": number,
  "generation_time": number,
  "download_url": string
}
```

#### ユーザー辞書API
```http
# 辞書取得
GET /api/v1/dictionary/{user_id}

# 用語追加
POST /api/v1/dictionary/{user_id}/terms
{
  "term": string,
  "reading": string,
  "category": string
}

# 用語更新
PUT /api/v1/dictionary/{user_id}/terms/{term_name}
{
  "reading": string,
  "category": string
}

# 用語削除
DELETE /api/v1/dictionary/{user_id}/terms/{term_name}
```

---

## 🔐 セキュリティ設計

### 認証・認可

```javascript
// Firebase Authentication
- Google OAuth 2.0
- メールアドレス/パスワード認証
- JWT トークンベース認証

// API認証フロー
1. Frontend: Firebase Auth でログイン
2. Frontend: ID Token取得
3. Backend: Firebase Admin SDK でトークン検証
4. Backend: ユーザー情報取得・認可チェック
```

### データ保護

```javascript
// Firestore セキュリティルール
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 学級通信は作成者のみ編集可能
    match /newsletters/{newsletterId} {
      allow read: if resource.data.shareSettings.isPublic == true 
                  || request.auth.uid == resource.data.userId;
      allow write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // ユーザー辞書は本人のみアクセス
    match /user_dictionaries/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### API セキュリティ

```python
# FastAPI セキュリティ設定
from fastapi.security import HTTPBearer
from firebase_admin import auth

security = HTTPBearer()

async def verify_firebase_token(token: str = Depends(security)):
    try:
        decoded_token = auth.verify_id_token(token.credentials)
        return decoded_token
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid authentication")

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yutori-kyoshitu.web.app"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)
```

---

## 📈 パフォーマンス設計

### フロントエンド最適化

```dart
// Flutter Web最適化
- Tree Shaking: 未使用コード自動削除
- Code Splitting: 機能別バンドル分割
- Lazy Loading: 画面遷移時の遅延読み込み
- Service Worker: オフライン対応・キャッシュ

// Quill.js最適化
- Delta形式での軽量データ保存
- 仮想スクロール: 大量テキスト対応
- デバウンス: 自動保存の最適化
```

### バックエンド最適化

```python
# FastAPI最適化
- 非同期処理: async/await使用
- 接続プール: データベース接続最適化
- キャッシュ: Redis使用（将来拡張）
- レスポンス圧縮: gzip有効化

# AI API最適化
- バッチ処理: 複数リクエスト同時処理
- ストリーミング: リアルタイム生成結果配信
- タイムアウト設定: 30秒制限
```

### データベース最適化

```javascript
// Firestore最適化
- 複合インデックス: クエリ高速化
- データ分割: 大きなドキュメントの分割
- キャッシュ: クライアントサイドキャッシュ
- オフライン同期: 自動同期機能

// インデックス設計
newsletters: [
  { fields: ['userId', 'createdAt'], order: 'desc' },
  { fields: ['status', 'updatedAt'], order: 'desc' },
  { fields: ['theme', 'createdAt'], order: 'desc' }
]
```

---

## 🚀 デプロイ設計

### CI/CD パイプライン

```yaml
# GitHub Actions ワークフロー
name: 🚀 学校だよりAI CI/CD

on:
  push:
    branches: [main, develop]
    paths-ignore: ['docs/**', '*.md']

jobs:
  test:
    - Flutter analyze & test
    - Python flake8 & pytest
    - セキュリティスキャン
    
  deploy-staging:
    - Firebase Hosting (staging)
    - Cloud Run (staging)
    
  deploy-production:
    - Firebase Hosting (production)
    - Cloud Run (production)
    - リリースタグ作成
```

### インフラ構成

```yaml
# 本番環境
Production:
  Frontend: Firebase Hosting
  Backend: Cloud Run (asia-northeast1)
  Database: Firestore (asia-northeast1)
  Storage: Firebase Storage
  CDN: Firebase Hosting CDN
  
# ステージング環境  
Staging:
  Frontend: Firebase Hosting (staging channel)
  Backend: Cloud Run (staging)
  Database: Firestore (staging project)
```

---

## 📊 監視・ログ設計

### ログ設計

```python
# 構造化ログ
import structlog

logger = structlog.get_logger()

# API呼び出しログ
logger.info(
    "api_request",
    endpoint="/api/v1/ai/generate",
    user_id=user_id,
    processing_time=0.85,
    status="success"
)

# エラーログ
logger.error(
    "ai_generation_failed",
    user_id=user_id,
    error_type="timeout",
    input_length=1500,
    retry_count=2
)
```

### メトリクス監視

```javascript
// Google Cloud Monitoring
- API レスポンス時間
- エラー率
- 同時接続数
- データベース読み書き回数
- AI API使用量・コスト

// Firebase Analytics
- ユーザー行動分析
- 機能使用率
- 離脱ポイント分析
```

---

## 🔄 将来拡張設計

### スケーラビリティ

```yaml
# 水平スケーリング対応
- Cloud Run: 自動スケーリング (0-100インスタンス)
- Firestore: 自動シャーディング
- Firebase Storage: 無制限ストレージ

# 負荷分散
- Cloud Load Balancer
- CDN キャッシュ
- データベース読み取りレプリカ
```

### 機能拡張ポイント

```javascript
// 予定されている拡張機能
1. リアルタイム共同編集 (WebSocket)
2. 音声合成 (Text-to-Speech)
3. 画像生成 (Imagen API)
4. 多言語対応 (Translation API)
5. モバイルアプリ (Flutter iOS/Android)
```

---

## 📞 技術サポート

### 開発環境
- **ローカル開発**: [開発ガイド](development_guide.md)参照
- **デバッグ**: Chrome DevTools + Flutter Inspector
- **テスト**: 単体・統合・E2Eテスト完備

### 本番環境
- **監視**: Google Cloud Monitoring
- **ログ**: Cloud Logging
- **アラート**: Slack通知連携

---

**🏗️ 設計思想: 高品質・高パフォーマンス・高可用性を実現する学級通信システム！** 