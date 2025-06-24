# バックエンド テスト手順書

このドキュメントは、Google ADK v1.0を使用して再構築されたバックエンドアプリケーションの動作確認とテストの手順を説明します。

## 0. 事前チェック（重要）

**テストを実行する前に、必ず以下の事前チェックを実行してください：**

```bash
# プロジェクトルートから実行
make check-backend
```

または個別に：

```bash
cd backend

# 開発用依存関係のインストール
poetry install --with dev --no-root

# 構文チェック
poetry run python -m py_compile app/main.py app/pdf.py app/classroom.py app/stt.py app/phrase.py

# 静的解析
poetry run ruff check .

# 自動修正（必要に応じて）
poetry run ruff check . --fix
```

## 1. 事前準備

テストを実行する前に、以下の環境構築を完了させてください。

### 1.1. リポジトリのクローンと依存関係のインストール

```bash
# リポジトリをクローン
git clone <repository_url>
cd new-agent/backend

# Poetryを使用してPythonの依存関係をインストール
poetry install --no-root
```

### 1.2. 依存ツールのインストール

#### `wkhtmltopdf` (PDF変換用)

PDF変換機能（`/pdf`エンドポイント）は `wkhtmltopdf` に依存しています。

**macOS (Homebrewを使用):**
```bash
brew install --cask wkhtmltopdf
```

**Debian/Ubuntu:**
```bash
sudo apt-get install wkhtmltopdf
```

### 1.3. Google Cloud認証の設定

Google ADKとGoogle Cloudサービスを使用するため、認証情報を設定します。

#### 方法1: アプリケーションデフォルト認証（推奨）
```bash
gcloud auth application-default login
```

#### 方法2: サービスアカウント認証
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"
```

### 1.4. 環境変数の設定

プロジェクトのルートディレクトリに `.env` ファイルを作成し、必要な環境変数を設定します。

```bash
# new-agent/.env
GOOGLE_API_KEY="your_google_api_key_here"
GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
GCS_BUCKET_NAME="your-gcs-bucket-name"
```

## 2. サーバーの起動

以下のコマンドでFastAPIサーバーを起動します。

```bash
cd backend
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

サーバーが起動すると、コンソールに以下のようなログが表示されます：
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [xxxxx] using WatchFiles
```

## 3. APIドキュメントの確認

サーバー起動後、以下のURLでSwagger UIを確認できます：
- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

## 4. APIエンドポイントのテスト

### 4.1. `/chat` (Google ADK Agent チャット機能)

Google ADKの`Runner`を使用したマルチエージェントシステムのテストです。

**手順:**

```bash
curl -X POST -N -H "Content-Type: application/json" \
-d '{
    "session": "user123:session456",
    "message": "学級通信を作成してください"
}' \
http://127.0.0.1:8000/chat
```

**期待される結果:**
Google ADKのイベントストリームがSSE形式で返されます：

```
event: message
data: {"type": "user_message", "content": "学級通信を作成してください"}

event: message
data: {"type": "agent_response", "agent": "orchestrator_agent", "content": "..."}

event: message
data: {"type": "agent_transfer", "from": "orchestrator", "to": "planner_agent"}

...
```

### 4.2. `/pdf` (HTMLからPDFへの変換)

**手順:**
```bash
curl -X POST http://127.0.0.1:8000/pdf/ \
-H "Content-Type: application/json" \
-d '{
    "html_content": "<html><head><meta charset=\"utf-8\"><title>テスト</title></head><body><h1>こんにちは、世界！</h1><p>これはPDFのテストです。</p></body></html>",
    "session_id": "test-session-123",
    "document_id": "test-document-001"
}'
```

**期待される結果:**
```json
{
  "status": "success",
  "pdf_url": "https://storage.googleapis.com/your-bucket/pdfs/test-session-123/..."
}
```

### 4.3. `/classroom` (Google Classroomへの投稿)

**⚠️ 注意:** このAPIは実際にGoogle Classroomに投稿されます。テスト用のコースIDを使用してください。

**手順:**
```bash
curl -X POST http://127.0.0.1:8000/classroom/ \
-H "Content-Type: application/json" \
-d '{
    "course_id": "YOUR_TEST_COURSE_ID",
    "title": "APIテスト投稿",
    "text": "Google ADK バックエンドからのテスト投稿です。"
}'
```

**期待される結果:**
```json
{
  "status": "success",
  "announcement_id": "123456789",
  "link": "https://classroom.google.com/c/YOUR_COURSE_ID/a/123456789/details"
}
```

### 4.4. `/stt` (音声文字起こし)

**手順:**
テスト用音声ファイルを準備し、アップロードします。

```bash
curl -X POST http://127.0.0.1:8000/stt/ \
-F "audio_file=@/path/to/your/test.wav" \
-F "phrase_set_resource=projects/YOUR_PROJECT_ID/locations/global/phraseSets/YOUR_PHRASE_SET_ID"
```

**期待される結果:**
```json
{
  "status": "success",
  "transcript": "こんにちは、これは音声認識のテストです。令和小学校の学級通信作成システムです。",
  "confidence": 0.95
}
```

### 4.5. `/phrase` (Speech-to-Text カスタム辞書登録)

**手順:**
音声認識の精度向上のためのカスタム語彙を登録します。

```bash
curl -X POST http://127.0.0.1:8000/phrase/ \
-H "Content-Type: application/json" \
-d '{
    "project_id": "your-gcp-project-id",
    "phrase_set_id": "school-vocabulary",
    "phrases": ["令和小学校", "学級通信", "運動会", "授業参観", "PTA"],
    "boost_value": 15.0
}'
```

**期待される結果:**
```json
{
  "status": "success",
  "phrase_set_name": "projects/your-gcp-project-id/locations/global/phraseSets/school-vocabulary",
  "phrases_count": 5
}
```

## 5. トラブルシューティング

### 5.1. よくあるエラーと対処法

**Import エラー**
```
ModuleNotFoundError: No module named 'backend'
```
→ `poetry install --no-root` を実行し、相対パスでのインポートを確認

**Google ADK v1.0.0 依存関係エラー**
```
ModuleNotFoundError: No module named 'deprecated'
Error during streaming: module 'google.genai.types' has no attribute 'to_content'
```
→ 依存関係を追加: `poetry add deprecated`
→ ADK v1.0.0のブレイキングチェンジに対応済み

**認証エラー**
```
google.auth.exceptions.DefaultCredentialsError
```
→ `gcloud auth application-default login` を実行

**PDF変換エラー**
```
wkhtmltopdf not found
```
→ wkhtmltopdfをインストール（セクション1.2参照）

### 5.2. ログの確認

サーバーログを確認して、詳細なエラー情報を取得します：
```bash
poetry run uvicorn app.main:app --reload --log-level debug
```

### 5.3. Google ADK固有のデバッグ

Google ADKの詳細なトレースを有効にする場合：
```python
# 開発環境でのみ使用
import os
os.environ["ADK_DEBUG"] = "true"
```

## 6. 監視・観測可能性（オプション）

本番環境では、Google ADKの観測可能性ツールの使用を推奨します：

- **Phoenix**: オープンソースの自己ホスト型
- **Arize AX**: プロダクション対応の監視プラットフォーム

詳細は[Google ADK Observability Documentation](https://google.github.io/adk-docs/observability/)を参照してください。

---

以上でテストは完了です。問題が発生した場合は、まず事前チェック（セクション0）を再実行し、エラーログを確認してください。
