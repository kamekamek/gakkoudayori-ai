# ゆとり職員室 バックエンド

FastAPI + Google Cloud ベースのHTMLグラレコ風学級通信作成システム API

## 🎯 概要

音声認識・AI編集・PDF生成・クラウド配信の統合APIを提供。Google Cloud上でのスケーラブルな学級通信作成バックエンドです。

## 🚀 開発環境構築

### 前提条件
- Python 3.10+
- Google Cloud SDK
- サービスアカウントキー（JSON）
- Poetry または pip

### セットアップ手順

```bash
# 1. 仮想環境構築（推奨）
python -m venv venv
source venv/bin/activate  # macOS/Linux
# または
venv\Scripts\activate     # Windows

# 2. 依存関係インストール
pip install -r requirements.txt

# 3. Google Cloud認証設定
export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
gcloud auth application-default login

# 4. 開発サーバー起動
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### ポート・URL
- **開発サーバー**: http://localhost:8000
- **API ドキュメント**: http://localhost:8000/docs
- **本番URL**: Cloud Run デプロイ先

## 🏗️ アーキテクチャ

### ディレクトリ構造
```
backend/
├── main.py                   # FastAPIアプリケーションエントリーポイント
├── requirements.txt          # Python依存関係
├── cloud_config.yaml         # Google Cloudサービス設定
├── config/                   # 設定・構成管理
│   ├── README.md            # Google Cloud設定ガイド
│   ├── gcloud_config.py     # Cloud設定・接続テスト
│   └── test_gcloud_config.py # 設定テストスクリプト
├── credentials/             # サービスアカウントキー（gitignore）
├── app/                     # メインアプリケーション（予定）
│   ├── api/endpoints/       # APIエンドポイント
│   ├── models/              # データモデル
│   ├── services/            # ビジネスロジック
│   └── utils/               # ユーティリティ
└── tests/                   # テストコード
```

### 技術スタック
- **API Framework**: FastAPI 0.104.1
- **ASGI Server**: Uvicorn 0.24.0
- **AI Platform**: Google Vertex AI Gemini 1.5 Pro
- **音声認識**: Google Cloud Speech-to-Text
- **音声合成**: Google Cloud Text-to-Speech
- **データベース**: Cloud Firestore 2.13.1
- **ストレージ**: Cloud Storage 2.10.0
- **認証**: Firebase Admin SDK 6.2.0
- **PDF生成**: WeasyPrint 60.2
- **テンプレート**: Jinja2 3.1.2

## 🔧 Google Cloud設定

### 必須サービス
```yaml
# cloud_config.yaml で定義
- aiplatform.googleapis.com      # Vertex AI
- speech.googleapis.com          # Speech-to-Text
- texttospeech.googleapis.com    # Text-to-Speech
- firestore.googleapis.com       # Firestore
- storage.googleapis.com         # Cloud Storage
- run.googleapis.com             # Cloud Run
```

### 接続テスト機能

```python
# 安全な接続確認（推奨）
from config.gcloud_config import test_connections
test_connections(dry_run=True)  # リソース操作なし

# 実際のリソース操作テスト（要注意）
test_connections(dry_run=False)  # 確認プロンプト後実行
```

詳細は [config/README.md](config/README.md) を参照

## 📚 API 設計

### エンドポイント構成
```
/api/v1/
├── /health              # ヘルスチェック
├── /auth/               # 認証・認可
│   ├── /login          # ユーザーログイン
│   └── /verify         # JWT トークン検証
├── /speech/             # 音声処理
│   ├── /transcribe     # 音声→テキスト変換
│   ├── /synthesize     # テキスト→音声合成
│   └── /dictionary     # ユーザー辞書管理
├── /ai/                 # AI機能
│   ├── /rewrite        # Gemini テキストリライト
│   ├── /generate-title # AI見出し生成
│   └── /custom-instruct # カスタム指示処理
├── /documents/          # ドキュメント管理
│   ├── /               # CRUD操作
│   ├── /templates      # テンプレート管理
│   └── /history        # 履歴管理
├── /pdf/                # PDF生成
│   ├── /generate       # HTML→PDF変換
│   └── /preview        # プレビュー生成
└── /integrations/       # 外部連携
    ├── /classroom      # Google Classroom
    ├── /drive          # Google Drive
    └── /line           # LINE通知
```

### レスポンス形式（統一）
```python
# 成功レスポンス
{
    "status": "success",
    "data": { ... },
    "message": "操作が正常に完了しました"
}

