#!/bin/bash
# 段階的Claude Code起動システム (依存関係考慮型)

set -e

SESSION_NAME="yutori-parallel"
PROJECT_ROOT="/Users/kamenonagare/yutorikyoshitu"

# ログ関数
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_warning() { echo "⚠️  $1"; }

echo "🚀 Phase 2段階的Claude Code起動システム"
echo "======================================"

# Claude Code存在確認
check_claude_availability() {
    log_info "Claude Code確認中..."
    
    if ! command -v claude >/dev/null 2>&1; then
        echo "❌ claude コマンドが見つかりません"
        echo ""
        echo "Claude Codeのインストール手順:"
        echo "1. https://claude.ai/download からダウンロード"
        echo "2. インストール後、ターミナルで 'claude' コマンドが利用可能か確認"
        exit 1
    fi
    
    log_success "Claude Code確認完了"
}

# Tmuxセッション確認
check_tmux_session() {
    log_info "Tmuxセッション確認中..."
    
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "❌ Tmuxセッション '$SESSION_NAME' が見つかりません"
        echo ""
        echo "環境セットアップが必要です:"
        echo "  ./scripts/setup_parallel_v2.sh"
        exit 1
    fi
    
    log_success "Tmuxセッション確認完了"
}

# Phase 1: 優先エージェント起動（Quill.js + Gemini API）
start_priority_agents() {
    log_info "Phase 1: 優先エージェント起動中..."
    echo ""
    
    # Quill.js HTMLエージェント起動
    log_info "🎨 Quill.js HTMLエージェント起動中..."
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "echo '🚀 T2-QU-001-A: Quill.js HTMLファイル作成 エージェント起動'" Enter
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "echo '優先度: PRIORITY | 他のエージェントが待機中'" Enter
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "claude" Enter
    
    sleep 2
    
    # 初期指示送信
    tmux send-keys -t "$SESSION_NAME:quill-html-agent.0" "あなたはquill-html-agentです。T2-QU-001-A: Quill.js HTMLファイル作成を開始してください。CLAUDE.mdの指示に従い、web/quill/index.htmlを作成してください。完了後、他エージェントに通知します。" Enter
    
    log_success "Quill.js HTMLエージェント起動完了"
    
    # Gemini APIエージェント起動（並列）
    log_info "🤖 Gemini APIエージェント起動中..."
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "echo '🚀 T3-AI-002-A: Gemini API基盤実装 エージェント起動'" Enter
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "echo '優先度: PARALLEL | Quill.jsと並列実行'" Enter
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "claude" Enter
    
    sleep 2
    
    # 初期指示送信
    tmux send-keys -t "$SESSION_NAME:gemini-api-agent.0" "あなたはgemini-api-agentです。T3-AI-002-A: Gemini API基盤実装を開始してください。CLAUDE.mdの指示に従い、backend/functions/services/gemini_client.pyを実装してください。" Enter
    
    log_success "Gemini APIエージェント起動完了"
    echo ""
}

# Phase 2: 依存エージェント起動（WebView統合）
start_dependent_agent() {
    log_info "Phase 2: 依存エージェント準備中..."
    echo ""
    
    # WebView統合エージェント準備
    log_info "📱 WebView統合エージェント準備中..."
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "clear" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo '⏳ T2-QU-002-A: WebView Flutter統合 エージェント待機中'" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo '依存関係: T2-QU-001-A完了待ち'" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo '🎯 T2-QU-001-A完了後に自動起動します'" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo 'または手動起動: claude'" Enter
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "echo ''" Enter
    
    log_success "WebView統合エージェント準備完了（待機状態）"
    echo ""
}

# Phase 3: 監視・通知システム起動
start_monitoring_system() {
    log_info "Phase 3: 監視システム起動中..."
    echo ""
    
    # コントロールパネルに監視情報表示
    tmux send-keys -t "$SESSION_NAME:control" "echo '📊 エージェント監視システム起動中...'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '🎯 現在の状況:'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '  🚀 quill-html-agent: 実行中'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '  🚀 gemini-api-agent: 実行中'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '  ⏳ webview-integration-agent: 待機中'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo ''" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '📋 手動操作:'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '  エージェント通信: ./scripts/agent_communication.sh'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo '  進捗確認: ./scripts/monitor_integration.sh'" Enter
    tmux send-keys -t "$SESSION_NAME:control" "echo ''" Enter
    
    log_success "監視システム起動完了"
}

# WebView統合エージェント手動起動
start_webview_agent_manually() {
    log_info "📱 WebView統合エージェント手動起動..."
    
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "claude" Enter
    sleep 2
    tmux send-keys -t "$SESSION_NAME:webview-integration-agent.0" "あなたはwebview-integration-agentです。T2-QU-002-A: WebView Flutter統合を開始してください。CLAUDE.mdの指示に従い、Quill.jsとFlutterを統合してください。" Enter
    
    log_success "WebView統合エージェント手動起動完了"
}

# 使用方法表示
show_usage() {
    echo "🤖 段階的Claude Code起動システム"
    echo "================================"
    echo ""
    echo "使用方法:"
    echo "  $0                    # 自動段階起動"
    echo "  $0 --webview         # WebView統合エージェント手動起動"
    echo "  $0 --status          # 起動状況確認"
    echo ""
    echo "起動順序:"
    echo "  Phase 1: quill-html-agent + gemini-api-agent (並列)"
    echo "  Phase 2: webview-integration-agent (依存待ち)"
    echo "  Phase 3: 監視システム"
    echo ""
}

# 起動状況確認
check_startup_status() {
    echo "📊 Claude Code起動状況確認:"
    echo ""
    
    # 各ウィンドウの状況確認
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "🤖 quill-html-agent:"
        tmux capture-pane -t "$SESSION_NAME:quill-html-agent.0" -p | tail -3
        echo ""
        
        echo "🤖 gemini-api-agent:"
        tmux capture-pane -t "$SESSION_NAME:gemini-api-agent.0" -p | tail -3
        echo ""
        
        echo "🤖 webview-integration-agent:"
        tmux capture-pane -t "$SESSION_NAME:webview-integration-agent.0" -p | tail -3
        echo ""
    else
        echo "❌ Tmuxセッションが見つかりません"
    fi
}

# メイン処理
main() {
    case "${1:-}" in
        "--webview")
            check_tmux_session
            start_webview_agent_manually
            ;;
        "--status")
            check_startup_status
            ;;
        "--help"|"-h")
            show_usage
            ;;
        "")
            # 自動段階起動
            check_claude_availability
            check_tmux_session
            echo ""
            start_priority_agents
            start_dependent_agent
            start_monitoring_system
            echo ""
            log_success "🎉 段階的Claude Code起動完了！"
            echo ""
            echo "📋 次のステップ:"
            echo "1. tmux attach-session -t $SESSION_NAME でセッション確認"
            echo "2. T2-QU-001-A完了後、WebView統合エージェント手動起動:"
            echo "   $0 --webview"
            echo "3. ./scripts/agent_communication.sh --status で進捗確認"
            echo ""
            ;;
        *)
            echo "❌ 不明なオプション: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@" 