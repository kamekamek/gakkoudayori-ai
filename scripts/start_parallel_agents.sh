#!/bin/bash
# 並列エージェント自動起動スクリプト (Phase 2対応)

set -e

SESSION_NAME="yutori-parallel"
PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

echo "🤖 Phase 2並列AIエージェント自動起動"
echo "================================="

# Tmuxセッションの存在確認
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    log_warning "Tmuxセッションが見つかりません。先に setup_parallel_dev.sh を実行してください"
    echo "実行コマンド: ./scripts/setup_parallel_dev.sh"
    exit 1
fi

log_info "Tmuxセッション '$SESSION_NAME' に接続中..."

# 各エージェントに自動指示を送信
start_agent() {
    local window_name=$1
    local task_id=$2
    local task_description=$3
    local instruction=$4
    
    log_info "🤖 $window_name エージェント起動中..."
    
    # Claude Code起動指示
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '🚀 $task_id エージェント自動起動中...'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo 'タスク: $task_description'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo 'Claude Code指示: $instruction'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
    
    # Claude Code起動コマンド準備
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '📋 Claude Code起動準備完了'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '以下のコマンドでClaude Codeを起動してください:'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '  claude'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '起動後、以下を伝えてください:'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '\"$instruction\"'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
    
    log_success "$window_name エージェント準備完了"
}

# 各エージェントの起動
log_info "各エージェントに指示を送信中..."

# Window 1: Quill.js HTMLエージェント
start_agent "quill-html-agent" "T2-QU-001-A" "Quill.js HTMLファイル作成" \
"T2-QU-001-A: Quill.js HTMLファイル作成を開始してください。docs/tasks.mdで完了条件を確認し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"

# Window 2: WebView統合エージェント
start_agent "webview-integration-agent" "T2-QU-002-A" "WebView Flutter統合" \
"T2-QU-002-A: WebView Flutter統合を開始してください。T2-QU-001-Aの完了後に実行可能です。docs/tasks.mdで完了条件を確認し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"

# Window 3: Gemini APIエージェント  
start_agent "gemini-api-agent" "T3-AI-002-A" "Gemini API基盤実装" \
"T3-AI-002-A: Gemini API基盤実装を開始してください。docs/tasks.mdで完了条件を確認し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"

echo ""
log_success "🎉 全エージェントの準備が完了しました！"
echo ""
echo "📋 次のステップ:"
echo "1. 各ウィンドウに移動してClaude Codeを起動"
echo "   C-b 1 → claude (Quill.js HTML)"
echo "   C-b 2 → claude (WebView統合)"  
echo "   C-b 3 → claude (Gemini API)"
echo ""
echo "2. 各エージェントに表示された指示を伝える"
echo ""
echo "3. 監視ダッシュボードで進捗確認:"
echo "   ./scripts/monitor_parallel_agents.sh"
echo ""
echo "🚀 効率的な並列実装を開始してください！" 