# API エンドポイント仕様書

**カテゴリ**: API | **レイヤー**: DETAIL | **更新**: 2025-01-09  
**担当**: 亀ちゃん | **依存**: 01_REQUIREMENT_overview.md | **タグ**: #api #backend #rest

## 🎯 TL;DR（30秒で読める要約）

- **目的**: 学校だよりAIシステムのREST API完全仕様
- **対象**: バックエンド開発者、API連携担当者  
- **成果物**: 全エンドポイント、リクエスト/レスポンス、認証方式
- **次のアクション**: バックエンド実装開始

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | 01_REQUIREMENT_overview.md | 要件定義 |
| 依存 | 11_DESIGN_database_schema.md | データベース設計 |
| 関連 | 21_SPEC_ai_prompts.md | AIプロンプト仕様 |

## 📊 メタデータ

- **複雑度**: High
- **推定読了時間**: 12分
- **更新頻度**: 中

---

## 1. API基本情報

### 1.1 ベースURL - 🔴 実装に基づく更新

| 環境 | ベースURL |
|------|----------|
| ローカル開発 | `http://localhost:8081` |
| 本番環境 | `https://yutori-backend-944053509139.asia-northeast1.run.app` |

### 1.2 認証方式

**Firebase Authentication JWT Token**

```http
Authorization: Bearer <firebase_jwt_token>
```

### 1.3 共通ヘッダー

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>
```

### 1.4 レスポンス形式

**成功時**:
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2025-01-09T10:30:00Z"
}
```

