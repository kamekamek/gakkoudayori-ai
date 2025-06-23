# APIエンドポイントリファレンス

学校だよりAIのバックエンドAPIの詳細仕様です。すべてのエンドポイントはRESTful設計に従い、JSON形式でデータをやり取りします。

## 🌐 API概要

### ベースURL

```
開発環境: http://localhost:8081/api/v1/ai
本番環境: https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai
```

### 認証

すべてのAPIエンドポイントはFirebase Authenticationによる認証が必要です。

```http
Authorization: Bearer {firebase_id_token}
```

### 共通レスポンス形式

成功時:
```json
{
  "success": true,
  "data": {
    // エンドポイント固有のデータ
  },
  "timestamp": "2025-06-20T10:30:00Z"
}
```

エラー時:
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "エラーメッセージ",
    "details": {}
  },
  "timestamp": "2025-06-20T10:30:00Z"
}
```

## 📋 エンドポイント一覧

### 音声処理

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/speech/recognize` | 音声ファイルをテキストに変換 |
| POST | `/speech/stream` | リアルタイム音声認識（WebSocket） |

### AI処理

| メソッド | パス | 説明 |
|---------|------|------|
| POST | `/ai/rewrite` | テキストをAIでリライト |
| POST | `/ai/generate-headings` | 見出しを自動生成 |
| POST | `/ai/suggest-layout` | レイアウト提案 |

### ドキュメント管理

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/documents` | ドキュメント一覧取得 |
| GET | `/documents/{id}` | ドキュメント詳細取得 |
| POST | `/documents` | ドキュメント作成 |
| PUT | `/documents/{id}` | ドキュメント更新 |
| DELETE | `/documents/{id}` | ドキュメント削除 |

### テンプレート

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/templates` | テンプレート一覧取得 |
| GET | `/templates/{id}` | テンプレート詳細取得 |

### ユーザー辞書

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/dictionary` | ユーザー辞書取得 |
| POST | `/dictionary/words` | 単語追加 |
| DELETE | `/dictionary/words/{id}` | 単語削除 |

## 🎤 音声処理API

### POST /speech/recognize

音声ファイルをテキストに変換します。

#### リクエスト

```http
POST /api/v1/ai/speech/recognize
Content-Type: multipart/form-data
Authorization: Bearer {token}
```

```
audio: (binary) 音声ファイル
language: ja-JP (オプション)
model: latest_long (オプション)
```

#### レスポンス

```json
{
  "success": true,
  "data": {
    "transcript": "今日は運動会の練習をしました。子どもたちは一生懸命頑張っていました。",
    "confidence": 0.95,
    "words": [
      {
        "word": "今日",
        "startTime": 0.0,
        "endTime": 0.5,
        "confidence": 0.98
      }
    ],
    "language": "ja-JP",
    "duration": 15.3
  }
}
```

#### エラーコード

| コード | 説明 | 対処法 |
|--------|------|--------|
| AUDIO_TOO_LONG | 音声が5分を超えている | 音声を分割して送信 |
| UNSUPPORTED_FORMAT | 対応していない音声形式 | WebM/MP3/WAV形式で送信 |
| RECOGNITION_FAILED | 音声認識に失敗 | 音質を確認して再試行 |

### WebSocket /speech/stream

リアルタイム音声認識用のWebSocketエンドポイント。

#### 接続

```javascript
const ws = new WebSocket('wss://api.example.com/api/v1/ai/speech/stream');

