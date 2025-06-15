#!/bin/bash
# エージェント間通信システム (Claude-Code-Communication手法応用)

set -e

SESSION_NAME="yutori-parallel"
PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"
LOG_FILE="logs/agent_communication.log"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

# 使用方法表示
show_usage() {
    echo "🤖 エージェント通信システム"
    echo "=========================="
    echo ""
    echo "使用方法:"
    echo "  $0 [エージェント名] [メッセージ]"
    echo "  $0 --list                    # エージェント一覧"
    echo "  $0 --status                  # 全エージェント状態"
    echo "  $0 --notify [タスクID]       # タスク完了通知"
    echo ""
    echo "エージェント名:"
    echo "  quill-html-agent"
    echo "  webview-integration-agent"
    echo "  gemini-api-agent"
    echo ""
    echo "例:"
    echo "  $0 quill-html-agent 'T2-QU-001-A完了しました'"
    echo "  $0 --notify T2-QU-001-A"
}

# エージェント一覧表示
list_agents() {
    echo "📋 利用可能なエージェント:"
    echo ""
    
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux list-windows -t "$SESSION_NAME" | grep -E "(quill|webview|gemini)" | while read line; do
            window_info=$(echo "$line" | awk '{print $2}')
            echo "  🤖 $window_info"
        done
    else
        echo "❌ Tmuxセッション '$SESSION_NAME' が見つかりません"
        echo "   './scripts/setup_parallel_v2.sh' を先に実行してください"
    fi
}

# エージェント状態確認
check_agents_status() {
    echo "📊 エージェント状態確認:"
    echo ""
    
    local agents=("quill-html-agent" "webview-integration-agent" "gemini-api-agent")
    
    for agent in "${agents[@]}"; do
        check_single_agent_status "$agent"
    done
}

# 単一エージェント状態確認
check_single_agent_status() {
    local agent_name=$1
    local task_key=$(echo "$agent_name" | sed 's/-agent$//')
    local worktree_path="../yutorikyoshitu-${task_key}"
    
    echo "🤖 $agent_name:"
    
    if [[ -d "$worktree_path" ]]; then
        cd "$worktree_path"
        
        local branch=$(git branch --show-current)
        local commits=$(git rev-list HEAD --count 2>/dev/null || echo "0")
        local modified=$(git status --porcelain | wc -l)
        local last_commit=$(git log -1 --format="%h %s" 2>/dev/null || echo "No commits")
        
        echo "  📁 ディレクトリ: $worktree_path"
        echo "  🌿 ブランチ: $branch"
        echo "  📝 コミット数: $commits"
        echo "  🔄 変更ファイル: $modified"
        echo "  📜 最終コミット: $last_commit"
        
        cd - > /dev/null
    else
        echo "  ❌ Worktreeが見つかりません: $worktree_path"
    fi
    echo ""
}

# メッセージ送信
send_message() {
    local agent_name=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Tmuxセッション存在確認
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "❌ Tmuxセッション '$SESSION_NAME' が見つかりません"
        return 1
    fi
    
    # エージェントウィンドウ存在確認
    if ! tmux list-windows -t "$SESSION_NAME" | grep -q "$agent_name"; then
        echo "❌ エージェント '$agent_name' が見つかりません"
        echo "利用可能なエージェント:"
        list_agents
        return 1
    fi
    
    # メッセージ送信
    log_info "メッセージ送信中: $agent_name"
    
    # Claude Codeペインにメッセージ送信
    tmux send-keys -t "$SESSION_NAME:$agent_name.0" "$message" Enter
    
    # ログ記録
    echo "[$timestamp] TO:$agent_name MESSAGE:$message" >> "$LOG_FILE"
    
    log_success "メッセージ送信完了: $agent_name"
}

# タスク完了通知
notify_task_completion() {
    local task_id=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "タスク完了通知送信中: $task_id"
    
    case $task_id in
        "T2-QU-001-A")
            # Quill.js HTML完了 → WebView統合エージェントに通知
            send_message "webview-integration-agent" "🎉 依存タスクT2-QU-001-A完了！WebView統合タスクを開始してください。"
            ;;
        "T2-QU-002-A")
            # WebView統合完了 → 関連エージェントに通知
            send_message "quill-html-agent" "🎉 T2-QU-002-A WebView統合完了！連携確認をお願いします。"
            ;;
        "T3-AI-002-A")
            # Gemini API完了 → 他エージェントに通知
            send_message "quill-html-agent" "🎉 T3-AI-002-A Gemini API基盤完了！AI統合準備ができました。"
            send_message "webview-integration-agent" "🎉 T3-AI-002-A Gemini API基盤完了！AI統合準備ができました。"
            ;;
        *)
            log_warning "未知のタスクID: $task_id"
            ;;
    esac
    
    # 完了ログ記録
    echo "[$timestamp] TASK_COMPLETED:$task_id" >> "$LOG_FILE"
    
    log_success "タスク完了通知送信完了: $task_id"
}

# メイン処理
main() {
    # ログディレクトリ作成
    mkdir -p logs
    
    case "${1:-}" in
        "--list")
            list_agents
            ;;
        "--status")
            check_agents_status
            ;;
        "--notify")
            if [[ -z "${2:-}" ]]; then
                echo "❌ タスクIDを指定してください"
                show_usage
                exit 1
            fi
            notify_task_completion "$2"
            ;;
        "--help"|"-h"|"")
            show_usage
            ;;
        *)
            if [[ -z "${2:-}" ]]; then
                echo "❌ メッセージを指定してください"
                show_usage
                exit 1
            fi
            send_message "$1" "$2"
            ;;
    esac
}

main "$@" 