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
    # Claude Codeのチェックはオプション（存在しない場合は警告のみ）
    if ! command -v claude >/dev/null 2>&1; then
        log_warning "claude コマンドが見つかりません (手動でClaude Codeを起動してください)"
    fi
    
    log_success "依存関係チェック完了"
}

# プロジェクトディレクトリの確認
check_project_dir() {
    if [[ ! -d ".git" ]]; then
        log_error "Gitリポジトリのルートで実行してください"
        exit 1
    fi
    
    PROJECT_ROOT=$(pwd)
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    log_info "プロジェクト: $PROJECT_NAME (${PROJECT_ROOT})"
}

# 並列タスクの定義（依存関係がクリアなもの）
declare -A PARALLEL_TASKS=(
    ["e2e-test"]="T1-FL-005-A:E2Eテスト環境構築:feat/e2e-test-setup:60"
    ["quill-html"]="T2-QU-001-A:Quill.js HTMLファイル作成:feat/quill-html-base:45"
    ["gemini-api"]="T3-AI-002-A:Gemini API基盤実装:feat/gemini-api-client:50"
)

# Git Worktreeの作成
setup_worktrees() {
    log_info "Git Worktreeを設定中..."
    
    # 既存のworktreeをクリーンアップ
    git worktree prune 2>/dev/null || true
    
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        
        worktree_path="../${PROJECT_NAME}-${task_key}"
        
        # 既存のworktreeディレクトリを削除
        if [[ -d "$worktree_path" ]]; then
            log_warning "既存のworktree削除: $worktree_path"
            rm -rf "$worktree_path"
        fi
        
        # 既存のブランチを削除（存在する場合）
        if git show-ref --verify --quiet refs/heads/"$branch_name"; then
            log_warning "既存のブランチ削除: $branch_name"
            git branch -D "$branch_name" 2>/dev/null || true
        fi
        
        # 新しいworktreeを作成
        log_info "Worktree作成: $task_id ($description)"
        git worktree add "$worktree_path" -b "$branch_name"
        
        # 依存関係のチェックとセットアップ
        if [[ -f "$worktree_path/frontend/pubspec.yaml" ]]; then
            log_info "Flutter依存関係をチェック中: $task_key"
            (cd "$worktree_path/frontend" && flutter pub get 2>/dev/null || log_warning "Flutter pub get失敗")
        fi
        
        if [[ -f "$worktree_path/backend/functions/requirements.txt" ]]; then
            log_info "Python依存関係をチェック中: $task_key"
            # 仮想環境のチェック
            if [[ -d "$worktree_path/backend/functions/venv" ]]; then
                (cd "$worktree_path/backend/functions" && source venv/bin/activate && pip install -r requirements.txt 2>/dev/null) || log_warning "Python dependencies install失敗"
            fi
        fi
        
        log_success "Worktree作成完了: $worktree_path"
    done
    
    echo ""
    log_success "全てのWorktreeが作成されました"
    git worktree list
}

# Tmux セッションの作成
setup_tmux_sessions() {
    log_info "Tmux セッションを設定中..."
    
    # メインセッションの作成
    session_name="yutori-parallel"
    
    # 既存セッションを終了
    if tmux has-session -t "$session_name" 2>/dev/null; then
        log_warning "既存のセッション終了: $session_name"
        tmux kill-session -t "$session_name"
    fi
    
    # 新しいセッションを作成
    tmux new-session -d -s "$session_name" -c "$PROJECT_ROOT"
    tmux rename-window -t "$session_name:0" "main"
    
    # メインウィンドウにダッシュボード表示
    tmux send-keys -t "$session_name:main" "echo '🚀 並列AI開発セッション開始'" Enter
    tmux send-keys -t "$session_name:main" "echo '================================'" Enter
    tmux send-keys -t "$session_name:main" "echo '使用方法:'" Enter
    tmux send-keys -t "$session_name:main" "echo '1. C-b 1-3 で各エージェントウィンドウに移動'" Enter
    tmux send-keys -t "$session_name:main" "echo '2. 上ペインでClaude Code起動'" Enter
    tmux send-keys -t "$session_name:main" "echo '3. 下ペインで開発サーバー/テスト実行'" Enter
    tmux send-keys -t "$session_name:main" "echo ''" Enter
    
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
        tmux send-keys -t "$session_name:$window_name.0" "clear" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo '📋 $task_id: $description ($duration分)'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo 'Branch: $branch_name'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo 'Directory: $worktree_path'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo ''" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo '🤖 Claude Code起動コマンド:'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo 'claude'" Enter
        tmux send-keys -t "$session_name:$window_name.0" "echo ''" Enter
        
        # 下ペイン: 開発サーバー/テスト実行用
        tmux send-keys -t "$session_name:$window_name.1" "clear" Enter
        tmux send-keys -t "$session_name:$window_name.1" "echo '⚙️  開発サーバー/テスト実行用ペイン'" Enter
        
        case $task_key in
            "e2e-test")
                tmux send-keys -t "$session_name:$window_name.1" "echo '🧪 E2Eテスト実行コマンド:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'cd frontend && flutter test integration_test/'" Enter
                ;;
            "quill-html") 
                tmux send-keys -t "$session_name:$window_name.1" "echo '🌐 ブラウザプレビュー:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'cd frontend && flutter run -d chrome'" Enter
                ;;
            "gemini-api")
                tmux send-keys -t "$session_name:$window_name.1" "echo '🔧 API テスト:'" Enter
                tmux send-keys -t "$session_name:$window_name.1" "echo 'cd backend/functions && python -m pytest'" Enter
                ;;
        esac
        
        tmux send-keys -t "$session_name:$window_name.1" "echo ''" Enter
        
        ((window_index++))
    done
    
    # メインウィンドウに戻る
    tmux select-window -t "$session_name:0"
    
    log_success "Tmuxセッション '$session_name' が作成されました"
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

