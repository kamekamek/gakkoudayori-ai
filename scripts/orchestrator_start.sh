#!/usr/bin/env bash
# ------------------------------------------------------------
#   orchestrator_start.sh
#   オーケストレーターシステム起動
#   セットアップ済み環境の起動用
# ------------------------------------------------------------
set -euo pipefail

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_orchestrator() { echo -e "${PURPLE}[ORCHESTRATOR]${NC} $1"; }

# 環境確認
check_environment() {
    log_info "環境確認中..."
    
    # Tmux確認
    if ! command -v tmux >/dev/null 2>&1; then
        log_error "tmuxが必要です"
        exit 1
    fi
    
    # Git worktree確認
    if ! git worktree list | grep -q "yutori-parent-"; then
        log_warning "Git worktreeが見つかりません"
        log_info "セットアップを実行中..."
        ./scripts/orchestrator_setup.sh
        return
    fi
    
    # 通信ライブラリ確認
    if [[ ! -f "scripts/communication.sh" ]]; then
        log_error "通信ライブラリが見つかりません"
        exit 1
    fi
    
    log_success "環境確認完了"
}

# 既存セッション確認・接続
check_existing_session() {
    if tmux has-session -t orchestrator 2>/dev/null; then
        log_warning "既存のorchestratorセッションが見つかりました"
        
        read -p "既存セッションに接続しますか？ (y/n): " connect_existing
        if [[ "$connect_existing" =~ ^[Yy]$ ]]; then
            log_info "既存セッションに接続中..."
            exec tmux attach-session -t orchestrator
        else
            log_info "既存セッションを終了中..."
            tmux kill-session -t orchestrator
        fi
    fi
}

# システム起動
start_system() {
    log_orchestrator "オーケストレーターシステム起動中..."
    
    # セットアップ実行（worktreeとtmuxセッション作成）
    ./scripts/orchestrator_setup.sh
    
    log_success "システム起動完了"
}

# 接続案内
show_connection_info() {
    log_orchestrator "🎯 接続情報"
    echo ""
    echo "📋 セッション接続:"
    echo "  tmux attach-session -t orchestrator"
    echo ""
    echo "🤖 Claude Code統合:"
    echo "  1. セッションに接続後、通信ライブラリを読み込み:"
    echo "     source ./scripts/communication.sh"
    echo ""
    echo "  2. 利用可能コマンド:"
    echo "     - task_distribute 'Quill.js統合実装'"
    echo "     - send_to_parent 1 'HTML基盤実装開始'"
    echo "     - send_to_child 1 1 'index.html作成'"
    echo "     - status_all"
    echo "     - collect_reports"
    echo ""
    echo "📍 ペイン配置:"
    echo "┌─────────┬─────────┬─────────┐"
    echo "│ Pane 0  │ Pane 1  │ Pane 2  │"
    echo "│Parent1  │Child1-1 │Child1-2 │"
    echo "│ Quill   │  HTML   │   JS    │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 3  │ Pane 4  │ Pane 5  │"
    echo "│Parent2  │Child2-1 │Child2-2 │"
    echo "│ WebView │ Flutter │ Bridge  │"
    echo "├─────────┼─────────┼─────────┤"
    echo "│ Pane 6  │ Pane 7  │ Pane 8  │"
    echo "│Parent3  │Child3-1 │Child3-2 │"
    echo "│ Gemini  │   API   │Response │"
    echo "└─────────┴─────────┴─────────┘"
    echo ""
    echo "🚀 推奨作業フロー:"
    echo "  1. 各ペインでClaude Code起動"
    echo "  2. オーケストレーター(Pane 0)から指示開始"
    echo "  3. 親エージェントが子に分解指示"
    echo "  4. 完了報告・統合テスト"
    echo ""
    
    log_warning "⚠️ ターミナルサイズを大きく設定してください（推奨: 200x50以上）"
}

# 自動接続オプション
auto_connect() {
    local auto_connect_flag="$1"
    
    if [[ "$auto_connect_flag" == "auto" || "$auto_connect_flag" == "-a" ]]; then
        log_info "自動接続モードで起動中..."
        check_environment
        check_existing_session
        start_system
        log_info "自動接続中..."
        exec tmux attach-session -t orchestrator
    fi
}

# メイン実行
main() {
    log_orchestrator "🎯 Claude Code オーケストレーター起動システム"
    
    # 自動接続チェック
    if [[ $# -gt 0 ]]; then
        auto_connect "$1"
    fi
    
    check_environment
    check_existing_session  
    start_system
    show_connection_info
    
    echo ""
    read -p "今すぐセッションに接続しますか？ (y/n): " connect_now
    if [[ "$connect_now" =~ ^[Yy]$ ]]; then
        log_info "セッションに接続中..."
        exec tmux attach-session -t orchestrator
    else
        log_info "後で以下のコマンドで接続してください:"
        echo "  tmux attach-session -t orchestrator"
    fi
}

# 使用方法
usage() {
    echo "使用方法: $0 [auto|-a]"
    echo ""
    echo "オプション:"
    echo "  auto, -a    自動接続モード（確認なしで接続）"
    echo ""
    echo "例:"
    echo "  $0          # 対話モード"
    echo "  $0 auto     # 自動接続"
}

# 引数処理
if [[ $# -gt 0 && ("$1" == "help" || "$1" == "-h" || "$1" == "--help") ]]; then
    usage
    exit 0
fi

# 実行
main "$@" 