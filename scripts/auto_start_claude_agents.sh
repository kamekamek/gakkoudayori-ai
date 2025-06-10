#!/bin/bash
# 完全自動Claude Code並列エージェント起動スクリプト

set -e

SESSION_NAME="yutori-parallel"
PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

echo "🤖 完全自動Claude Code並列エージェント起動"
echo "======================================="

# Tmuxセッションの存在確認
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    log_warning "Tmuxセッションが見つかりません。先に setup_parallel_dev.sh を実行してください"
    echo "実行コマンド: ./scripts/setup_parallel_dev.sh"
    exit 1
fi

# Claude Codeの存在確認
if ! command -v claude >/dev/null 2>&1; then
    log_warning "claude コマンドが見つかりません"
    echo "Claude Codeを手動でインストールしてください"
    exit 1
fi

log_info "Tmuxセッション '$SESSION_NAME' で自動エージェント起動中..."

# 完全自動エージェント起動
auto_start_claude_agent() {
    local window_name=$1
    local task_id=$2
    local task_description=$3
    local claude_instruction=$4
    
    log_info "🤖 $window_name 完全自動起動中..."
    
    # Claude Code自動起動
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '🚀 $task_id 完全自動起動中...'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo 'タスク: $task_description'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '自動指示: $claude_instruction'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'" Enter
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "echo ''" Enter
    
    # Claude Code起動
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "claude" Enter
    
    # 3秒待機してからメッセージ送信
    sleep 3
    
    # 自動でClaude Codeに指示を送信
    tmux send-keys -t "$SESSION_NAME:$window_name.0" "$claude_instruction" Enter
    
    log_success "$window_name エージェント完全自動起動完了"
}

log_info "Phase 2並列エージェント完全自動起動開始..."

# 並列でClaude Codeエージェント起動
{
    auto_start_claude_agent "quill-html-agent" "T2-QU-001-A" "Quill.js HTMLファイル作成" \
    "T2-QU-001-A: Quill.js HTMLファイル作成を開始してください。docs/tasks.mdで完了条件を確認し、web/quill/index.htmlを作成し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"
} &

{
    auto_start_claude_agent "gemini-api-agent" "T3-AI-002-A" "Gemini API基盤実装" \
    "T3-AI-002-A: Gemini API基盤実装を開始してください。docs/tasks.mdで完了条件を確認し、backend/functions/でGemini APIクライアントを実装し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"
} &

# 少し遅延してWebView統合（依存関係があるため）
sleep 5

{
    auto_start_claude_agent "webview-integration-agent" "T2-QU-002-A" "WebView Flutter統合" \
    "T2-QU-002-A: WebView Flutter統合を開始してください。T2-QU-001-A完了後に実行してください。docs/tasks.mdで完了条件を確認し、Flutter WebViewでQuill.jsを統合し、TDD (Red→Green→Refactor) で実装してください。完了後、tasks.mdのチェックボックスを更新してください。"
} &

wait

echo ""
log_success "🎉 全Claude Codeエージェントが自動起動しました！"
echo ""
echo "📊 監視ダッシュボード:"
echo "   ./scripts/monitor_parallel_agents.sh"
echo ""
echo "📱 Tmuxセッション接続:"
echo "   tmux attach-session -t yutori-parallel"
echo ""
echo "🎯 各ウィンドウ確認:"
echo "   C-b 1: Quill.js HTMLエージェント"
echo "   C-b 2: WebView統合エージェント"  
echo "   C-b 3: Gemini APIエージェント"
echo ""
echo "🚀 Phase 2並列実装が自動開始されました！" 