## 🎯 タスク概要
- **ID**: $task_id
- **説明**: $description  
- **予想時間**: $duration分
- **TDD要件**: Red→Green→Refactor
- **Git Branch**: $branch_name

## 🔥 実行指示
1. **関連仕様書を読み込み**、実装計画を立てる
2. **テストを先に実装**する (Red Phase)
3. **最小限の実装**でテストを通す (Green Phase)  
4. **リファクタリング**で品質向上 (Blue Phase)
5. **完了後、tasks.mdのチェックボックス更新**

## 📂 プロジェクト構造
- **Frontend**: Flutter Web (lib/以下)
- **Backend**: Python Flask (backend/functions/以下)
- **Tests**: Dart/Python テストファイル

## ⚙️ 重要な設定
- **Git branch**: $branch_name
- **Base directory**: $worktree_path
- **TDD必須**: 全ての機能にテストを書く
- **依存関係**: tasks_dependencies.mdを参照

## 📋 関連ファイル
- **タスク詳細**: docs/tasks.md  
- **依存関係**: docs/tasks_dependencies.md
- **API仕様**: docs/30_API_endpoints.md

## 🎯 完了条件
このタスクの完了条件については、docs/tasks.mdの該当セクションを参照してください。
EOF

        log_success "Claude設定作成: $claude_md"
    done
}

# 監視スクリプトの作成
setup_monitoring() {
    log_info "監視スクリプトを作成中..."
    
    cat > scripts/monitor_parallel_agents.sh << 'EOF'
#!/bin/bash
# 並列エージェント監視スクリプト

PROJECT_NAME="yutorikyoshitu"

check_agent_progress() {
    local task_key=$1
    local worktree_path="../${PROJECT_NAME}-${task_key}"
    
    if [[ ! -d "$worktree_path" ]]; then
        echo "❌ Worktree not found: $task_key"
        return 1
    fi
    
    cd "$worktree_path"
    
    # Git状況確認
    local branch=$(git branch --show-current)
    local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
    local modified=$(git status --porcelain | wc -l)
    local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "No commits")
    
    echo "📋 Agent: $task_key"
    echo "  Branch: $branch"
    echo "  Commits: $commits"
    echo "  Modified files: $modified"
    echo "  Last commit: $last_commit"
    echo ""
}

# メイン監視ループ
while true; do
    clear
    echo "🚀 並列AI開発 監視ダッシュボード"
    echo "=================================="
    echo "更新時刻: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 各エージェントの状況確認
    for task in e2e-test quill-html gemini-api; do
        check_agent_progress "$task"
    done
    
    echo "🔄 30秒後に更新... (Ctrl+C で終了)"
    sleep 30
done
EOF

    chmod +x scripts/monitor_parallel_agents.sh
    log_success "監視スクリプト作成: scripts/monitor_parallel_agents.sh"
}

# メイン実行関数
main() {
    echo ""
    log_info "🚀 並列AI開発環境セットアップを開始します"
    echo ""
    
    check_dependencies
    check_project_dir
    setup_worktrees
    setup_tmux_sessions  
    setup_claude_configs
    setup_monitoring
    
    echo ""
    log_success "🎉 並列開発環境のセットアップが完了しました！"
    
    echo ""
    echo "📋 次のステップ:"
    echo "1. tmux attach-session -t yutori-parallel"
    echo "2. 各ウィンドウ(e2e-agent, quill-agent, gemini-agent)でClaude Codeを起動"
    echo "3. 並列でタスクを実行開始"
    echo ""
    
    echo "📊 実行可能タスク:"
    for task_key in "${!PARALLEL_TASKS[@]}"; do
        IFS=':' read -r task_id description branch_name duration <<< "${PARALLEL_TASKS[$task_key]}"
        echo "  • $task_id: $description ($duration分)"
    done
    echo ""
    
    echo "🔍 監視ダッシュボード起動 (別ターミナル):"
    echo "  ./scripts/monitor_parallel_agents.sh"
    echo ""
    
    log_warning "⚠️  重要: 各エージェントは独立して動作します。進捗は定期的に確認してください。"
    echo ""
}

# スクリプト実行
main "$@" 