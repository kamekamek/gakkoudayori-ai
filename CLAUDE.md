# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**重要**: 必ず日本語で応答すること

## 🎯 プロジェクト概要

**学校だよりAI** - Google Cloud Japan AI Hackathon Vol.2 提出プロジェクト
音声入力 → AI文章生成 → WYSIWYG編集 → PDF出力による学級通信作成時間の大幅短縮システム

### 🏗️ システムアーキテクチャ

**2エージェント連携システム（Google ADK v1.4.2+）**
```
Flutter Web App (フロントエンド)
    ↓ HTTP API (/api/v1/adk/chat/stream)
FastAPI Backend (バックエンド - Cloud Run)
    ↓ Google ADK Runner
MainConversationAgent (root_agent)
    ├─ ユーザー対話・音声認識
    ├─ outline.json生成・保存
    └─ LayoutAgent (sub_agent) 呼び出し
            ↓
        LayoutAgent
            ├─ JSON読み込み (/tmp/adk_artifacts/)
            ├─ HTML生成 (newsletter.html)
            └─ セッション状態保存
    ↓ 
┌─ Vertex AI ────┬─ Firebase ──────┬─ その他 ─────────┐
│  - Gemini Pro  │  - Auth         │  - Cloud Storage │
│  - STT API     │  - Firestore    │  - PDF生成       │
└────────────────┴─────────────────┴──────────────────┘
```

### 🤖 ADKエージェント構成

- **MainConversationAgent** (root_agent): 
  - LlmAgentベースでユーザーとの自然対話
  - 音声入力対応・JSON構成案生成
  - LayoutAgentをsub_agentとして管理
  - セッション状態とファイルシステム両方でデータ永続化

- **LayoutAgent** (sub_agent):
  - LlmAgentでJSON → HTMLレイアウト変換
  - テンプレートフォールバック機能
  - 整合性検証・品質保証
  
- **データフロー**: 
  - セッション状態: `ctx.session.state["outline"]` → `ctx.session.state["html"]`
  - ファイルシステム: `/tmp/adk_artifacts/outline.json` → `/tmp/adk_artifacts/newsletter.html`
  - 2重保存によるデータ損失防止

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
# ADKサーバーをモジュールとして起動 (main_conversation_agentがroot_agent)
python -m google.adk.cli.main web --agent-path ./agents --port 8080

# 特定のエージェントが存在するか確認
python -m agents.main_conversation_agent.agent
python -m agents.layout_agent.agent

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

### 重要：Claude Codeからのタスク実行時の注意点
- Bashツールを使用する際は、必ず実行前にコマンドの説明を行うこと
- テストやリントを実行する前に、事前チェックとして `make check-backend` を実行すること
- エラーが発生した場合は、詳細なエラーメッセージと解決方法を日本語で説明すること

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
- `AdkChatProvider`: ADKエージェントとの通信状態管理・HTML受信処理
- `PreviewProvider`: HTMLプレビュー表示管理・編集履歴機能
- `NewsletterProvider`: 学級通信データ管理・基本情報保存
- `ImageProvider`: 画像アップロード・Grid表示管理

### 🔄 フロントエンド・バックエンド連携フロー
1. **ユーザー入力** → `AdkChatProvider.sendMessage()`
2. **ADKストリーミング** → `/api/v1/adk/chat/stream` (FastAPI)
3. **エージェント処理** → MainConversationAgent → LayoutAgent
4. **HTML受信** → `AdkChatProvider._generatedHtml`
5. **プレビュー表示** → `PreviewProvider.updateHtmlContent()`

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
uv run python -c "from agents.main_conversation_agent.agent import create_main_conversation_agent; agent = create_main_conversation_agent(); print('MainConversationAgent created successfully')"
uv run python -c "from agents.layout_agent.agent import create_layout_agent; agent = create_layout_agent(); print('LayoutAgent created successfully')"

# プロンプトファイル変更後の反映確認
# agents/*/prompts/*.md を編集後、ADKサーバー再起動が必要
```

### データフロー確認
```bash
# ADK artifacts確認
ls -la /tmp/adk_artifacts/
# outline.json (MainConversationAgent出力)
# newsletter.html (LayoutAgent出力) 

