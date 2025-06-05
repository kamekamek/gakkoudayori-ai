# ゆとり職員室 システム設計書

**Google Cloud Japan AI Hackathon Vol.2 対応版**

---

**📚 ドキュメントナビ**: [📋 Index](index.md) | [📖 Overview](README.md) | [📝 要件定義](REQUIREMENT.md) | **🏗️ システム設計** | [📋 タスク](tasks.md) | [🧪 TDD](tdd_guide.md)

---

## 📋 目次

1. [システム概要](#1-システム概要)
2. [技術アーキテクチャ](#2-技術アーキテクチャ)
3. [API設計](#3-api設計)
4. [データ設計](#4-データ設計)
5. [セキュリティ設計](#5-セキュリティ設計)
6. [デプロイメント設計](#6-デプロイメント設計)
7. [監視・ログ設計](#7-監視ログ設計)

---

## 1. システム概要

### 1.1 アーキテクチャ原則

- **シンプル第一**: 複雑な分散処理より確実な動作を優先
- **レスポンス重視**: 主要操作は500ms以内の応答
- **段階的拡張**: MVPから機能追加しやすい設計
- **Google Cloud統合**: ハッカソン要件を満たしつつ運用効率を最大化

### 1.2 システム境界

```
┌─ Flutter Web App ────────────────┐
│  - 音声録音UI                      │
│  - リアルタイムプレビュー             │
│  - PDF/配信設定                   │
└─────────────┬─────────────────┘
              │ HTTPS API
┌─ Cloud Run (FastAPI) ────────────┐
│  - 音声処理エンドポイント             │
│  - コンテンツ生成エンドポイント         │
│  - PDF生成・配信エンドポイント         │
└─────────────┬─────────────────┘
              │
┌─ Google Cloud Services ──────────┐
│  - Vertex AI (Gemini 1.5 Pro)   │
│  - Speech-to-Text API            │
│  - Text-to-Speech API            │
│  - Cloud Storage                 │
│  - Firestore                     │
│  - Cloud Functions               │
└──────────────────────────────────┘
```

---

## 2. 技術アーキテクチャ

### 2.1 フロントエンド: Flutter Web

**技術選定理由**:
- ハッカソン要件（Flutter賞対象）
- 単一コードベースでWeb/モバイル対応
- リアルタイム音声録音対応

**主要ライブラリ**:
```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.1.0              # API通信
  audio_session: ^0.1.13     # 音声録音
  just_audio: ^0.9.34       # 音声再生
  file_picker: ^6.1.1       # ファイル選択
  pdf_render: ^1.4.7        # PDFプレビュー
  provider: ^6.1.1          # 状態管理
  flutter_html: ^3.0.0      # HTML描画
  html_editor_enhanced: ^2.5.1 # WYSIWYG HTMLエディタ
  lottie: ^2.7.0            # アニメーション
  drag_and_drop_lists: ^0.3.3 # ドラッグ&ドロップ
  socket_io_client: ^2.0.3 # リアルタイムチャット
  diff_match_patch: ^0.4.1 # 差分表示・比較
```

### 2.2 バックエンド: Cloud Run (FastAPI)

**技術選定理由**:
- ハッカソン要件（Cloud Run利用）
- 自動スケーリング
- コールドスタート最小化
- Pythonエコシステム活用

**主要ライブラリ**:
```python
# requirements.txt
fastapi==0.104.1
uvicorn==0.24.0
google-cloud-speech==2.21.0
google-cloud-texttospeech==2.16.3
google-cloud-firestore==2.13.1
google-cloud-storage==2.10.0
google-cloud-aiplatform==1.38.1
reportlab==4.0.4        # PDF生成
weasyprint==60.2        # HTML→PDF変換
jinja2==3.1.2           # HTMLテンプレート
beautifulsoup4==4.12.2  # HTML解析
cssutils==2.9.0         # CSS処理
python-multipart==0.0.6 # ファイルアップロード
python-socketio==5.9.0  # WebSocketサーバー
asyncio==3.4.3          # 非同期処理
```

### 2.3 AI/ML: Vertex AI 統合

**利用サービス**:
- **Gemini 1.5 Pro**: テキスト生成・リライト・見出し作成
- **Speech-to-Text**: 音声認識（PhraseHints対応）
- **Text-to-Speech**: 音声合成（拡張機能）

**API統合パターン**:
```python
from google.cloud import aiplatform
from vertexai.generative_models import GenerativeModel

# Gemini統合例
model = GenerativeModel("gemini-1.5-pro")
response = model.generate_content([
    "以下の文章を学級通信らしくリライトしてください:",
    user_input
])
```

---

## 3. API設計

### 3.1 REST API エンドポイント

**ベースURL**: `https://yutori-api-{env}-{project-id}.a.run.app`

#### 3.1.1 音声処理API

```http
POST /api/v1/speech/transcribe
Content-Type: multipart/form-data

{
  "audio_file": [binary],
  "user_dict": ["固有名詞1", "固有名詞2"],
  "language_code": "ja-JP"
}

Response:
{
  "transcript": "認識されたテキスト",
  "confidence": 0.95,
  "processing_time_ms": 1200
}
```

#### 3.1.2 コンテンツ生成API

```http
POST /api/v1/content/generate
Content-Type: application/json

{
  "text": "元の文章",
  "operations": ["rewrite", "generate_headings", "suggest_layout"],
  "custom_instruction": "やさしい語り口で",
  "season": "spring",
  "output_format": "html"
}

Response:
{
  "rewritten_text": "リライト後の文章",
  "headings": ["見出し1", "見出し2"],
  "html_content": "<div class='newsletter-content'>...</div>",
  "layout_suggestion": {
    "template": "graphical_record",
    "color_palette": ["#FFB6C1", "#98FB98"],
    "css_classes": ["spring-theme", "handwritten-style"],
    "sections": [
      {
        "type": "header",
        "content": "運動会について",
        "style": "bubble-header",
        "icon": "sports_icon"
      },
      {
        "type": "content",
        "content": "本日は...",
        "style": "speech-bubble"
      }
    ]
  },
  "graphic_elements": [
    {
      "type": "icon",
      "name": "運動会アイコン",
      "svg_path": "/templates/icons/sports.svg"
    }
  ],
  "processing_time_ms": 800
}
```

#### 3.1.3 HTMLテンプレート管理API

```http
GET /api/v1/templates/graphics
Query Parameters: ?category=icons&season=spring

Response:
{
  "templates": [
    {
      "id": "speech_bubble_1",
      "name": "吹き出し（基本）",
      "category": "layout",
      "html": "<div class='speech-bubble'>{{content}}</div>",
      "css": ".speech-bubble { background: #fff; border-radius: 20px; ... }",
      "preview_url": "/templates/previews/speech_bubble_1.png"
    }
  ],
  "icons": [
    {
      "id": "school_bell",
      "name": "学校の鐘",
      "svg": "<svg>...</svg>",
      "tags": ["学校", "時間", "お知らせ"]
    }
  ],
  "seasonal_palettes": {
    "spring": {
      "primary": "#FFB6C1",
      "secondary": "#98FB98", 
      "accent": "#FFE4E1"
    }
  }
}
```

#### 3.1.4 PDF生成・配信API

```http
POST /api/v1/document/generate
Content-Type: application/json

{
  "content": {
    "title": "3年1組 学級通信",
    "sections": [...],
    "layout": {...}
  },
  "output_format": "pdf",
  "distribution": {
    "save_to_drive": true,
    "post_to_classroom": true,
    "send_line_notify": false
  }
}

Response:
{
  "pdf_url": "https://storage.googleapis.com/...",
  "drive_link": "https://drive.google.com/...",
  "classroom_post_id": "12345",
  "processing_time_ms": 2000
}
```

### 3.2 WebSocket API (チャットベース編集)

**接続エンドポイント**: `wss://yutori-api-{env}.a.run.app/ws/chat`

**メッセージ形式**:
```javascript
// クライアント → サーバー
{
  "type": "edit_request",
  "session_id": "user123_session456",
  "content": "現在のHTML内容",
  "instruction": "この見出しをもっと親しみやすくして",
  "target_element": "#heading-1",
  "context": {
    "previous_edits": [...],
    "content_type": "newsletter"
  }
}

// サーバー → クライアント  
{
  "type": "edit_suggestion",
  "suggestion_id": "sugg_789",
  "changes": [
    {
      "element": "#heading-1",
      "old_content": "運動会について",
      "new_content": "みんなで楽しむ運動会♪",
      "diff_html": "<span class='removed'>運動会について</span><span class='added'>みんなで楽しむ運動会♪</span>"
    }
  ],
  "explanation": "より親しみやすい表現に変更しました",
  "alternatives": [
    "ワクワク運動会のお知らせ",
    "楽しい運動会がやってくる！"
  ]
}

// 適用確認
{
  "type": "apply_changes",
  "suggestion_id": "sugg_789",
  "action": "accept" // または "reject" / "request_alternative"
}
// Flutter側実装例
const ws = WebSocket('wss://yutori-api-{env}-{project-id}.a.run.app/ws/speech/stream');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  if (data.type === 'transcript_partial') {
    updatePartialTranscript(data.text);
  }
};
```

---

## 4. データ設計

### 4.1 Firestore コレクション設計

#### 4.1.1 Users コレクション

```javascript
// /users/{userId}
{
  "email": "teacher@school.ed.jp",
  "display_name": "田中 太郎",
  "school_name": "○○小学校",
  "class_name": "3年1組",
  "user_dictionary": ["運動会", "学習発表会", "田中太郎"],
  "custom_instructions": {
    "default": "やさしい語り口で",
    "saved": ["学年主任らしい口調", "保護者向けの丁寧な文体"]
  },
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-20T15:30:00Z"
}
```

#### 4.1.2 Documents コレクション

```javascript
// /documents/{documentId}
{
  "user_id": "user123",
  "title": "3年1組 学級通信 第5号",
  "status": "draft", // draft, completed, published
  "content": {
    "original_text": "今日は運動会の練習をしました...",
    "rewritten_text": "本日は運動会の練習に取り組みました...",
    "headings": ["運動会練習について", "来週の予定"],
    "html_content": "<div class='newsletter-wrapper'>...</div>",
    "css_classes": ["spring-theme", "graphical-record"],
    "graphic_elements": [
      {
        "type": "icon",
        "id": "school_bell",
        "position": {"x": 100, "y": 50}
      }
    ],
    "layout": {
      "template": "graphical_record",
      "sections": [...],
      "color_palette": "spring"
    }
  },
  "ai_metadata": {
    "gemini_model": "gemini-1.5-pro",
    "processing_stats": {
      "speech_to_text_ms": 1200,
      "content_generation_ms": 800,
      "pdf_generation_ms": 2000
    }
  },
  "distribution": {
    "pdf_url": "https://storage.googleapis.com/...",
    "drive_link": "https://drive.google.com/...",
    "classroom_posted": true,
    "line_notified": false
  },
  "created_at": "2024-01-20T14:00:00Z",
  "completed_at": "2024-01-20T14:18:00Z"
}
```

### 4.2 Cloud Storage バケット設計

```
yutori-storage-{env}/
├── users/
│   └── {userId}/
│       ├── audio/
│       │   └── {documentId}/
│       │       ├── original.wav
│       │       └── processed.mp3
│       ├── documents/
│       │   └── 2024/
│       │       ├── 01/
│       │       │   ├── 学級通信第1号.pdf
│       │       │   ├── 学級通信第1号.html
│       │       │   └── 学級通信第2号.pdf
│       │       └── 02/
│       └── images/
│           └── uploads/
└── templates/
    ├── graphical_record/
    │   ├── layouts/
    │   │   ├── speech_bubbles.html
    │   │   ├── handwritten_headers.html
    │   │   └── illustration_frames.html
    │   ├── icons/
    │   │   ├── school/
    │   │   ├── seasons/
    │   │   └── activities/
    │   └── css/
    │       ├── spring_theme.css
    │       ├── summer_theme.css
    │       └── base_graphical.css
    └── seasonal_palettes/
        ├── spring.json
        └── winter.json
```

---

## 5. セキュリティ設計

### 5.1 認証・認可

**Firebase Authentication統合**:
```python
# FastAPI認証ミドルウェア
from firebase_admin import auth

async def verify_firebase_token(authorization: str):
    try:
        token = authorization.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception:
        raise HTTPException(status_code=401)
```

### 5.2 データ保護

- **転送時暗号化**: HTTPS/TLS 1.3
- **保存時暗号化**: Cloud Storage/Firestore標準暗号化
- **音声データ**: 処理後24時間で自動削除
- **個人情報**: 最小限のメタデータのみ保存

### 5.3 API制限

```python
# Rate limiting実装
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/api/v1/speech/transcribe")
@limiter.limit("10/minute")  # 1分間10回まで
async def transcribe_audio():
    pass
```

---

## 6. デプロイメント設計

### 6.1 環境構成

| 環境 | 用途 | URL | 
|------|------|-----|
| development | 開発・テスト | `yutori-dev-{project-id}.a.run.app` |
| staging | 最終確認 | `yutori-staging-{project-id}.a.run.app` |
| production | 本番 | `yutori-{project-id}.a.run.app` |

### 6.2 CI/CD パイプライン

**Cloud Build設定**:
```yaml
# cloudbuild.yaml
steps:
  # Flutter Web ビルド
  - name: 'cirrusci/flutter:stable'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        flutter pub get
        flutter build web
        
  # FastAPI Dockerイメージビルド
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/yutori-api:$COMMIT_SHA', './backend']
    
  # Cloud Runデプロイ
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'yutori-api'
      - '--image=gcr.io/$PROJECT_ID/yutori-api:$COMMIT_SHA'
      - '--region=asia-northeast1'
      - '--platform=managed'
```

### 6.3 環境変数管理

**Secret Manager統合**:
```python
from google.cloud import secretmanager

def get_secret(secret_name: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{PROJECT_ID}/secrets/{secret_name}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

# 使用例
GEMINI_API_KEY = get_secret("gemini-api-key")
CLASSROOM_CLIENT_SECRET = get_secret("classroom-client-secret")
```

---

## 7. 監視・ログ設計

### 7.1 アプリケーションログ

**構造化ログ出力**:
```python
import json
import logging
from google.cloud import logging as cloud_logging

# Cloud Logging統合
cloud_logging_client = cloud_logging.Client()
cloud_logging_client.setup_logging()

def log_api_request(endpoint: str, user_id: str, processing_time: float):
    logging.info(json.dumps({
        "event": "api_request",
        "endpoint": endpoint,
        "user_id": user_id,
        "processing_time_ms": processing_time,
        "timestamp": datetime.utcnow().isoformat()
    }))
```

### 7.2 メトリクス監視

**Cloud Monitoring指標**:
- API応答時間（95パーセンタイル < 500ms）
- エラー率（< 1%）
- Gemini API呼び出し回数・レスポンス時間
- PDF生成成功率
- ユーザーセッション時間

### 7.3 アラート設定

```yaml
# monitoring_alert.yaml
alertPolicy:
  displayName: "API Response Time Alert"
  conditions:
    - displayName: "API latency > 1s"
      conditionThreshold:
        filter: 'resource.type="cloud_run_revision"'
        comparison: COMPARISON_GREATER_THAN
        thresholdValue: 1000
        duration: "300s"
  notificationChannels:
    - "projects/{PROJECT_ID}/notificationChannels/{CHANNEL_ID}"
```

---

## 🔄 次のステップ

1. **プロトタイプ開発** (Week 1-2)
   - Flutter基本UI + FastAPI基盤
   - 音声録音・再生機能
   - Gemini API統合

2. **コア機能実装** (Week 3-4)
   - STT + ユーザー辞書
   - リライト・見出し生成
   - 基本的なPDF生成

3. **統合・テスト** (Week 5-6)
   - 全機能統合
   - パフォーマンステスト
   - デモ準備

**設計書更新**: 実装過程で判明した技術的課題は随時このドキュメントに反映 