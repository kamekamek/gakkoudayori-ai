# 🚀 学級通信エディタ - デプロイガイド

このドキュメントでは、学級通信エディタプロジェクトのデプロイ方法を初心者向けに詳しく説明します。

**注意**: このプロジェクトは既にPhase R（MVP）が完了しており、基本機能が稼働中です。

## 📋 目次

1. [前提条件](#前提条件)
2. [環境変数とシークレットの設定](#環境変数とシークレットの設定)
3. [開発環境での起動](#開発環境での起動)
4. [本番環境へのデプロイ](#本番環境へのデプロイ)
5. [トラブルシューティング](#トラブルシューティング)

## 🔧 前提条件

デプロイを行う前に、以下のツールがインストールされていることを確認してください：

### 必須ツール

```bash
# Flutter SDK
flutter --version

# Firebase CLI
firebase --version

# Google Cloud CLI
gcloud --version

# Docker（バックエンドデプロイ用）
docker --version

# Make（オプション、便利なコマンド実行用）
make --version
```

### アカウント設定

1. **Google Cloud Platform**
   - プロジェクトID: 既存プロジェクト使用
   - 必要なAPI有効化済み（Vertex AI、Speech-to-Text）

2. **Firebase**
   - プロジェクト: 既存プロジェクト使用
   - Hosting設定済み

## 🔐 環境変数とシークレットの設定

### 1. Google Cloud APIキーの取得

#### Vertex AI (Gemini) APIキー
```bash
# Google Cloud Consoleで以下の手順を実行：
# 1. https://console.cloud.google.com/apis/credentials にアクセス
# 2. 「認証情報を作成」→「APIキー」を選択
# 3. 作成されたAPIキーをコピー
# 4. APIキーの制限を設定（推奨）
```

#### Speech-to-Text APIキー
```bash
# 同様の手順でSpeech-to-Text用のAPIキーを作成
# または同じAPIキーを使用することも可能
```

### 2. 環境変数ファイルの作成

#### フロントエンド環境変数
```bash
# frontend/.env.development
ENVIRONMENT=development
API_BASE_URL=https://yutori-api-dev.a.run.app
GEMINI_API_KEY=your_gemini_api_key_here
SPEECH_TO_TEXT_API_KEY=your_speech_api_key_here
```

```bash
# frontend/.env.production
ENVIRONMENT=production
API_BASE_URL=https://yutori-api.a.run.app
GEMINI_API_KEY=your_gemini_api_key_here
SPEECH_TO_TEXT_API_KEY=your_speech_api_key_here
```

#### バックエンド環境変数
```bash
# backend/functions/.env
GEMINI_API_KEY=your_gemini_api_key_here
SPEECH_TO_TEXT_API_KEY=your_speech_api_key_here
CORS_ORIGINS=https://your-frontend-domain.web.app,http://localhost:3000
```

### 3. Google Cloud Secretsの設定

本番環境では、APIキーをGoogle Cloud Secret Managerで管理します：

```bash
# Gemini APIキーをSecretに保存
gcloud secrets create gemini-api-key --data-file=-
# プロンプトでAPIキーを入力

# Speech-to-Text APIキーをSecretに保存
gcloud secrets create speech-api-key --data-file=-
# プロンプトでAPIキーを入力

# Secretsの確認
gcloud secrets list
```

## 🏃‍♂️ 開発環境での起動

### 1. 依存関係のインストール

```bash
# フロントエンド（最小依存関係）
cd frontend
flutter pub get

# バックエンド
cd ../backend/functions
pip install -r requirements.txt
```

### 2. 開発サーバーの起動

#### バックエンドの起動
```bash
# backend/functionsディレクトリで実行
python main.py
```

#### フロントエンドの起動
```bash
# プロジェクトルートで実行
make dev

# または手動で実行
cd frontend
flutter run -d chrome \
  --dart-define=ENVIRONMENT=development \
  --dart-define=API_BASE_URL=https://yutori-api-dev.a.run.app \
  --dart-define=GEMINI_API_KEY=your_api_key_here
```

## 🚀 本番環境へのデプロイ

### 1. バックエンドのデプロイ

#### Docker イメージのビルドとデプロイ
```bash
# プロジェクトルートで実行
make deploy-backend

# または手動で実行
cd backend
gcloud builds submit --tag gcr.io/your-project-id/yutori-api

gcloud run deploy yutori-api \
  --image gcr.io/your-project-id/yutori-api \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 8080 \
  --set-env-vars GEMINI_API_KEY=your_api_key_here
```

#### 環境変数の設定（Cloud Run）
```bash
# Cloud Runサービスに環境変数を設定
gcloud run services update yutori-api \
  --region asia-northeast1 \
  --set-env-vars GEMINI_API_KEY=your_api_key_here,SPEECH_TO_TEXT_API_KEY=your_api_key_here

# またはSecretを使用（推奨）
gcloud run services update yutori-api \
  --region asia-northeast1 \
  --set-secrets GEMINI_API_KEY=gemini-api-key:latest,SPEECH_TO_TEXT_API_KEY=speech-api-key:latest
```

### 2. フロントエンドのデプロイ

#### Firebase Hostingへのデプロイ
```bash
# プロジェクトルートで実行
make deploy-frontend

# または手動で実行
cd frontend
flutter build web \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://yutori-api.a.run.app \
  --dart-define=GEMINI_API_KEY=your_api_key_here \
  --release

firebase deploy --only hosting
```

### 3. 全体デプロイ（推奨）

```bash
# バックエンドとフロントエンドを一括デプロイ
make deploy-all
```

## 🧪 ステージング環境

### ステージング環境の設定

```bash
# ステージング用バックエンドのデプロイ
gcloud run deploy yutori-api-dev \
  --image gcr.io/your-project-id/yutori-api \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated \
  --port 8080

# ステージング用フロントエンドのデプロイ
make deploy-staging
```

## 🔍 デプロイ後の確認

### 1. サービスの動作確認

```bash
# バックエンドAPIの確認
curl https://yutori-api.a.run.app/health

# フロントエンドの確認
# ブラウザで本番URLにアクセス
```

### 2. ログの確認

```bash
# Cloud Runのログ確認
gcloud logs read --service yutori-api --region asia-northeast1

# Firebase Hostingのログ確認
firebase hosting:channel:list
```

## 🛠️ トラブルシューティング

### よくある問題と解決方法

#### 1. APIキーエラー
```
エラー: "API key not valid"
解決方法:
- APIキーが正しく設定されているか確認
- APIキーの制限設定を確認
- 必要なAPIが有効化されているか確認
```

#### 2. CORS エラー
```
エラー: "Access to fetch at ... has been blocked by CORS policy"
解決方法:
- バックエンドのCORS設定を確認
- フロントエンドのドメインがCORS_ORIGINSに含まれているか確認
```

#### 3. デプロイエラー
```
エラー: "Permission denied"
解決方法:
- gcloud auth login で認証を確認
- 必要な権限が付与されているか確認
- プロジェクトIDが正しいか確認
```

#### 4. 環境変数が読み込まれない
```
解決方法:
- .envファイルが正しい場所にあるか確認
- ファイル名が正確か確認（.env.development など）
- dart-defineオプションが正しく設定されているか確認
```

## 📝 デプロイチェックリスト

デプロイ前に以下の項目を確認してください：

### 事前確認
- [ ] 必要なツールがインストール済み
- [ ] Google Cloud / Firebase認証済み
- [ ] APIキーが取得済み
- [ ] 環境変数ファイルが作成済み

### バックエンドデプロイ
- [ ] Dockerfileが正しく設定されている
- [ ] requirements.txtが最新
- [ ] 環境変数が設定されている
- [ ] Cloud Runサービスが起動している

### フロントエンドデプロイ
- [ ] pubspec.yamlの依存関係が最新（最小構成）
- [ ] ビルドエラーがない
- [ ] 環境変数が正しく設定されている
- [ ] Firebase Hostingが設定済み

### デプロイ後確認
- [ ] フロントエンドが正常に表示される
- [ ] バックエンドAPIが応答する
- [ ] 音声録音機能が動作する
- [ ] AI生成機能が動作する
- [ ] HTML表示・ダウンロード機能が動作する

## 🎯 現在の実装状況

このプロジェクトは既に**Phase R（MVP）が完了**しており、以下の機能が稼働中です：

### ✅ 実装済み機能
- 🎤 **音声録音**（Web Audio API）- リアルタイム音声レベル監視
- 📝 **音声→テキスト変換**（Google Speech-to-Text）- 高精度日本語認識
- 🤖 **テキスト→学級通信生成**（Vertex AI + Gemini Pro）- 教育的内容自動生成
- 📄 **HTML表示・ダウンロード**（dart:js_interop）- 即座にファイル保存

### 🔧 技術スタック
- **フロントエンド**: Flutter Web（最小依存関係）
- **バックエンド**: Python Flask + Google Cloud APIs
- **AI**: Vertex AI + Gemini Pro 1.5
- **インフラ**: Google Cloud Platform

## 🔗 関連リンク

- [現在の実装仕様](docs/91_CURRENT_SPEC.md)
- [APIエンドポイント仕様](docs/30_API_endpoints.md)
- [依存関係管理](docs/92_DEPENDENCIES.md)

## 📞 サポート

問題が発生した場合は、以下の情報を含めてお問い合わせください：

1. エラーメッセージの全文
2. 実行したコマンド
3. 環境情報（OS、Flutter/Dartバージョンなど）
4. ログファイル（該当部分）

---

**注意**: APIキーなどの機密情報は絶対にGitリポジトリにコミットしないでください。必ず環境変数やSecret Managerを使用してください。 