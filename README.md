# 学校だよりAI

**AIによる学級通信自動生成システム**

*Google Cloud Japan AI Hackathon Vol.2 提出プロジェクト*

<div align="center">

![Logo](https://img.shields.io/badge/Google%20Cloud-AI%20Hackathon%20Vol.2-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Vertex AI](https://img.shields.io/badge/Vertex%20AI-4285F4?style=for-the-badge&logo=googlecloud&logoColor=white)

</div>

---

## 🎯 プロジェクトゴール

**「学級通信作成時間を従来の2-3時間から20分以内に短縮」**

音声入力 → AI文章生成 → WYSIWYG編集 → PDF出力

**→ 先生が子どもと向き合う時間を創出！**

---

## ✨ 主要機能

### 🎤 音声入力
- **ワンタップ録音**: 簡単な音声入力でコンテンツ作成
- **リアルタイム文字起こし**: Google Speech-to-Text API統合
- **ノイズ抑制**: 教室環境でも高精度な音声認識
- **ユーザー辞書**: 学校固有の用語・名前の認識率向上

### 🤖 AI文章生成（Google ADK）
- **2エージェント連携**: MainConversationAgent + LayoutAgent
- **自動リライト**: Gemini 2.0 Proによる自然な文章調整
- **学級通信特化**: 教育現場に適した文体・構成自動生成
- **JSON→HTML変換**: 構造化データから美しいレイアウト生成
- **リアルタイム編集**: 対話形式での差分表示・即座反映

### 🖼️ 画像アップロード・管理
- **複数形式対応**: JPEG、PNG、GIF、WebP、BMP対応
- **自動圧縮**: Web最適化による高速表示
- **ファイル選択**: ドラッグ&ドロップ、ファイル選択、URL指定
- **プレビュー機能**: Grid表示、回転、並び替え対応
- **Cloud Storage**: Firebase Storage統合

### 🎨 リアルタイムプレビュー
- **HTMLプレビュー**: ADKエージェント生成結果を即座に表示
- **レスポンシブ対応**: デスクトップ・モバイル最適化
- **編集履歴**: バージョン管理・差分表示
- **A4レイアウト**: 印刷に最適化されたプレビュー

### 📄 PDF出力・配信
- **高品質PDF**: WeasyPrint + A4最適化レイアウト
- **日本語フォント**: NotoSansCJK完全対応
- **自動レイアウト**: 季節テーマ色彩・装飾自動反映
- **ワンクリック配信**: PDF生成・ダウンロード・共有

### 🎭 デモモード
- **X-User-IDヘッダー**: 認証なしでの即座体験
- **全機能利用可能**: 音声入力からPDF出力まで
- **サンプルデータ**: 実際の学級通信例を確認可能

---

## 🏗️ 技術スタック

### **ハッカソン必須要件対応**
- ✅ **Google Cloud Platform**: Vertex AI + Speech-to-Text + Cloud Run + Storage
- ✅ **Vertex AI Gemini 2.0 Pro**: テキスト生成・リライト・エージェント処理
- ✅ **Flutter Web**: 特別賞対象フロントエンド
- ✅ **Firebase**: 特別賞対象（Authentication・Firestore・Storage）
- ✅ **Google ADK v1.4.2+**: エージェント開発基盤

### **システムアーキテクチャ**

**2エージェント連携システム（Google ADK + uv管理）**
```
Flutter Web App (フロントエンド)
    ↓ HTTP API (/api/v1/adk/chat/stream, /api/v1/upload/images)
FastAPI Backend (バックエンド - Cloud Run, uv管理)
    ↓ Google ADK Runner
MainConversationAgent (root_agent)
    ├─ ユーザー対話・音声認識・画像処理
    ├─ outline.json生成・保存
    └─ LayoutAgent (sub_agent) 呼び出し
            ↓
        LayoutAgent
            ├─ JSON読み込み (/tmp/adk_artifacts/)
            ├─ HTML生成 (newsletter.html)
            └─ セッション状態保存
    ↓ 
┌─ Vertex AI ────┬─ Firebase ──────┬─ Cloud Storage ──┬─ その他 ─────┐
│  - Gemini Pro  │  - Auth         │  - 画像保存      │  - PDF生成    │
│  - STT API     │  - Firestore    │  - ファイル管理   │  - WebSocket │
└────────────────┴─────────────────┴──────────────────┴──────────────┘
```

### **ADKエージェント構成**
- **MainConversationAgent** (root_agent): ユーザーとの自然対話・JSON構成案生成・画像認識
- **LayoutAgent** (sub_agent): JSON → HTMLレイアウト変換・画像統合・品質保証

### **新機能（v2.0）**
- **画像アップロード**: `/api/v1/upload/images` エンドポイント
- **MIMEタイプ自動判定**: 複数形式対応・バリデーション強化
- **uv依存関係管理**: Poetry→uv移行完了
- **レスポンシブUI**: モバイル・デスクトップ最適化

---

## 🚀 クイックスタート

### 📖 ドキュメント

**🎬 新規参加者**
1. [📚 ドキュメント一覧](docs/README.md) - 全体ナビゲーション
2. [📏 ハッカソンルール](docs/HACKASON_RULES.md) - 制約・要件理解
3. [🏆 プロジェクト完了報告](docs/archive/PROJECT_COMPLETION_SUMMARY.md) - 最終成果物

**💻 開発者**
1. [🏗️ システム設計](docs/system_architecture.md) - 技術アーキテクチャ
2. [🧪 テストガイド](docs/guides/TESTING_GUIDE.md) - テスト実行・品質管理

### 🛠️ 開発環境構築

#### 1. プロジェクトクローン
```bash
# GitHubからプロジェクトをクローンします
git clone https://github.com/kamekamek/gakkoudayori-ai.git
cd gakkoudayori-ai
```

#### 2. バックエンドサーバー起動 (FastAPI on Cloud Run - uv管理)

**ターミナル1**で以下のコマンドを実行します。

```bash
# 1. バックエンドディレクトリへ移動
cd backend

# 2. uv依存関係のインストール（高速・自動仮想環境作成）
uv sync

# 3. 環境変数を設定
#    .env ファイルを新規作成し、実際の値を記述してください
cp .env.example .env
# 例:
# GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
# GEMINI_API_KEY="your-gemini-api-key"

# 4. ADK対応FastAPIサーバーを起動
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# または、ADKデバッグUI付きで起動
uv run python -m google.adk.cli.main web --agent-path ./agents --port 8080
```
> サーバーは `http://localhost:8000` で起動します。
> APIドキュメントは `http://localhost:8000/docs` で確認できます。
> ADKデバッグUI: `http://localhost:8080/adk/ui` （デバッグモード時）

#### 3. フロントエンドサーバー起動 (Flutter)

**ターミナル2**で以下のコマンドを実行します。

```bash
# 1. フロントエンドディレクトリへ移動
cd frontend

# 2. 必要なパッケージをインストール
flutter pub get

# 3. (初回のみ) Firebaseプロジェクトと連携
# flutterfire configure

# 4. Flutter Webアプリを起動
#    バックエンドのURLを指定して実行します
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```
> アプリケーションが `http://localhost:8080` で自動的に開きます。

---

## 🔐 セキュリティ・設定管理

### Firebase設定 (Frontend)

Firebase設定ファイル `frontend/lib/firebase_options.dart` が必要です。
プロジェクトにFirebaseを接続していない場合は、`flutterfire configure`コマンドで生成してください。

### 環境変数 (Backend)

バックエンドの環境変数は `backend/.env` ファイルで管理します（uv対応）。`.env.example`をコピーして作成してください。

```
# backend/.env.example
GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
GEMINI_API_KEY="your-gemini-api-key"
GCS_BUCKET_NAME="gakkoudayori-newsletters"
ENVIRONMENT="development"
```

### APIエンドポイント一覧 (v2.0)

**ADK関連**
- `POST /api/v1/adk/chat/stream` - ADKチャットストリーミング
- `GET /api/v1/artifacts/html/{session_id}` - HTML取得
- `POST /api/v1/artifacts/html` - HTML保存

**画像アップロード (NEW)**
- `POST /api/v1/upload/images` - 画像ファイルアップロード
- `GET /api/v1/upload/images/{session_id}` - セッション画像一覧
- `DELETE /api/v1/upload/images/{session_id}` - 画像削除

**その他機能**
- `POST /api/v1/stt/` - 音声認識
- `POST /api/v1/generate-pdf` - PDF生成
- `GET /health` - ヘルスチェック

---

## 🤝 コントリビューション

### 🔧 開発ワークフロー
1. **ブランチ作成**: `git checkout -b feature/your-feature`
2. **開発・テスト**: TDD実践でコード実装
3. **品質確認**: `make lint && make test`
4. **プルリクエスト**: mainブランチへのPR作成

### 📋 品質基準
- **テストカバレッジ**: 80%以上維持
- **静的解析**: Flutter analyze・flake8・black通過
- **パフォーマンス**: 音声→PDF生成20秒以内

---

## 📞 サポート・質問

- **開発手順**: [開発ガイド](docs/development_guide.md)参照
- **技術仕様**: [システム設計](docs/system_architecture.md)参照  
- **プロジェクト履歴**: [完了報告書](docs/archive/PROJECT_COMPLETION_SUMMARY.md)参照
- **ハッカソン要件**: [ハッカソンルール](docs/HACKASON_RULES.md)参照

---

## 📜 ライセンス

MIT License - Google Cloud Japan AI Hackathon Vol.2 提出用

---

**🎯 ゴール達成: 学級通信作成時間を2-3時間から15分以内に短縮！**

---

## 🆕 v2.0 新機能ハイライト

### 🖼️ 画像アップロード機能
- **複数ファイル同時アップロード**: 最大10ファイル、10MB/ファイル
- **自動圧縮・最適化**: Web表示とPDF出力に最適化
- **レスポンシブUI**: デスクトップ・モバイル対応のGrid表示

### 🚀 ADK v1.4.2+ 完全対応
- **2エージェント連携**: MainConversationAgent + LayoutAgent
- **セッション管理**: 永続化とリアルタイム同期
- **デバッグUI**: `http://localhost:8080/adk/ui` でエージェント状態確認

### ⚡ uv高速依存関係管理
- **Poetry→uv移行**: インストール時間70%短縮
- **仮想環境自動管理**: `uv sync`で一発セットアップ
- **CI/CD最適化**: GitHub Actions対応

### 📱 レスポンシブUI強化
- **モバイルファースト**: 768px以下でタブ切り替え
- **デスクトップ最適化**: 左右分割レイアウト
- **UIオーバーフロー修正**: 全画面サイズ対応
