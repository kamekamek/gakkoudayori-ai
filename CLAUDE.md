# CLAUDE.md
必ず日本語で応答すること
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🎯 プロジェクト概要

**学校だよりAI** - Google Cloud Japan AI Hackathon Vol.2 提出プロジェクト
音声入力 → AI文章生成 → WYSIWYG編集 → PDF出力による学級通信作成時間の大幅短縮システム

### 🏗️ システムアーキテクチャ

**マルチエージェントシステム（Google ADK v1.4.2+）**
```
Flutter Web App (フロントエンド)
    ↓ HTTP API
FastAPI Backend (バックエンド - Cloud Run)
    ↓ Google ADK
┌─ OrchestratorAgent ─┬─ ConversationAgent ─┬─ LayoutAgent ─┐
│  (ワークフロー管理)   │  (対話・JSON生成)  │  (HTML生成)   │
└─────────────────────┴──────────────────────┴──────────────┘
    ↓ 
┌─ Vertex AI ────┬─ Firebase ──────┬─ その他 ─────────┐
│  - Gemini Pro  │  - Auth         │  - Cloud Storage │
│  - STT API     │  - Firestore    │  - PDF生成       │
└────────────────┴─────────────────┴──────────────────┘
```

### 🤖 ADKエージェント構成

- **OrchestratorAgent**: SequentialAgentベースの2段階パイプライン制御
- **ConversationAgent**: LlmAgentでユーザー対話 → `outline.json`生成
- **LayoutAgent**: LlmAgentでJSON → `newsletter.html`変換
- **データフロー**: `/tmp/adk_artifacts/` でのファイルベース連携

## 📦 パッケージ管理 (uv)

このプロジェクトは **uv** で依存関係を管理しています。uvはRustで作られた高速なPythonパッケージマネージャーです。

### uv基本コマンド
```bash
# 依存関係をインストール
uv sync

# 開発依存関係も含めてインストール
uv sync --extra dev

# 新しいパッケージを追加
uv add package-name

# 開発依存関係を追加
uv add --dev package-name

# Python実行
uv run python script.py

# 仮想環境をアクティベート
source .venv/bin/activate
```
---

## 🔍 Python動作確認・デバッグ方法

### python -c を使った動作確認
```bash
# クラスの初期化方法を確認
python -c "from google.adk.agents import SequentialAgent; help(SequentialAgent.__init__)"

# メソッド一覧を確認
python -c "from google.adk.agents import SequentialAgent; print(dir(SequentialAgent))"

# モジュールが正しくインポートできるか確認
python -c "import google.adk.agents; print('ADK agents imported successfully')"

# 現在のPythonパスを確認
python -c "import sys; print('\n'.join(sys.path))"

# インストールされているパッケージのバージョン確認
python -c "import google.adk; print(f'ADK version: {google.adk.__version__}')"
```

### python -m を使ったモジュール実行
```bash
# ADKサーバーをモジュールとして起動
python -m google.adk.cli.main web

# 特定のモジュールが存在するか確認
python -m agents.orchestrator_agent.agent

# pipでパッケージ管理
python -m pip list | grep google
python -m pip install --upgrade google-adk
```

### エラー診断用ワンライナー
```bash
# モジュールのインポートエラーを詳細表示
python -c "
try:
    from agents.generator_agent.agent import create_generator_agent
    print('Import successful')
except ImportError as e:
    print(f'Import error: {e}')
    import sys
    print(f'Python path: {sys.path}')
"

# 現在のワーキングディレクトリとPythonパスの確認
python -c "import os, sys; print(f'CWD: {os.getcwd()}'); print(f'Python path: {sys.path}')"
```

## 🏃‍♂️ Quick Start Commands

### Most Common Development Commands
```bash
# Start development environment
make dev                          # Flutter Web with proper env vars

# Quality checks before committing
make test && make lint            # Run all tests and linting
make ci-test                      # Full CI pipeline locally

# Deployment
make deploy                       # Deploy both frontend and backend

# Reset when things break
make reset-dev                    # Clean rebuild of dev environment
```

### ADK Agent Development (NEW - uv管理)
```bash
# Start ADK development server with uv
cd backend
uv run python -m google.adk.cli.main web --agent-path ./agents --port 8080

# Test ADK agents with uv
uv run pytest tests/test_adk_agent.py -v

# Test individual agents
uv run python test_uv_migration.py

# Access ADK debug UI
# http://localhost:8080/adk/ui
```

### Flutter Web Development
```bash
cd frontend
flutter pub get                   # Install dependencies
flutter run -d chrome            # Start dev server
flutter test                     # Run tests
flutter analyze                  # Static analysis
```

