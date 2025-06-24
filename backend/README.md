# Gakkoudayori AI Backend v2

REMAKE.mdに基づいた再設計バージョンのバックエンドアプリケーションです。
FastAPIとGoogle Agent Development Kit (ADK) を使用しています。

## 必要なもの

- Python 3.11+
- Poetry
- Google Cloud SDK (認証用)
- `wkhtmltopdf`

macOSの場合:
```bash
brew install wkhtmltopdf
```

## 環境設定

1. **Google Cloud認証**

   プロジェクトに対して認証を行います。
   ```bash
   gcloud auth application-default login
   ```

2. **環境変数**

   プロジェクトのルートに`.env`ファイルを作成し、必要な環境変数を設定します。（将来的な設定の外部化のため）
   例:
   ```env
   GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
   GCS_BUCKET_NAME="your-gcs-bucket-name"
   ```

## 実行方法

1. **依存関係のインストール**

   `backend`ディレクトリでPoetryを使用して依存関係をインストールします。
   ```bash
   cd backend
   poetry install
   ```

2. **サーバーの起動**

   Uvicornを使用してFastAPIサーバーを起動します。
   ```bash
   poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
   ```
   `--reload`フラグは、開発中にコードの変更を自動的にリロードします。

## 🔍 事前チェック（重要）

**コードを実行する前に必ず以下のチェックを実行してください：**

### 1. 全体チェック（推奨）
```bash
# プロジェクトルートから実行
make check-backend
```

### 2. 個別チェック
```bash
cd backend

# 開発用依存関係のインストール
poetry install --with dev

# Import チェック（最も重要）
poetry run python -c "from app.main import app; print('✅ Import成功')"

# 静的解析
poetry run ruff check .

# 型チェック
poetry run mypy .

# テスト実行
poetry run pytest tests/ -v
```

### 3. コードフォーマット
```bash
# 自動フォーマット
poetry run black .
poetry run isort .

# フォーマットチェック
poetry run black --check .
poetry run isort --check-only .
```

## エラーの種類と対策

### Import エラー
- **原因**: モジュールパスの誤り、依存関係の不足
- **対策**: `poetry run python -c "from app.main import app"` で事前確認

### 型エラー
- **原因**: 型注針の誤り、型の不整合
- **対策**: `poetry run mypy .` で事前確認

### スタイルエラー
- **原因**: コーディング規約違反
- **対策**: `poetry run ruff check .` で事前確認

## APIドキュメント

サーバーを起動後、以下のURLにアクセスすると、Swagger UIでAPIドキュメントの確認とテストができます。

[http://localhost:8080/docs](http://localhost:8080/docs)
