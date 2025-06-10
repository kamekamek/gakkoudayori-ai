#!/bin/bash

# 🚀 並列AI開発環境セットアップスクリプト
# Usage: ./scripts/setup_parallel_dev.sh

set -e

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 必要なツールの確認
check_dependencies() {
    log_info "依存関係をチェック中..."
    
    command -v tmux >/dev/null 2>&1 || { log_error "tmux が必要です"; exit 1; }
    command -v git >/dev/null 2>&1 || { log_error "git が必要です"; exit 1; }
    command -v claude >/dev/null 2>&1 || { log_error "claude code が必要です"; exit 1; }
    
    log_success "全ての依存関係が確認できました"
}

# プロジェクトディレクトリの確認
check_project_dir() {
    if [[ ! -d ".git" ]]; then
        log_error "Gitリポジトリのルートで実行してください"
        exit 1
    fi
    
    PROJECT_ROOT=$(pwd)
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    log_info "プロジェクト: $PROJECT_NAME"
}

# 並列タスクの定義
declare -A PARALLEL_TASKS=(
    ["e2e-test"]="T1-FL-005-A:E2Eテスト環境構築:feat/e2e-test-setup:60"
    ["quill-html"]="T2-QU-001-A:Quill.js HTMLファイル作成:feat/quill-html-base:45"
    ["gemini-api"]="T3-AI-002-A:Gemini API基盤実装:feat/gemini-api-client:50"
)

# Git Worktreeの作成
setup_worktrees() {
    log_info "Git Worktreeを設定中..."
    
    # 既存のworktreeをクリーンアップ
    git worktree prune
    
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        
        # 既存のworktreeディレクトリを削除
        if [[ -d "$worktree_path" ]]; then
            log_warning "既存のworktree削除: $worktree_path"
            rm -rf "$worktree_path"
        fi
        
        # 新しいworktreeを作成
        log_info "Worktree作成: $task_id ($description)"
        git worktree add "$worktree_path" -b "$branch_name"
        
        # 依存関係の確認とコピー
        if [[ "$task_key" == "quill-html" || "$task_key" == "gemini-api" ]]; then
            # フロントエンドまたはバックエンドの依存関係をインストール
            if [[ -f "$worktree_path/frontend/pubspec.yaml" ]]; then
                log_info "Flutter依存関係をインストール中: $task_key"
                (cd "$worktree_path/frontend" && flutter pub get)
            fi
            
            if [[ -f "$worktree_path/backend/functions/requirements.txt" ]]; then
                log_info "Python依存関係をインストール中: $task_key"
                (cd "$worktree_path/backend/functions" && pip install -r requirements.txt)
            fi
        fi
    done
    
    log_success "全てのWorktreeが作成されました"
    git worktree list
}

# Tmux セッションの作成
setup_tmux_sessions() {
    log_info "Tmux セッションを設定中..."
    
    # メインセッションの作成
    session_name="yutori-parallel"
    
    # 既存セッションを終了
    tmux has-session -t "$session_name" 2>/dev/null && tmux kill-session -t "$session_name"
    
    # 新しいセッションを作成
    tmux new-session -d -s "$session_name" -c "$PROJECT_ROOT"
    tmux rename-window -t "$session_name:0" "main"
    
    # 各タスク用のウィンドウを作成
    window_index=1
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        window_name="${task_key}-agent"
        
        # 新しいウィンドウを作成
        tmux new-window -t "$session_name:$window_index" -c "$worktree_path" -n "$window_name"
        
        # 垂直分割してペインを作成
        tmux split-window -t "$session_name:$window_name" -v -c "$worktree_path"
        
        # 上ペイン: Claude Code実行準備
        tmux send-keys -t "$session_name:$window_name.0" "# $task_id: $description ($duration分)" Enter
        tmux send-keys -t "$session_name:$window_name.0" "# Claude Code実行コマンド:" Enter
        tmux send-keys -t "$session_name:$window_name.0" "# claude --dangerously-skip-permissions" Enter
        
        # 下ペイン: 開発サーバー/テスト実行用
        tmux send-keys -t "$session_name:$window_name.1" "# 開発サーバー/テスト実行用ペイン" Enter
        
        case $task_key in
            "e2e-test")
                tmux send-keys -t "$session_name:$window_name.1" "# E2Eテスト実行コマンド:" Enter
                tmux send-keys -t "$session_name:$window_name.1" "# cd frontend && flutter test integration_test/" Enter
                ;;
            "quill-html") 
                tmux send-keys -t "$session_name:$window_name.1" "# ブラウザプレビュー:" Enter
                tmux send-keys -t "$session_name:$window_name.1" "# cd frontend && flutter run -d chrome" Enter
                ;;
            "gemini-api")
                tmux send-keys -t "$session_name:$window_name.1" "# API テスト:" Enter
                tmux send-keys -t "$session_name:$window_name.1" "# cd backend/functions && python -m pytest" Enter
                ;;
        esac
        
        ((window_index++))
    done
    
    # メインウィンドウに戻る
    tmux select-window -t "$session_name:0"
    
    log_success "Tmuxセッション '$session_name' が作成されました"
    log_info "接続コマンド: tmux attach-session -t $session_name"
}

# Claude Code用の設定ファイル作成
setup_claude_configs() {
    log_info "Claude Code設定を作成中..."
    
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        claude_md="$worktree_path/CLAUDE.md"
        
        # 各worktree用のCLAUDE.mdを作成
        cat > "$claude_md" << EOF
# $task_id: $description

## タスク概要
- **ID**: $task_id
- **説明**: $description  
- **予想時間**: $duration分
- **TDD要件**: Red→Green→Refactor

## 実行指示
1. 関連仕様書を読み込み、実装計画を立てる
2. テストを先に実装する (Red Phase)
3. 最小限の実装でテストを通す (Green Phase)  
4. リファクタリングで品質向上 (Blue Phase)
5. 完了後、tasks.mdのチェックボックス更新

## プロジェクト構造
- Frontend: Flutter Web (lib/以下)
- Backend: Python Flask (backend/functions/以下)
- Tests: Dart/Python テストファイル

## 重要な設定
- Git branch: $branch_name
- Base directory: $worktree_path
- TDD必須: 全ての機能にテストを書く

## 関連ファイル
- タスク詳細: docs/tasks.md  
- 依存関係: docs/tasks_dependencies.md
- API仕様: docs/30_API_endpoints.md
EOF

        log_success "Claude設定作成: $claude_md"
    done
}

# メイン実行関数
main() {
    log_info "🚀 並列AI開発環境セットアップを開始します"
    
    check_dependencies
    check_project_dir
    setup_worktrees
    setup_tmux_sessions  
    setup_claude_configs
    
    log_success "🎉 並列開発環境のセットアップが完了しました！"
    
    echo ""
    log_info "📋 次のステップ:"
    echo "1. tmux attach-session -t yutori-parallel"
    echo "2. 各ウィンドウ(e2e-agent, quill-agent, gemini-agent)でClaude Codeを起動"
    echo "3. 並列でタスクを実行開始"
    echo ""
    
    log_info "📊 実行可能タスク:"
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        echo "  • $task_id: $description ($duration分)"
    done
    echo ""
    
    log_warning "⚠️  重要: 各エージェントは独立して動作します。進捗は定期的に確認してください。"
}

# スクリプト実行
main "$@" 