**エラー時**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "リクエストデータが不正です",
    "details": { ... }
  },
  "timestamp": "2025-01-09T10:30:00Z"
}
```

---

## ❌ 2. 認証・ユーザー管理（未実装）

以下の機能は現在未実装です：

- `GET /api/v1/user/profile` - ユーザー情報取得
- `PUT /api/v1/user/profile` - ユーザー設定更新

**実装方針**: 現在はFirebase Authenticationによる認証のみで、詳細なプロフィール管理は未実装。

---

## ❌ 3. ドキュメント管理（未実装）

以下の機能は現在未実装です：

- `GET /api/v1/documents` - ドキュメント一覧取得
- `GET /api/v1/documents/{document_id}` - ドキュメント詳細取得
- `POST /api/v1/documents` - ドキュメント作成
- `PUT /api/v1/documents/{document_id}` - ドキュメント更新
- `DELETE /api/v1/documents/{document_id}` - ドキュメント削除

**実装方針**: 現在はセッションベースの一時的な処理のみで、永続化されたドキュメント管理機能は未実装。

---

## 4. AI機能 - 🔴 実装状況に基づく更新

### 4.1 音声文字起こし ✅ 実装済み

```http
POST /api/v1/ai/transcribe
```

**リクエスト** (multipart/form-data):
```
audio_file: <audio_file.webm>  # WebM/Opus形式（48kHz対応）
user_id: "user123"
```

**レスポンス**:
```json
{
  "transcription": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "confidence": 0.95,
  "corrected_text": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "corrections": [],
  "audio_metadata": {
    "duration_seconds": 15.5,
    "format": "webm",
    "sample_rate": 48000
  }
}
```

### 4.2 音声フォーマット一覧 ✅ 実装済み

```http
GET /api/v1/ai/formats
```

**レスポンス**:
```json
{
  "supported_formats": {
    "webm": {
      "codec": "opus",
      "sample_rates": [48000],
      "recommended": true
    },
    "wav": {
      "sample_rates": [16000, 44100, 48000],
      "recommended": false
    }
  }
}
```

### 4.3 新フロー: 音声→JSON構造化 ✅ 実装済み

```http
POST /api/v1/ai/speech-to-json
```

**リクエスト**:
```json
{
  "transcription": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "theme": "CLASSIC",
  "user_id": "user123"
}
```

**レスポンス**:
```json
{
  "structured_data": {
    "title": "運動会練習について",
    "sections": [
      {
        "heading": "練習の様子",
        "content": "子どもたちはとても頑張っていました",
        "type": "narrative"
      }
    ],
    "mood": "positive",
    "season": "spring"
  },
  "processing_time_ms": 1200
}
```

### 4.4 新フロー: JSON→HTMLグラレコ生成 ✅ 実装済み

```http
POST /api/v1/ai/json-to-graphical-record
```

**リクエスト**:
```json
{
  "json_data": {
    "title": "運動会練習について",
    "sections": [{
      "heading": "練習の様子",
      "content": "子どもたちはとても頑張っていました",
      "type": "narrative"
    }]
  },
  "template_name": "colorful",
  "user_id": "user123"
}
```

**レスポンス**:
```json
{
  "html_content": "<div class='newsletter-container colorful-theme'>...</div>",
  "template_used": "colorful",
  "processing_time_ms": 800
}
```

### 4.5 従来フロー: HTML生成（制約付き） ✅ 実装済み

```http
POST /api/v1/ai/generate-html
```

**リクエスト**:
```json
{
  "text_content": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "additional_instructions": "やさしい語り口で",
  "user_id": "user123"
}
```

**レスポンス**:
```json
{
  "html_content": "<h1>学級通信</h1><h2>運動会練習について</h2><p>今日は運動会の練習をしました...</p>",
  "filtered_content": "<h1>学級通信</h1><h2>運動会練習について</h2><p>今日は運動会の練習をしました...</p>",
  "filter_info": {
    "removed_tags": [],
    "filtered": false
  },
  "processing_time_ms": 800
}
```

### 4.6 学級通信生成（統合版） ✅ 実装済み

```http
POST /api/v1/ai/generate-newsletter
```

**リクエスト**:
```json
{
  "transcription": "今日は運動会の練習をしました。",
  "season": "spring",
  "additional_instructions": "やさしい語り口で",
  "user_id": "user123"
}
```

### 4.7 ニューズレターテンプレート一覧 ✅ 実装済み

```http
GET /api/v1/ai/newsletter-templates
```

**レスポンス**:
```json
{
  "templates": [
    {
      "id": "spring_basic",
      "name": "春の基本テンプレート",
      "season": "spring"
    }
  ]
}
```

## 🔴 5. ユーザー辞書機能 - 新たに実装済み

### 5.1 ユーザー辞書取得 ✅ 実装済み

```http
GET /api/v1/dictionary/{user_id}
```

**レスポンス**:
```json
{
  "default_terms": {
    "運動会": ["うんどうかい", "ウンドウカイ"]
  },
  "custom_terms": {
    "田中太郎": ["たなかたろう", "タナカタロウ"]
  },
  "stats": {
    "total_terms": 209,
    "custom_terms_count": 1,
    "last_updated": "2025-01-09T10:30:00Z"
  }
}
```

### 5.2 カスタム用語追加 ✅ 実装済み

```http
POST /api/v1/dictionary/{user_id}/terms
```

**リクエスト**:
```json
{
  "term": "田中太郎",
  "pronunciations": ["たなかたろう", "タナカタロウ"]
}
```

### 5.3 用語更新・削除 ✅ 実装済み

```http
PUT /api/v1/dictionary/{user_id}/terms/{term_name}
DELETE /api/v1/dictionary/{user_id}/terms/{term_name}
```

### 5.4 音声認識修正・学習機能 ✅ 実装済み

```http
POST /api/v1/dictionary/{user_id}/correct
POST /api/v1/dictionary/{user_id}/learn
POST /api/v1/dictionary/{user_id}/suggest
```

### 5.5 辞書統計情報 ✅ 実装済み

```http
GET /api/v1/dictionary/{user_id}/stats
```

---

## 6. PDF生成・管理 - 🔴 実装状況に基づく更新

### 6.1 PDF生成 ✅ 実装済み

```http
POST /api/v1/ai/generate-pdf
```

**リクエスト**:
```json
{
  "html_content": "<h1>学級通信</h1><p>内容...</p>",
  "filename": "newsletter_2025_06",
  "user_id": "user123"
}
```

**レスポンス**:
```json
{
  "pdf_data": "<base64_encoded_pdf_content>",
  "filename": "newsletter_2025_06.pdf",
  "file_size_bytes": 245760,
  "processing_time_ms": 2000
}
```

### 6.2 PDF情報取得 ✅ 実装済み

```http
GET /api/v1/ai/pdf-info/{pdf_id}
```

**レスポンス**:
```json
{
  "pdf_id": "pdf_123",
  "filename": "newsletter_2025_06.pdf",
  "created_at": "2025-01-09T10:30:00Z",
  "file_size_bytes": 245760,
  "status": "ready"
}
```

### ❌ 未実装機能（将来実装予定）

以下の機能は現在未実装です：

- `POST /api/v1/export/drive` - Google Drive保存
- `POST /api/v1/export/classroom` - Google Classroom投稿

---

## 7. システム・ユーティリティ - 🔴 実装状況に基づく更新

### 7.1 ルートヘルスチェック ✅ 実装済み

```http
GET /
```

**レスポンス**:
```json
{
  "message": "ゆとり職員室 API Server is running",
  "status": "healthy",
  "timestamp": "2025-01-09T10:30:00Z"
}
```

### 7.2 詳細ヘルスチェック ✅ 実装済み

```http
GET /health
```

**レスポンス**:
```json
{
  "status": "healthy",
  "services": {
    "firebase": "connected",
    "speech_to_text": "available",
    "vertex_ai": "available"
  },
  "timestamp": "2025-01-09T10:30:00Z"
}
```

### 7.3 Firebase設定情報 ✅ 実装済み

```http
GET /config
```

**レスポンス**:
```json
{
  "firebase_config": {
    "project_id": "yutori-kyoshitu",
    "status": "initialized"
  }
}
```

### ❌ 未実装機能（将来実装予定）

以下の機能は現在未実装です：

- `GET /api/v1/usage/stats` - 使用統計

---

## 7. エラーコード一覧

| コード | 説明 | HTTPステータス |
|--------|------|---------------|
| `VALIDATION_ERROR` | リクエストデータ不正 | 400 |
| `UNAUTHORIZED` | 認証失敗 | 401 |
| `FORBIDDEN` | 権限不足 | 403 |
| `NOT_FOUND` | リソース未存在 | 404 |
| `RATE_LIMITED` | レート制限超過 | 429 |
| `AI_SERVICE_ERROR` | AI処理エラー | 500 |
| `STORAGE_ERROR` | ストレージエラー | 500 |
| `INTERNAL_ERROR` | 内部エラー | 500 |

### エラーレスポンス例

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "リクエストデータが不正です",
    "details": {
      "field": "html_content",
      "reason": "必須フィールドが不足しています"
    }
  },
  "timestamp": "2025-01-09T10:30:00Z",
  "request_id": "req_abc123"
}
```

---

## 8. レート制限

| エンドポイント | 制限 |
|---------------|------|
| `/api/v1/ai/transcribe` | 10回/分 |
| `/api/v1/ai/generate-html` | 20回/分 |
| `/api/v1/ai/assist` | 50回/分 |
| `/api/v1/export/pdf` | 30回/分 |
| その他のエンドポイント | 100回/分 |

**制限超過時のレスポンス**:
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "API呼び出し制限を超過しました",
    "details": {
      "retry_after": 60,
      "limit": 10,
      "window": "1分"
    }
  }
}
```

---

## 9. 認証詳細

### 9.1 Firebase JWT検証

バックエンドでの実装例：

```python
import firebase_admin
from firebase_admin import auth

async def verify_firebase_token(token: str):
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### 9.2 権限レベル

| 権限 | 説明 | 対象機能 |
|------|------|----------|
| `user` | 一般ユーザー | 基本機能全般 |
| `premium` | プレミアムユーザー | AI機能制限緩和 |
| `admin` | 管理者 | システム管理機能 |

このAPI仕様により、要件書で定義された全機能のバックエンド連携が実現可能になります。 