# エラーレスポンス
{
    "status": "error", 
    "error_code": "VALIDATION_ERROR",
    "message": "ユーザーに表示するエラーメッセージ",
    "details": { ... }  # 開発者向け詳細
}
```

## 🤖 AI・音声機能実装

### Vertex AI Gemini統合
```python
# プロンプトエンジニアリング例
REWRITE_PROMPT = """
以下の音声認識結果を、小学校の学級通信にふさわしい
親しみやすく読みやすい文章に書き直してください。

音声認識結果: {transcribed_text}
カスタム指示: {custom_instruction}  # 「やさしい語り口」等

出力要件:
- 誤字・脱字の修正
- 自然な語順への調整  
- 学年に応じた語彙選択
- 保護者に伝わりやすい表現
"""
```

### Speech-to-Text最適化
```python
# ノイズ抑制・教育現場特化設定
recognition_config = {
    "encoding": "LINEAR16",
    "sample_rate_hertz": 16000,
    "language_code": "ja-JP",
    "alternative_language_codes": ["en-US"],
    "enable_automatic_punctuation": True,
    "enable_speaker_diarization": True,
    "diarization_speaker_count": 2,
    "use_enhanced": True,  # 拡張モデル
    "model": "latest_long",  # 長時間音声対応
}
```

## 🔒 セキュリティ・認証

### JWT 認証実装
```python
# Firebase Admin SDK統合
import firebase_admin
from firebase_admin import auth

async def verify_firebase_token(token: str) -> dict:
    """Firebase JWT トークンを検証"""
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception:
        raise HTTPException(401, "認証が必要です")
```

### API セキュリティ
- **CORS設定**: フロントエンドオリジンのみ許可
- **Rate Limiting**: IP・ユーザー別リクエスト制限
- **Input Validation**: Pydantic モデルによる厳密検証
- **Error Sanitization**: 機密情報漏洩防止

## 🧪 テスト戦略

### テスト種類
```bash
# 単体テスト
pytest tests/unit/ -v

# 統合テスト
pytest tests/integration/ -v

# API テスト  
pytest tests/api/ -v

# カバレッジ測定
pytest --cov=app tests/ --cov-report=html
```

### モックテスト例
```python
@pytest.mark.asyncio
async def test_speech_transcription_success():
    """音声認識成功ケース"""
    with patch('app.services.speech_service.SpeechClient') as mock_client:
        mock_client.return_value.recognize.return_value = MagicMock(
            results=[MagicMock(alternatives=[MagicMock(transcript="テスト音声")])]
        )
        
        result = await transcribe_audio(test_audio_data)
        assert result["transcribed_text"] == "テスト音声"
```

## 📊 パフォーマンス・監視

### 性能目標
- **API 応答時間**: <500ms（Gemini除く）
- **音声認識**: <3秒（30秒音声）
- **PDF生成**: <3秒（2ページ標準通信）
- **Gemini API**: <1秒（リライト処理）

### ログ・監視設定
```python
# 構造化ログ
import structlog

logger = structlog.get_logger()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    
    logger.info("API call completed", 
                path=request.url.path,
                method=request.method,
                status_code=response.status_code,
                process_time=process_time)
    return response
```

## 🚀 デプロイ・運用

### Cloud Run デプロイ
```bash
# Dockerイメージビルド
docker build -t gcr.io/$PROJECT_ID/yutori-backend .

# イメージプッシュ  
docker push gcr.io/$PROJECT_ID/yutori-backend

# Cloud Run デプロイ
gcloud run deploy yutori-backend \
    --image gcr.io/$PROJECT_ID/yutori-backend \
    --platform managed \
    --region asia-northeast1 \
    --allow-unauthenticated
```

### 環境変数
```bash
# 本番環境設定
ENVIRONMENT=production
PROJECT_ID=your-gcp-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
JWT_SECRET=your-jwt-secret
CORS_ORIGINS=https://your-frontend-domain.com
```

## 🐛 トラブルシューティング

### よくある問題

#### 1. Google Cloud認証エラー
```bash
# サービスアカウント確認
gcloud auth list
export GOOGLE_APPLICATION_CREDENTIALS="correct/path/to/key.json"

# 権限確認
gcloud projects get-iam-policy $PROJECT_ID
```

#### 2. Vertex AI APIエラー  
```python
# config/gcloud_config.py でサービス有効化確認
test_connections(dry_run=True)

# APIキー・リージョン設定確認
# 配当制限・課金設定確認
```

#### 3. PDF生成エラー
```bash
# WeasyPrint依存関係確認
sudo apt-get install libpango-1.0-0 libharfbuzz0b libpangoft2-1.0-0

# フォント設定確認（日本語対応）
fc-list :lang=ja
```

### デバッグツール
```bash
# APIドキュメント確認
curl http://localhost:8000/docs

# ヘルスチェック
curl http://localhost:8000/health

# ログ確認（Cloud Run）
gcloud logging read "resource.type=cloud_run_revision"
```

## 🤝 コントリビューション

### コーディング規約
[../CODING_GUIDELINES.md](../docs/CODING_GUIDELINES.md) の Python/FastAPI セクションを参照

### プルリクエスト前チェック
- [ ] `flake8 app/` エラー0件
- [ ] `black app/` フォーマット適用
- [ ] `mypy app/` 型チェック通過
- [ ] `pytest` 全テスト通過
- [ ] API ドキュメント更新（必要時）

### コミットメッセージ
```
[API] 音声認識エンドポイントの実装
[AI] Gemini見出し生成機能を追加
[FIX] PDF生成時の日本語フォント表示バグ修正
[TEST] Firestoreサービスの統合テスト追加
[DEPLOY] Cloud Run本番環境設定を更新
```

---

**🎯 目標: 信頼性の高いAPIで20分通信作成を支える！**