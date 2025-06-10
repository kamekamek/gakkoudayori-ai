# 🚀 並列AI開発 クイックスタートガイド

**目的**: tmux + git worktree + Claude Code を使った並列タスク実装のステップバイステップガイド

---

## ⚡ クイック実行

```bash
# 1. 並列環境セットアップ（3分）
./scripts/setup_parallel_dev.sh

# 2. 監視ダッシュボード起動（別ターミナル）
./scripts/monitor_parallel_agents.sh

# 3. 並列セッション接続
tmux attach-session -t yutori-parallel

# 4. 各エージェントでClaude Code起動
# C-b 1, C-b 2, C-b 3でウィンドウ移動し、上ペインで「claude」実行
```

---

## 📋 詳細手順

### 1️⃣ 環境準備（5分）

```bash
# 必要ツールの確認
which tmux git flutter python

# プロジェクトルートにいることを確認
pwd  # /Users/kamenonagare/yutorikyoshitu

# 現在のブランチ状況確認
git status
git worktree list  # 既存worktreeがあれば表示
```

### 2️⃣ 並列環境セットアップ（3分）

```bash
# セットアップスクリプト実行
./scripts/setup_parallel_dev.sh
```

**何が作成されるか：**
- **Git Worktree**: 3つの独立した作業ディレクトリ
  - `../yutorikyoshitu-e2e-test` (feat/e2e-test-setup)
  - `../yutorikyoshitu-quill-html` (feat/quill-html-base)  
  - `../yutorikyoshitu-gemini-api` (feat/gemini-api-client)
- **Tmux セッション**: `yutori-parallel` (4ウィンドウ)
- **Claude設定**: 各worktreeにCLAUDE.md
- **監視ツール**: scripts/monitor_parallel_agents.sh

### 3️⃣ 監視ダッシュボード起動（別ターミナル）

```bash
# 新しいターミナルを開き、プロジェクトルートで実行
cd /Users/kamenonagare/yutorikyoshitu
./scripts/monitor_parallel_agents.sh
```

**ダッシュボード表示例：**
```
🚀 並列AI開発 監視ダッシュボード
==================================
更新時刻: 2025-01-17 19:45:23

📋 Agent: e2e-test
  Branch: feat/e2e-test-setup
  Commits: 0
  Modified files: 0
  Last commit: No commits

📋 Agent: quill-html
  Branch: feat/quill-html-base
  Commits: 0
  Modified files: 0
  Last commit: No commits

📋 Agent: gemini-api
  Branch: feat/gemini-api-client
  Commits: 0
  Modified files: 0
  Last commit: No commits

🔄 30秒後に更新... (Ctrl+C で終了)
```

### 4️⃣ 並列セッション接続

```bash
# Tmuxセッションに接続
tmux attach-session -t yutori-parallel
```

**セッション構成：**
- **Window 0 (main)**: プロジェクト管理・進捗確認
- **Window 1 (e2e-agent)**: T1-FL-005-A実行
- **Window 2 (quill-agent)**: T2-QU-001-A実行  
- **Window 3 (gemini-agent)**: T3-AI-002-A実行

---

## 🤖 AIエージェント起動手順

### ステップ1: 各ウィンドウでClaude Code起動

#### Window 1: E2Eテストエージェント
```bash
# C-b 1 でウィンドウ移動
# 上ペインで実行:
claude

# 起動後、以下を伝える:
# "T1-FL-005-A: E2Eテスト環境構築を開始してください。CLAUDE.mdに詳細があります。"
```

#### Window 2: Quill.jsエージェント
```bash
# C-b 2 でウィンドウ移動
# 上ペインで実行:
claude

# 起動後、以下を伝える:
# "T2-QU-001-A: Quill.js HTMLファイル作成を開始してください。CLAUDE.mdに詳細があります。"
```

#### Window 3: Gemini APIエージェント
```bash
# C-b 3 でウィンドウ移動
# 上ペインで実行:
claude

# 起動後、以下を伝える:
# "T3-AI-002-A: Gemini API基盤実装を開始してください。CLAUDE.mdに詳細があります。"
```

### ステップ2: 各エージェントに実行指示

各Claude Codeインスタンスで以下のプロンプトを使用：

```markdown
# 標準実行プロンプト

@CLAUDE.md このタスクを開始してください。

実行方針：
1. TDD Red-Green-Refactorサイクルに従う
2. テストを先に実装する
3. 最小限の実装でテストを通す
4. リファクタリングで品質向上
5. 完了後はtasks.mdを更新

関連仕様書の確認も忘れずにお願いします。
```