# ファイルベース連携のデバッグ
tail -f /tmp/adk_artifacts/outline.json
tail -f /tmp/adk_artifacts/newsletter.html

# セッション状態確認（実装時）
# ADK Web UI: http://localhost:8080/adk/ui でセッション状態を確認可能
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
- `backend/agents/main_conversation_agent/agent.py` - メインエージェント (root_agent)
- `backend/agents/layout_agent/agent.py` - HTMLレイアウト生成エージェント (sub_agent)
- `backend/agents/*/prompt*.py` - エージェントプロンプト定義
- `/tmp/adk_artifacts/` - エージェント間データ交換
  - `outline.json` - MainConversationAgentが生成するJSON構成案
  - `newsletter.html` - LayoutAgentが生成するHTMLファイル

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
- ✅ **特別賞**: Flutter + Firebase + Deep Dive (ADK・2エージェント連携)
- ✅ **完成度**: 目標達成（2-3時間→15分短縮）・全機能実装済み
- ✅ **技術特徴**: MainConversationAgent + LayoutAgentのシンプルな2段階構成

### ADK v1.4.2+ 使用時の注意
- `Gemini(model_name="gemini-2.5-pro")` - 最新Geminiモデル使用
- `google.adk.agents` - **LlmAgentのみ使用** (MainConversationAgent・LayoutAgent)
- sub_agents機能でエージェント間連携を実現
- プロンプトファイル変更時はADKサーバー再起動必須
- セッション状態とファイルシステム両方でデータ永続化

### Poetry→uv移行完了
- ✅ `pyproject.toml`でuv管理設定済み
- ✅ 全コマンドで`uv run`使用
- ✅ CI/CDパイプライン対応済み

### レスポンシブ対応済み
- デスクトップ: 左右分割レイアウト (768px+)
- モバイル: タブ切り替えレイアウト (768px-)
- Flutter Webで完全対応

## 🎯 Claude Code使用時の重要なルール

### タスク管理
- 複数ステップの作業では、必ずTodoWriteツールを使用してタスクを管理すること
- タスク完了時は即座にTodoWriteツールで状況を更新すること
- テストやビルドが失敗した場合、該当タスクは完了マークしないこと

### コード品質
- コード変更前に必ず既存のコードスタイルを確認し、それに従うこと
- 新しいライブラリを使用する前に、既存のプロジェクトで使用されているかを確認すること
- セキュリティベストプラクティスに従い、秘密情報をコードに含めないこと

### Cursor Rulesとの統合
このプロジェクトは以下のCursor Rulesに従います：
- [task_management_tdd.mdc](.cursor/rules/task_management_tdd.mdc): TDD実装フローとタスク管理の統合
- [document_management.mdc](.cursor/rules/document_management.mdc): ドキュメント管理ルール

## 🚀 Claude Code活用のベストプラクティス

### 開発前の準備
1. **要件定義を先に行う** - すぐに開発を始めず、まず要件を明確にする
2. **ブラウザ操作環境の準備** - Claude Codeがブラウザを操作できる環境を整える
3. **適切なログ設定** - 詳細なログを出力し、Claude Codeに解析させる
4. **コマンド名称の共有** - プロジェクト固有のコマンドをClaude Codeに伝える

### 効率的な作業フロー
5. **音声による完了報告** - 作業完了時は`afplay`で音声報告を行う
6. **git worktreeの活用** - `.git/`配下にワークツリーを作成し、並行開発を支援
7. **権限管理** - `/permissions`コマンドでツール許可を適切に管理
8. **こまめなコミット** - 作業の節目でこまめにコミットを行う

### Claude Code環境設定チェックリスト
- [ ] 権限設定: `/permissions`でツール許可を確認
- [ ] git worktree準備: 並行開発用ワークツリー作成
- [ ] ログ設定: 詳細なエラーログとデバッグ情報の出力設定
- [ ] 音声設定: `afplay`による完了報告の準備
- [ ] 環境変数: 必要な環境変数の設定確認

### 作業効率化コマンド
```bash
# 完了報告用音声再生（macOS）
afplay /System/Library/Sounds/Glass.aiff

# git worktreeの活用
git worktree add .git/feature-branch feature-branch
git worktree list

# Claude Code権限確認
/permissions

# 詳細ログ出力設定の確認
echo "DEBUG=true" >> .env
```
