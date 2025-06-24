# バックエンド テスト手順書

このドキュメントは、再構築されたバックエンドアプリケーションの動作確認とテストの手順を説明します。

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

### 1.2. `wkhtmltopdf` のインストール

PDF変換機能（`/pdf`エンドポイント）は `wkhtmltopdf` に依存しています。お使いのOSに合わせてインストールしてください。

**macOS (Homebrewを使用):**
```bash
brew install --cask wkhtmltopdf
```

**Debian/Ubuntu:**
```bash
sudo apt-get install wkhtmltopdf
```

### 1.3. 環境変数の設定

プロジェクトのルートディレクトリに `.env` ファイルを作成し、必要な環境変数を設定します。

```bash
# new-agent/.env
GOOGLE_API_KEY="your_google_api_key_here"
GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-file.json"
CLASSROOM_SUBJECT="（テスト）学級通信"
```

- `GOOGLE_API_KEY`: Google CloudプロジェクトのAPIキー。
- `GOOGLE_APPLICATION_CREDENTIALS`: Google Cloudサービスアカウントの認証情報（JSONファイル）への絶対パス。
- `CLASSROOM_SUBJECT`: Google Classroomに投稿する際のデフォルトの件名。

## 2. サーバーの起動

以下のコマンドでFastAPIサーバーを起動します。

```bash
cd backend
poetry run uvicorn app.main:app --reload
```

サーバーが起動すると、コンソールに以下のようなログが表示されます。
`Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)`

## 3. APIエンドポイントのテスト

`curl` コマンドを使用して各APIエンドポイントの動作を確認します。

### 3.1. `/chat` 及び `/stream` (AIチャット機能)

このテストは、AIエージェントの（現在のモック）動作とSSEによるストリーミングを確認します。

**手順:**

1.  **チャットセッションを開始**
    ターミナルで以下のコマンドを実行し、セッションIDを取得します。

    ```bash
    curl -X POST http://127.0.0.1:8000/chat \
    -H "Content-Type: application/json" \
    -d '{
        "session_id": "test-session-123",
        "message": "/create 5月号"
    }'
    ```

    **期待される結果:**
    ```json
    {
      "session_id": "test-session-123"
    }
    ```

2.  **イベントストリームを受信**
    別のターミナルを開き、前のステップで使ったセッションID (`test-session-123`) を使って以下のコマンドを実行します。

    ```bash
    curl -N http://127.0.0.1:8000/stream/test-session-123
    ```

    **期待される結果:**
    AIエージェントの処理ステップに応じたSSEイベントが順次表示されます。最終的に `{"type": "complete"}` を含むイベントが流れてきたらストリームが閉じます。

    ```
    event: message
    data: {"type": "status", "content": "Planner Agent started..."}

    event: message
    data: {"type": "artifact", "name": "outline.json", "content": "..."}

    ...
    ```

### 3.2. `/pdf` (HTMLからPDFへの変換)

**手順:**
HTMLコンテンツを送信してPDFを生成します。

```bash
curl -X POST http://127.0.0.1:8000/pdf/ \
-H "Content-Type: application/json" \
-d '{
    "html_content": "<html><body><h1>こんにちは、世界！</h1><p>これはPDFのテストです。</p></body></html>",
    "user_id": "test-user-001"
}'
```

**期待される結果:**
生成されたPDFへの署名付きURLと、Firestoreに保存されたドキュメントIDを含むJSONが返されます。

```json
{
  "status": "success",
  "pdf_url": "https://storage.googleapis.com/...",
  "firestore_doc_id": "..."
}
```

### 3.3. `/classroom` (Google Classroomへの投稿)

**注意:** このAPIを叩くと実際に投稿が行われます。テスト用のコースIDを使用してください。

**手順:**
コースID、タイトル、本文を指定してアナウンスを投稿します。

```bash
curl -X POST http://127.0.0.1:8000/classroom/ \
-H "Content-Type: application/json" \
-d '{
    "course_id": "YOUR_TEST_COURSE_ID",
    "title": "テストアナウンス",
    "text": "これはAPIからのテスト投稿です。"
}'
```

**期待される結果:**
成功メッセージと投稿IDを含むJSONが返されます。

```json
{
  "status": "success",
  "announcement_id": "..."
}
```

### 3.4. `/stt` (音声文字起こし)

**手順:**
テスト用の音声ファイル（例: `test.wav`）を用意してください。

```bash
curl -X POST http://127.0.0.1:8000/stt/ \
-F "file=@/path/to/your/test.wav" \
-F "phrase_set_id=custom_words_for_test"
```

**期待される結果:**
文字起こしされたテキストを含むJSONが返されます。

```json
{
  "transcript": "こんにちは、これは音声認識のテストです。"
}
```

### 3.5. `/phrase` (ユーザー辞書登録)

**手順:**
音声認識精度を向上させるための単語リストを登録します。

```bash
curl -X POST http://127.0.0.1:8000/phrase/ \
-H "Content-Type: application/json" \
-d '{
    "phrase_set_id": "my-custom-phrases",
    "phrases": ["令和小学校", "AIアシスタント", "学級通信"]
}'
```

**期待される結果:**
登録の成功を示すJSONが返されます。

```json
{
  "status": "success",
  "phrase_set_name": "projects/.../phraseSets/my-custom-phrases"
}
```

---
以上でテストは完了です。
