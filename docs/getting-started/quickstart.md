# クイックスタート

このガイドでは、学校だよりAIの開発環境をセットアップし、ローカルで起動するまでの手順を説明します。

## 📋 前提条件

以下のツールがインストールされている必要があります：

- **Flutter SDK** 3.4.0以上
- **Python** 3.9以上
- **Node.js** 18以上
- **Google Cloud CLI**
- **Firebase CLI**
- **Git**

## 🚀 セットアップ手順

### 1. リポジトリのクローン

```bash
git clone https://github.com/your-repo/gakkoudayori-ai.git
cd gakkoudayori-ai
```

### 2. 環境設定

#### Google Cloud プロジェクトの設定

```bash
# Google Cloud CLIでログイン
gcloud auth login

# プロジェクトIDを設定
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# 必要なAPIを有効化
gcloud services enable speech.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable storage.googleapis.com
```

#### Firebase プロジェクトの設定

```bash
# Firebase CLIでログイン
firebase login

# プロジェクトを選択
firebase use $PROJECT_ID
```

### 3. フロントエンドのセットアップ

```bash
# フロントエンドディレクトリに移動
cd frontend

# 依存関係のインストール
flutter pub get

# Firebase設定ファイルのコピー
cp firebase_options.dart.template firebase_options.dart
cp web/firebase-config.js.sample web/firebase-config.js

# 設定ファイルを編集して実際の値を入力
# firebase_options.dart と web/firebase-config.js を編集
```

### 4. バックエンドのセットアップ

```bash
# バックエンドディレクトリに移動
cd ../backend/functions

# Python仮想環境の作成
python -m venv venv
source venv/bin/activate  # macOS/Linux
# または
# venv\Scripts\activate  # Windows

# 依存関係のインストール
pip install -r requirements.txt

# 環境変数の設定
cp .env.example .env
# .envファイルを編集して必要な設定を入力
```

### 5. ローカルでの起動

#### 開発環境の起動（推奨）

```bash
# プロジェクトルートで
make dev
```

これにより以下が起動します：
- Flutter Web開発サーバー（ポート5000）
- Firebase Emulators（Functions、Firestore、Storage）

#### 個別起動

フロントエンドのみ：
```bash
cd frontend
flutter run -d chrome --web-port=5000
```

バックエンドのみ：
```bash
cd backend/functions
python start_server.py
```

### 6. 動作確認

1. ブラウザで http://localhost:5000 にアクセス
2. Google認証でログイン
3. 「新規作成」ボタンから学校だより作成を開始
4. 音声入力またはテキスト入力で内容を入力
5. AI整形ボタンで文章を整形
6. エディタで編集
7. PDFプレビューで確認

## 🧪 テストの実行

### フロントエンドテスト

```bash
cd frontend
flutter test
flutter analyze
```

### バックエンドテスト

```bash
cd backend/functions
pytest
flake8 .
black . --check
```

### E2Eテスト

```bash
cd frontend/e2e
npm install
npm run test
```

## 🛠️ 便利なコマンド

```bash
# 全テストと品質チェックを実行
make test && make lint

# コードフォーマット
make format

# プロダクションビルド
make build-prod

# デプロイ（本番環境）
make deploy
```

## 📝 環境変数の設定

### フロントエンド（dart-define）

開発環境：
```bash
--dart-define=API_BASE_URL=http://localhost:8081/api/v1/ai
```

本番環境：
```bash
--dart-define=API_BASE_URL=https://yutori-backend-944053509139.asia-northeast1.run.app/api/v1/ai
```

### バックエンド（.env）

```env
# Google Cloud設定
PROJECT_ID=your-project-id
LOCATION=asia-northeast1

# Vertex AI設定
VERTEX_AI_MODEL=gemini-2.5-pro-preview-0409

# Firebase設定
FIREBASE_STORAGE_BUCKET=your-bucket-name

# API設定
ALLOWED_ORIGINS=http://localhost:5000,https://yourdomain.com
```

## 🐛 トラブルシューティング

### Flutter関連

**問題**: `flutter pub get`でエラーが発生する
```bash
# Flutterのバージョンを確認
flutter --version

# キャッシュをクリア
flutter clean
flutter pub cache clean
flutter pub get
```

### Firebase関連

**問題**: Firebase Emulatorsが起動しない
```bash
# Java のインストールを確認
java -version

# Emulatorのアップデート
firebase init emulators
```

### Python関連

**問題**: パッケージのインストールエラー
```bash
# pipのアップグレード
pip install --upgrade pip

# 依存関係の再インストール
pip install -r requirements.txt --force-reinstall
```

## 🔗 次のステップ

- [AI機能ワークフロー](../guides/ai-workflow.md) - 音声認識とAI処理の詳細
- [エディタ機能](../guides/editing.md) - Quill.jsエディタの使い方
- [APIリファレンス](../reference/api/endpoints.md) - バックエンドAPI仕様

## 📞 サポート

問題が解決しない場合は：
1. [既知の問題](../troubleshooting/)を確認
2. GitHubでIssueを作成
3. プロジェクトのDiscordチャンネルで質問

---

*Happy Coding! 🚀*