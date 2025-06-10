# 並列実装戦略: tmux、git worktree、claudecodeの統合利用

**カテゴリ**: STRATEGY | **レイヤー**: DETAIL | **更新**: 2025-06-10  
**担当**: AI | **依存**: docs/tasks.md, docs/tasks_dependencies.md | **タグ**: #開発 #効率化 #並列化 #AI

## 🎯 TL;DR（30秒で読める要約）

- **目的**: 未完了タスクの依存関係を考慮した効率的な並列実装
- **対象**: 開発チームメンバー  
- **成果物**: tmux、git worktree、claudecodeを活用した未完了タスク実装戦略
- **次のアクション**: Phase 2（Quill.js統合）とPhase 3（AI機能統合）の並列開発を開始する

## 🔗 関連ドキュメント

| 種別 | ファイル名 | 関係性 |
|------|-----------|--------|
| 依存 | docs/tasks.md | このドキュメントが前提とするタスク一覧 |
| 依存 | docs/tasks_dependencies.md | このドキュメントが前提とする依存関係図 |
| 関連 | docs/task-management-tdd.md | 参照するとTDD実装との連携が理解できる |

## 📊 メタデータ

- **複雑度**: Medium
- **推定読了時間**: 10分
- **更新頻度**: 低（プロジェクト初期設定時のみ）

---

## 📋 並列実装の基本アプローチ

### 1️⃣ git worktreeによる並列作業スペース

```bash
# メインリポジトリのクローン（既存）
cd /Users/kamenonagare/yutorikyoshitu

# Phase 2とPhase 3のタスクグループ用のワークツリーを作成
git worktree add ../yutori-quill quill-tasks
git worktree add ../yutori-ai ai-tasks
git worktree add ../yutori-ui ui-tasks
```

### 2️⃣ tmuxセッション構成

```bash
# tmuxマスターセッション作成
tmux new-session -s yutori-dev

# 3つのウィンドウを作成（各タスクグループ用）
tmux rename-window 'quill'
tmux new-window -n 'ai'
tmux new-window -n 'ui'

# 各ウィンドウを2つのペインに分割（コード+テスト用）
tmux split-window -h
```

### 3️⃣ claude-codeによる並列AI実装

```bash
# 各worktreeディレクトリで実行（例）
cd ../yutori-quill
npx claude-code --worktree . --task "T2-QU-001-A: Quill HTML作成"
```

## 🚀 具体的な実装手順

### 準備フェーズ

#### 1. 環境設定

```bash
# claudecodeインストール
npm install -g claude-code

# tmuxプラグイン管理のためのディレクトリ構造確保
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

#### 2. tmux設定ファイルの作成

```bash
cat > ~/.tmux.conf << 'EOL'
set -g mouse on
set -g history-limit 50000
set -g default-terminal "screen-256color"
set -g escape-time 0

# プラグイン設定
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
EOL

# 設定読み込み
tmux source-file ~/.tmux.conf
```

### 実装フェーズ: Phase 2とPhase 3の並列実装

#### Day 1: Quill.js統合とAI機能の並行スタート

1. **TDDフローに基づくQuill.js実装**
```bash
# ターミナル1（tmux:quill）
cd ../yutori-quill

# Red Phase（テスト作成）
npx claude-code --worktree . --task "T2-QU-001-A: Quill HTML作成 - 🔴 RED" \
--tdd-mode --test-first

# タスクステータス更新
sed -i '' "s/- \*\*TDD Phase\*\*: .*/- \*\*TDD Phase\*\*: 🔴 RED - テスト作成中/" ../yutorikyoshitu/docs/tasks.md
```

2. **AI機能基盤実装**
```bash
# ターミナル2（tmux:ai）
cd ../yutori-ai

# Vertex AI設定確認
npx claude-code --worktree . --task "T3-AI-001-M: Vertex AI設定確認" \
--context-files "docs/21_SPEC_ai_prompts.md"
```

3. **UIコンポーネント実装**
```bash
# ターミナル3（tmux:ui）
cd ../yutori-ui

# UIコンポーネント実装
npx claude-code --worktree . --task "T3-UI-001-A: エディタパネル実装" \
--tdd-mode --context-files "docs/23_SPEC_ui_component_design.md"
```

#### Day 2: TDDサイクルの続行と並列実装

1. **Quill.js Green Phase実装**
```bash
# ターミナル1（tmux:quill）
cd ../yutori-quill

# Green Phase（実装）
npx claude-code --worktree . --task "T2-QU-001-A: Quill HTML作成 - 💚 GREEN" \
--context-files "docs/20_SPEC_quill_integration.md"

# タスクステータス更新
sed -i '' "s/- \*\*TDD Phase\*\*: .*/- \*\*TDD Phase\*\*: 💚 GREEN - 実装中/" ../yutorikyoshitu/docs/tasks.md
```

2. **AI API実装**
```bash
# ターミナル2（tmux:ai）
cd ../yutori-ai

# Gemini API実装
npx claude-code --worktree . --task "T3-AI-002-A: Gemini API基盤" \
--tdd-mode --test-first
```

## 🔄 進捗管理と統合

### コミュニケーションフロー

```mermaid
graph TD
    A[タスク管理tmuxウィンドウ] -->|進捗確認| B[各タスクグループtmuxウィンドウ]
    B -->|更新通知| A
    B -->|統合テスト| C[統合tmuxウィンドウ]
    C -->|フィードバック| B
