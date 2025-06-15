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

### 1.1 ベースURL

| 環境 | ベースURL |
|------|----------|
| 開発環境 | `https://yutori-api-dev.a.run.app` |
| 本番環境 | `https://yutori-api.a.run.app` |

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

## 2. 認証・ユーザー管理

### 2.1 ユーザー情報取得

```http
GET /api/v1/user/profile
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "uid": "user123",
    "email": "teacher@school.ed.jp",
    "display_name": "田中 太郎",
    "school_name": "○○小学校",
    "class_name": "3年1組",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-09T10:30:00Z",
    "settings": {
      "default_season": "spring",
      "auto_save_interval": 30
    }
  }
}
```

### 2.2 ユーザー設定更新

```http
PUT /api/v1/user/profile
```

**リクエスト**:
```json
{
  "display_name": "田中 太郎",
  "school_name": "○○小学校",
  "class_name": "3年1組",
  "settings": {
    "default_season": "autumn",
    "auto_save_interval": 60
  }
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "message": "プロフィールを更新しました"
  }
}
```

---

## 3. ドキュメント管理

### 3.1 ドキュメント一覧取得

```http
GET /api/v1/documents?status=draft&limit=20&offset=0
```

**クエリパラメータ**:
| パラメータ | 型 | 必須 | 説明 |
|-----------|---|------|------|
| `status` | string | ❌ | `draft`, `published`, `archived` |
| `limit` | integer | ❌ | 取得件数（デフォルト: 20, 最大: 100） |
| `offset` | integer | ❌ | オフセット（デフォルト: 0） |
| `search` | string | ❌ | タイトル・内容での検索 |

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "documents": [
      {
        "id": "doc_123",
        "title": "3年1組 学級通信 第5号",
        "status": "draft",
        "created_at": "2025-01-09T09:00:00Z",
        "updated_at": "2025-01-09T10:30:00Z",
        "preview_text": "今日は運動会の練習をしました...",
        "word_count": 450,
        "season_theme": "spring"
      }
    ],
    "total_count": 45,
    "has_more": true
  }
}
```

### 3.2 ドキュメント詳細取得

```http
GET /api/v1/documents/{document_id}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "id": "doc_123",
    "title": "3年1組 学級通信 第5号",
    "status": "draft",
    "html_content": "<h1>学級通信 第5号</h1><p>皆さんこんにちは...</p>",
    "delta_json": "{\"ops\":[{\"insert\":\"学級通信 第5号\"},{\"attributes\":{\"header\":1},\"insert\":\"\\n\"}]}",
    "created_at": "2025-01-09T09:00:00Z",
    "updated_at": "2025-01-09T10:30:00Z",
    "word_count": 450,
    "season_theme": "spring",
    "ai_metadata": {
      "generated_at": "2025-01-09T09:00:00Z",
      "model_version": "gemini-2.0-flash-exp",
      "processing_time_ms": 1200
    }
  }
}
```

### 3.3 ドキュメント作成

```http
POST /api/v1/documents
```

**リクエスト**:
```json
{
  "title": "学級通信 6月号",
  "html_content": "<h1>学級通信 6月号</h1><p>内容...</p>",
  "delta_json": "{\"ops\":[...]}",
  "season_theme": "summer",
  "status": "draft"
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "id": "doc_456",
    "message": "ドキュメントを作成しました"
  }
}
```

### 3.4 ドキュメント更新

```http
PUT /api/v1/documents/{document_id}
```

**リクエスト**:
```json
{
  "title": "学級通信 6月号（修正版）",
  "html_content": "<h1>学級通信 6月号</h1><p>修正された内容...</p>",
  "delta_json": "{\"ops\":[...]}",
  "status": "published"
}
```

### 3.5 ドキュメント削除

```http
DELETE /api/v1/documents/{document_id}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "message": "ドキュメントを削除しました"
  }
}
```

---

## 4. AI機能

### 4.1 音声文字起こし

```http
POST /api/v1/ai/transcribe
```

**リクエスト** (multipart/form-data):
```
audio_file: <audio_file.wav>
language: "ja-JP"
user_dictionary: ["運動会", "学習発表会", "田中太郎"]
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "transcript": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
    "confidence": 0.95,
    "processing_time_ms": 1200,
    "sections": [
      {
        "title": "運動会練習について",
        "content": "今日は運動会の練習をしました。",
        "start_time": 0,
        "end_time": 3.5
      }
    ]
  }
}
```

### 4.2 HTML生成

```http
POST /api/v1/ai/generate-html
```

**リクエスト**:
```json
{
  "transcript": "今日は運動会の練習をしました。子どもたちはとても頑張っていました。",
  "custom_instruction": "やさしい語り口で",
  "season_theme": "spring",
  "document_type": "class_newsletter",
  "constraints": {
    "allowed_tags": ["h1", "h2", "h3", "p", "ul", "ol", "li", "strong", "em", "br"],
    "max_word_count": 800
  }
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "html_content": "<h1>学級通信 6月号</h1><h2>運動会練習について</h2><p>今日は運動会の練習をしました...</p>",
    "delta_json": "{\"ops\":[{\"insert\":\"学級通信 6月号\"},{\"attributes\":{\"header\":1},\"insert\":\"\\n\"}]}",
    "sections": [
      {
        "title": "運動会練習について",
        "type": "content"
      }
    ],
    "ai_metadata": {
      "model": "gemini-2.0-flash-exp",
      "processing_time_ms": 800,
      "word_count": 450,
      "confidence": 0.92
    }
  }
}
```

### 4.3 AI補助機能

```http
POST /api/v1/ai/assist
```

**リクエスト**:
```json
{
  "action": "rewrite",
  "selected_text": "今日は運動会の練習をしました。",
  "instruction": "もっと詳しく書いて",
  "context": {
    "document_title": "学級通信 6月号",
    "surrounding_text": "...前後の文脈..."
  }
}
```

**アクション種別**:
| アクション | 説明 |
|-----------|------|
| `rewrite` | 文章をリライト |
| `expand` | 内容を詳しく展開 |
| `summarize` | 要約 |
| `generate_heading` | 見出し生成 |
| `add_greeting` | 挨拶文追加 |
| `add_schedule` | 予定表追加 |

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "text": "本日は運動会に向けた練習を行いました。子どもたちは真剣に取り組み、素晴らしい成長を見せてくれました。",
        "confidence": 0.95,
        "explanation": "より詳細で丁寧な表現に変更しました"
      },
      {
        "text": "今日の運動会練習では、リレーとダンスの練習を中心に行いました。",
        "confidence": 0.88,
        "explanation": "具体的な練習内容を追加しました"
      }
    ],
    "original_text": "今日は運動会の練習をしました。",
    "processing_time_ms": 600
  }
}
```