---

## 📊 進捗管理・監視

### リアルタイム監視

```bash
# 監視ダッシュボード（30秒間隔で更新）
./scripts/monitor_parallel_agents.sh

# Git状況の手動確認
git worktree list
git branch -a | grep feat/

# 各エージェントの進捗確認
cd ../yutorikyoshitu-e2e-test && git log --oneline
cd ../yutorikyoshitu-quill-html && git log --oneline  
cd ../yutorikyoshitu-gemini-api && git log --oneline
```

### 進捗更新チェック

```bash
# tasks.mdの進捗確認
grep -E "T1-FL-005-A|T2-QU-001-A|T3-AI-002-A" docs/tasks.md

# テスト状況確認
cd ../yutorikyoshitu-e2e-test/frontend && flutter test
cd ../yutorikyoshitu-quill-html/frontend && flutter test
cd ../yutorikyoshitu-gemini-api/backend/functions && python -m pytest
```

---

## 🔧 トラブルシューティング

### よくある問題と解決策

#### 1. Tmuxセッションが見つからない
```bash
# セッション一覧確認
tmux list-sessions

# セッション再作成
./scripts/setup_parallel_dev.sh
```

#### 2. Git Worktreeエラー
```bash
# 既存worktreeのクリーンアップ
git worktree prune
rm -rf ../yutorikyoshitu-*

# 再セットアップ
./scripts/setup_parallel_dev.sh
```

#### 3. Claude Codeが起動しない
```bash
# Cursorのリロード
# Cmd+Shift+P -> "Developer: Reload Window"

# Claude Code手動起動
# VS Code/Cursor拡張から「Claude Code」を起動
```

#### 4. 依存関係エラー
```bash
# Flutter依存関係の再インストール
cd frontend && flutter clean && flutter pub get

# Python依存関係の再インストール  
cd backend/functions && pip install -r requirements.txt
```

### エラー発生時の対応

```bash
# 1. 現在の状況確認
tmux list-sessions
git worktree list
git status

# 2. 部分的なリセット
tmux kill-session -t yutori-parallel  # Tmuxのみリセット
git worktree remove ../yutorikyoshitu-problematic-agent  # 問題のあるworktreeのみ削除

# 3. 完全リセット
./scripts/cleanup_parallel_env.sh  # 全環境クリーンアップ（別途作成）
./scripts/setup_parallel_dev.sh    # 再セットアップ
```

---

## 🎯 成功の指標

### タスク完了の確認

各タスクが以下の状態になったら完了：

#### T1-FL-005-A (E2Eテスト環境構築)
- [ ] integration_test/ ディレクトリ作成
- [ ] E2Eテストファイルの実装
- [ ] `flutter test integration_test/` が成功
- [ ] tasks.mdの完了チェック更新

#### T2-QU-001-A (Quill.js HTMLファイル作成)
- [ ] web/quill/ ディレクトリ作成
- [ ] HTML/CSS/JSファイルの実装
- [ ] Flutter Webで表示確認
- [ ] tasks.mdの完了チェック更新

#### T3-AI-002-A (Gemini API基盤実装)
- [ ] backend/functions/ にAPI実装
- [ ] Vertex AI連携機能
- [ ] `python -m pytest` が成功
- [ ] tasks.mdの完了チェック更新

### 統合作業の準備

```bash
# 全タスク完了後、統合ブランチ作成準備
cd /Users/kamenonagare/yutorikyoshitu
git checkout main
git pull origin main

# 統合スクリプト実行（後で作成）
./scripts/integrate_parallel_work.sh
```

---

## 🎉 期待される成果

### 並列実行による効率化

- **従来**: 155分の逐次実行（60分+45分+50分）
- **並列**: 60分の並列実行（最長タスクT1-FL-005-A）
- **効率向上**: 約2.6倍の時間短縮

### 品質向上

- **TDD実践**: 全タスクでRed-Green-Refactorサイクル
- **独立テスト**: 各機能が独立してテスト可能
- **統合テスト**: 最終的な統合時に全機能テスト

### 学習効果

- **Git Worktree**: 並列開発環境の構築スキル
- **Tmux管理**: 複数セッションの効率的な管理
- **AI協働**: 複数AIエージェントとの並列作業

この並列開発戦略により、**効率・品質・学習**の三方良しを実現できます！ 