ws.onopen = () => {
  // 認証情報を送信
  ws.send(JSON.stringify({
    type: 'auth',
    token: firebaseIdToken
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'transcript') {
    console.log('認識結果:', data.transcript);
  }
};
```

#### メッセージ形式

クライアント → サーバー:
```json
{
  "type": "audio",
  "data": "base64_encoded_audio_chunk",
  "sequence": 1
}
```

サーバー → クライアント:
```json
{
  "type": "transcript",
  "transcript": "認識されたテキスト",
  "isFinal": false,
  "confidence": 0.92
}
```

## 🤖 AI処理API

### POST /ai/rewrite

テキストをAIでリライトします。

#### リクエスト

```http
POST /api/v1/ai/ai/rewrite
Content-Type: application/json
Authorization: Bearer {token}
```

```json
{
  "text": "今日は運動会の練習をしました。みんな頑張ってました。",
  "style": "formal",
  "options": {
    "addGreeting": true,
    "seasonalContext": "spring",
    "targetAudience": "parents"
  }
}
```

#### レスポンス

```json
{
  "success": true,
  "data": {
    "originalText": "今日は運動会の練習をしました。みんな頑張ってました。",
    "rewrittenText": "保護者の皆様\n\n春の陽気が心地よい中、本日は運動会の練習を行いました。子どもたちは、それぞれの競技に一生懸命取り組み、素晴らしい姿を見せてくれました。",
    "changes": [
      {
        "type": "greeting_added",
        "text": "保護者の皆様"
      },
      {
        "type": "seasonal_context",
        "text": "春の陽気が心地よい中"
      },
      {
        "type": "formality_adjusted",
        "from": "みんな頑張ってました",
        "to": "子どもたちは、それぞれの競技に一生懸命取り組み"
      }
    ],
    "metadata": {
      "processingTime": 2.3,
      "modelUsed": "gemini-1.5-pro",
      "tokenCount": 156
    }
  }
}
```

#### スタイルオプション

| スタイル | 説明 | 使用場面 |
|----------|------|----------|
| formal | 丁寧で格式のある文体 | 公式な通知 |
| friendly | 親しみやすい文体 | 日常的な連絡 |
| informative | 情報重視の文体 | お知らせ・連絡事項 |
| seasonal | 季節感のある文体 | 季節の行事 |

### POST /ai/generate-headings

コンテンツから適切な見出しを生成します。

#### リクエスト

```json
{
  "content": "長いテキスト内容...",
  "count": 5,
  "style": "newsletter"
}
```

#### レスポンス

```json
{
  "success": true,
  "data": {
    "headings": [
      {
        "text": "運動会に向けて",
        "level": 1,
        "position": 0
      },
      {
        "text": "練習の様子",
        "level": 2,
        "position": 150
      },
      {
        "text": "来週の予定",
        "level": 2,
        "position": 350
      }
    ],
    "suggestions": [
      "今月のお知らせ",
      "保護者の皆様へ"
    ]
  }
}
```

## 📄 ドキュメント管理API

### GET /documents

ユーザーのドキュメント一覧を取得します。

#### リクエスト

```http
GET /api/v1/ai/documents?page=1&limit=20&sort=updatedAt&order=desc
Authorization: Bearer {token}
```

#### クエリパラメータ

| パラメータ | 型 | 説明 | デフォルト |
|-----------|-----|------|------------|
| page | number | ページ番号 | 1 |
| limit | number | 1ページあたりの件数 | 20 |
| sort | string | ソート項目 | updatedAt |
| order | string | ソート順序 (asc/desc) | desc |
| status | string | ステータスフィルタ | all |

#### レスポンス

```json
{
  "success": true,
  "data": {
    "documents": [
      {
        "id": "doc_123456",
        "title": "4月の学級通信",
        "status": "published",
        "createdAt": "2025-04-01T10:00:00Z",
        "updatedAt": "2025-04-03T15:30:00Z",
        "thumbnail": "https://storage.example.com/thumbnails/doc_123456.png",
        "tags": ["4月", "新学期", "お知らせ"],
        "wordCount": 856
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalCount": 97,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### POST /documents

新しいドキュメントを作成します。

#### リクエスト

```json
{
  "title": "5月の学級通信",
  "content": {
    "delta": { "ops": [...] },
    "html": "<div>...</div>",
    "plainText": "プレーンテキスト版"
  },
  "template": "spring_template_01",
  "tags": ["5月", "運動会"],
  "settings": {
    "layout": "standard",
    "themeColor": "#2c5aa0",
    "fontSize": "medium"
  }
}
```

#### レスポンス

```json
{
  "success": true,
  "data": {
    "id": "doc_789012",
    "title": "5月の学級通信",
    "status": "draft",
    "createdAt": "2025-05-01T10:00:00Z",
    "editUrl": "/editor/doc_789012",
    "shareUrl": null
  }
}
```

### PUT /documents/{id}

ドキュメントを更新します。

#### リクエスト

```json
{
  "title": "5月の学級通信（更新版）",
  "content": {
    "delta": { "ops": [...] },
    "html": "<div>...</div>"
  },
  "status": "published"
}
```

#### 部分更新

PATCHのような部分更新もサポート:

```json
{
  "status": "published"
}
```

## 🎨 テンプレートAPI

### GET /templates

利用可能なテンプレート一覧を取得します。

#### リクエスト

```http
GET /api/v1/ai/templates?category=seasonal&season=spring
```

#### レスポンス

```json
{
  "success": true,
  "data": {
    "templates": [
      {
        "id": "spring_01",
        "name": "春の学級通信テンプレート",
        "category": "seasonal",
        "tags": ["春", "新学期", "桜"],
        "thumbnail": "https://storage.example.com/templates/spring_01_thumb.png",
        "description": "桜のデザインが特徴的な春向けテンプレート",
        "popularity": 4.5,
        "usageCount": 1523
      }
    ],
    "categories": [
      {
        "id": "seasonal",
        "name": "季節",
        "count": 12
      },
      {
        "id": "event",
        "name": "行事",
        "count": 8
      }
    ]
  }
}
```

## 📚 ユーザー辞書API

### GET /dictionary

ユーザー固有の辞書を取得します。

#### レスポンス

```json
{
  "success": true,
  "data": {
    "words": [
      {
        "id": "word_001",
        "word": "○○小学校",
        "reading": "まるまるしょうがっこう",
        "category": "school",
        "priority": 10
      },
      {
        "id": "word_002",
        "word": "体育館",
        "reading": "たいいくかん",
        "variations": ["体育館", "体育室"],
        "category": "facility",
        "priority": 8
      }
    ],
    "categories": [
      "school",
      "facility",
      "person",
      "event",
      "custom"
    ],
    "totalCount": 45
  }
}
```

### POST /dictionary/words

新しい単語を辞書に追加します。

#### リクエスト

```json
{
  "word": "運動会実行委員会",
  "reading": "うんどうかいじっこういいんかい",
  "category": "event",
  "variations": ["実行委員会", "運動会委員会"]
}
```

## 🔒 エラーハンドリング

### HTTPステータスコード

| コード | 説明 | 例 |
|--------|------|-----|
| 200 | 成功 | 正常なレスポンス |
| 201 | 作成成功 | リソースの新規作成 |
| 400 | 不正なリクエスト | パラメータエラー |
| 401 | 認証エラー | トークン無効/期限切れ |
| 403 | アクセス権限なし | 他ユーザーのリソース |
| 404 | リソースが見つからない | 存在しないドキュメント |
| 429 | レート制限 | API呼び出し回数超過 |
| 500 | サーバーエラー | 内部エラー |

### エラーレスポンス詳細

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": {
      "fields": {
        "title": "タイトルは必須です",
        "content": "コンテンツは10文字以上必要です"
      }
    },
    "requestId": "req_abc123",
    "timestamp": "2025-06-20T10:30:00Z"
  }
}
```

## 📊 レート制限

### 制限値

| エンドポイント | 制限 | ウィンドウ |
|---------------|------|-----------|
| 音声認識 | 100回 | 1時間 |
| AI処理 | 200回 | 1時間 |
| ドキュメント作成 | 50回 | 1時間 |
| その他 | 1000回 | 1時間 |

### レート制限ヘッダー

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1623456789
```

## 🧪 APIテスト環境

### Postmanコレクション

開発用のPostmanコレクションが用意されています：
- [開発環境用コレクション](https://postman.com/collections/dev)
- [本番環境用コレクション](https://postman.com/collections/prod)

### cURLサンプル

```bash
# 音声認識
curl -X POST https://api.example.com/api/v1/ai/speech/recognize \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "audio=@recording.webm"

# AIリライト
curl -X POST https://api.example.com/api/v1/ai/ai/rewrite \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "テストテキスト",
    "style": "formal"
  }'
```

---

*次のステップ: [データモデル](../schema/data-model.md)でFirestoreのスキーマを確認*