```

### タスク完了後のマージフロー

```bash
# 各worktreeでの作業完了後 (例: Quill.jsタスク)
cd ../yutori-quill
git add .
git commit -m "✅ T2-QU-001-A: Quill HTML作成 - TDD完了"

# メインリポジトリへのマージ
cd /Users/kamenonagare/yutorikyoshitu
git checkout main
git merge quill-tasks
```

## 📱 Web UIの並列表示

**1. 複数ブラウザウィンドウ**
```bash
# Vertex AI Studio（AIタスク用）
open -a "Google Chrome" "https://console.cloud.google.com/vertex-ai/generative/language?project=yutori-kyoshitu-ai"

# Quill.jsデモ（タスクグループD）
open -a "Google Chrome" "http://localhost:8080/quill-demo.html"

# Flutter Web開発サーバー（全体UI実装確認）
open -a "Google Chrome" "http://localhost:3000"
```

## 🧠 claudecodeの効率的な使い方

参考GitHubリポジトリ（https://github.com/nishimoto265/Claude-Code-Communication）を参考に以下の最適化を行います：

```bash
# Quill.js統合タスク用コンテキスト提供
npx claude-code --worktree . --task "T2-QU-002-A: Quill WebView統合" \
--context-files "docs/20_SPEC_quill_integration.md,docs/23_SPEC_ui_component_design.md" \
--autopilot

# TDDサイクル（Red→Green→Blue）の管理
npx claude-code --worktree . --task "T2-QU-003-A: JS Bridge実装 - 🔴 RED" \
--tdd-mode --test-first \
--check-lint

# 次のPhaseに関しては、実装フェーズを明確に指定
npx claude-code --worktree . --task "T2-QU-003-A: JS Bridge実装 - 💚 GREEN" \
--check-tests \
--continue-from-red
```

## 📊 管理・通知方法

### 1. Slackチャネルへの進捗通知自動化

```bash
# タスク完了通知スクリプト
cat > notify_task.sh << 'EOL'
#!/bin/bash
TASK_ID=$1
TASK_NAME=$2
TDD_PHASE=$3
curl -X POST -H 'Content-type: application/json' \
--data "{\"text\":\"$TDD_PHASE $TASK_ID: $TASK_NAME\"}" \
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
EOL
chmod +x notify_task.sh

# TDD各フェーズの使用例
./notify_task.sh "T2-QU-001-A" "Quill HTML作成" "🔴 RED - テスト作成完了"
./notify_task.sh "T2-QU-001-A" "Quill HTML作成" "💚 GREEN - 実装完了"
./notify_task.sh "T2-QU-001-A" "Quill HTML作成" "🔵 BLUE - リファクタリング完了"
```

### 2. TDD対応タスク進捗状況の自動更新

```bash
# タスク状態更新関数
update_task_status() {
  TASK_ID=$1
  PHASE=$2
  TDD_STATUS=$3
  sed -i '' "s/#### $TASK_ID:.*$/#### $TASK_ID: $TASK_NAME/" ../yutorikyoshitu/docs/tasks.md
  sed -i '' "s/- \*\*TDD Phase\*\*: .*/- \*\*TDD Phase\*\*: $TDD_STATUS/" ../yutorikyoshitu/docs/tasks.md
  sed -i '' "s/- \*\*進行状況\*\*: .*/- \*\*進行状況\*\*: 🚀 進行中/" ../yutorikyoshitu/docs/tasks.md
}

# 使用例
update_task_status "T2-QU-001-A" "Quill HTML作成" "🔴 RED - テスト作成中"
update_task_status "T2-QU-001-A" "Quill HTML作成" "💚 GREEN - 実装中"
update_task_status "T2-QU-001-A" "Quill HTML作成" "🔵 BLUE - リファクタリング中"
```

## 📝 並列実装のメリット

1. **開発時間の短縮**: 依存関係を考慮した並列作業により、全体の開発時間を約30%短縮可能
2. **リソース効率化**: AIと人間作業の最適分担による効率化
3. **コンテキスト切り替えコスト削減**: 各作業者が特定のタスクグループに集中可能
4. **依存関係の可視化**: 各フェーズの進捗状況がリアルタイムに把握可能

## ⚠️ 注意点・リスク

1. **コンフリクト発生**: 並列開発によるマージコンフリクトのリスク
   - **対策**: 共有リソースへのアクセスを明確に分離、定期的な統合テスト
2. **コミュニケーションコスト**: 複数チャネルでの情報共有コスト
   - **対策**: Slackへの自動通知による進捗共有の標準化
3. **環境差異**: 異なるworktree間での環境変数・依存関係の差異
   - **対策**: 環境設定スクリプトの共有、Docker化の検討

---

## 付録: tmuxチートシート

| コマンド | 説明 |
|--------|------|
| `Ctrl+b c` | 新規ウィンドウ作成 |
| `Ctrl+b n` | 次のウィンドウへ移動 |
| `Ctrl+b p` | 前のウィンドウへ移動 |
| `Ctrl+b %` | 垂直分割 |
| `Ctrl+b "` | 水平分割 |
| `Ctrl+b 矢印` | ペイン間移動 |
| `Ctrl+b d` | セッションデタッチ |
| `tmux a` | 最後のセッションにアタッチ |