### Backend Python Development (uv管理)
```bash
cd backend                       # uvで管理されたbackendディレクトリ
uv run uvicorn app.main:app --reload  # Start FastAPI server with uv
uv run pytest                   # Run tests with uv
uv run black . && uv run isort . # Format code with uv
uv add package-name             # Add new dependency
uv sync                         # Sync dependencies
```

## 🎨 フロントエンド構成 (Flutter Web)

### Feature-based Clean Architecture
```
/frontend/lib/features/
├── ai_assistant/     # ADK チャットインターフェース
├── editor/          # 画像アップロード・プレビュー  
├── home/            # メイン画面・レスポンシブレイアウト
├── newsletter/      # 学級通信管理
└── settings/        # 設定画面
```

### 主要Provider
- `AdkChatProvider`: ADKエージェントとの通信状態管理
- `PreviewProvider`: HTMLプレビュー表示管理
- `NewsletterProvider`: 学級通信データ管理
- `ImageProvider`: 画像アップロード・Grid表示管理

### レスポンシブ対応
- **デスクトップ(>768px)**: 左右分割レイアウト（チャット｜プレビュー）
- **モバイル(≤768px)**: タブ切り替えレイアウト

## 🔧 開発・デバッグのベストプラクティス

### ADKエージェント開発時の注意点
```bash
# ADKサーバー起動（デバッグUI付き）
cd backend
uv run python -m google.adk.cli.main web --agent-path ./agents --port 8080
# → http://localhost:8080/adk/ui でデバッグ可能

# エージェント個別テスト
uv run python -c "from agents.conversation_agent.agent import create_conversation_agent; agent = create_conversation_agent(); print('Agent created successfully')"

# プロンプトファイル変更後の反映確認
# agents/*/prompts/*.md を編集後、ADKサーバー再起動が必要
```

### データフロー確認
```bash
# ADK artifacts確認
ls -la /tmp/adk_artifacts/
# outline.json (ConversationAgent出力)
# newsletter.html (LayoutAgent出力) 

# ファイルベース連携のデバッグ
tail -f /tmp/adk_artifacts/outline.json
```

### Firebase・GCP認証設定
```bash
# サービスアカウントキー配置確認
ls backend/secrets/service-account-key.json

# 環境変数設定確認
echo $GOOGLE_APPLICATION_CREDENTIALS
echo $GOOGLE_CLOUD_PROJECT
```

## 🧪 テスト戦略

### ADK互換性テスト
```bash
make test-adk                    # ADK v1.4.2互換性テスト
uv run python test_uv_migration.py  # uv移行確認テスト
```

### 品質チェックフロー
```bash
make lint                        # 静的解析（Flutter + Python）
make test                        # 全テスト実行
make ci-test                     # CI環境模擬テスト
```

## 📋 重要なファイルパス

### エージェント関連
- `backend/agents/orchestrator_agent/agent.py` - メインワークフロー
- `backend/agents/*/prompts/*.md` - エージェントプロンプト
- `/tmp/adk_artifacts/` - エージェント間データ交換

### フロントエンド主要ファイル
- `frontend/lib/services/adk_agent_service.dart` - ADK通信サービス
- `frontend/lib/features/home/presentation/pages/home_page.dart` - メイン画面
- `frontend/lib/features/ai_assistant/providers/adk_chat_provider.dart` - チャット状態管理

### 設定・環境
- `backend/pyproject.toml` - Python依存関係（uv管理）
- `frontend/pubspec.yaml` - Flutter依存関係
- `Makefile` - 開発コマンド集約
- `firebase.json` - Firebase設定

## 🎯 プロジェクト固有の重要事項

### ハッカソン要件対応状況
- ✅ **必須**: Google Cloud (Cloud Run + Vertex AI + Speech-to-Text)
- ✅ **特別賞**: Flutter + Firebase + Deep Dive (ADK・マルチエージェント)
- ✅ **完成度**: 目標達成（2-3時間→15分短縮）・全機能実装済み

### ADK v1.4.2+ 使用時の注意
- `Gemini(model_name="gemini-2.5-pro")` - 最新Geminiモデル使用
- `google.adk.agents` - SequentialAgent・LlmAgent・SimpleOrchestratorAgent使用
- プロンプトファイル変更時はADKサーバー再起動必須

### Poetry→uv移行完了
- ✅ `pyproject.toml`でuv管理設定済み
- ✅ 全コマンドで`uv run`使用
- ✅ CI/CDパイプライン対応済み

### レスポンシブ対応済み
- デスクトップ: 左右分割レイアウト (768px+)
- モバイル: タブ切り替えレイアウト (768px-)
- Flutter Webで完全対応
