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

## APIドキュメント

サーバーを起動後、以下のURLにアクセスすると、Swagger UIでAPIドキュメントの確認とテストができます。

[http://localhost:8080/docs](http://localhost:8080/docs)