---

## 5. 出力・配信

### 5.1 PDF生成

```http
POST /api/v1/export/pdf
```

**リクエスト**:
```json
{
  "document_id": "doc_123",
  "format_options": {
    "page_size": "A4",
    "margin": "20mm",
    "include_header": true,
    "include_footer": true,
    "season_theme": "spring"
  }
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "pdf_url": "https://storage.googleapis.com/yutori-storage/documents/doc_123/output.pdf",
    "expires_at": "2025-01-10T10:30:00Z",
    "file_size_bytes": 245760,
    "processing_time_ms": 2000
  }
}
```

### 5.2 Google Drive保存

```http
POST /api/v1/export/drive
```

**リクエスト**:
```json
{
  "document_id": "doc_123",
  "drive_folder_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
  "file_name": "学級通信_第5号_2025年6月"
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "drive_file_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
    "drive_link": "https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view",
    "shared_link": "https://drive.google.com/file/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/view?usp=sharing"
  }
}
```

### 5.3 Google Classroom投稿

```http
POST /api/v1/export/classroom
```

**リクエスト**:
```json
{
  "document_id": "doc_123",
  "course_id": "123456789",
  "post_options": {
    "title": "学級通信 第5号",
    "description": "6月の学級通信をお届けします",
    "schedule_time": "2025-06-15T08:00:00Z"
  }
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "post_id": "CgkI4_DY8gEQdhIKCMjjj7CFAhCtAQ",
    "classroom_link": "https://classroom.google.com/c/123456789/p/CgkI4_DY8gEQdhIKCMjjj7CFAhCtAQ/details",
    "scheduled_time": "2025-06-15T08:00:00Z"
  }
}
```

---

## 6. システム・ユーティリティ

### 6.1 ヘルスチェック

```http
GET /api/v1/health
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "environment": "production",
    "services": {
      "database": "healthy",
      "storage": "healthy",
      "ai": "healthy",
      "auth": "healthy"
    },
    "timestamp": "2025-01-09T10:30:00Z"
  }
}
```

### 6.2 使用統計

```http
GET /api/v1/usage/stats
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "current_period": {
      "documents_created": 15,
      "ai_generations": 42,
      "pdfs_generated": 12,
      "storage_used_mb": 256
    },
    "limits": {
      "documents_per_month": 100,
      "ai_generations_per_month": 500,
      "storage_limit_mb": 1024
    }
  }
}
```

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